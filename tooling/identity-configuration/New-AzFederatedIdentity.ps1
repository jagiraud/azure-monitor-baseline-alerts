<#
.SYNOPSIS
    Creates a new federated identity in Azure and assigns the role to the identity.
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.LINK
    https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-powershell%2Cwindows#use-the-azure-login-action-with-openid-connect
.EXAMPLE
    New-AzFederatedIdentity 
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>


[CmdletBinding()]
param (
    [Parameter(
        Mandatory = $true
    )]
    [string]
    $IdentityName = "az-alz-swe-platform-mi",
    $IdentityRoleAssignment = "Owner",
    $IdentityRoleAssignmentScope = "/providers/Microsoft.Management/managementGroups/225b122c-22cd-45b0-95c2-21ee5de01f0d"
)

#* Create the Microsoft Entra application.

$app = New-AzADApplication -DisplayName $IdentityName

<#
This command will output the AppId property that is your ClientId. 
The Id property is APPLICATION-OBJECT-ID and it will be used for creating federated credentials with Graph API calls.
#>

#* Create a service principal. Replace the $clientId with the AppId from your output. 
#* This command generates output with a different Id and will be used in the next step. The new Id is the ObjectId.

$sp = New-AzADServicePrincipal -ApplicationId $app.AppId

#* Create a new role assignment. Beginning with Az PowerShell module version 7.x, New-AzADServicePrincipal no longer assigns the Contributor role to the service principal by default. 
#* Replace $resourceGroupName with your resource group name, and $objectId with generated Id.

New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $IdentityRoleAssignment -Scope $IdentityRoleAssignmentScope

#* Get the values for clientId, subscriptionId, and tenantId to use later in your GitHub Actions workflow.

$clientId = $app.AppId
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Subscription.TenantId

#* Output the values for clientId, subscriptionId, and tenantId to be used when configuring your GitHub Actions workflow.
Write-Output "clientId: $clientId"
Write-Output "subscriptionId: $subscriptionId"
Write-Output "tenantId: $tenantId"


#1 End of part 1
#2 Part 2: Add federated credentials

New-AzADAppFederatedCredential -ApplicationObjectId $app.Id -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com/' -Name $IdentityName -Subject 'repo:jagiraud/azure-monitor-baseline-alerts:environment:main'
