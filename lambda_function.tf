#------------------------------------------------------------------------------#
# IAM AssumeRole
#------------------------------------------------------------------------------#

data "aws_iam_policy_document" "ddns_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
        "events.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "ddns" {
  name_prefix        = "ddns-${lower(var.name)}-"
  assume_role_policy = "${data.aws_iam_policy_document.ddns_role.json}"
}

#------------------------------------------------------------------------------#
# IAM Policies
#------------------------------------------------------------------------------#

# TODO: restrict access to particular resources
data "aws_iam_policy_document" "ddns" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]

    # TODO: "arn:aws:logs:us-east-1:123456789012:log-group:my-log-group*:log-stream:my-log-stream*"
  }

  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:CreateTags",
    ]

    resources = [
      "*",
    ]

    # TODO: "arn:aws:ec2:region:account-id:instance/instance-id"
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    resources = [
      "${formatlist("arn:aws:route53:::hostedzone/%s", list(var.forward_zone_id))}",
      "${formatlist("arn:aws:route53:::hostedzone/%s", var.reverse_zone_id_list)}",
    ]
  }
}

resource "aws_iam_role_policy" "ddns" {
  name_prefix = "lambda-ddns-"
  role        = "${aws_iam_role.ddns.id}"
  policy      = "${data.aws_iam_policy_document.ddns.json}"
}

#------------------------------------------------------------------------------#
# Lambda function
#------------------------------------------------------------------------------#

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/ddns/lambda.py"
  output_path = "${path.module}/ddns/lambda.zip"
}

resource "aws_lambda_function" "ddns" {
  function_name = "ddns-${lower(var.name)}"
  description   = "Simple dynamic DNS with Route53"

  filename         = "${path.module}/ddns/lambda.zip"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  handler          = "lambda.handler"
  role             = "${aws_iam_role.ddns.arn}"
  runtime          = "python3.6"
  memory_size      = 128
  timeout          = 300
}

#------------------------------------------------------------------------------#
# Cloudwatch log group
#------------------------------------------------------------------------------#

resource "aws_cloudwatch_log_group" "ddns" {
  name              = "/aws/lambda/${aws_lambda_function.ddns.function_name}"
  retention_in_days = 7
}

#------------------------------------------------------------------------------#
# Cloudwatch event trigger
#------------------------------------------------------------------------------#

resource "aws_cloudwatch_event_rule" "ddns" {
  name        = "ddns-${lower(var.name)}"
  description = "EC2 instance launch/termination events in the ASG ${var.name}"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance Launch Successful",
    "EC2 Instance Terminate Successful"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "${aws_launch_configuration.main.name}"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "ddns" {
  target_id = "lambda"
  rule      = "${aws_cloudwatch_event_rule.ddns.name}"
  arn       = "${aws_lambda_function.ddns.arn}"
}

resource "aws_lambda_permission" "ddns" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ddns.arn}"
  source_arn    = "${aws_cloudwatch_event_rule.ddns.arn}"
  principal     = "events.amazonaws.com"
  statement_id  = "allow-cloudwatch-invocation"
}
