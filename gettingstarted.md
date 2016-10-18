#Creating Azure Resources with Terraform
There are multiple ways to provision infrastructure into Azure today, from creating resources through user interface of Azure portal (http://portal.azure.com) to using Azure CLI to authoring enterprise-grade infrastructure solutions with Azure Resource Manager JSON-based templates. The last option - writing JSON-based definitions of infrastructure resources - gets us very close to fulfilling the Infrastructure-as-Code promise, but JSON syntax can hardly be characterized as readable with double quotation marks and unintuitive comment placement making it hard to follow.

This is where Terraform comes in, providing a way to deploy cloud infrastructure using a higher-level templating language. But beyond improved readability, Terraform templates allow you to use the same templating language for a variety of public cloud providers, making it a valuable tool in your multi-cloud strategy. In this article, I will show you how to get started using Terraform with Azure, provisioning a Ubuntu virtual machine with Wordpress installed on it in a separate resource group together with all the supporting cloud infrastructure necessary for this VM to run.

##Installing Terraform
The install process for Terraform is straightforward - [download](https://www.terraform.io/downloads.html) the package appropriate for your OS and unzip it into a separate install directory. The package contains a single executable file, which you can should also define a global PATH for. Instructions on setting the PATH on Linux and Mac can be found on [this page](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux), while [this page](https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows) contains instructions for setting the PATH on Windows.

##Setting up Terraform Access to Azure
To unlock Terraform magic in Azure, we must supply four pieces of security information to Terraform scripts.
