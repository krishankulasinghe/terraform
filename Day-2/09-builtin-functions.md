# Built-in Functions

Terraform is an infrastructure as code (IaC) tool that allows you to define and provision infrastructure resources in a declarative manner. Terraform provides a wide range of built-in functions that you can use within your configuration files (usually written in HashiCorp Configuration Language, or HCL) to manipulate and transform data. These functions help you perform various tasks when defining your infrastructure. Here are some commonly used built-in functions in Terraform:

1. `concat(list1, list2, ...)`: Combines multiple lists into a single list.

```hcl
variable "list1" {
  type    = list(string)
  default = ["a", "b"]
}

variable "list2" {
  type    = list(string)
  default = ["c", "d"]
}

output "combined_list" {
  value = concat(var.list1, var.list2)
}
```

2. `element(list, index)`: Returns the element at the specified index in a list.

```hcl
variable "my_list" {
  type    = list(string)
  default = ["apple", "banana", "cherry"]
}

output "selected_element" {
  value = element(var.my_list, 1) # Returns "banana"
}
```

3. `length(list)`: Returns the number of elements in a list.

```hcl
variable "my_list" {
  type    = list(string)
  default = ["apple", "banana", "cherry"]
}

output "list_length" {
  value = length(var.my_list) # Returns 3
}
```

4. `zipmap(keys, values)`: Creates a map from a list of keys and a list of values. The old `map()` function has been removed; use `zipmap` or a map literal.

```hcl
variable "keys" {
  type    = list(string)
  default = ["name", "age"]
}

variable "values" {
  type    = list(string)
  default = ["Alice", "30"]
}

output "my_map" {
  value = zipmap(var.keys, var.values) # Returns {"name" = "Alice", "age" = "30"}
}
```

5. `lookup(map, key)`: Retrieves the value associated with a specific key in a map.

```hcl
variable "my_map" {
  type    = map(string)
  default = {"name" = "Alice", "age" = "30"}
}

output "value" {
  value = lookup(var.my_map, "name") # Returns "Alice"
}
```

6. `join(separator, list)`: Joins the elements of a list into a single string using the specified separator.

```hcl
variable "my_list" {
  type    = list(string)
  default = ["apple", "banana", "cherry"]
}

output "joined_string" {
  value = join(", ", var.my_list) # Returns "apple, banana, cherry"
}
```

These are just a few examples of the built-in functions available in Terraform. You can find more functions and detailed documentation in the official Terraform documentation, which is regularly updated to include new features and improvements

## Trying functions and checking code

Try `concat(["one"], ["two"])`, `cidrsubnet("10.20.0.0/16", 8, 1)` and `join("-", ["tf", "day2"])` in `terraform console`. Type `exit` when finished. Console expressions do not create cloud resources. The snippets above are separate examples, so do not paste repeated variable/output names into one file.

`terraform fmt` makes layout consistent; `terraform validate` checks configuration after init. Read the filename and line in an error, fix it and validate again. The `element` function wraps indexes; normal list indexing such as `var.my_list[1]` does not.

## Project: two Azure web servers

Run the complete code in `PROJECT-vpc-with-ec2` after Day 1 login and key setup. The directory name is historical. It creates a Virtual Network, two subnets, an NSG, two small Ubuntu VMs, a Standard Load Balancer and a private Blob container.

**Cost:** two VMs, two disks, a public IP, Standard Load Balancer, storage operations and data transfer can be billed. This is the largest lesson; check the calculator and destroy it promptly. The storage account's name uses a random lowercase suffix because Azure storage names must be globally unique, 3–24 lowercase letters or digits. The container is private and the website does not depend on it.

**Permissions:** this project assigns your signed-in identity Storage Blob Data Contributor. You need permission to create resources and grant that role. If you cannot grant roles, ask your administrator before applying. Contributor alone cannot create role assignments. RBAC may take several minutes to spread; a Blob `403` may need a wait and a fresh plan/apply. Do not enable storage account keys to bypass it.

Supply your current public IPv4 address with `/32`, using the same terminal as Terraform. Find it through your trusted network/router service; do not use your laptop's private `192.168...` address. In PowerShell, replacing the placeholder:

```powershell
$env:TF_VAR_http_source_cidr = "YOUR-PUBLIC-IP/32"
```

In Bash:

```bash
export TF_VAR_http_source_cidr="YOUR-PUBLIC-IP/32"
```

If your network changes, update the input and apply a new plan. The rule opens HTTP only to you; no inbound SSH is opened. NSGs have default rules as well as your rule. The default AzureLoadBalancer rule permits health checks; default VNet rules allow internal traffic.

CIDR is a way to write a network range. `/16` has room for many private addresses; `/24` is a smaller subnet; `/32` is one IPv4 address. The project uses `cidrsubnet` to calculate two ranges inside the VNet. Azure reserves some addresses in each subnet. A subnet is not an availability zone.

Azure has built-in system routes; there is no internet gateway resource. Private VMs need an explicit outbound method to download packages. The Standard Load Balancer's outbound rule supplies it here. Its inbound rule disables automatic outbound SNAT so the explicit outbound rule controls it. SNAT rewrites a private source IP to a public IP for internet requests.

The load balancer forwards TCP port 80 to healthy VMs. An HTTP probe asks each server for `/`. This teaches load balancing without the cost of Application Gateway. It does not add HTTPS, URL routing or production resilience. Requests from the same client may keep landing on one server; refreshing does not guarantee alternating pages.

`custom_data` supplies Base64-encoded shell scripts. Ubuntu's cloud-init runs them at first boot to install Apache and make a page. Azure metadata uses the `Metadata:true` header and an API version, not a saved key. Never put secrets in custom data. `path.module` locates files relative to the module. `depends_on` ensures the outbound path and backend NIC associations exist before VM creation; use it only for dependencies not expressed by ordinary references.

Run inside the project directory:

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=web.tfplan
terraform apply web.tfplan
terraform output -raw website_url
terraform destroy
```

Before destroying, open the printed URL from the IP you allowed. VM creation can finish before cloud-init finishes; wait a few minutes for Apache and the probe. For a failed page, check Azure Load Balancer backend health and VM status. An administrator can use Azure Run Command to inspect `/var/log/cloud-init-output.log` without opening SSH. Do not widen the firewall just to troubleshoot.

Keep the public-key and CIDR inputs set until cleanup completes. Deleting the container destroys its data. If Azure refuses deletion because a Blob is leased, confirm no other process is using it before clearing the lease. Confirm `tf-day2-web-rg` is gone after:

```shell
terraform destroy
```

References: [Terraform functions](https://developer.hashicorp.com/terraform/language/functions), [Azure outbound access](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access).
