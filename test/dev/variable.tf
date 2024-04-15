variable "region" {
  type        = string
  default     = "ap-northeast-2"
  description = "dev-region"
}
variable "provider_token" {
  type = string
  sensitive = true
}