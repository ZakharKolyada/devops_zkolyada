variable "env_name" {
  description = "Environment Name (prefix for resources)"
  default     = "prod"
}

variable "subscription_id" {
  description = "The Subscription ID for Azure."
  type        = string
}

variable "client_id" {
  description = "The Client ID of the Service Principal."
  type        = string
}

variable "client_secret" {
  description = "The Client Secret of the Service Principal."
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "The Tenant ID for Azure."
  type        = string
}