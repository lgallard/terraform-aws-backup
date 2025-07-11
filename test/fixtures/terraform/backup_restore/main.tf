# Test fixture for backup restoration scenarios
# This creates resources that can be backed up and restored

# Create a VPC for testing
resource "aws_vpc" "test_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name            = "${var.resource_prefix}-test-vpc"
    Environment     = "test"
    BackupRequired  = "true"
    SecurityLevel   = "high"
    TestScenario    = "backup-restore"
  }
}

# Create a subnet
resource "aws_subnet" "test_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name            = "${var.resource_prefix}-test-subnet"
    Environment     = "test"
    BackupRequired  = "true"
    SecurityLevel   = "high"
    TestScenario    = "backup-restore"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name            = "${var.resource_prefix}-test-igw"
    Environment     = "test"
    TestScenario    = "backup-restore"
  }
}

# Create a route table
resource "aws_route_table" "test_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name            = "${var.resource_prefix}-test-rt"
    Environment     = "test"
    TestScenario    = "backup-restore"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "test_rta" {
  subnet_id      = aws_subnet.test_subnet.id
  route_table_id = aws_route_table.test_rt.id
}

# Create a security group
resource "aws_security_group" "test_sg" {
  name        = "${var.resource_prefix}-test-sg"
  description = "Security group for backup restore testing"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name            = "${var.resource_prefix}-test-sg"
    Environment     = "test"
    TestScenario    = "backup-restore"
  }
}

# Create an EBS volume with test data
resource "aws_ebs_volume" "test_volume" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 8
  type              = "gp3"
  encrypted         = true

  tags = {
    Name            = "${var.resource_prefix}-test-volume"
    Environment     = "test"
    BackupRequired  = "true"
    SecurityLevel   = "high"
    TestScenario    = "backup-restore"
    DataIntegrity   = "test-data-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  }
}

# Create an EC2 instance for testing
resource "aws_instance" "test_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.test_subnet.id
  vpc_security_group_ids = [aws_security_group.test_sg.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    volume_id = aws_ebs_volume.test_volume.id
  }))

  tags = {
    Name            = "${var.resource_prefix}-test-instance"
    Environment     = "test"
    BackupRequired  = "true"
    SecurityLevel   = "high"
    TestScenario    = "backup-restore"
  }
}

# Attach the EBS volume to the instance
resource "aws_volume_attachment" "test_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.test_volume.id
  instance_id = aws_instance.test_instance.id
}

# Create a DynamoDB table for testing
resource "aws_dynamodb_table" "test_table" {
  name           = "${var.resource_prefix}-test-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name            = "${var.resource_prefix}-test-table"
    Environment     = "test"
    BackupRequired  = "true"
    SecurityLevel   = "high"
    TestScenario    = "backup-restore"
  }
}

# Add test data to DynamoDB table
resource "aws_dynamodb_table_item" "test_item" {
  table_name = aws_dynamodb_table.test_table.name
  hash_key   = aws_dynamodb_table.test_table.hash_key

  item = jsonencode({
    id = {
      S = "test-item-1"
    }
    data = {
      S = "test-data-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    }
    created_at = {
      S = timestamp()
    }
  })
}

# Create backup plan for testing
module "backup" {
  source = "../../../../"

  vault_name = var.vault_name
  plan_name  = var.plan_name

  rules = [
    {
      name                     = "immediate-backup"
      schedule                 = null  # Manual backup for testing
      start_window             = 60
      completion_window        = 120
      enable_continuous_backup = false
      
      lifecycle = {
        delete_after = 7  # Short retention for testing
      }
      
      recovery_point_tags = {
        TestScenario = "backup-restore"
        Environment  = "test"
      }
    }
  ]

  selections = {
    "test-resources" = {
      resources = [
        aws_ebs_volume.test_volume.arn,
        aws_instance.test_instance.arn,
        aws_dynamodb_table.test_table.arn
      ]
      
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "BackupRequired"
          value = "true"
        }
      ]
    }
  }

  tags = {
    Environment     = "test"
    TestScenario    = "backup-restore"
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}