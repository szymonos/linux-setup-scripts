<#
.SYNOPSIS
Get list of Azure Subscriptions for the function ArgumentCompleter attribute.
#>
function ArgAzGetSubscriptions {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # generate and set the ValidateSet
    $query = "ResourceContainers | where type =~ 'microsoft.resources/subscriptions' | project name"
    [string[]]$possibleValues = Invoke-AzGraph -Query $query | Select-Object -ExpandProperty name

    # return matching branches
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}
