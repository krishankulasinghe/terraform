The `file`, `remote-exec`, and `local-exec` provisioners can copy files or run commands after resource creation. Use them only when provider resources, cloud-init or a prepared image cannot do the job. This lesson keeps provisioners for practice; Day 2 shows cloud-init.

1. **file Provisioner:**

   The `file` provisioner is used to copy files or directories from the local machine to a remote machine. This is useful for deploying configuration files, scripts, or other assets to a provisioned instance.

   Example:

   ```hcl
   # Fragment inside terraform_data.configure in main.tf:
   provisioner "file" {
     source      = "${path.module}/app.py"
     destination = "/home/azureuser/app.py"
   }
   ```

   In this example, the `file` provisioner copies `app.py` from the local module directory to `/home/azureuser/app.py` on the Azure VM using SSH.

2. **remote-exec Provisioner:**

   The `remote-exec` provisioner is used to run scripts or commands on a remote machine over SSH or WinRM connections. It's often used to configure or install software on provisioned instances.

   Example:

   ```hcl
   # Fragment inside terraform_data.configure, using a provisioner-local SSH connection:
   provisioner "remote-exec" {
     inline = [
       "sudo apt-get -o Acquire::Retries=5 update",
       "sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y python3-flask",
     ]
   }
   ```

   In this example, the `remote-exec` provisioner connects to the Azure Ubuntu VM using SSH and installs Flask. The complete main.tf also starts the practice app.

3. **local-exec Provisioner:**

   The `local-exec` provisioner is used to run scripts or commands locally on the machine where Terraform is executed. It is useful for tasks that don't require remote execution, such as initializing a local database or configuring local resources.

   Example:

   ```hcl
   resource "terraform_data" "example" {
     provisioner "local-exec" {
       command = "echo This is a local command"
     }
   }
   ```

   In this example, a built-in `terraform_data` resource runs a local command when it is created. Provisioners do not run on every apply or on refresh. No extra provider is needed for terraform_data.

## Run the Azure example

Complete Day 1 login and SSH setup. Day 5 requires a dedicated key without a passphrase because Terraform's connection reads the private key file. Protect it locally. `main.tf` creates one paid VM, disk and Standard public IP. An NSG permits ports 22 and 8080 only from your public IPv4 address with `/32`. The public IP also gives explicit outbound connectivity for package downloads. Your local firewall must permit outbound SSH.

In PowerShell, replace the placeholder with your public IPv4 address:

```powershell
$env:TF_VAR_ssh_source_cidr = "YOUR-PUBLIC-IP/32"
# If needed, override the default ~/.ssh/terraform_azure key path:
$env:TF_VAR_ssh_private_key_path = "$HOME/.ssh/terraform_azure"
```

In Bash use `export TF_VAR_ssh_source_cidr="YOUR-PUBLIC-IP/32"` and `export TF_VAR_ssh_private_key_path="$HOME/.ssh/terraform_azure"`. Keep the public key input from Day 1; it must match this private key. Never commit the private key.

The complete example uses `terraform_data.configure` to hold all provisioners. A reference to the VM ID makes it wait for VM creation. Each creation provisioner's SSH connection uses `azureuser`, the public IP, `file(pathexpand(var.ssh_private_key_path))`, and a 10-minute connection timeout. `path.module` finds app.py relative to this module. Provisioners must be inside a resource block.

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=provision.tfplan
terraform apply provision.tfplan
terraform output -raw website_url
```

Open that URL from the network you allowed. Flask runs on port 8080 as `azureuser` through a transient systemd service, not as root. This is a practice server, and the transient service is not intended to survive VM reboots. Use a persistent service and production WSGI server for a real application.

## Creation, destruction and failure handling

By default a provisioner runs at creation. `when = destroy` runs before destruction of its resource. The example's destroy provisioner prints a local message. Keep a destroy provisioner in configuration until it has run; removing its block first prevents it from running. Destroy provisioners are skipped for tainted resources and with `create_before_destroy`.

The default `on_failure = fail` stops apply and a failed creation provisioner taints its containing resource. Here the containing resource is terraform_data, so a retry need not replace the VM. `on_failure = continue` ignores an error and can leave broken configuration; do not use it for required setup. Terraform has no general automatic command retry loop. The package commands use apt's own retries; the SSH timeout controls connection attempts.

For SSH timeout, confirm your current public IP, NSG association, matching key, VM boot status and network access. If the file path is wrong, correct it. If the app file changes, `filesha256` changes the trigger and runs setup again. For an intentional rerun after fixing a problem:

```shell
terraform plan -replace=terraform_data.configure -out=retry.tfplan
terraform apply retry.tfplan
```

Review this plan before applying. The `-replace` flag is preferred to the deprecated `terraform taint` command. Do not widen SSH access to the whole internet to troubleshoot.

## Cleanup

Keep the same inputs and run from `Day-5`:

```shell
terraform destroy
```

Confirm its Resource Group is gone. Once no lab VM uses your dedicated disposable key, delete its private/public files locally if you no longer need them.

Reference: [Terraform provisioners](https://developer.hashicorp.com/terraform/language/provisioners).
