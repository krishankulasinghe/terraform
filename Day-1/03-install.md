# Install Terraform

## Windows

1. Install Terraform from the Downloads [Page](https://developer.hashicorp.com/terraform/downloads)

(or)

2. Use GitHub Codespaces (check your current allowance and billing)

- Login to your GitHub account
- Click on the Profile Icon to the top right
- Click on "your codespaces" as shown in the [Image](../Images/codespaces-location.png)
- Codespaces will provide you a virtual machine with Ubuntu and VS Code by default.
- Follow the steps provided in the Downloads [Page](https://developer.hashicorp.com/terraform/downloads) for Linux.

## Linux

- Follow the steps provided in the Downloads [Page](https://developer.hashicorp.com/terraform/downloads) for Linux.

## macOS

- Follow the steps provided in the Downloads [Page](https://developer.hashicorp.com/terraform/downloads) for macOS.

## Azure tools and version checks

Use Terraform 1.9 or newer, below 2.0. Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) for your operating system and OpenSSH if `ssh-keygen` is missing. Windows provides OpenSSH Client as an optional feature. Put Terraform's executable directory on PATH and reopen your terminal after installation.

```shell
terraform version
az version
ssh -V
```

If a command is missing, complete installation before continuing. Codespaces uses the Linux tools and does not pay for Azure resources. For a terminal without a browser, use `az login --use-device-code`. Terraform downloads providers through `terraform init`; do not install them manually.
