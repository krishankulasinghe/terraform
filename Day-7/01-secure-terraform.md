# Ways to secure Terraform

There are a few ways to manage sensitive information in Terraform files. Here are some of the most common methods:

## Use the sensitive attribute

- Terraform's `sensitive` attribute hides variables and outputs in normal CLI display. The value can still be stored in state and saved plans. It does not encrypt them. `terraform output -raw`, `-json`, state inspection or debug logs can reveal values.

## Secret management system

- Store passwords, API keys and other secrets in a secret management system such as HashiCorp Vault or Azure Key Vault. Ordinary Terraform secret data sources copy their values into state. For applications, prefer a managed identity that reads Key Vault at runtime, rather than putting secrets in Terraform tags, custom data or code.

## Remote Backend

- Use a private Azure Blob backend with encryption at rest, Microsoft Entra ID authentication, scoped access, and locking (Day 4). Local state is plain text. Terraform has no `terraform encrypt` command. Protect local state and plans using operating-system permissions and encrypted storage, and keep them out of Git.

## Environment Variables

- Use environment variables for login settings and sensitive inputs rather than hard-coding them. They are not encrypted storage and may be visible to local processes or logging tools. Avoid printing them. For this course, use `az login` with `ARM_SUBSCRIPTION_ID`; no saved Azure client secret is needed. Automation should prefer managed identity or workload identity federation with scoped RBAC.

Here are some specific examples of how to use these methods:

To mark a variable as sensitive:

```hcl
variable "practice_message" {
  description = "Disposable practice value, never a real password."
  type        = string
  sensitive   = true
}
```

In PowerShell supply a disposable value with `$env:TF_VAR_practice_message = "practice-only"`. In Bash use `export TF_VAR_practice_message="practice-only"`. Terraform reads input environment variables prefixed `TF_VAR_`; there is no `source = "env://..."` variable argument. Inputs cannot have a `value` argument referring to a data source. Use references directly or local values instead.

For a temporary Vault KV v2 secret read, the next lesson uses:

```hcl
ephemeral "vault_kv_secret_v2" "demo" {
  mount = "secret"
  name  = "tutorial"
}

resource "terraform_data" "secret_demo" {
  provisioner "local-exec" {
    command = "echo Vault practice secret is available to this command"
    environment = {
      PRACTICE_MESSAGE = ephemeral.vault_kv_secret_v2.demo.data["message"]
    }
  }
}
```

This is a fragment; follow [Vault integration](02-vault-integration.md) for authentication and runnable code. Day 7 requires Terraform 1.11 or newer and Vault provider 5.12 or newer. `ephemeral` means temporary: Terraform does not save the value in state or plans. It can supply a provisioner environment, but cannot be used in an ordinary resource argument or root output. The command prints a fixed message without displaying the secret. Still use only a disposable practice value: a command could leak its environment if it prints it. Never put secrets in Azure tags, even if their input is marked sensitive.

The repository `.gitignore` excludes state, plans, private keys and `*.local.tfvars`. Commit `.terraform.lock.hcl` and non-secret sample inputs. Ignoring a file does not remove previously committed data. If a credential leaks, rotate it.

Cleanup: destroy the Day 7 resources before stopping Vault, remove practice secrets, and clear VAULT_TOKEN/secret-related environment variables from the terminal. Older local state backups or remote versions from ordinary secret data sources may still contain secret values.

Reference: [Sensitive data in Terraform](https://developer.hashicorp.com/terraform/language/manage-sensitive-data).
