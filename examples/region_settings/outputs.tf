# Region Settings Outputs

output "region_settings_id" {
  description = "AWS Region where region settings are applied"
  value       = module.region_settings.region_settings_id
}

output "enabled_services" {
  description = "List of AWS services enabled for backup in this region"
  value       = module.region_settings.region_settings_summary != null ? module.region_settings.region_settings_summary.enabled_services : []
}

output "disabled_services" {
  description = "List of AWS services disabled for backup in this region"
  value       = module.region_settings.region_settings_summary != null ? module.region_settings.region_settings_summary.disabled_services : []
}

output "service_count" {
  description = "Count of configured services (enabled/disabled/managed)"
  value       = module.region_settings.region_settings_summary != null ? module.region_settings.region_settings_summary.service_count : null
}

output "region_settings_summary" {
  description = "Complete summary of region settings configuration"
  value       = module.region_settings.region_settings_summary
}
