#Creating Azure Resources with Terraform
There are multiple ways to provision infrastructure into Azure today, from creating resources through user interface of Azure portal (http://portal.azure.com) to using Azure CLI to authoring enterprise-grade infrastructure solutions with Azure Resource Manager JSON-based templates. The last option - writing JSON-based definitions of infrastructure resources - gets us very close to fulfilling the Infrastructure-as-Code promise, but JSON syntax can hardly be characterized as readable with double quotation marks and unintuitive comment placement making it hard to follow.

This is where Terraform comes in, providing a way to deploy cloud infrastructure using a higher-level templating language. But beyond improved readability, Terraform templates allow you to use the same templating language for a variety of public cloud providers, making it a valuable tool in your multi-cloud strategy. In this article, I will show you how to get started using Terraform with Azure, provisioning a virtual machine running Ubuntu OS in a separate resource group together with all the supporting cloud infrastructure necessary for this VM to run.

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

![Image of Terraform Plan](https://github.com/echuvyrov/terraform101/blob/master/tf_plan2.png)

Everything looks correct, go ahead and provision this new resource group in Azure by executing 
```
terraform apply terraformscripts
```
If you look in the Azure portal now, you should see the new empty resource group called "terraformtest." In the section below, you will add a Virtual Machine and all the supporting infrastructure to it.

##Provisioning Ubuntu VM with Terraform
Let's extend Terraform script we've created above with details necessary to provision a Virtual Machine running Ubuntu. The list of resources that you will provision in the sections below are: network with a single subnet, a network interface card, a storage account with storage container, a public IP and a virtual machine utilizing all the resources above. For a thorough documentation of each of the Azure Terraform resources, consult [Terraform documentation](https://www.terraform.io/docs/providers/azurerm/index.html).

The full version of the [provisioning script](https://github.com/echuvyrov/terraform101/blob/master/terraform101.tf) is also provided for convenience.

###Extending the Terraform Script
Extend the script created above with the following resources. 
~~~~
# create a virtual network
resource "azurerm_virtual_network" "helloterraformnetwork" {
    name = "acctvn"
    address_space = ["10.0.0.0/16"]
    location = "West US"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
}

# create subnet
resource "azurerm_subnet" "helloterraformsubnet" {
    name = "acctsub"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    virtual_network_name = "${azurerm_virtual_network.helloterraformnetwork.name}"
    address_prefix = "10.0.2.0/24"
}
~~~~
The script above creates a virtual network and a subnet within that virtual network. Note the reference to the resource group you have created already via the "${azurerm_resource_group.helloterraform.name}" and the similar style reference using the resource type and name in the definition of the subnet.

~~~~
# create public IP
resource "azurerm_public_ip" "helloterraformips" {
    name = "terraformtestip"
    location = "West US"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "TerraformDemo"
    }
}

# create network interface
resource "azurerm_network_interface" "helloterraformnic" {
    name = "tfni"
    location = "West US"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"

    ip_configuration {
        name = "testconfiguration1"
        subnet_id = "${azurerm_subnet.helloterraformsubnet.id}"
        private_ip_address_allocation = "static"
        private_ip_address = "10.0.2.5"
        public_ip_address_id = "${azurerm_public_ip.helloterraformips.id}"
    }
}
~~~~
Script snippets above create a public IP and a network interface that makes use of the public IP created. Note the references to subnet_id and public_ip_address_id - Terraform has built-in intelligence to realize that network interface has a dependency on resources that need to be created prior to the creation of the network interface.

~~~~
# create storage account
resource "azurerm_storage_account" "helloterraformstorage" {
    name = "helloterraformstorage"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    location = "westus"
    account_type = "Standard_LRS"

    tags {
        environment = "staging"
    }
}

# create storage container
resource "azurerm_storage_container" "helloterraformstoragestoragecontainer" {
    name = "vhd"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    storage_account_name = "${azurerm_storage_account.helloterraformstorage.name}"
    container_access_type = "private"
    depends_on = ["azurerm_storage_account.helloterraformstorage"]
}
~~~~
Here, you created a storage account and defined a storage container within that storage account - this is where you will store VHDs for the virtual machine about to be created.

~~~~
# create virtual machine
resource "azurerm_virtual_machine" "helloterraformvm" {
    name = "terraformvm"
    location = "West US"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    network_interface_ids = ["${azurerm_network_interface.helloterraformnic.id}"]
    vm_size = "Standard_A0"

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "14.04.2-LTS"
        version = "latest"
    }

    storage_os_disk {
        name = "myosdisk"
        vhd_uri = "${azurerm_storage_account.helloterraformstorage.primary_blob_endpoint}${azurerm_storage_container.helloterraformstoragestoragecontainer.name}/myosdisk.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
        computer_name = "hostname"
        admin_username = "testadmin"
        admin_password = "Password1234!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags {
        environment = "staging"
    }
}
~~~~
Finally, the snippet above creates a virtual machine that utilizes all the resources we have provisioned already: storage account and container for a virtual hard disk (VHD), network interface with public IP and subnet specified, as well as the resource group you have already created. Note the vm_size property, where the script specifies the most affordable Azure SKU - A0, as well as the storage image reference to Ubuntu OS from Canonical.

###Executing the Script
With the script saved, exit to the console/command line and type
```
terraform apply terraformscripts
```
After some time, you should see the resources, including a virtual machine, appearing in the "terraformtest" resource group in Azure portal.

##Coming Up Next
In the future installments of Terraform on Azure series, we will cover working with the Terraform state, separating code in modules, working as a distributed team and other topics to allow you to take full advantage of this next-generation cloud provisioning tool.

