variable "region" {
  default = "us-east-1"
}

variable "number_of_public_subnets" {
  default = 3
}

variable "webservers_ami" {
  default = "ami-0778521d914d23bc1"
}

variable "instance_type" {
  default = "t2.micro"
}
