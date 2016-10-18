#Creating Azure Resources with Terraform
There are multiple ways to provision infrastructure into Azure today, from creating resources through user interface of Azure portal (http://portal.azure.com) to using Azure CLI to authoring enterprise-grade infrastructure templates with Azure Resource Manager JSON-based templates. The last option - writing JSON-based definitions of infrastructure resources - gets us very close to fulfilling the Infrastructure-as-Code promise, but JSON syntax can hardly be characterized as readable with double quotation marks and unintuitive comment placement making it hard to follow.

This is where Terraform comes in, providing a way to deploy cloud infrastructure using a higher-level templating language. But beyond improved readability, Terraform templates allow you to use the same templating language for a variety of public cloud providers, making it a valuable tool in your multi-cloud strategy. In this article, I will show you how to get started using Terraform with Azure, provisioning a Ubuntu virtual machine with Wordpress installed on it in a separate resource group together with all the supporting cloud infrastructure necessary for this VM to run.

##Setting up Terraform Access to Azure


