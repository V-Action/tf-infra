variable "porta_http" {
    description = "porta http"
    default = 80
    type = number
}

variable "porta_https" {
    description = "porta https"
    default = 443
    type = number
}

variable "porta_ssh" {
    description = "porta ssh"
    default = 22
    type = number
}

variable "porta_mysql" {
    description = "porta mysql"
    default = 3306
    type = number
}

variable "zona_disponibilidade" {
    description = "zona_disponibilidade"
    default = "us-east-1"
    type = string
}

variable "email_list" {
    description = "Lista de e-mails para o SNS e Lambda"
    type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR principal da VPC"
  type        = string
  default     = "10.0.0.0/21"
}
