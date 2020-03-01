#------------------------------------------------------------------------------#
# IAM
#------------------------------------------------------------------------------#

data "aws_iam_policy_document" "main_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "main" {
  name_prefix        = "ec2-${lower(var.name)}-"
  assume_role_policy = "${data.aws_iam_policy_document.main_role.json}"
}

resource "aws_iam_role_policy" "main" {
  count = "${length(var.iam_policy_documents)}"

  name_prefix = "${lower(var.name)}"
  role        = "${aws_iam_role.main.id}"
  policy      = "${element(var.iam_policy_documents, count.index)}"
}

resource "aws_iam_instance_profile" "main" {
  name = "${lower(var.name)}"
  role = "${aws_iam_role.main.name}"
}

#------------------------------------------------------------------------------#
# Boot script Template
#------------------------------------------------------------------------------#

data "template_file" "user_data" {
  template = "${file("${path.module}/init.sh")}"

  vars {
    hostname_prefix = "${lower(var.name)}"
    domain          = "${replace(data.aws_route53_zone.forward_zone.name, "/.$/", "")}"
  }
}

#------------------------------------------------------------------------------#
# Launch Configuration
#------------------------------------------------------------------------------#

resource "aws_launch_configuration" "main" {
  name_prefix = "${lower(var.name)}"

  # instance type
  image_id      = "${var.image_id}"
  instance_type = "${var.instance_type}"
  spot_price    = "${var.spot_price}"

  # vpc
  security_groups             = ["${var.security_groups}"]
  associate_public_ip_address = "${var.associate_public_ip_address}"

  # storage
  root_block_device = ["${var.root_block_device}"]
  ebs_block_device  = ["${var.ebs_block_device}"]

  # customization
  user_data            = "${data.template_file.user_data.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.main.arn}"

  # monitoring
  enable_monitoring = true

  lifecycle {
    create_before_destroy = true
  }
}
