variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro" 
}

variable "key_name" {
  description = "The name of the SSH key pair to associate with the EC2 instance"
  type        = string
  default     = "verticurl" 
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"  
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"                                     
}