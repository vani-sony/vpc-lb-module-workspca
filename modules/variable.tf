variable "region" {
  description = "region is specified"
  
}

variable "vpccidr" {
  description = "calling vpc" 
}

variable "publicsubn1" {
  description = "calling 1st public subnet" 
}
variable "publicsubn2" {
  description = "calling 2 public subnet" 
}

variable "privatesubn1" {
  description = "calling 1st private subnet" 
}
variable "privatesubn2" {
  description = "calling 2 private subnet" 
}

variable "publiroute" {
  description = "route table value"  
}
variable "privroute" {
  description = "private route"
  
}
variable "lbtype" {
  description = "load balencer type" 
}
variable "lt_type" {
    description = "type of launch template"
}
variable "lt_amiid" {
    description = "ami of launch template"
}



