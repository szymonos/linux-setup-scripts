<#
.SYNOPSIS
Send request to Microsoft Graph API.

.PARAMETER Path
Request path.
.PARAMETER ApiVersion
API version.
.PARAMETER Token
Microsoft Graph access token.
.PARAMETER Filter
Filter specified for the API request.
.PARAMETER Select
Select specific fields in the API request.
.PARAMETER Method
Request method. Allowed values: Get, Patch, Post, Put, Delete. Default: Get.
.PARAMETER Body
Request payload provided as string or hashtable.
.PARAMETER InFile
Request payload provided as path to file.
.PARAMETER SkipPagination
Switch whether or not to retrieve paginated results.
.PARAMETER JsonOutput
Switch whether to return a response as json.
#>
function Invoke-MgApiRequest {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Path,

        [ValidateScript({ $_ -match '^(v\d+\.\d+)|(beta)$' }, ErrorMessage = 'API version should be in the v0.0 format.')]
        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion = 'v1.0',

        [securestring]$Token,

        [string]$Filter,

        [string[]]$Select,

        [ValidateSet('Get', 'Patch', 'Post', 'Put', 'Delete')]
        [string]$Method = 'Get',

        [Parameter(Mandatory, ParameterSetName = 'Payload:Body')]
        [ValidateNotNullorEmpty()]
        [object]$Body,

        [Alias('f')]
        [Parameter(Mandatory, ParameterSetName = 'Payload:File')]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' }, ErrorMessage = "'{0}' is not a valid path.")]
        [string]$InFile,

        [switch]$SkipPagination,

        [switch]$JsonOutput
    )

    begin {
        # get Azure ARM access token if not prvided
        if (-not $Token) {
            $Token = (Get-MsoToken -ResourceUrl 'https://graph.microsoft.com/').Token
        }
        # build Azure REST API request parameters for splatting
        $params = @{
            Method         = $Method
            Authentication = 'Bearer'
            Token          = $Token
            Headers        = @{ 'Content-Type' = 'application/json' }
            ErrorAction    = 'Stop'
        }

        # add payload
        if ($Method -in @('Patch', 'Post', 'Put')) {
            if ($Body) {
                $params.Body = switch -Regex ($Body.GetType().Name) {
                    String {
                        $Body
                    }
                    'Hashtable|OrderedDictionary' {
                        $Body | ConvertTo-Json -Depth 99
                    }
                    default {
                        $null
                    }
                }
            } elseif ($InFile) {
                $params.InFile = $InFile
            }
        }

        # build Query
        if ($PSBoundParameters.Filter -or $PSBoundParameters.Select) {
            $Query = '?'
            if ($PSBoundParameters.Filter) {
                $Query += "`$filter=$($Filter.Replace(' ', '%20').Replace("'", '%27'))"
            }
            if ($PSBoundParameters.Select) {
                if ($PSBoundParameters.Filter) {
                    $Query += '&'
                }
                $Query += "`$select=$($Select.Trim() | Join-String -Separator ',')"
            }
        }

        # initialize variables
        $response = $null
        $responseList = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        # calculate request Uri
        $params.Uri = [System.UriBuilder]::new(
            'https',
            'graph.microsoft.com',
            443,
            "${ApiVersion}/${Path}",
            $Query
        ).Uri
        # write verbose messages
        Write-Verbose "$($params.Method.ToUpper()) $($params.Uri)"
        if ($params.Body) {
            Write-Verbose "Body`n$($params.Body)"
        }
        do {
            # send API request
            try {
                $response = Invoke-CommandRetry {
                    Invoke-RestMethod @params
                }
            } catch {
                if ($PSBoundParameters.ErrorAction -eq 'SilentlyContinue') {
                    Write-Verbose $_
                } else {
                    Write-Verbose $_.Exception.GetType().FullName
                    Write-Error $_
                }
            }
            # add response to response list
            if ($response.value) {
                $response.value.ForEach({ $responseList.Add($_) })
            } else {
                $response.ForEach({ $responseList.Add($_) })
            }
            # check pagination
            if ($response.'@odata.nextLink') {
                if ($SkipPagination) {
                    $response.'@odata.nextLink' = $null
                } else {
                    $params.Uri = $response.'@odata.nextLink'
                }
            }
        } while ($response.'@odata.nextLink')
    }

    end {
        # return response
        if ($JsonOutput) {
            if (Get-Command jq -CommandType Application -ErrorAction SilentlyContinue) {
                return $responseList | ConvertTo-Json -Depth 99 | jq
            } else {
                return $responseList | ConvertTo-Json -Depth 99
            }
        } else {
            return $responseList
        }
    }
}

<#
.SYNOPSIS
Get federated credentials for an Azure AD application.
.PARAMETER ApplicationObjectId
The object ID of the Azure AD application.
.PARAMETER ApiVersion
API version of the Microsoft Graph.
#>
function Get-MgAppFederatedCredential {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ApplicationObjectId,

        [ValidateScript({ $_ -match '^(v\d+\.\d+)|(beta)$' }, ErrorMessage = 'API version should be in the v0.0 format.')]
        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion
    )

    begin {
        # update PSBoundParameters
        $PSBoundParameters['Path'] = "applications/$ApplicationObjectId/federatedIdentityCredentials"
        $PSBoundParameters.Remove('ApplicationObjectId') | Out-Null
    }

    process {
        return Invoke-MgApiRequest @PSBoundParameters
    }
}
