locals {
  resource_group_name   = element(coalescelist(data.azurerm_resource_group.infra.*.name, azurerm_resource_group.infra.*.name, [""]), 0)
  location              = element(coalescelist(data.azurerm_resource_group.infra.*.location, azurerm_resource_group.infra.*.location, [""]), 0)
}

data "azurerm_resource_group" "infra" {
  count                 = var.create_resource_group == false ? 1 : 0
  name                  = var.resource_group_name
}

resource "azurerm_resource_group" "infra" {
  count                 = var.create_resource_group == true ? 1 : 0
  location              = var.resource_group_location
  name                  = var.resource_group_name
  tags                  = var.tags
}

data "azurerm_subnet" "infra" {
  name                  = var.subnet_name
  virtual_network_name  = var.vnet_name
  resource_group_name   = var.vnet_rg_name
}

data "azurerm_private_dns_zone" "infra" {
  name                  = var.pvt_dns_zone_name
  resource_group_name   = var.pvt_rg_name
}

data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "psql" {
  name                   = var.kv_pointer_name
  resource_group_name    = var.kv_pointer_rg
}

resource "random_password" "psql" {
  length  = 16
  special = false
}

#Create Key Vault Secret
resource "azurerm_key_vault_secret" "psql" {
  name         = var.mypostgre_fs_name
  value        = random_password.psql.result
  key_vault_id = data.azurerm_key_vault.psql.id
}

# Manages the PSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "infra" {
  name                   = var.mypostgre_fs_name
  resource_group_name    = local.resource_group_name
  location               = var.resource_group_location
  version                = var.server_ver
  delegated_subnet_id    = data.azurerm_subnet.infra.id
  private_dns_zone_id    = data.azurerm_private_dns_zone.infra.id
  administrator_login    = var.admin_username
  administrator_password = azurerm_key_vault_secret.psql.value
  zone                   = var.server_zone == null ? 0 : 1
  storage_mb             = var.size_mb
  sku_name               = var.sku
  backup_retention_days  = var.bkp_retention_days
  maintenance_window {
    day_of_week = 3
    start_hour  = 20
    start_minute = 0
  }

  tags = var.tags

  depends_on     = [
    data.azurerm_subnet.infra, data.azurerm_private_dns_zone.infra
  ]

  lifecycle {
    ignore_changes = [
      administrator_password, administrator_login, tags, zone
    ]
  }
  
}

  
