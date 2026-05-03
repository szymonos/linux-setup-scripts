<#
.SYNOPSIS
Function resolving CIDR notation range.

.PARAMETER InputObject
Input string to be converted from CIDR range.
#>
function ConvertFrom-CIDR {
    [CmdletBinding()]
    [OutputType([Collections.Generic.List[PSCustomObject]])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string[]]${InputObject}
    )

    begin {
        $ranges = [Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        $addr, $maskLength = $InputObject -split '/'
        [int]$maskLen = 0
        if (-not [int32]::TryParse($maskLength, [ref] $maskLen)) {
            throw "Cannot parse CIDR mask length string: '$maskLen'"
        }
        if (0 -gt $maskLen -or $maskLen -gt 32) {
            throw 'CIDR mask length must be between 0 and 32'
        }
        $ipAddr = [Net.IPAddress]::Parse($addr)
        if ($ipAddr -eq $null) {
            throw "Cannot parse IP address: $addr"
        }
        if ($ipAddr.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
            throw 'Can only process CIDR for IPv4'
        }

        $shiftCnt = 32 - $maskLen
        $mask = -bnot ((1 -shl $shiftCnt) - 1)
        $ipNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($ipAddr.GetAddressBytes(), 0))
        $ipStart = ($ipNum -band $mask)
        $ipEnd = ($ipNum -bor (-bnot $mask))

        # return as tuple of strings:
        $ranges.Add([PSCustomObject]@{
                CidrRange  = $InputObject[0]
                StartIP    = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipStart)) -join '.'
                EndIP      = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipEnd)) -join '.'
                TotalHosts = $ipEnd - $ipStart + 1
            }
        )
    }

    end {
        return $ranges
    }
}


<#
.SYNOPSIS
Download file from the specified Uri

.PARAMETER Uri
Uri to download the file from.
.PARAMETER Destination
Destination folder do save the file to
#>
function Invoke-DownloadFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [ValidateScript( { Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
        [string]$Destination = '.'
    )

    $client = [Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('PowerShell')

    $response = $client.GetAsync($Uri).Result

    if ($response.IsSuccessStatusCode) {
        $contentDisposition = $response.Content.Headers.ContentDisposition
        $fileName = if ($null -ne $contentDisposition) {
            $contentDisposition.FileName
        } else {
            [IO.Path]::GetFileName($Uri)
        }
    } else {
        throw "Failed to download file. Status code: $($response.StatusCode)"
    }

    $folderPath = [IO.Path]::GetFullPath($Destination)
    $destinationPath = [IO.Path]::Combine($folderPath, $fileName)

    $stream = [IO.FileStream]::new($destinationPath, [IO.FileMode]::Create)
    $response.Content.CopyToAsync($stream).Wait()
    $stream.Close()

    Write-Host "File downloaded to: $destinationPath"
}

Set-Alias -Name idf -Value Invoke-DownloadFile
