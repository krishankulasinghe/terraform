# MIGRATION TO TERRAFORM & DRIFT DETECTION

Original supplementary video: https://youtu.be/-4IMy5ihiiU

Use the Azure exercise below for this course. Import connects an existing cloud resource to a Terraform resource address. Drift means the cloud changed outside Terraform, for example someone edited a tag in the portal.

## Prerequisites

Complete Day 1 login and set ARM_SUBSCRIPTION_ID. Use a fresh practice folder and a dedicated empty Resource Group. Do not import work or production resources for this exercise. A Resource Group alone has no separate charge; do not put paid resources in it.

## 1. Create a group outside Terraform

```shell
az group create --name tf-import-practice-rg --location eastus --tags purpose=import-practice
az group show --name tf-import-practice-rg --query id --output tsv
```

Copy the returned Azure resource ID. If this name already exists, pick a new name and use it consistently below; never claim someone else's group.

## 2. Describe it in code

Save this as `main.tf` in the fresh folder:

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli = true
}

resource "azurerm_resource_group" "imported" {
  name     = "tf-import-practice-rg"
  location = "eastus"
  tags     = { purpose = "import-practice" }
}

import {
  to = azurerm_resource_group.imported
  id = "/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/tf-import-practice-rg"
}
```

Replace the `id` with the actual copied ID. Import does not automatically make your handwritten code match the real object. Read the plan; correct code to match intended settings before applying. Do not bind the same Azure object to multiple resource addresses or state files.

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=import.tfplan
terraform apply import.tfplan
terraform state list
terraform plan
```

The first plan should import one group without deleting or replacing it. The final plan should show no changes. Once imported, remove the import block (or keep it as a record until cleanup). The resource block must stay. CLI `terraform import ADDRESS ID` is another option, but it only imports state; it does not write configuration.

## 3. Detect and resolve drift

In the portal, add `owner = portal-change` to this group's tags. Then run:

```shell
terraform plan -detailed-exitcode
```

Terraform should propose removing the extra tag because it is absent from code. Exit code 0 means no changes, 2 means changes, and 1 means an error. In PowerShell inspect `$LASTEXITCODE`; in Bash inspect `$?` immediately after the command.

Choose the intended result: to restore code's settings, review a fresh normal plan and apply it. To keep the portal tag, add `owner = "portal-change"` to the code's tags, then plan and apply. State inspection reads saved values; it is not a live drift check.

You can review a state-only update with:

```shell
terraform plan -refresh-only -out=refresh.tfplan
terraform apply refresh.tfplan
```

Refresh-only updates Terraform's record and outputs, not Azure resources or your code. If you do not update code too, a later normal plan still proposes restoring code's settings. Prefer this reviewed workflow over the old `terraform refresh` command.

## 4. Cleanup

Remove the import block before cleanup so it cannot import the group again later. Keep the resource block and run:

```shell
terraform destroy
az group exists --name tf-import-practice-rg
```

Review the deletion plan and confirm the group is empty before accepting. The Azure command should return `false`. Import makes the existing resource managed by this state, including destruction. `terraform state rm` only stops tracking; it does not delete the resource and is not cleanup.

If import fails, check the ID, subscription and permissions. If the plan proposes a replacement, stop and compare code with the existing object. Do not use `ignore_changes` broadly to hide drift. Never delete state to start over.

References: [Import blocks](https://developer.hashicorp.com/terraform/language/import/single-resource), [Refresh-only plans](https://developer.hashicorp.com/terraform/tutorials/state/refresh).
