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
  description = "Complete summary of region settings configuration (non-sensitive)"
  value       = module.region_settings.region_settings_summary
}

output "region_settings_hash" {
  description = "SHA256 hash of configuration for change tracking"
  value       = module.region_settings.region_settings_hash
}

output "configuration_health_check" {
  description = "Health check and region validation status"
  value       = module.region_settings.configuration_health_check
}

# Note: region_settings_details is marked as sensitive and won't appear in terraform output
# To view: terraform output -json region_settings_details
