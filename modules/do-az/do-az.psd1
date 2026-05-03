@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'do-az.psm1'

    # Version number of this module.
    ModuleVersion        = '1.22.5'

    # Supported PSEditions
    CompatiblePSEditions = @('Core')

    # ID used to uniquely identify this module
    GUID                 = 'e6489e60-2302-441c-a1ed-25ab5d2b52d5'

    # Author of this module
    Author               = 'Szymon Osiecki'

    # Copyright statement for this module
    Copyright            = '(c) Szymon Osiecki. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'This module is intended to streamline work with Azure.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '7.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @(
        'do-common'
        'Az.Accounts'
        'Az.ResourceGraph'
    )

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    ScriptsToProcess     = @(
        'Classes/do-az.ps1'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @(
        # az
        'Connect-AzContext'
        'Get-AzCtx'
        'Get-AzResourceTypeApiVersions'
        'Get-MsoToken'
        'Set-AzKeyVaultAccessPolicyApi'
        'Get-KeyVaultCertificate'
        'Get-KeyVaultSecret'
        'Set-KeyVaultSecret'
        'Get-VirtualNetwork'
        'Get-PrivateEndpoint'
        'Set-SubscriptionMenu'
        'Invoke-AzApiRequest'
        'Get-AksCredential'
        # azgraph
        'Invoke-AzGraph'
        'Get-AzGraphSubscription'
        'Get-AzGraphResourceGroup'
        'Get-AzGraphResourceGroupByName'
        'Get-AzGraphResource'
        'Get-AzGraphResourceByName'
        # completers
        'ArgAzGetSubscriptions'
        # aks
        'Set-AksFederatedCredential'
        # msgraph
        'Invoke-MgApiRequest'
        'Get-MgAppFederatedCredential'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @(
        'ssm'
        'setfcaks'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/szymonos/ps-modules/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/szymonos/ps-modules'

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # Prerelease string of this module
            # Prerelease = 'beta'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

}
