# Variables

Input and output variables in Terraform are essential for parameterizing and sharing values within your Terraform configurations and modules. They allow you to make your configurations more dynamic, reusable, and flexible.

## Input Variables

Input variables are used to parameterize your Terraform configurations. They allow you to pass values into your modules or configurations from the outside. Input variables can be defined within a module or at the root level of your configuration. Here's how you define an input variable:

```hcl
variable "example_var" {
  description = "An example input variable"
  type        = string
  default     = "default_value"
}
```

In this example:

- `variable` is used to declare an input variable named `example_var`.
- `description` provides a human-readable description of the variable.
- `type` specifies the data type of the variable (e.g., `string`, `number`, `list`, `map`, etc.).
- `default` provides a default value for the variable, which is optional.

You can then use the input variable within your module or configuration like this:

```hcl
resource "azurerm_resource_group" "example" {
  name = var.example_var
  location = "eastus"
}
```

You reference the input variable using `var.example_var`.

## Output Variables

Output variables allow you to expose values from your module or configuration, making them available for use in other parts of your Terraform setup. Here's how you define an output variable:

```hcl
output "example_output" {
  description = "An example output variable"
  value       = azurerm_resource_group.example.id
}
```

In this example:

- `output` is used to declare an output variable named `example_output`.
- `description` provides a description of the output variable.
- `value` specifies the value that you want to expose as an output variable. This value can be a resource attribute, a computed value, or any other expression.

You can reference output variables in the root module or in other modules by using the syntax `module.module_name.output_name`, where `module_name` is the name of the module containing the output variable.

For example, if you have an output variable named `example_output` in a module called `example_module`, you can access it in the root module like this:

```hcl
output "root_output" {
  value = module.example_module.example_output
}
```

This allows you to share data and values between different parts of your Terraform configuration and create more modular and maintainable infrastructure-as-code setups.

## Run the Azure variables example

The snippets above illustrate inputs and outputs. For a complete example, use [06-variables-implementation.tf](06-variables-implementation.tf). It is a real `.tf` file; run from `Day-2`. Its project subfolder is a separate configuration.

`vm_size` defaults to `Standard_B1s`. `location` defaults to `eastus`. `admin_ssh_public_key` has no default; supply its public key text using the Day 1 setup. A validation block checks the key format. Validation catches bad input but cannot guarantee Azure capacity or permission. Use specific types such as `list(string)`, `map(string)`, `bool` or `number` to describe expected input.

The output is a private IP because this VM has no public IP. View it with `terraform output -raw private_ip`. Outputs are available after apply.

This creates one paid VM and disk. Run and clean up:

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=variables.tfplan
terraform apply variables.tfplan
terraform output
terraform destroy
```
