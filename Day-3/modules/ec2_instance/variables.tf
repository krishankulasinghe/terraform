variable "location" {
  description = "Azure region. Check VM size availability before applying."
  type        = string
  default     = "eastus"
}

variable "name" {
  description = "Short name used for this lesson's resources."
  type        = string
  default     = "tf-day1"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.name))
    error_message = "Use 3-20 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "vm_size" {
  description = "Small paid VM size; availability and price depend on your subscription."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_ssh_public_key" {
  description = "Your SSH PUBLIC key text, supplied through TF_VAR_admin_ssh_public_key."
  type        = string
  validation {
    condition     = startswith(trimspace(var.admin_ssh_public_key), "ssh-rsa ")
    error_message = "Supply an RSA SSH public key, not a private key or file path."
  }
}
