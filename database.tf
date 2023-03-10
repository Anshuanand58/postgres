resource "azurerm_postgresql_flexible_server_database" "psql" {
  for_each            = var.databases
  name                = each.key
  server_id           = azurerm_postgresql_flexible_server.infra.id
  charset             = lookup(each.value, "charset", "utf8")
  collation           = lookup(each.value, "collation", "en_US.utf8")
}

resource "azurerm_postgresql_flexible_server_configuration" "psql-default" {
  for_each = var.server_parameters_default
  name      = each.key
  server_id = azurerm_postgresql_flexible_server.infra.id
  value     = each.value
}

resource "azurerm_postgresql_flexible_server_configuration" "psql-variable" {
  for_each = var.server_parameters_variable
  name      = each.key
  server_id = azurerm_postgresql_flexible_server.infra.id
  value     = each.value
}
