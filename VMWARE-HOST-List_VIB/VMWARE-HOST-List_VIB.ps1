<#
.DESCRIPTION
This Script retrieve the VIB information on all the VMware Host
.PARAMETER AllVib
    This is the default parameter to retrieve all the VIBs information
.PARAMETER VIBName
    Specifies a specific VIB Name
.PARAMETER VIBVendor
    Specifies a specific VIB Vendor
.EXAMPLE
    VMWARE-HOST-List_VIB.ps1 -AllVib
.EXAMPLE
    VMWARE-HOST-List_VIB.ps1 -VibName "net-e1000e" -Verbose
.EXAMPLE
    VMWARE-HOST-List_VIB.ps1 -VibVendor "Dell" -Verbose
.NOTES
    Francois-Xavier Cat
    lazywinadmin.com
    @lazywinadmin
#>
[CmdletBinding(DefaultParameterSetName = "All")]
PARAM (
    [parameter(Mandatory = $true)]
    [pscredential]
    $Credential,
    [parameter(Mandatory = $true)]
    $Vcenter,
    [Parameter(mandatory = $true, ParameterSetName = "All")]
    [Switch]$AllVib,
    [Parameter(mandatory = $true, ParameterSetName = "VIBName")]
    $VibName,
    [Parameter(mandatory = $true, ParameterSetName = "VIBVendor")]
    $VibVendor
)
BEGIN {
    TRY {
        # Verify VMware Snapin is loaded
        IF (-not (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction 'SilentlyContinue')) {
            Write-Verbose -Message "BEGIN - Loading Vmware Snapin VMware.VimAutomation.Core..."
            Add-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction Stop -ErrorVariable ErrorBeginAddPssnapin
        }

        # Verify VMware Snapin is connected to at least one vcenter
        IF (-not ($global:DefaultVIServer.count -gt 0)) {
            Write-Verbose -Message "BEGIN - Currently not connected to a vCenter..."
            $Vcenter = Read-Host -Prompt "You are not connected to a VMware vCenter, Please enter the FQDN or IP of the vCenter"

            IF ((Read-Host -Prompt "You are currently logged as: $($env:username). Do you want to specify different credential ? (Y/N)") -eq 'Y') {
                Connect-VIServer -Server $Vcenter -credential (Get-Credential) -ErrorAction Stop -ErrorVariable ErrorBeginConnectViServer
            }
            ELSE {
                Connect-VIServer -Server $Vcenter -ErrorAction Stop -ErrorVariable ErrorBeginConnectViServer
            }
        }
    }
    CATCH {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
PROCESS {
    TRY {
        $VMHosts = Get-VMHost -ErrorAction Stop -ErrorVariable ErrorGetVMhost | Where-Object -FilterScript { $_.ConnectionState -eq "Connected" }

        IF ($PSBoundParameters['AllVib']) {
            Foreach ($CurrentVMhost in $VMHosts) {
                TRY {
                    # Exposes the ESX CLI functionality of the current host
                    $ESXCLI = Get-EsxCli -VMHost $CurrentVMhost.name
                    # Retrieve Vibs
                    $ESXCLI.software.vib.list() |
                        ForEach-Object -Process {
                            $VIB = $_
                            $Prop = [ordered]@{
                                'VMhost'          = $CurrentVMhost.Name
                                'ID'              = $VIB.ID
                                'Name'            = $VIB.Name
                                'Vendor'          = $VIB.Vendor
                                'Version'         = $VIB.Version
                                'Status'          = $VIB.Status
                                'ReleaseDate'     = $VIB.ReleaseDate
                                'InstallDate'     = $VIB.InstallDate
                                'AcceptanceLevel' = $VIB.AcceptanceLevel
                            }#$Prop

                            # Output Current Object
                            New-Object -TypeName PSobject -Property $Prop
                        }#FOREACH
                }#TRY
                CATCH {
                    Throw $_
                }
            }
        }
        IF ($PSBoundParameters['VibVendor']) {
            Foreach ($CurrentVMhost in $VMHosts) {
                TRY {
                    # Exposes the ESX CLI functionality of the current host
                    $ESXCLI = Get-EsxCli -VMHost $CurrentVMhost.name
                    # Retrieve Vib from vendor $vibvendor
                    $ESXCLI.software.vib.list() | Where-Object -FilterScript { $_.Vendor -eq $VibVendor } |
                    ForEach-Object
                {
                    $VIB = $_
                    $Prop = [ordered]@{
                        'VMhost'          = $CurrentVMhost.Name
                        'ID'              = $VIB.ID
                        'Name'            = $VIB.Name
                        'Vendor'          = $VIB.Vendor
                        'Version'         = $VIB.Version
                        'Status'          = $VIB.Status
                        'ReleaseDate'     = $VIB.ReleaseDate
                        'InstallDate'     = $VIB.InstallDate
                        'AcceptanceLevel' = $VIB.AcceptanceLevel
                    }#$Prop

                    # Output Current Object
                    New-Object -TypeName PSobject -Property $Prop
                }#FOREACH
            }#TRY
            CATCH {
                Throw $_
            }
        }
    }
    IF ($PSBoundParameters['VibName']) {
        Foreach ($CurrentVMhost in $VMHosts) {
            TRY {
                # Exposes the ESX CLI functionality of the current host
                $ESXCLI = Get-EsxCli -VMHost $CurrentVMhost.name
                # Retrieve Vib with name $vibname
                $ESXCLI.software.vib.list() | Where-Object -FilterScript { $_.Name -eq $VibName } |
                ForEach-Object
            {
                $VIB = $_
                $Prop = [ordered]@{
                    'VMhost'          = $CurrentVMhost.Name
                    'ID'              = $VIB.ID
                    'Name'            = $VIB.Name
                    'Vendor'          = $VIB.Vendor
                    'Version'         = $VIB.Version
                    'Status'          = $VIB.Status
                    'ReleaseDate'     = $VIB.ReleaseDate
                    'InstallDate'     = $VIB.InstallDate
                    'AcceptanceLevel' = $VIB.AcceptanceLevel
                }#$Prop

                # Output Current Object
                New-Object -TypeName PSobject -Property $Prop
            }#FOREACH
        }#TRY
        CATCH {
            Throw $_
        }
    }
}
}
CATCH {
    throw $_
}
}
