resource "aws_security_group" "cockroachdb-node-sg" {
  name        = "cockroachdb-node-sg"
  description = "Cockroachdb node security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Intra cluster"
    from_port   = 26257
    to_port     = 26257
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Intra cluster"
    from_port   = 26257
    to_port     = 26257
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_block
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "console"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_lb" "loadbalancer" {
#   name               = "test-lb-tf"
#   internal           = false
#   load_balancer_type = "network"
#   subnets            = var.nlb_subnet_ids
# }

resource "aws_iam_role_policy" "aws_opsworks_service_role_policy" {
  name   = "aws_opsworks_service_role_policy"
  role   = aws_iam_role.aws_opsworks_service_role.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
                "ec2:*",
                "iam:PassRole",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:DescribeAlarms",
                "ecs:*",
                "elasticloadbalancing:*",
                "rds:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}
resource "aws_iam_role" "aws_opsworks_service_role" {
  name                  = "aws_opsworks_service_role"
  force_detach_policies = true
  assume_role_policy    = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "opsworks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
    EOF
}

resource "aws_iam_instance_profile" "aws_opsworks_instance_profile" {
  name = "aws_opsworks_instance_profile"
  role = aws_iam_role.aws_opsworks_instance_profile_role.name
}

resource "aws_iam_role" "aws_opsworks_instance_profile_role" {
  name                  = "aws_opsworks_instance_profile"
  force_detach_policies = true
  assume_role_policy    = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
    EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.aws_opsworks_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_region" "region" {}


resource "aws_opsworks_stack" "main" {
  name                          = "test"
  region                        = data.aws_region.region.name
  service_role_arn              = aws_iam_role.aws_opsworks_service_role.arn
  default_instance_profile_arn  = aws_iam_instance_profile.aws_opsworks_instance_profile.arn
  configuration_manager_version = "12"
  default_os                    = "Amazon Linux 2"
  default_subnet_id             = var.nlb_subnet_ids[0]
  custom_cookbooks_source {
    type = "git"
    url  = "https://github.com/sannithibalaji/cockroachdb_opsworks.git"
  }
  use_custom_cookbooks         = true
  vpc_id                       = var.vpc_id
  use_opsworks_security_groups = false
}

resource "aws_opsworks_custom_layer" "cockroach-db" {
  name                      = "Cockroach-db"
  short_name                = "cockroach-db"
  stack_id                  = aws_opsworks_stack.main.id
  custom_security_group_ids = [aws_security_group.cockroachdb-node-sg.id]
  auto_assign_public_ips    = true
  custom_json               = <<EOF
{
  "fqdn" : "${var.fqdn}",
  "cockroach_version": "${var.cockroach_version}"
}
  EOF
  custom_setup_recipes      = ["opsworks::setup"]
  custom_configure_recipes  = ["opsworks::configure"]
}

resource "aws_opsworks_application" "cockroach-db-app" {
  name       = "cockroach_db_app"
  type       = "other"
  stack_id   = aws_opsworks_stack.main.id
  # environment {
  #   key    = "ca.crt"
  #   value  = file(var.ca_crt_path)
  #   secure = true
  # }
  # environment {
  #   key    = "ca.key"
  #   value  = file(var.ca_key_path)
  #   secure = true
  # }
  enable_ssl = true
  ssl_configuration {
    private_key = file(var.ca_key_path)
    certificate = file(var.ca_crt_path)
  }
  app_source {
    type     = "git"
    revision = "master"
    url      = "https://github.com/example.git"
  }
}

# resource "aws_opsworks_instance" "my-instance" {
#   stack_id = aws_opsworks_stack.main.id

#   layer_ids = [
#     aws_opsworks_custom_layer.cockroach-db.id,
#   ]

#   instance_type = "m5.large"
#   os            = "Amazon Linux 2"
#   state         = "running"
#   security_group_ids = [aws_security_group.cockroachdb-node-sg.id]
#   subnet_id = var.nlb_subnet_ids[0]
#   root_device_type = "ebs"
# }

# resource "aws_opsworks_instance" "my-instance-2" {
#   stack_id = aws_opsworks_stack.main.id

#   layer_ids = [
#     aws_opsworks_custom_layer.cockroach-db.id,
#   ]

#   instance_type = "m5.large"
#   os            = "Amazon Linux 2"
#   state         = "running"
#   security_group_ids = [aws_security_group.cockroachdb-node-sg.id]
#   subnet_id = var.nlb_subnet_ids[1]
#   root_device_type = "ebs"
# }
