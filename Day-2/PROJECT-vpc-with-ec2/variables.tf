variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "cidr" {
  description = "Private address range for the Virtual Network."
  type        = string
  default     = "10.20.0.0/16"
  validation {
    condition     = can(cidrsubnet(var.cidr, 8, 1))
    error_message = "Supply a CIDR range that can contain two subnets."
  }
}

variable "vm_size" {
  description = "Small paid VM size; check availability for your subscription."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_ssh_public_key" {
  description = "RSA SSH public key text; no inbound SSH is opened in this project."
  type        = string
  validation {
    condition     = startswith(trimspace(var.admin_ssh_public_key), "ssh-rsa ")
    error_message = "Supply your RSA SSH public key text."
  }
}

variable "http_source_cidr" {
  description = "Your public IPv4 address with /32, to restrict the practice website."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.http_source_cidr)) && endswith(var.http_source_cidr, "/32")
    error_message = "Use your public IPv4 address with /32."
  }
}
