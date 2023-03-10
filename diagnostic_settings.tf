resource "azurerm_monitor_diagnostic_setting" "diagnostic" {
  name               = var.mypostgre_fs_name
  target_resource_id = azurerm_postgresql_flexible_server.infra.id
  storage_account_id = var.storage_account_id

  dynamic "log" {
    for_each = var.logs

    content {
      category_group = log.value.name
      enabled        = log.value.enabled

      retention_policy {
        enabled = log.value.enabled && log.value.retention_days != null ? true : false
        days    = log.value.enabled ? log.value.retention_days : 0
      }
    }
  }
  dynamic "metric" {
    for_each = var.metrics == null ? [] : var.metrics

    content {
      category = metric.value.name
      enabled  = metric.value.enabled

      retention_policy {
        enabled = metric.value.enabled && metric.value.retention_days != null ? true : false
        days    = metric.value.enabled ? metric.value.retention_days : 0
      }
    }
  }
}
