variable "sales_access_key" {}

variable "sales_secret_key" {}

variable "region" {
  default = "eu-west-3"
}

variable "environment" {
  default = "dev"
}

variable "sales_vpc_cidr" {
  default = "10.20.0.0/16"
}

variable "sales_AZ" {
  default = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
}

variable "sales_public_subnet" {
    type = list
  default = ["10.20.0.0/20", "10.20.16.0/20", "10.20.32.0/20"]
}

variable "sales_private_subnet" {
  default = ["10.20.128.0/20", "10.20.144.0/20", "10.20.160.0/20"]
}

# Custom validation on 