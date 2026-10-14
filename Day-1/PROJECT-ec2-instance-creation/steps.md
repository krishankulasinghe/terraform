# Overview of steps

Create a directory for your Terraform project and create a Terraform configuration file (usually named `main.tf`) in that directory. In this file, you define the AzureRM provider and resources you want to create. Use the complete [main.tf](main.tf) in this directory. Azure needs a Resource Group, Virtual Network, subnet, NIC, disk and SSH public key as well as the VM. Complete [Azure login and key setup](../04-aws-connection.md) first. The historical directory name is kept for existing links.

The VM uses an Ubuntu image reference, `Standard_B1s` size and a Standard LRS disk. It has no public IP; its private IP is not reachable directly from your laptop. `latest` chooses an image at creation, not ongoing OS patches. Pin a tested image version for repeatable production builds. Tags are labels, never a place for secrets.

## Initialize Terraform

In your terminal, navigate to the directory containing your Terraform configuration files and run:

```
terraform init
```

This command initializes the Terraform working directory, downloading any necessary provider plugins.

## Apply the Configuration

This example creates one paid VM and disk. Check the price and size availability first. Format, validate and review a plan before creating Azure resources:

```
terraform fmt
terraform validate
terraform plan -out=lesson.tfplan
terraform apply lesson.tfplan
```

Review the saved plan before applying: `+` creates, `~` updates, `-` deletes and `-/+` replaces. Applying a saved plan does not ask for another confirmation. A normal unsaved `terraform apply` asks for `yes`. Protect plan files because they can contain sensitive data. Validate checks code, not Azure permissions, quota or capacity.

## Verify Resources

After Terraform completes provisioning, check the Resource Group in the Azure portal or run:

```shell
terraform output
az vm list --resource-group tf-day1-rg --output table
```

If you changed the name input, use that Resource Group name. State connects Terraform addresses to Azure IDs. An unchanged plan should show no changes; do not delete state to start over.

## Destroy Resources

If you want to remove the resources created by Terraform, you can use the following command:

```
terraform destroy
```

Be cautious when using `terraform destroy` as it will delete resources as specified in your Terraform configuration.

Keep the same account, backend and inputs until cleanup succeeds. Review the destroy plan and type `yes`. Confirm the Resource Group is gone in Azure. If apply fails halfway, preserve state, correct the error and rerun plan/apply or destroy. Stopping the VM can leave disk charges. Commit `.terraform.lock.hcl` to record selected provider versions; keep `.terraform/`, state and plans out of Git.
