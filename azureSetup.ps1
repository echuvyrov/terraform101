Param(
  [ValidateSet('','Requirements','Setup')]
  [string]$runOption
)

$azure_client_name=""     # Application name
$azure_client_secret=""   # Application password
$azure_group_name=""
$azure_storage_name=""
$azure_subscription_id="" # Derived from the account after login
$azure_tenant_id=""       # Derived from the account after login
$location=""
$azure_object_id=""

function ShowHelp() {
	Write-Host "azure-setup"
	Write-Host ""
	Write-Host "  azure-setup helps you generate Terraform credentials for Azure"
	Write-Host ""
	Write-Host "  The script application"
	Write-Host "  (client), service principal, and permissions and displays a snippet"
	Write-Host "  for use in your Terraform templates."
	Write-Host ""
	Write-Host "  For simplicity we make a lot of assumptions and choose reasonable"
	Write-Host "  defaults. If you want more control over what happens, please use"
	Write-Host "  the Azure Powershell directly."
	Write-Host ""
	Write-Host "  Note that you must already have an Azure account, username,"
	Write-Host "  password, and subscription. You can create those here:"
	Write-Host ""
	Write-Host "  - https://account.windowsazure.com/"
	Write-Host ""
	Write-Host "REQUIREMENTS"
	Write-Host ""
	Write-Host "  - Azure PowerShell"
	Write-Host "  - jq"
	Write-Host ""
	Write-Host "  Use the requirements command (below) for more info."
	Write-Host ""
	Write-Host "USAGE"
	Write-Host ""
	Write-Host "  .\azure-setup.ps1 requirements"
	Write-Host "  .\azure-setup.ps1 setup"
	Write-Host ""
}

function Requirements() {
	$found=0

	$azureversion = (Get-Module -ListAvailable -Name AzureRM -Refresh)
	If ($azureversion.Version.Major -gt 0) 
	{
		$found=$found + 1
		Write-Host "Found Azure PowerShell version: $($azureversion.Version.Major).$($azureversion.Version.Minor)"
	}
	Else
	{
		Write-Host "Azure PowerShell is missing. Please download and install Azure PowerShell from"
		Write-Host "http://aka.ms/webpi-azps"		
	}

	return $found
}

function AskSubscription() {
	$azuresubscription = Add-AzureRmAccount
	$script:azure_subscription_id = $azuresubscription.Context.Subscription.Id
	$script:azure_tenant_id = $azuresubscription.Context.Subscription.TenantId		
}

Function RandomComplexPassword ()
{
	param ( [int]$Length = 8 )
 	#Usage: RandomComplexPassword 12
 	$Assembly = Add-Type -AssemblyName System.Web
 	$RandomComplexPassword = [System.Web.Security.Membership]::GeneratePassword($Length,2)
 	return $RandomComplexPassword
}

function AskName() {
	Write-Host ""
	Write-Host "Choose a name for your client."
	Write-Host "This is mandatory - do not leave blank."
	Write-Host "ALPHANUMERIC ONLY. Ex: mytfdeployment."
	Write-Host  "> " -NoNewline
	$script:meta_name = Read-Host
}

function AskSecret() {
	Write-Host ""
	Write-Host "Enter a secret for your application. We recommend generating one with"
	Write-Host "openssl rand -base64 24. If you leave this blank we will attempt to"
	Write-Host "generate one for you using .Net Security Framework. THIS WILL BE SHOWN IN PLAINTEXT."
	Write-Host "Ex: myterraformsecret8734"
	Write-Host "> " -NoNewline
	$script:azure_client_secret = Read-Host
	if ($script:azure_client_secret -eq "")
	{
		$script:azure_client_secret = RandomComplexPassword(43)
	}	
	Write-Host "Client_secret: $script:azure_client_secret"
}

function CreateServicePrinciple() {
	Write-Host "==> Creating service principal"
	$app = New-AzureRmADApplication -DisplayName $meta_name -HomePage "https://$script:meta_name" -IdentifierUris "https://$script:meta_name" -Password $script:azure_client_secret
 	New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
	
	#sleep 10 seconds to allow resource creation to converge
	Start-Sleep -s 10
 	New-AzureRmRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $app.ApplicationId.Guid
	
	$script:azure_client_id = $app.ApplicationId
	$script:azure_object_id = $app.ObjectId

	if ($error.Count > 0)
	{
		Write-Host "Error creating service principal: $azure_client_id"
		exit
	}
}

function ShowConfigs() {
	Write-Host ""
	Write-Host "Use the following configuration for your Terraform scripts:"
	Write-Host ""
	Write-Host "{"
	Write-Host "      'client_id': $azure_client_id,"
	Write-Host "      'client_secret': $azure_client_secret,"
	Write-Host "      'subscription_id': $azure_subscription_id,"
	Write-Host "      'tenant_id': $azure_tenant_id"
	Write-Host "}"
	Write-Host ""
}

function Setup() {
	$reqs = Requirements
	
	if($reqs -gt 0)
	{
		AskSubscription
		AskName
		AskSecret

		CreateServicePrinciple

		ShowConfigs
	}
}

switch ($runOption)
    {
        "requirements" { Requirements }
        "setup" { Setup }
        default { ShowHelp }
    }

