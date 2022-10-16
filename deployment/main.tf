terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.17.0"
    }
    azapi = {
      source  = "Azure/azapi"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

variable "admin_username" {
  type = string
}
variable "admin_password" {
  type = string
}
variable "cluster_username" {
  type = string
}
variable "cluster_password" {
  type = string
}
