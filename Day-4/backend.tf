# The storage must exist BEFORE terraform init. See statefile_scenarios.md.
# Supply its names with -backend-config. Never supply storage keys.
terraform {
  backend "azurerm" {
    use_cli          = true
    use_azuread_auth = true
    container_name   = "tfstate"
    key              = "day4/terraform.tfstate"
  }
}
