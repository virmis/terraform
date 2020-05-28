variable "ENV" {
}

variable "INSTANCE_TYPE" {
  default = "t2.micro"
}

variable "PRIVATE_SUBNETS" {
  type = list
}

variable "PUBLIC_SUBNETS" {
  type = list
}
variable "VPC_ID" {
}

variable "SECURITY_GROUPS" {
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "~/.ssh/id_rsa.pub"
}

### ALB
resource "aws_lb" "ec2lb" {
  name               = "${var.ENV}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${var.SECURITY_GROUPS}"]
  subnets = var.PUBLIC_SUBNETS

  tags          = {
    Environment = "${var.ENV}"
    Name        = "${var.ENV}-alb"
  }
}

resource "aws_lb_target_group" "ec2_web_servers" {
  name     = "${var.ENV}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.VPC_ID
}

resource "aws_lb_listener" "ec2_web_servers" {
  load_balancer_arn = aws_lb.ec2lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_web_servers.arn
  }
}

resource "aws_lb_target_group_attachment" "ec2_web_servers" {
  target_group_arn = aws_lb_target_group.ec2_web_servers.arn
  target_id        = aws_instance.instance.id
  port             = 80

  depends_on = [aws_instance.instance]
}

output "alb_tg_arn" {
  description = "ALB target group ARN"
  value       = aws_lb_target_group.ec2_web_servers.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value        = aws_lb.ec2lb.dns_name
}


### EC2
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.INSTANCE_TYPE
  subnet_id = element(var.PRIVATE_SUBNETS, 0)
  vpc_security_group_ids = [aws_security_group.allow-from-alb.id]
  key_name = aws_key_pair.mykeypair.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
echo "<h2>EC2 in private subnet behind ALB</h2>" | sudo tee /var/www/html/index.html
sudo systemctl start apache2
sudo systemctl enable apache2
EOF

  tags = {
    Name        = "private-${var.ENV}"
    Environment = var.ENV
  }
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}

resource "aws_security_group" "allow-from-alb" {
  vpc_id      = var.VPC_ID
  name        = "allow-from-alb-${var.ENV}"
  description = "security group that allows http from ALB and all egress traffic"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${var.SECURITY_GROUPS}"]
  }

  tags = {
    Name        = "allow-from-alb"
    Environment = var.ENV
  }
}

resource "aws_instance" "public_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.INSTANCE_TYPE
  subnet_id = element(var.PUBLIC_SUBNETS, 0)
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  key_name = aws_key_pair.mykeypair.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name        = "public-${var.ENV}"
    Environment = var.ENV
  }
}

output "public_ip" {
  value = aws_instance.public_instance.public_ip
}

resource "aws_security_group" "allow-ssh" {
  vpc_id      = var.VPC_ID
  name        = "allow-ssh-${var.ENV}"
  description = "security group that allows ssh and all egress traffic"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "allow-ssh"
    Environment = var.ENV
  }
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair-${var.ENV}"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}

### IAM ROLES

# Inline policy with read access to S3 and permission to describe tags and idescribe instances
resource "aws_iam_role_policy" "s3_read_ec2_describe_policy" {
  name = "s3_read_ec2_describe_policy"
  role = aws_iam_role.s3_read_ec2_describe_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "s3:DescribeJob",
          "s3:GetAccelerateConfiguration",
          "s3:GetAccessPoint",
          "s3:GetAccessPointPolicy",
          "s3:GetAccessPointPolicyStatus",
          "s3:GetAccountPublicAccessBlock",
          "s3:GetAnalyticsConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketNotification",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketPolicy",
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetInventoryConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetMetricsConfiguration",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectLegalHold",
          "s3:GetObjectRetention",
          "s3:GetObjectTagging",
          "s3:GetObjectTorrent",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionTorrent",
          "s3:GetReplicationConfiguration",
          "s3:HeadBucket",
          "s3:ListAccessPoints",
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListBucketVersions",
          "s3:ListJobs",
          "s3:ListMultipartUploadParts",
          "tag:DescribeReportCreation",
          "tag:GetComplianceSummary",
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF

}

resource "aws_iam_role" "s3_read_ec2_describe_role" {
  name = "s3_read_ec2_describe_role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF

  tags = {
    Name        = "s3_read_ec2_describe_role"
    Environment = var.ENV
  }

}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.s3_read_ec2_describe_role.name
}

