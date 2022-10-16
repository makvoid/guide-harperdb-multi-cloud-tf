provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aci_rg" {
  name     = "hdbrg"
  location = "France Central"
}

resource "azurerm_container_group" "containergroup" {
  name                  = "hdbgroup"
  resource_group_name   = azurerm_resource_group.aci_rg.name
  location              = azurerm_resource_group.aci_rg.location
  ip_address_type       = "Public"
  dns_name_label        = "hdbnode"
  os_type               = "Linux"

  container {
    name       = "hdbnode"
    image      = "harperdb/harperdb"
    cpu        = "0.5"
    memory     = "1.0"
    ports {
      port     = 9925
      protocol = "TCP"
    }
    ports {
      port     = 9926
      protocol = "TCP"
    }
    ports {
      port     = 9927
      protocol = "TCP"
    }
    environment_variables = {
      "CUSTOM_FUNCTIONS" = "true"
      "HTTPS_ON"         = "true"
      "CLUSTERING"       = "true"
      "CLUSTERING_PORT"  = "9927"
      "NODE_NAME"        = "hdbawsnode"
    }
    secure_environment_variables = {
      "HDB_ADMIN_USERNAME"  = var.admin_username
      "HDB_ADMIN_PASSWORD"  = var.admin_password
      "CLUSTERING_USER"     = var.cluster_username
      "CLUSTERING_PASSWORD" = var.cluster_password
    }
  }

  tags = {
    manager = "terraform"
  }
}