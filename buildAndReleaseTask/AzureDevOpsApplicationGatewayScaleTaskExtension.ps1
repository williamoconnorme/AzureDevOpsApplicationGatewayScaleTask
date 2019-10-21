[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Import dependencies
Import-Module -Name .\ps_modules\Az.Accounts\1.6.1\Az.Accounts.psd1 -Force
Import-Module -Name .\ps_modules\Az.Network\1.12.0\Az.Network.psd1 -Force

# Set variables from task form input
$resourceGroupName = Get-VstsInput -Name "ResourceGroupName" -Require
$applicationGatewayName = Get-VstsInput -Name "applicationGatewayName" -Require
$applicationGatewaySkuName = Get-VstsInput -Name "applicationGatewaySkuName" -Require
$connectedServiceNameARM = Get-VstsInput -Name "ConnectedServiceNameARM" -Require
$applicationGatewayCapacity = Get-VstsInput -Name "applicationGatewayCapacity" -Require
$endPointRM = Get-VstsEndpoint -Name $connectedServiceNameARM -Require
$clientId = $endPointRM.Auth.Parameters.ServicePrincipalId
$clientSecret = $endPointRM.Auth.Parameters.ServicePrincipalKey
$tenantId = $endPointRM.Auth.Parameters.TenantId

# Authenticate using service principal
$password = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($clientId, $password)
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId 

# Set SKU Tier
switch ($applicationGatewaySkuName) {
    "Standard_Small" { $applicationGatewayTierName = "Standard" }
    "Standard_Medium" { $applicationGatewayTierName = "Standard" }
    "Standard_Large" { $applicationGatewayTierName = "Standard" }
    "WAF_Medium" { $applicationGatewayTierName = "WAF" }
    "WAF_Large" { $applicationGatewayTierName = "WAF" }
    "Standard_v2" { $applicationGatewayTierName = "Standard_v2" }
    "WAF_v2" { $applicationGatewayTierName = "WAF_v2" }
}

# Scale Application Gateway
Write-Output "Configuring $($applicationGatewayName) to tier: $($applicationGatewayTierName) and SKU: $($applicationGatewaySkuName)"
$applicationGateway = Get-AzApplicationGateway -Name $applicationGatewayName -ResourceGroupName $resourceGroupName
$applicationGateway = Set-AzApplicationGatewaySku -ApplicationGateway $applicationGateway -Name $applicationGatewaySkuName -Tier $applicationGatewayTierName -Capacity $applicationGatewayCapacity
$applicationGateway = Set-AzApplicationGateway -ApplicationGateway $applicationGateway