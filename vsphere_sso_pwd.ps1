# Performs a discovery of the VMware hosts within vCenter and 
# saves them to Vault with with a supplied password.
# Pass the vcenter, vaultserver, host password and vault token as parameters.
#
# Workflow:  
#   a. Login into vCenter and list all ESXi hosts
#   b. For each host set a specified password into Vault in the sytemcreds/esxihosts

param (
    [Parameter(Mandatory=$true)][string]$vcenter,
    [Parameter(Mandatory=$true)][string]$vcenteruser,
    [Parameter(Mandatory=$true)][string]$vaultserver,
    [Parameter(Mandatory=$true)][string]$vaulttoken
 )

 write-output "VCenter Server: $vcenter"
 write-output "VCenter User: $vcenteruser"
 write-output "Vault Server: $vaultserver"
 write-output "Vault Token: $vaulttoken"

# Connect to vCenter or ESXi Host and enumerate hosts to be updated
    $JSON="{ `"allow_repeat`": true,`"allow_uppercase`": true, `"digits`": `"1`",`"length`": `"8`",`"symbols`": `"1`"} }"
$jsondata =  Invoke-RestMethod -Headers @{'X-Vault-Token' = $vaulttoken} -Method POST -Body $JSON -Uri $vaultserver/v1/gen/password 
write-output "VMhost : $vcenter"
if($?) {

    $newpw = $jsondata.data.value
    write-output "news passwod : $newpw"     

   if($?) {
        write-host "Connecting to $vcenter..."
        Connect-SsoAdminServer -Server $vcenter -User $vcenteruser -Password '}Wfe3Exj' -SkipCertificateCheck
        write-host "Changing $vcenteruser password on $vcenter"
        #Remove-SsoPersonUser -User (Get-SsoPersonUser -Name $vcenteruser -Domain vsphere.local)
        #New-SsoPersonUser -User $vcenteruser -Password $newpw -FirstName $vcenteruser -LastName 'vsphere.local'
        #Set-SsoPersonUser -User $vcenteruser -Group 'Administrator' -Add
        $NewPwd = ConvertTo-SecureString $newpw -AsPlainText -Force
        Set-SsoSelfPersonUserPassword -Password $NewPwd
        Disconnect-SsoAdminServer -Server $Global:DefaultSsoAdminServers[0]
        if($?) {
            Write-Output "$vcenteruser password was stored in Vault and updated on ESXi host - $vcenter"
        }
        else {
            Write-Output "Error: $vcenteruser password was stored in Vault but *not* changed on the ESXi host - $vcenter"
        }
    }
    else {
        Write-Output "Error saving new password to Vault. ESXi password will remain unchanged for $vcenter"
    }
 }
else {
     Write-Output "Error reading password from Vault. Be sure a password is saved under the Vault path: /systemcreds/esxihosts/$vcenter"
 }
