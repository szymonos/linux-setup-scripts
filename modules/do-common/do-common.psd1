@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'do-common.psm1'

    # Version number of this module.
    ModuleVersion        = '1.8.3'

    # Supported PSEditions
    CompatiblePSEditions = @('Core')

    # ID used to uniquely identify this module
    GUID                 = '4fa2b6d3-def2-4684-8ed2-8d02508f35bc'

    # Author of this module
    Author               = 'Szymon Osiecki'

    # Copyright statement for this module
    Copyright            = '(c) Szymon Osiecki. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'This module is intended to streamline my workflow with PowerShell.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '7.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    ScriptsToProcess     = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @(
        # certs
        'Add-CertificateProperties'
        'ConvertFrom-PEM'
        'ConvertTo-PEM'
        'Get-Certificate'
        'Get-CertificateOpenSSL'
        'Get-RootCertificates'
        'Show-Certificate'
        'Show-CertificateChain'
        'Show-ConvertedPem'
        # cli
        'Invoke-DigColored'
        # common
        'ConvertFrom-Base64'
        'ConvertTo-Base64'
        'ConvertFrom-Base64Url'
        'ConvertFrom-JWT'
        'ConvertFrom-Cfg'
        'ConvertTo-Cfg'
        'ConvertTo-UTF8LF'
        'Convert-ROT13'
        'ConvertTo-JsonFormatted'
        'Get-ArrayIndexMenu'
        'Get-CmdletAlias'
        'Get-DotEnv'
        'Get-LogMessage'
        'Get-PSReadLineHistory'
        'Format-Duration'
        'Invoke-CommandRetry'
        'Invoke-ExampleScriptSave'
        'New-Password'
        'Set-DotEnv'
        'Show-Object'
        'Test-IsAdmin'
        # dotnet
        'Get-DotnetCurrentDirectory'
        'Set-DotnetCurrentDirectory'
        'Set-DotnetLocation'
        # logs
        'Set-LogFile'
        'Show-LogContext'
        'Write-LogContext'
        # net
        'ConvertFrom-CIDR'
        'Invoke-DownloadFile'
        # python
        'Invoke-CertifiFixFromChain'
        'Invoke-VenvActivate'
        'Invoke-VenvDeactivate'
        'Invoke-CondaSetup'
        'Invoke-PySetup'
        'Invoke-UvSetup'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @(
        # certs
        'pemdec'
        # cli
        'digc'
        # common
        'alias'
        'egsave'
        'json'
        'pshistory'
        'ghi'
        # dotnet
        'swd'
        'sswd'
        'cds'
        # net
        'idf'
        # python
        'fixcertpy'
        'fxcertpy'
        'iva'
        'ivd'
        'ics'
        'ips'
        'ius'
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
