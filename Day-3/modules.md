# Modules

The advantage of using Terraform modules in your infrastructure as code (IaC) projects lies in improved organization, reusability, and maintainability. Here are the key benefits:

1. **Modularity**: Terraform modules allow you to break down your infrastructure configuration into smaller, self-contained components. This modularity makes it easier to manage and reason about your infrastructure because each module handles a specific piece of functionality, such as an Azure Linux VM, a database, or a network configuration.

2. **Reusability**: With modules, you can create reusable templates for common infrastructure components. Instead of rewriting similar configurations for multiple projects, you can reuse modules across different Terraform projects. This reduces duplication and promotes consistency in your infrastructure.

3. **Simplified Collaboration**: Modules make it easier for teams to collaborate on infrastructure projects. Different team members can work on separate modules independently, and then these modules can be combined to build complex infrastructure deployments. This division of labor can streamline development and reduce conflicts in the codebase.

4. **Versioning and Maintenance**: Modules can have their own versioning, making it easier to manage updates and changes. When you update a module, you can increment its version, and other projects using that module can choose when to adopt the new version, helping to prevent unexpected changes in existing deployments.

5. **Abstraction**: Modules can abstract away the complexity of underlying resources. For example, an Azure Linux VM module can hide the details of network security groups, subnets, and other configurations, allowing users to focus on high-level parameters like VM size and image reference.

6. **Testing and Validation**: Modules can be individually tested and validated, ensuring that they work correctly before being used in multiple projects. This reduces the risk of errors propagating across your infrastructure.

7. **Documentation**: Modules promote self-documentation. When you define variables, outputs, and resource dependencies within a module, it becomes clear how the module should be used, making it easier for others (or your future self) to understand and work with.

8. **Scalability**: As your infrastructure grows, modules provide a scalable approach to managing complexity. You can continue to create new modules for different components of your architecture, maintaining a clean and organized codebase.

9. **Security and Compliance**: Modules can encapsulate security and compliance best practices. For instance, you can create a module for launching Azure Linux VMs with predefined network security groups, Azure RBAC roles, and other security-related configurations, ensuring consistency and compliance across your deployments.

## Azure module exercise, locals and data sources

A module is a folder of Terraform files. This lesson's root `main.tf` calls the child in `modules/ec2_instance`. The historical path is kept; the child now creates an Azure Linux VM and its private network.

The child accepts inputs in `variables.tf`, creates resources in `main.tf`, and returns values in `outputs.tf`. The parent supplies the public key and a small VM size. It reads `module.linux_vm.private_ip`. You run commands in `Day-3`, not in the child. The child inherits the root's AzureRM provider configuration and declares its own provider requirement; it does not log in separately.

**Cost:** one VM and its disk are billed. The VM has no public IP. After Day 1 login and key setup, run:

```shell
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=module.tfplan
terraform apply module.tfplan
terraform output
terraform destroy
```

## Locals

A local is a name for a value calculated inside your code, not an input from the user. In the Day 2 web project, `local.servers` names a map linking server names to script filenames. This saves repetition. Variables come from outside; locals are calculated inside. Neither automatically hides secrets.

## Data sources

A data source reads information rather than creating the object. In the Day 2 project, `data.azurerm_client_config.current` reads the signed-in identity's object ID so an RBAC assignment can target it. An object ID identifies a user or application in Microsoft Entra ID; it is not a password.

Data sources often contact an API during plan. They do not import existing resources into management. A resource block creates or manages an object; an import (Day 8) connects an existing object to such a block.

## Sharing a module

Local modules use a relative `source` path. After changing the source or adding a module, rerun init. Registry modules use a Registry address and a separate `version`; pin a tested version. For a Git source, pin a commit or release rather than a moving branch. Read its inputs, outputs, permissions and costs before use. Do not assume a public module is safe just because it is published.

Provider lock files pin provider packages, not registry module versions. Keep a module's purpose small and inputs clear. Avoid hiding large paid resources behind a harmless-looking module name.

If you return to this example later, check state and clean it up from `Day-3` with:

```shell
terraform destroy
```
