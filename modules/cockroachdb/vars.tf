variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = list(string)
}

variable "nlb_subnet_ids" {
  type = list(string)
}

variable "fqdn" {
  type= string
}

variable "cockroach_version" {
  type = string
  default = "v20.2.3"
}

variable "ca_crt_path" {
  type = string
}

variable "ca_key_path" {
  type = string
}