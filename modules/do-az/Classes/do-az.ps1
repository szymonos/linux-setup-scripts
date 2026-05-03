<#
.SYNOPSIS
Class of AzGraph compatible Azure objects.
#>
class AzGraphSubscription {
    [string]$id
    [string]$name
    [string]$type
    [guid]$subscriptionId
    [string]$subscription
    [guid]$tenantId
    [psobject]$properties
    [string]$ResourceId

    # constructors
    AzGraphSubscription () { }

    AzGraphSubscription ([PSCustomObject]$obj) {
        $this.id = $obj.id
        $this.name = $obj.name
        $this.type = $obj.type
        $this.subscriptionId = $obj.subscriptionId
        $this.subscription = $this.name
        $this.tenantId = $obj.tenantId
        $this.properties = $obj.properties
        $this.ResourceId = $this.id
    }

    AzGraphSubscription ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 3 -and $idSplit[1] -eq 'subscriptions') {
                $this.id = $id
                $this.type = 'microsoft.resources/subscriptions'
                $this.subscriptionId = $idSplit[2]
                $this.ResourceId = $id
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    [string] ToString() {
        return $this.ResourceId
    }
}
# Specify AzGraphResource DefaultDisplayPropertySet
Update-TypeData -TypeName 'AzGraphSubscription' -DefaultDisplayPropertySet 'name', 'type', 'subscriptionId', 'id' -ErrorAction SilentlyContinue


class AzGraphResourceGroup : AzGraphSubscription {
    [string]$location
    [string]$resourceGroup
    [string]$subscription
    [psobject]$tags

    # constructors
    AzGraphResourceGroup () { }

    AzGraphResourceGroup ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 5 -and $idSplit[1] -eq 'subscriptions' -and $idSplit[3] -eq 'resourceGroups') {
                $this.id = $id
                $this.name = $idSplit[4]
                $this.resourceGroup = $this.name.ToLower()
                $this.type = 'microsoft.resources/subscriptions/resourcegroups'
                $this.subscriptionId = $idSplit[2]
                $this.ResourceId = $this.id
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzGraphResourceGroup ([PSCustomObject]$obj) {
        $this.id = $obj.id
        $this.location = $obj.location
        $this.name = $obj.name
        $this.resourceGroup = $obj.resourceGroup
        $this.type = $obj.type
        $this.subscriptionId = $obj.subscriptionId
        $this.subscription = $obj.subscription
        $this.tenantId = $obj.tenantId
        $this.properties = $obj.properties
        $this.tags = $obj.tags
        $this.ResourceId = $this.id
    }

    [string] ToString() {
        return $this.ResourceId
    }
}
# Specify AzGraphResourceGroup DefaultDisplayPropertySet
Update-TypeData -TypeName 'AzGraphResourceGroup' -DefaultDisplayPropertySet 'name', 'type', 'subscriptionId', 'subscription', 'id' -ErrorAction SilentlyContinue


class AzGraphResource : AzGraphResourceGroup {
    [string]$kind
    [psobject]$sku
    [psobject]$identity

    # constructors
    AzGraphResource () { }

    AzGraphResource ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 9 -and $idSplit[1] -eq 'subscriptions' -and $idSplit[3] -eq 'resourceGroups' -and $idSplit[5] -eq 'providers') {
                $this.id = $id
                $this.name = $idSplit[8]
                $this.resourceGroup = $idSplit[4]
                $this.type = "$($idSplit[6])/$($idSplit[7])"
                $this.subscriptionId = $idSplit[2]
                $this.ResourceId = $this.id
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzGraphResource ([guid]$SubscriptionId, [string]$ResourceGroup, [string]$Type, [string]$Name) {
        $this.id = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/$Type/$Name"
        $this.name = $Name
        $this.resourceGroup = $ResourceGroup
        $this.type = $Type
        $this.subscriptionId = $SubscriptionId
        $this.ResourceId = $this.id
    }

    AzGraphResource ([PSCustomObject]$obj) {
        $this.id = $obj.id
        $this.kind = $obj.kind
        $this.location = $obj.location
        $this.name = $obj.name
        $this.resourceGroup = $obj.resourceGroup
        $this.type = $obj.type
        $this.subscriptionId = $obj.subscriptionId
        $this.subscription = $obj.subscription
        $this.tenantId = $obj.tenantId
        $this.sku = $obj.sku
        $this.properties = $obj.properties
        $this.tags = $obj.tags
        $this.identity = $obj.identity
        $this.ResourceId = $this.id
    }

    AzGraphResource ([AzGraphResource]$obj) {
        $this.id = $obj.id
        $this.kind = $obj.kind
        $this.location = $obj.location
        $this.name = $obj.name
        $this.resourceGroup = $obj.resourceGroup
        $this.type = $obj.type
        $this.subscriptionId = $obj.subscriptionId
        $this.subscription = $obj.subscription
        $this.tenantId = $obj.tenantId
        $this.sku = $obj.sku
        $this.properties = $obj.properties
        $this.tags = $obj.tags
        $this.identity = $obj.identity
        $this.ResourceId = $this.id
    }

    [AzGraphResource] GetSubscriptionName () {
        $this.subscription = (Get-AzGraphSubscription -SubscriptionId $this.subscriptionId).name

        return [AzGraphResource]::new($this)
    }

    [string] ToString() {
        return $this.ResourceId
    }
}
# Specify AzGraphResource DefaultDisplayPropertySet
Update-TypeData -TypeName 'AzGraphResource' -DefaultDisplayPropertySet 'name', 'resourceGroup', 'type', 'subscriptionId', 'id' -ErrorAction SilentlyContinue


<#
.SYNOPSIS
Class of Az module compatible Azure object.
#>
class AzResource {
    [string]$ResourceId
    [string]$Id
    [string]$Kind
    [string]$Location
    [string]$ResourceName
    [string]$Name
    [string]$ResourceGroupName
    [string]$ResourceType
    [string]$Type
    [guid]$SubscriptionId
    [string]$SubscriptionName
    [psobject]$Sku
    [psobject]$Properties
    [psobject]$Tags
    [psobject]$Identity

    # constructors
    AzResource () { }

    AzResource ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 9 -and $idSplit[1] -eq 'subscriptions' -and $idSplit[3] -eq 'resourceGroups' -and $idSplit[5] -eq 'providers') {
                $this.ResourceId = $id
                $this.Id = $this.ResourceId
                $this.ResourceName = $idSplit[8]
                $this.Name = $this.ResourceName
                $this.ResourceGroupName = $idSplit[4]
                $this.ResourceType = "$($idSplit[6])/$($idSplit[7])"
                $this.Type = $this.ResourceType
                $this.SubscriptionId = $idSplit[2]
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzResource ([guid]$subscriptionId, [string]$resourceGroupName, [string]$resourceType, [string]$name) {
        $this.ResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/$resourceType/$name"
        $this.Id = $this.ResourceId
        $this.ResourceName = $name
        $this.Name = $this.ResourceName
        $this.ResourceGroupName = $resourceGroupName
        $this.ResourceType = $resourceType
        $this.Type = $this.ResourceType
        $this.SubscriptionId = $subscriptionId
    }

    AzResource ([AzGraphResource]$obj) {
        $this.ResourceId = $obj.id
        $this.Id = $this.ResourceId
        $this.Kind = $obj.kind
        $this.Location = $obj.location
        $this.ResourceName = $obj.name
        $this.Name = $this.ResourceName
        $this.ResourceGroupName = $obj.resourceGroup
        $this.ResourceType = $obj.type
        $this.Type = $this.ResourceType
        $this.SubscriptionId = $obj.subscriptionId
        $this.SubscriptionName = $obj.subscription
        $this.Sku = $obj.sku
        $this.Properties = $obj.properties
        $this.Tags = $obj.tags
        $this.Identity = $obj.identity
    }

    AzResource ([AzResource]$obj) {
        $this.ResourceId = $obj.ResourceId
        $this.Id = $this.ResourceId
        $this.Kind = $obj.Kind
        $this.Location = $obj.Location
        $this.ResourceName = $obj.ResourceName
        $this.Name = $this.ResourceName
        $this.ResourceGroupName = $obj.ResourceGroupName
        $this.ResourceType = $obj.ResourceType
        $this.Type = $this.ResourceType
        $this.SubscriptionId = $obj.SubscriptionId
        $this.SubscriptionName = $obj.SubscriptionName
        $this.Sku = $obj.Sku
        $this.Properties = $obj.Properties
        $this.Tags = $obj.Tags
        $this.Identity = $obj.Identity
    }

    [AzResource] GetSubscriptionName () {
        $this.SubscriptionName = (Get-AzGraphSubscription -SubscriptionId $this.SubscriptionId).name

        return [AzResource]::new($this)
    }

    [string] ToString() {
        return $this.ResourceId
    }
}
# Specify AzResource DefaultDisplayPropertySet
Update-TypeData -TypeName 'AzResource' -DefaultDisplayPropertySet 'Name', 'ResourceGroupName', 'ResourceType', 'SubscriptionId', 'ResourceId' -ErrorAction SilentlyContinue
