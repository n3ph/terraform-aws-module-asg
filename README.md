# Auto Scaling Group with Dynamic DNS
This module provides functionality for creating an auto scaling group with the
ability to register/unregister the launched/terminated instances in the provided
DNS zone.

## Prerequisites
* An EC2 instance AMI built with `devops/ansible/roles/amiconfig`
* Route53 DNS forward and reverse zones to register/unregister instances in

## Usage
### General
`name` - Name of this autoscaling group and the related resources (**required**)  
`tags` - A map of tags to add to all resources (default: **{}**)  
`default_tags` - A map of default tags to add to all resources (default: **{Terraform = true}**)  

### Launch configuration
`image_id` - EC2 image ID to use (**required**)  
`instance_type` - EC2 instance type **required**)  
`security_groups` - List of security group IDs to assign to the launch configuration **required**)  
`root_block_device` - List of root device map **required**)  
`ebs_block_device` - list of additional device maps (Default: **[]**)  
`associate_public_ip_address` - Trigger to add an public ip address association (Default: **false**)  
`spot_price` - Price to pay for spot instaces on market. Keep empty to not use spot instances (Default: **""**)  

### Autoscaling group
`vpc_id` - VPC Identifier (**required**)  
`subnet_ids` - List of subnets IDs to use (**required**)  
`min_size` - ASG minimum size (Default: **1**)  
`max_size` - ASG maximum size (Default: **1**)  
`desired_capacity` - ASG desired capacity (Default: **1**)  
`health_check_type` - Controls how health checking is done. Values are - EC2 and ELB (**required**)  
`target_group_arns` - A list of aws_alb_target_group ARNs, for use with Application Load Balancing (Default. **[]**)  
`wait_for_capacity_timeout` - A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. (See also Waiting for Capacity below.) Setting this to '0' causes Terraform to skip all Capacity Waiting behavior. (Default. **10m**)   

### DDNS
`private_forward_zone_id` - Route53 Forward Zone Id for DDNS (Default: **""**)  
`public_forward_zone_id` - Route53 Forward Zone Id for DDNS (Default: **""**)  
`variable "reverse_zone_id_list` - List of all Route53 Reverse Zone Id's for DDNS (Default. **[]**)  

### EC2 Policy
`iam_policy_documents` - List of Policy Documents to attach to EC2 Role used for EC2 Instances described via Launch Configuration (Default. **[]**)  

## Testing
You first need to initialize the terrafrom runtime environment
```sh
cd ./test
terraform init
```

To only test the codebase itself you may run:
```sh
terraform plan
```

To actually deploy all coded resources run:
```sh
terraform apply
```
