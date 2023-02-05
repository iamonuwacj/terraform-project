# Create a AWS VPC which contains the following
#   - VPC
#   - Public subnet(s)
#   - Private subnet(s)
#   - Internet Gateway
#   - Routing table

resource "aws_vpc" "alt-terra" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # Internal domain name
  enable_dns_hostnames = true # Internal host name

  tags = {
    Name = "testapp-vpc"
  }
}

resource "aws_subnet" "testapp_public_subnet" {
  # Number of public subnet is defined in vars
  count = var.number_of_public_subnets

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index + 2}.0/24"
  vpc_id                  = aws_vpc.alt-terra.id
  map_public_ip_on_launch = true # This makes the subnet public

  tags = {
    Name = "testapp-public-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "testapp_internet_gateway" {
  vpc_id = aws_vpc.alt-terra.id

  tags = {
    Name = "alt-terra-internet-gateway"
  }
}

resource "aws_route_table" "testapp_route_table" {
  vpc_id = aws_vpc.alt-terra.id

  route {
    # Associated subet can reach public internet
    cidr_block = "0.0.0.0/0"

    # Which internet gateway to use
    gateway_id = aws_internet_gateway.testapp_internet_gateway.id
  }

  tags = {
    Name = "alt-terra-public-custom-rtb"
  }
}

resource "aws_route_table_association" "testapp-custom-rtb-public-subnet" {
  count          = 3
  route_table_id = aws_route_table.testapp_route_table.id
  subnet_id      = aws_subnet.testapp_public_subnet.*.id[count.index]
}

resource "aws_security_group" "webservers" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.alt-terra.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "webservers" {
  count           = 3
  ami             = var.webservers_ami
  instance_type   = var.instance_type
  key_name        = "tf-key-pair"
  security_groups = [aws_security_group.webservers.id]
  subnet_id       = aws_subnet.testapp_public_subnet.*.id[count.index]

provisioner "local-exec" {
    command = "echo '${self.public_ip}' >> ./host_inventory"
  }

  tags = {
    Name = "Server-${count.index}"
  }
}

resource "null_resource" "ansible-playbook" {
  provisioner "local-exec" {
    command = "ansible-playbook -i host_inventory --key-file tf-key-pair.pem mini-project-playbook.yml"
  }

  depends_on = [aws_instance.webservers]
}

