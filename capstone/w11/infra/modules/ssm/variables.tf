variable "name" {
  type        = string
  description = "The name of the SSM parameter"
}

variable "value" {
  type        = string
  sensitive   = true
  description = "The value of the SSM parameter"
}

variable "type" {
  type        = string
  description = "The type of the SSM parameter (e.g. SecureString, String)"
  default     = "SecureString"
}

variable "description" {
  type        = string
  description = "The description of the SSM parameter"
  default     = ""
}
