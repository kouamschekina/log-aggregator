variable "k3s_token" {
  description = "Pre-shared K3s cluster token for server/agent join"
  type        = string
  default     = "cnglt-supersecret-token"
}

variable "k3s_version" {
  description = "K3s version channel or explicit version (optional)"
  type        = string
  default     = ""
}
