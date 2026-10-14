# Connect Terraform to Azure

The filename is kept for existing links. This lesson uses Azure CLI login, not saved client secrets.

## 1. Choose your subscription

Run these commands in the terminal where you will run Terraform:

```shell
az login
az account list --output table
az account set --subscription "YOUR-SUBSCRIPTION-ID"
az account show --output table
```

Replace the subscription placeholder with your subscription's ID. An ID identifies the subscription; it is not a password. AzureRM 4.x needs the ID explicitly, even when Azure CLI has selected it.

PowerShell:

```powershell
$env:ARM_SUBSCRIPTION_ID = az account show --query id --output tsv
```

Bash (Linux, macOS, Codespaces):

```bash
export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
```

Environment variables are settings for the current terminal and its child processes. Set them again in a new terminal. The provider's `use_cli = true` uses your signed-in identity; it does not need a client secret.

## 2. Check permissions and availability

Azure RBAC means role-based access control: a role says what you can do, and a scope says where. Contributor can manage resources in its scope but cannot grant roles. To create the lesson Resource Groups, you need suitable subscription permission. Ask an administrator for a practice subscription or the appropriate scoped access.

The Day 2 Blob project also creates a role assignment, so it needs permission to grant roles (for example, Role Based Access Control Administrator at the appropriate scope), plus resource creation permission. The Day 4 backend needs Storage Blob Data Contributor on its container. A management role and a Blob data role are different permissions.

Azure registers service APIs such as Microsoft.Compute and Microsoft.Storage for a subscription. The provider normally handles its configured registrations. If registration is denied, ask your administrator to register the needed services. In a subscription where registration is managed for you, set `resource_provider_registrations = "none"` in the provider only after confirming the needed services are registered.

Check the small VM size before planning a VM:

```shell
az vm list-skus --location eastus --size Standard_B1s --all --output table
```

Check restrictions and vCPU quota in the portal too; a listed size does not guarantee capacity. Pick another small supported size if needed. Never switch to a large VM just to get past a quota error. Check its price first.

## 3. Prepare an SSH key

SSH is an encrypted way to log in to a Linux computer. A key pair has a public half for the VM and a private half that stays on your computer. This course uses RSA public keys.

Run the following only if the file does not already exist. Do not overwrite an existing key. When asked for a passphrase, choose one if you only use ordinary SSH. Day 5's Terraform SSH connection needs a dedicated disposable key without a passphrase; protect that file and delete it after the lab.

PowerShell:

```powershell
New-Item -ItemType Directory -Path "$HOME/.ssh" -Force | Out-Null
ssh-keygen -t rsa -b 3072 -f "$HOME/.ssh/terraform_azure"
```

Bash:

```bash
mkdir -p ~/.ssh
ssh-keygen -t rsa -b 3072 -f ~/.ssh/terraform_azure
```

Supply only the public key text to Terraform. In PowerShell:

```powershell
$env:TF_VAR_admin_ssh_public_key = Get-Content "$HOME/.ssh/terraform_azure.pub" -Raw
```

In Bash:

```bash
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/terraform_azure.pub)"
```

`TF_VAR_` tells Terraform to use an environment variable as an input. The remainder must match the Terraform variable name. Do not put the private key, passwords or tokens in `.tf` or committed `.tfvars` files.

The first VM has no public IP, so you cannot SSH to it directly from your laptop. Day 5 deliberately adds a public IP and a restricted SSH rule.

Next: [create the first VM](PROJECT-ec2-instance-creation/steps.md), then finish that example with `terraform destroy`.
