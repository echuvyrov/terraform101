#Creating Azure Resources with Terraform
There are multiple ways to provision infrastructure into Azure today, from creating resources through user interface of Azure portal (http://portal.azure.com) to using Azure CLI to authoring enterprise-grade infrastructure solutions with Azure Resource Manager JSON-based templates. The last option - writing JSON-based definitions of infrastructure resources - gets us very close to fulfilling the Infrastructure-as-Code promise, but JSON syntax can hardly be characterized as readable with double quotation marks and unintuitive comment placement making it hard to follow.

This is where Terraform comes in, providing a way to deploy cloud infrastructure using a higher-level templating language. But beyond improved readability, Terraform templates allow you to use the same templating language for a variety of public cloud providers, making it a valuable tool in your multi-cloud strategy. In this article, I will show you how to get started using Terraform with Azure, provisioning a Ubuntu virtual machine with Wordpress installed on it in a separate resource group together with all the supporting cloud infrastructure necessary for this VM to run.

##Installing Terraform
The install process for Terraform is straightforward - [download](https://www.terraform.io/downloads.html) the package appropriate for your OS and unzip it into a separate install directory. The package contains a single executable file, which you should also define a global PATH for. Instructions on setting the PATH on Linux and Mac can be found on [this page](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux), while [this page](https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows) contains instructions for setting the PATH on Windows. Verify your installation by running the "terraform" command - you should see a list of available commands as the output.

You are now almost ready to start provisioning infrastructure in Azure; there's just one small setup issue remaining - enabling Terraform to access your Azure subscription and provision resources on your behalf.

##Setting up Terraform Access to Azure
To unlock Terraform magic in Azure, you need to allow Terraform scripts to provision resources into your Azure subscriptions on your behalf. To enable that access, you need to setup two entities in Azure Active Directory (AAD) - AAD Application and AAD Service Principal - and use these entities' identifiers in your Terraform scripts. The reason for having both entities makes perfect sense in multi-tenant environments, where Service Principal is a local instance of a global AAD App and allows for granular local access control to global resources (in other words, you are configuring access levels at the Service Principal level, not app level).

When working with Terraform, however, you will be using a single AAD Application and a single Service Principal to enable resource provisioning; however, you still need to create both. To streamline this security setup process, Hashicorp and Microsoft have written scripts that create all the necessary security infrastructure in Azure (AAD App and Service Principal), allowing you to simply execute these scripts and copy/paste the necessary information into your scripts.

###Windows Users
If you are using a Windows machine to write your and execute your Terraform scripts, you need to (1) [install Azure PowerShell tools](https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/#step-1-install) and (2) download and execute the [azure-setup.ps1 script](https://github.com/echuvyrov/terraform101/blob/master/azureSetup.ps1) from the PowerShell console. To run the azure-setup.ps1 script, download it, execute the "./azure-setup.ps1 setup" command from the console and login into your Azure subscription with administrative privileges. Then, provide an application name (arbitrary string, required) when prompted and (optionally) supply a strong password when prompted. If you don't provide the password, the strong password will be generated for you using .Net security libraries.

###Linux/Mac Users
To get started with Terraform on Linux machines or Macs, you need to (1) [install Azure xPlat CLI tools](https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/), (2) [download and install jq](https://stedolan.github.io/jq/download/) JSON processor and  (3) download and execute the [azure-setup.sh script](https://github.com/mitchellh/packer/blob/master/contrib/azure-setup.sh) bash script from the console. To run the azure-setup.sh script, download it, execute the "./azure-setup setup" command from the console and login into your Azure subscription with administrative privileges. Then, provide an application name (arbitrary string, required) when prompted and (optionally) supply a strong password when prompted. If you don't provide the password, the strong password will be generated for you using .Net security libraries.

Both Linux and Windows scripts create an AAD Application and a Service Principal, giving Service Principal an owner-level access on the subscription. Because of high level of access granted, you should always protect the security information generated by those scripts. Take a note of all four pieces of security information provided by those scripts: client_id, client_secret, subscription_id and tenant_id. Finally, if for some reason you were not able to execute the scripts, you can create a Service Principal manually by following this [step-by-step documentation](https://www.terraform.io/docs/providers/azurerm/index.html) from Hashicorp.

##Minimum Viable Terraform Script
With Service Principal information in hand, let's use Terraform to create perhaps the smallest unit of work in Azure - resource group.

###Creating the Terraform Script
In your text editor of choice (Visual Code/Sublime/Vim/etc), create a file called terraform_azure101.tf. The exact name of the file is not important, since terraform accepts the folder name as a parameter - all scripts in the folder get executed. Paste the following code in that new file:

~~~~
# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "your_subscription_id_from_script_execution"
  client_id       = "your_client_id_from_script_execution"
  client_secret   = "your_client_secret_from_script_execution"
  tenant_id       = "your_tenant_id_from_script_execution"
}

# create a resource group 
resource "azurerm_resource_group" "helloterraform" {
    name = "terraformtest"
    location = "West US"
}
~~~~
In the "provider" section of the script, you tell Terraform to use an Azure provider to provision resources in the script. Refer to the results of Service Principal script execution above for values for subscription_id, client_id, client_secret and tenant_id. The "azure_rm_resource_group" resource instructs Terraform to create a new resource group; you will see more resource types available in Terraform below.

###Executing the Script
With the script saved, exit to the console/command line and type

```
terraform plan terraformscripts
```
In the above, we assume "terraformscripts" is the folder where the script was saved. Note that we used the "plan" Terraform command, which looks at the resources defined in the scripts, compares it to the state information saved by Terraform and then outputs planned execution _without_ creating resources in Azure. 

You should see something like the following screen after you execute the command above

![Image of Terraform Plan](https://github.com/echuvyrov/terraform101/blob/master/tf_plan.png) 



