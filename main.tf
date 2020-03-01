terraform {
  required_version = ">= 0.11.3"
}

#------------------------------------------------------------------------------#
# DNS
#------------------------------------------------------------------------------#

data "aws_route53_zone" "forward_zone" {
  zone_id = "${var.forward_zone_id}"
}

#------------------------------------------------------------------------------#
# Autoscaling Group
#------------------------------------------------------------------------------#

resource "aws_autoscaling_group" "main" {
  name                 = "${aws_launch_configuration.main.name}"
  launch_configuration = "${aws_launch_configuration.main.name}"

  # vpc
  vpc_zone_identifier = ["${var.subnet_ids}"]

  # capacity
  min_size              = "${var.min_size}"
  max_size              = "${var.max_size}"
  desired_capacity      = "${var.desired_capacity}"
  wait_for_elb_capacity = "${var.wait_for_elb_capacity}"

  # scaling
  default_cooldown = "${var.default_cooldown}"

  health_check_type         = "${var.health_check_type}"
  health_check_grace_period = "${var.health_check_grace_period}"

  wait_for_capacity_timeout = "${var.wait_for_capacity_timeout}"
  termination_policies      = ["Default"]

  # metrics
  enabled_metrics     = []
  metrics_granularity = "1Minute"

  # load balancing
  target_group_arns = ["${var.target_group_arns}"]

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "lambda:ddns:name"
      value               = "${var.name}"
      propagate_at_launch = true
    },
    {
      key                 = "lambda:ddns:ZoneId"
      value               = "${var.forward_zone_id}"
      propagate_at_launch = true
    },
    {
      key                 = "lambda:ddns:Domain"
      value               = "${replace(data.aws_route53_zone.forward_zone.name, "/.$/", "")}"
      propagate_at_launch = true
    },
    {
      key                 = "lambda:ddns:SingleHost"
      value               = "${var.max_size == 1 ? true : false}"
      propagate_at_launch = true
    },
    {
      key                 = "lambda:ddns:IsPublic"
      value               = "${var.associate_public_ip_address}"
      propagate_at_launch = true
    },
    {
      key                 = "lambda:ddns:ReverseZoneIdMap"
      value               = "${jsonencode(zipmap(var.subnet_ids,var.reverse_zone_id_list))}"
      propagate_at_launch = true
    },
  ]
}

output "name" {
  value = "${aws_autoscaling_group.main.name}"
}
