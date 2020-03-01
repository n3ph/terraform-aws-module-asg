#------------------------------------------------------------------------------#
# Global
#------------------------------------------------------------------------------#

variable "name" {
  description = "Name of this autoscaling group and the related resources"
}

#------------------------------------------------------------------------------#
# Launch configuration
#------------------------------------------------------------------------------#

variable "image_id" {
  description = "EC2 image ID to use"
}

variable "instance_type" {
  description = "EC2 instance type"
}

variable "security_groups" {
  description = "List of security groups to assign to the launch configuration"
  type        = "list"
}

variable "root_block_device" {
  description = "List of root device map"
  type        = "list"
}

variable "ebs_block_device" {
  description = "list of additional device maps"
  default     = []
}

variable "associate_public_ip_address" {
  description = "Trigger to add an public ip address association"
  default     = false
}

variable "spot_price" {
  description = "Price to pay for spot instaces on market. Keep empty to not use spot instances"
  default     = ""
}

#------------------------------------------------------------------------------#
# Autoscaling group
#------------------------------------------------------------------------------#

variable "vpc_id" {
  description = "VPC ID"
}

variable "subnet_ids" {
  description = "List of subnets IDs to use"
  type        = "list"
}

variable "min_size" {
  description = "ASG minimum size"
}

variable "max_size" {
  description = "ASG maximum size"
}

variable "desired_capacity" {
  description = "ASG desired capacity"
}

variable "health_check_type" {
  description = "Controls how health checking is done. Values are - EC2 and ELB"
}

variable "load_balancers" {
  description = "A list of elastic load balancer names to add to the autoscaling group names"
  default     = []
}

variable "target_group_arns" {
  description = "A list of aws_alb_target_group ARNs, for use with Application Load Balancing"
  default     = []
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. (See also Waiting for Capacity below.) Setting this to '0' causes Terraform to skip all Capacity Waiting behavior."
  default     = "10m"
}

variable "wait_for_elb_capacity" {
  description = "Setting this will cause Terraform to wait for exactly this number of healthy instances in all attached load balancers."
  default     = false
}

variable "default_cooldown" {
  description = "Time between a scaling activity and the succeeding scaling activity."
  default     = 300
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health."
  default     = 300
}

#------------------------------------------------------------------------------#
# DDNS
#------------------------------------------------------------------------------#

variable "forward_zone_id" {
  description = "Route53 Forward Zone Id for DDNS"
}

variable "reverse_zone_id_list" {
  description = "List of all Route53 Reverse Zone Id's for DDNS"
  default     = []
}

#------------------------------------------------------------------------------#
# IAM
#------------------------------------------------------------------------------#

variable "iam_policy_documents" {
  description = "List of policy documents to attach to ec2 role"
  default     = []
}
