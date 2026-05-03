$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/certs.ps1
. $PSScriptRoot/Functions/cli.ps1
. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/dotnet.ps1
. $PSScriptRoot/Functions/logs.ps1
. $PSScriptRoot/Functions/net.ps1
. $PSScriptRoot/Functions/python.ps1

$exportModuleMemberParams = @{
    Function = @(
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
    Variable = @()
    Alias    = @(
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
}

Export-ModuleMember @exportModuleMemberParams
