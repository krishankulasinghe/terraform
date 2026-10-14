# Terraform Zero to Hero course

## Day 1: Getting Started with Terraform

#### Introduction to Terraform and IaC

In this session, we'll introduce you to the fundamental concepts of Terraform and Infrastructure as Code (IaC). Learn why Terraform is crucial for managing infrastructure and how IaC streamlines provisioning.

#### Installing Terraform on MacOS, Linux and Windows

Get your hands dirty by installing Terraform on both MacOS, Linux and Windows. We'll guide you through the process with clear instructions and commands.

#### Setting up Terraform for Azure

Dive into Azure integration with Terraform. You'll learn how to sign in with Azure CLI and configure the AzureRM provider within Terraform to start provisioning resources.

#### Writing Your First Terraform Code

Start writing actual Terraform code with a simple example. Learn about the basic structure of a Terraform configuration file and how to define resources using the HCL language.

### Terraform Lifecycle

Understand the lifecycle of terraform. What is terraform `init`, `plan` and `apply`.

#### Launching an Azure Linux Virtual Machine

Take your skills up a notch by provisioning an Azure Linux VM using Terraform. Explore attributes like VM size, image reference, and tags to customize your VM.

#### Terraform State Basics

Understand the importance of Terraform state files. Learn about desired and current states, and how Terraform manages these states to ensure infrastructure consistency.

## Day 2: Advanced Terraform Configuration

#### Understanding Providers and Resources

Deepen your knowledge of providers and resources. Explore the role of different providers for various cloud platforms and understand how resources define infrastructure components.

#### Variables and Outputs in Terraform

Discover the power of variables for dynamic configurations. Learn how to define, declare, and utilize variables effectively. Explore outputs to retrieve and display essential information.

#### Conditional Expressions and Functions

Elevate your configurations with conditional expressions, adding logic to your code. We'll introduce you to Terraform's built-in functions for tasks like string manipulation and calculations.

#### Debugging and Formatting Terraform Files

Master the art of debugging Terraform configurations.Plus, learn why proper formatting with terraform fmt is crucial.

## Day 3: Building Reusable Infrastructure with Modules

#### Creating Modular Infrastructure with Terraform Modules

Unlock the potential of reusability with Terraform modules. Understand how modules enable you to create shareable and organized infrastructure components.

#### Local Values and Data Sources

Simplify complex expressions using local values. Dive into data sources and learn how to fetch data from existing resources or external systems, enhancing your configurations' flexibility.

#### Using Variables and Inputs with Modules

Explore the versatility of using variables within modules to customize their behavior. Learn how inputs work within modules and the benefits they offer.

#### Leveraging Outputs from Modules

Utilize module outputs to access critical information or propagate data to your root configuration. Learn how to make your modules more informative and useful.

#### Exploring Terraform Registry for Modules

Embark on a journey through the Terraform Registry. Discover pre-built, community-contributed modules and learn how to incorporate them into your own configurations.

## Day 4: Collaboration and State Management

#### Collaborating with Git and Version Control

Collaborate effectively using Git and version control. Grasp fundamental Git commands such as cloning, pulling, and pushing repositories to enhance teamwork.

#### Handling Sensitive Data and .gitignore

Tackle security challenges associated with sensitive data in version control. Explore the importance of .gitignore to exclude sensitive files from being committed.

#### Introduction to Terraform Backends

Uncover the role of Terraform backends in remote state storage. Learn why they're essential for maintaining infrastructure state and configurations.

#### Implementing Azure Blob Backend for State Storage

Get hands-on experience configuring a private Azure Blob container as a backend for remote state storage. Understand how this setup improves collaboration and state management.

#### State Locking with Azure Blob Leases

Dive into state locking and the prevention of concurrent updates. Use the Azure backend's built-in Blob lease locking, ensuring state consistency.

## Day 5: Provisioning and Provisioners

#### Understanding Provisioners in Terraform

Learn about provisioners, mechanisms for executing actions on resources during creation and destruction. Understand how they facilitate customization.

#### Remote-exec and Local-exec Provisioners

Differentiate between remote-exec and local-exec provisioners. Explore how remote-exec provisions actions on remote servers, while local-exec performs tasks locally.

#### Applying Provisioners at Creation and Destruction 

Discover when to use provisioners during resource creation or destruction. Configure provisioners within resource blocks to execute specific actions.

#### Failure Handling for Provisioners

Gain insights into handling provisioner failures. Learn about connection timeouts, deliberate retries, and the on_failure attribute to control provisioner behavior on failure.

## Day 6: Managing Environments with Workspaces

#### Introduction to Terraform Workspaces

Understand the concept of workspaces and their role in managing different environments. Learn how workspaces aid in isolating configurations.

#### Creating and Switching Between Workspaces

Learn how to create new workspaces and switch between them using terraform workspace commands. Understand their significance in environment management.

#### Using Workspaces for Environment Management

Learn deeper into how workspaces streamline environment management. Comprehend their benefits in maintaining separate state files for various settings.

## Day 7: Security and Advanced Topics

#### HashiCorp Vault Overview

Gain an overview of HashiCorp Vault, a powerful tool for secret management and data protection. Understand its significance in maintaining secure configurations.

#### Integrating Terraform with Vault for Secrets

Learn how to integrate Terraform with Vault to manage sensitive data securely. Discover how Vault can be used to store and distribute secrets within configurations.

## Day 8: Migration to Terraform and Drift Detection

Follow the [Azure import and drift exercise](Day-8/README.md) to bring an existing Resource Group under Terraform management, detect portal changes, and choose whether to restore or accept them.

## Azure course prerequisites and running the examples

Follow [installation](Day-1/03-install.md) and [Azure login and SSH setup](Day-1/04-aws-connection.md) first. Use Terraform 1.9 or newer (below 2.0; Day 7 requires 1.11 or newer), Azure CLI, OpenSSH and a practice Azure subscription. Examples use AzureRM 4.x. Check the [Azure pricing calculator](https://azure.microsoft.com/en-us/pricing/calculator/): small VMs are not automatically free. Disks, public IPs, load balancers, storage and data transfer may also cost money. A budget alert does not stop spending.

The original paths are kept so existing links still work. Names containing `aws`, `ec2` or `vpc` now contain Azure lessons. Each of these directories is a separate root module:

| Lesson | Run Terraform from | Instructions |
| --- | --- | --- |
| First VM | `Day-1/PROJECT-ec2-instance-creation` | [Steps](Day-1/PROJECT-ec2-instance-creation/steps.md) |
| Variables | `Day-2` | [Variables](Day-2/05-variables.md) |
| Two web servers | `Day-2/PROJECT-vpc-with-ec2` | [Project steps](Day-2/09-builtin-functions.md#project-two-azure-web-servers) |
| Modules | `Day-3` | [Modules](Day-3/modules.md) |
| Remote state | `Day-4` | [Backend setup](Day-4/statefile_scenarios.md) |
| Provisioners | `Day-5` | [Provisioners](Day-5/provisioners.md) |
| Workspaces | `Day-6` | Instructions below |
| Vault | `Day-7` | [Vault setup](Day-7/02-vault-integration.md) |
| Import and drift | A new practice directory | [Day 8](Day-8/README.md) |

Terraform combines all `.tf` files directly in your current directory. It reads a subfolder only when a module calls it. Run independent Markdown examples in separate practice folders. Do not apply from the repository root.

In each lesson, initialize, format, validate, review a plan, apply, inspect outputs, and clean up:

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=lesson.tfplan
terraform apply lesson.tfplan
terraform output
terraform destroy
```

Follow extra setup for Days 4 and 7 before init. `validate` checks code, not Azure permissions or capacity. Applying a saved plan executes it without another confirmation. Protect saved plans like state files, and create a new plan after changing code or inputs. Keep the same account, backend and inputs until destroy succeeds. Confirm the lesson Resource Group is gone in Azure. Stopping a VM can leave disk and IP charges.

## Day 6: Workspace exercise

A CLI workspace gives the same code a separate state. It does not switch subscriptions, permissions or code. The resource names in `Day-6/main.tf` include `terraform.workspace` so environments do not share VM names. Workspaces are useful for practice, but are not a security boundary. Use separate subscriptions and backends when strong environment isolation is needed.

After Day 1 login and public-key setup, run from `Day-6`. All three environments use small paid VM sizes to limit costs. Create and destroy one environment at a time:

```shell
terraform init
terraform fmt -recursive
terraform validate
terraform workspace new dev
terraform workspace list
terraform workspace show
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
terraform destroy
terraform workspace select default
terraform workspace delete dev
```

Repeat with `stage`, then `prod`, using a fresh plan for each workspace. If the workspace already exists, use `terraform workspace select dev` instead of `new`. Destroy resources in each workspace before deleting it; deleting a workspace does not delete Azure resources. Return to `default`, and destroy there too if you applied resources there.

## Common Azure troubleshooting

- Login/subscription error: repeat `az login`, check `az account show`, and set `ARM_SUBSCRIPTION_ID` in the same terminal as Terraform.
- `AuthorizationFailed`: check your RBAC scope with an administrator. Contributor cannot grant roles, and Blob data access is a separate permission.
- VM size unavailable or quota exceeded: follow Day 1's size check and choose another supported small size. In root VM examples use `-var='vm_size=...'`; in Days 3 and 6 adjust the module input or size map. Check its price first.
- Provider registration denied: have an administrator register the required Azure resource providers. Disable automatic registration only after they confirm registration is complete.
- Provider download error: check internet/proxy access and rerun init. Use `init -upgrade` only for an intentional provider update.
- A plan showing `-/+` replaces a resource. Read the reason before applying; replacement can lose disk data.

References: [AzureRM provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs), [Azure state backend](https://developer.hashicorp.com/terraform/language/backend/azurerm).
