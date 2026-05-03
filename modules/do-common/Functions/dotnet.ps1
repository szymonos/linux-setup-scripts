<#
.SYNOPSIS
Get dotnet current directory.
#>
function Get-DotnetCurrentDirectory {
    Resolve-Path $([IO.Path]::GetFullPath('.'))
}

Set-Alias -Name swd -Value Get-DotnetCurrentDirectory


<#
.SYNOPSIS
Set dotnet current directory to specified location.
#>
function Set-DotnetCurrentDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
        [string]$Path = $PWD
    )

    [IO.Directory]::SetCurrentDirectory($Path)
}

Set-Alias -Name sswd -Value Set-DotnetCurrentDirectory


<#
.SYNOPSIS
Set location to dotnet current directory.
#>
function Set-DotnetLocation {
    Set-Location $(Get-DotnetCurrentDirectory)
}

Set-Alias -Name cds -Value Set-DotnetLocation
