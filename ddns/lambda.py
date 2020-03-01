import json
import boto3
from botocore.exceptions import ClientError

# Globals {{{
route53 = boto3.client('route53')
# }}}

# Route53 helper {{{
def change_record(
        *,                      # force using keyword arguments
        zone_id,
        change,
        record_type = 'A',
        name,
        value,
        ttl = 300):

    if change not in ['UPSERT','DELETE']:
        raise Exception('Incorrect argument ' + change)

    print("Zone '{}': {} '{}' record '{}' -> '{}'.. ".format(
            zone_id,
            change,
            record_type,
            name,
            value), end = '')

    try:
        route53.change_resource_record_sets(
                HostedZoneId = zone_id,
                ChangeBatch = {
                    'Changes': [
                        {
                            'Action': change,
                            'ResourceRecordSet': {
                                'Type': record_type,
                                'Name': name,
                                'ResourceRecords': [
                                    {
                                        'Value': value
                                        }
                                    ],
                                'TTL': ttl
                                }
                            }
                        ]
                    }
                )
        print("OK")
    except ClientError as e:
        print("Failed: {}".format(e))

# }}}

# Lambda Handler {{{
def handler(event, context):

    # print the event received
    print(json.dumps(event))

    # fetch necessary information
    instance_id = event['detail']['EC2InstanceId']
    subnet_id = event['detail']['Details']['Subnet ID']

    ec2 = boto3.resource('ec2')
    instance = ec2.Instance(instance_id)

    if instance.tags is None:
        raise Exception("Missing required tags in the EC2 instance object")

    ## convert tags to a dict
    tags = dict(map(lambda x: (x['Key'], x['Value']), instance.tags))

    ## ip address
    if event['detail-type'] == 'EC2 Instance Launch Successful':
        if tags['lambda:ddns:IsPublic'] == 'true':
            ip_address = instance.public_ip_address
        else:
            ip_address = instance.private_ip_address

    elif event['detail-type'] == 'EC2 Instance Terminate Successful':
        ip_address = tags['lambda:ddns:IPAddress']

    ## DDNS zone info
    domain = tags['lambda:ddns:Domain']
    zone_id = tags['lambda:ddns:ZoneId']
    reverse_zone_id = json.loads(
            tags['lambda:ddns:ReverseZoneIdMap']
        )[subnet_id]

    # generate fqdn as '<asg_name>-<instance_id>.<domain>', e.g.:
    if tags['lambda:ddns:SingleHost'] == 'true':
        fqdn = "{}.{}".format(
                tags['lambda:ddns:name'],
                domain
                )
    else:
        fqdn = "{}-{}.{}".format(
                tags['lambda:ddns:name'],
                instance_id.split("i-", 1).pop(),
                domain
                )

    # generate reverse fqdn as, e.g., '254.21.128.10.in-addr.arpa.'
    reverse_fqdn = '{}.{}'.format(
            '.'.join(reversed(ip_address.split('.'))),
            'in-addr.arpa.')

    # on instance launch
    if event['detail-type'] == 'EC2 Instance Launch Successful':

        ## create additional instance tags
        instance.create_tags(Tags=[
            {
                'Key' : 'Name',
                'Value' : fqdn
                },
            {
                'Key' : 'lambda:ddns:IPAddress',
                'Value' : ip_address
                }
            ])

        ## create or update the PTR record in the reverse zone
        change_record(
                change      = 'UPSERT',
                zone_id     = reverse_zone_id,
                record_type = 'PTR',
                name        = reverse_fqdn,
                value       = fqdn)

        ## insert/update the A record in the forward zone
        change_record(
                change      = 'UPSERT',
                zone_id     = zone_id,
                name        = fqdn,
                value       = ip_address)

    # on instance termination
    elif event['detail-type'] == 'EC2 Instance Terminate Successful':

        ## remove the PTR record from the reverse zone
        change_record(
                change      = 'DELETE',
                zone_id     = reverse_zone_id,
                record_type = 'PTR',
                name        = reverse_fqdn,
                value       = fqdn)

        ## remove the A record from the forward zone
        change_record(
                change      = 'DELETE',
                zone_id     = zone_id,
                name        = fqdn,
                value       = ip_address)

# }}}
