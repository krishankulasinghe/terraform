# Vault Integration

Here are the detailed steps to use Vault with the Azure lesson. Vault is a secret store. This exercise uses a disposable secret and a local development server; no VM is needed to host Vault.

## Install Vault

This lesson requires Terraform 1.11 or newer (below 2.0) and Vault provider 5.12 or newer (below 6.0). Install the Vault CLI for your OS using [HashiCorp's instructions](https://developer.hashicorp.com/vault/install). Check `vault version`. On Ubuntu, the package installation steps are:

**Install gpg**

```bash
sudo apt update && sudo apt install -y gpg wget lsb-release
```

**Download the signing key to a new keyring**

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

**Verify the key's fingerprint**

```bash
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
```

Compare it with the current HashiCorp installation documentation before trusting it.

**Add the HashiCorp repo**

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install vault
```

## Start Vault

In a separate terminal, start the local development server:

```shell
vault server -dev -dev-listen-address="127.0.0.1:8200"
```

Keep this terminal open. Development mode stores data in memory, uses HTTP and prints a root token. It is for disposable practice only. Never expose it on `0.0.0.0`, forward its port publicly, or put real credentials in it. Vault and Terraform must run on the same machine for this loopback address to work. Production Vault requires TLS, persistent storage and proper access controls.

In a second PowerShell terminal, set its address and temporarily use the printed root token for setup:

```powershell
$env:VAULT_ADDR = "http://127.0.0.1:8200"
$env:VAULT_TOKEN = "COPY-THE-LOCAL-DEV-ROOT-TOKEN"
vault kv put secret/tutorial message="practice-only"
```

For Bash use `export VAULT_ADDR="http://127.0.0.1:8200"` and `export VAULT_TOKEN="COPY-THE-LOCAL-DEV-ROOT-TOKEN"`. Do not save these token values in files or Git.

## Configure Terraform to read the secret from Vault

1. **Enable AppRole Authentication**:

```shell
vault auth enable approle
```

2. **Create an AppRole**:

First save this non-secret policy as `terraform-policy.hcl` outside the lesson directory:

```hcl
path "secret/data/tutorial" {
  capabilities = ["read"]
}
```

It permits reading only the practice secret. From the directory containing that policy, run:

```shell
vault policy write terraform terraform-policy.hcl
vault write auth/approle/role/terraform token_policies=terraform secret_id_ttl=10m token_ttl=20m token_max_ttl=30m secret_id_num_uses=1 token_num_uses=0
```

The token can make multiple API requests within its short lifetime; zero uses means no request-count limit. The Secret ID permits one login.

3. **Generate Role ID and Secret ID**:

In PowerShell, capture them without printing them, then replace the root token with the restricted AppRole token:

```powershell
$vaultRoleId = vault read -field=role_id auth/approle/role/terraform/role-id
$vaultSecretId = vault write -field=secret_id -f auth/approle/role/terraform/secret-id
$env:VAULT_TOKEN = vault write -field=token auth/approle/login role_id=$vaultRoleId secret_id=$vaultSecretId
Remove-Variable vaultRoleId, vaultSecretId
```

In Bash:

```bash
vaultRoleId=$(vault read -field=role_id auth/approle/role/terraform/role-id)
vaultSecretId=$(vault write -field=secret_id -f auth/approle/role/terraform/secret-id)
export VAULT_TOKEN="$(vault write -field=token auth/approle/login role_id="$vaultRoleId" secret_id="$vaultSecretId")"
unset vaultRoleId vaultSecretId
```

`main.tf` reads VAULT_ADDR and VAULT_TOKEN from the environment. `skip_child_token = true` uses this restricted token directly; it does not need permission to mint a child token. Ensure the token remains valid for plan, apply and destroy. If it expires, use the local dev root token to generate a new Secret ID and repeat login. Use least-privilege policies and short token lifetimes in real deployments.

## Run the Azure example

In the same second terminal, complete Day 1 Azure login and public-key setup. Run from `Day-7`. The code creates one paid Azure VM and disk plus a `terraform_data` practice record. An `ephemeral` block reads the practice secret temporarily and passes it as an environment variable to a local command. Ephemeral means temporary: Terraform does not save this value in state or plans. The command prints only a fixed message, never the secret. Root outputs and ordinary resource arguments cannot receive ephemeral values; provisioner environments can. Ordinary secret data sources still store their values in state.

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=vault.tfplan
terraform apply vault.tfplan
terraform output
terraform destroy
```

For `connection refused`, check that Vault is running on the same machine and VAULT_ADDR is correct. For `403`, check token expiry, policy and the `secret/tutorial` KV v2 path. Do not widen the policy to every secret. The development server already mounts KV v2 at `secret`.

## Cleanup

Destroy first while Azure and Vault logins still work. Confirm the Azure Resource Group is gone. Stop the development server with Ctrl+C; its in-memory practice secrets disappear. Clear the token from PowerShell with `Remove-Item Env:VAULT_TOKEN`, or Bash with `unset VAULT_TOKEN`. Protect saved plans and state backups. If you previously used ordinary secret data sources, retained state may still contain their values.

References: [Vault development server](https://developer.hashicorp.com/vault/docs/concepts/dev-server), [AppRole](https://developer.hashicorp.com/vault/docs/auth/approle), [temporary KV v2 reads](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/ephemeral-resources/kv_secret_v2), [Vault provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs).
