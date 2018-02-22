function Connect-ConnectWiseManage {
    <#
    .SYNOPSIS
    This will create the connection to the manage server.
    
    .DESCRIPTION
    This will create a global variable that contains all needed connection and autherisiztion information.
    All other commands from the module will call this vatiable to get connection information.
    
    .PARAMETER Server
    The URL of your ConnectWise Mange server.
    Example: manage.mydomain.com
    
    .PARAMETER Company
    The login company that you are prompted with at logon.
    
    .PARAMETER MemberID
    The member that you are impersonating
    
    .PARAMETER IntegratorUser
    The integrator username
    docs: Member Impersonation
    
    .PARAMETER IntegratorPass
    The integrator password
    docs: Member Impersonation
    
    .PARAMETER pubkey
    Public API key created by a user
    docs: My Account
    
    .PARAMETER privatekey
    Private API key created by a user
    docs: My Account
    
    .EXAMPLE
    $Connection = @{
        Server = $Server
        IntegratorUser = $IntegratorUser
        IntegratorPass = $IntegratorPass
        Company = $Company 
        MemberID = $MemberID
    }
    Connect-ConnectWiseManage @Connection
    
    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/Manage/Developer_Guide#Authentication
    #>

    param(
        [Parameter(Mandatory=$true)]
        $Server,
        [Parameter(Mandatory=$true)]
        $Company,
        $MemberID,
        $IntegratorUser,
        $IntegratorPass,        
        $pubkey,
        $privatekey
    )
    
    # Check to make sure one of the full auth pairs is passed.
    ##TODO
    #if((!$MemberID -or !$IntegratorUser -or !$IntegratorPass) -and (!$pubkey -or !$privatekey)){}
    
    # If connecting with a public/private API key
    if($pubkey -and $privatekey){
        $Authstring  = $Company + '+' + $pubkey + ':' + $privatekey
        $encodedAuth  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));
        $Headers=@{
            Authorization = "Basic $encodedAuth"
            'Cache-Control'= 'no-cache'
            Accept = 'application/vnd.connectwise.com+json; version=3.0.0'
        }             
    }

    # If connecting with an integrator account and memberid
    if($IntegratorUser -and $IntegratorPass){
        $URL = "https://$($Server)/v4_6_release/apis/3.0/system/members/$($MemberID)/tokens"
        # Create auth header to get auth header ;P
        $Authstring  = $Company + '+' + $IntegratorUser + ':' + $IntegratorPass
        $encodedAuth  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));
        $Headers = @{
            Authorization = "Basic $encodedAuth"
            'x-cw-usertype' = "integrator"
            'Cache-Control'= 'no-cache'
            Accept = 'application/vnd.connectwise.com+json; version=3.0.0'
        }
        $Body = @{
            memberIdentifier = $MemberID
        }
    
        # Get an auth token
        $Result = Invoke-RestMethod -Method Post -Uri $URL -Headers $Headers -Body $Body -ContentType application/json

        # Create auth header
        $Authstring  = $Company + '+' + $Result.publicKey + ':' + $Result.privateKey
        $encodedAuth  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));
        $Headers=@{
            Authorization = "Basic $encodedAuth"
           'Cache-Control'= 'no-cache'
           Accept = 'application/vnd.connectwise.com+json; version=3.0.0'
        }    
    }

    # Creat the Server Connection object    
    $global:CWServerConnection = @{
        Server = $Server
        Headers = $Headers
    }
    
}
function Get-CWConfig {
    <#
    .SYNOPSIS
    This function will allow you to search for Manage configurations.

    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)

    .EXAMPLE
    Get-CWConfig -Condition "name=`"$ConfigName`""
    This will return all the configs with a name that matches $ConfigName

    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Company&e=Configurations&o=GET
    #>

    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize      
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/company/configurations"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}
    
    $Config = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Config
}
function Get-CWAddition {
    <#
    .SYNOPSIS
    This function will list additions to a Manage agreement.
        
    .PARAMETER AgreementID
    The agreement ID of the agreement the addition belongs to.

    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)

    
    .EXAMPLE
    Get-CWAddition -AgreementID $Agreement.id | where {$_.product.identifier -eq $AdditionName}
    
    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Finance&e=AgreementAdditions&o=GET
    #>
    param(
        $AgreementID,
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/finance/agreements/$AgreementID/additions"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}

    
    $Addition = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Addition
}
function Get-ChargeCode{
    <#
    .SYNOPSIS
    Gets a list of charge codes
    
    .EXAMPLE
    Get-ChargeCode
    
    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    #>
    param(
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/system/reports/ChargeCode"
    
    $ChargeCode = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    
    # Clean the returned object up
    $Item = @{}
    For ($a=0; $a -lt $ChargeCode.row_values.count; $a++){
        For ($b=0; $b -lt $ChargeCode.column_definitions.count; $b++){
            $Property += @{$(($ChargeCode.column_definitions[$b] | Get-Member -MemberType NoteProperty).Name) = $($ChargeCode.row_values[$a][$b])}
        }
        $Item.add($Property.Description,$Property)
        Remove-Variable Property -ErrorAction SilentlyContinue
    }
    return $Item

}
function Update-CWAddition {
    <#
    .SYNOPSIS
    This will update an addition to an agreement.
        
    .PARAMETER AgreementID
    The ID of the agreement that you are updating. Get-CWAgreement

    .PARAMETER AdditionID
    The ID of the adition that you are updating. Get-CWAddition

    .PARAMETER Operation
    What you are doing with the value. 
    replace

    .PARAMETER Path
    The value that you want to perform the operation on.

    .PARAMETER Value
    The value of that operation.

    .EXAMPLE
    $UpdateParam = @{
        AgreementID = $Agreement.id
        AdditionID = $Addition.id
        Operation = 'replace'
        Path = 'quantity'
        Value = $UmbrellaCount
    }
    Update-CWAddition @UpdateParam

    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017
    
    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Finance&e=AgreementAdditions&o=UPDATE
    #>
    param(
        [Parameter(Mandatory=$true)]
        $AgreementID,
        [Parameter(Mandatory=$true)]
        $AdditionID,
        [Parameter(Mandatory=$true)]
        $Operation,
        [Parameter(Mandatory=$true)]
        $Path,
        [Parameter(Mandatory=$true)]
        $Value
    )

    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $Body =@(
        @{            
            op = $Operation
            path = $Path
            value = $Value      
        }
    )

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/finance/agreements/$AgreementID/additions/$AdditionID"
    $Addition = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Patch -Body $(ConvertTo-Json $Body) -ContentType application/json
    
    return $Addition
}
function Get-CWAgreement {
    <#
    .SYNOPSIS
    This function will list agreements based on conditions.
        
    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)
   
    .EXAMPLE
    $Condition = "company/identifier=`"$($Config.company.identifier)`" AND parentagreementid = null AND cancelledFlag = False AND endDate > [$(Get-Date -format yyyy-MM-ddTHH:mm:sZ)]"
    Get-CWAgreement -Condition $Condition

    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Finance&e=Agreements&o=GET    
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/finance/agreements"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}

    
    $Agreement = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Agreement
}
function Get-CWCompany {
    <#
    .SYNOPSIS
    This function will list companies based on conditions.
        
    .PARAMETER Condition
    The search cryteria for your company.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"
   
    .EXAMPLE
    $Condition = "identifier=`"$($Config.company.identifier)`" and type/id IN (1,42,43,57)"
    Get-CWAgreement -Condition $Condition

    .NOTES
    Author: Chris Taylor
    Date: 8/14/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Company&e=Companies&o=GET  
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/company/companies"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}
    
    $Agreement = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Agreement
}
function Get-CWTicket {
    param(
        $TicketID
    )
        if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }
    $Condition = "id = $TicketID"
    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/service/tickets?conditions=$Condition"

    try{
        $Ticket = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
        return $Ticket
    }
    catch{
        Write-Output "There was an error: $($Error[0])"
    }    
}
function Remove-CWAddition {
    <#
    .SYNOPSIS
    This function will remove additions from a Manage agreement.
        
    .PARAMETER AgreementID
    The AgreementID of the agreement the addition belongs to.

    .PARAMETER AdditionID
    The addition ID that you want to delete.

    
    .EXAMPLE
    Remove-CWAddition -AdditionID $Addition.id -AgreementID $AgreementID.id
    
    .NOTES
    Author: Chris Taylor
    Date: 8/16/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Finance&e=AgreementAdditions&o=DELETE
    #>
    param(
        $AgreementID,
        $AdditionID
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/finance/agreements/$AgreementID/additions/$AdditionID"

    
    $Addition = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Delete
    return $Addition
}
function Get-CWTicketNote {
    param(
        $TicketID,
        $Conditions,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }
    
    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/service/tickets/$TicketID/notes"
    if($Conditions){
        $URI = "&conditions= $Conditions"
    }
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($URI -notlike "*\?*" -and $URI -like "*&*") {
        $URI = $URI -replace '(.*?)&(.*)', '$1?$2'
    }    

    try{
        $Ticket = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
        return $Ticket
    }
    catch{
        Write-Output "There was an error: $($Error[0])"
    }    
}
function Remove-CWCompany {
    <#
    .SYNOPSIS
    This function will remove a company from Manage.
        
    .PARAMETER CompanyID
    The ID of the company that you want to delete.
   
    .EXAMPLE
    Remove-CWAgreement -CompanyID 123

    .NOTES
    Author: Chris Taylor
    Date: 8/162017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Company&e=Companies&o=DELETE  
    #>
    param(
        $CompanyID
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/company/companies/$CompanyID"
    try{
        $Agreement = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Delete
        return $Agreement
    }
    catch{
        Write-Output "There was an error: $Error[0]"
    }    
}
function Find-CWTicket {
    param(
        $page,
        $pageSize,
        $conditions,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $Body = @{}
    switch ($PSBoundParameters.Keys) {
        'conditions'               { $Body.conditions               = $conditions               }
        'orderBy'                  { $Body.orderBy                  = $orderBy                  }
        'childconditions'          { $Body.childconditions          = $childconditions          }
        'customfieldconditions'    { $Body.customfieldconditions    = $customfieldconditions    }                       
    }
    $Body = $($Body | ConvertTo-Json)

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/service/tickets/search"
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($URI -notlike "*\?*" -and $URI -like "*&*") {
        $URI = $URI -replace '(.*?)&(.*)', '$1?$2'
    }

    try{
        $Ticket = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Post -ContentType 'application/json' -Body $Body
        return $Ticket
    }
    catch{
        Write-Output "There was an error: $($Error[0])"
    }    
}
function List-CWProductTypes {
    <#
    .SYNOPSIS
    This function will list product types.
    
    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)

    .EXAMPLE
    List-CWProductTypes
        Will list all product types.
    
    .NOTES
    Author: Chris Taylor
    Date: 2/20/2018

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Procurement&e=ProductTypes&o=GET
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/procurement/types"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}

    
    $Addition = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Addition
}
function Get-CWProductComponent {
    <#
    .SYNOPSIS
    This function will list a products components.
    
    ,PARAMETER ID
    The ID of the product that you want to get the components of.

    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)

    .EXAMPLE
    Get-CWProductComponent -ID 555
        Will list all product components for product 555.
    
    .NOTES
    Author: Chris Taylor
    Date: 2/20/2018

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Procurement&e=ProductComponents&o=GET    
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$ID,
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/procurement/products/$($ID)/components"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}

    
    $Component = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Component
}
function List-CWProducts {
    <#
    .SYNOPSIS
    This function will list all CW products.
    
    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)

    .EXAMPLE
    List-CWProducts
        Will list all products.
    
    .NOTES
    Author: Chris Taylor
    Date: 2/20/2018

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Procurement&e=ProductsItem&o=GET
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/procurement/products"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}

    
    $Product = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Product
}
function List-CWCatalogs {
    <#
    .SYNOPSIS
    This function will list the product catalogs.
    
    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)

    .EXAMPLE
    Get-CWCatalog
        Will list all catalogs.
    
    .NOTES
    Author: Chris Taylor
    Date: 2/20/2018

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Procurement&e=CatalogsItem&o=GET
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/procurement/catalog"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}

    
    $Catalog = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Catalog
}
function List-CWSubCategories {
    <#
    .SYNOPSIS
    This function will list the product sub categoris.
    
    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)

    .EXAMPLE
    List-CWSubCategories
        Will list all sub categories.
    
    .NOTES
    Author: Chris Taylor
    Date: 2/20/2018

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Procurement&e=SubCategories&o=GET
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/procurement/subcategories"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}
    
    $Catalog = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Catalog
}
function List-CWTypes {
    <#
    .SYNOPSIS
    This function will list the product types.
    
    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)

    .EXAMPLE
    List-CWTypes
        Will list all product types.
    
    .NOTES
    Author: Chris Taylor
    Date: 2/20/2018

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Procurement&e=ProductTypes&o=GET
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/procurement/subcategories"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}
    
    $Catalog = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Catalog
}
function New-CWCatalog {
    <#
    .SYNOPSIS
    This function will create a new catalog.

    .EXAMPLE
    New-CWCatalog
        Create a new catalogs.
    
    .NOTES
    Author: Chris Taylor
    Date: 2/20/2018

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Procurement&e=CatalogsItem&o=CREATE    
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,60)]
        [string]$identifier,
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,50)]
        [string]$description,
        [bool]$inactiveFlag,
        [Parameter(Mandatory=$true)]
        $subcategory,
        [Parameter(Mandatory=$true)]
        $type,
        [int]$productClass,
        [bool]$serializedFlag,
        [bool]$serializedCostFlag,
        [bool]$phaseProductFlag,
        $unitOfMeasure,
        [int]$minStockLevel,
        [number]$price,
        [number]$cost,
        [int]$priceAttribute,
        [bool]$taxableFlag,
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,6000)]
        [string]$customerDescription,
        $manufacturer,
        [ValidateLength(1,50)]
        [string]$manufacturerPartNumber,
        $vendor,
        [ValidateLength(1,50)]
        [string]$vendorSku,
        [string]$notes,
        [ValidateLength(1,50)]
        [string]$integrationXRef,
        [string]$dateEntered,
        $category,
        $_info,
        $customFields
    )
    # Check for connection
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    #validate subcategory
    if(!$SubCategory.id){
        Write-Warning "Invalid SubCategory, get object from List-CWSubCategory"
        break
    }
    if(List-CWSubCategories -Condition "id=$($SubCategory.id)") {
        Write-Output "Valid"
    }
    else {
        Write-Warning "$($SubCategory.id), is an invalid Sub Category id."
        break
    }
    #validate type
    if(!$Type.id){
        Write-Warning "Invalid type, get object from List-CWTypes"
        break
    }
    if(List-CWTypes -Condition "id=$($Type.id)") {
        Write-Output "Valid"
    }
    else {
        Write-Warning "$($Type.id), is an invalid Type id."
        break
    }

    #Build body
    $Body = @{
        CatalogItem = @{
            'identifier' = $identifier
            'description' = $description
            'subcategory' = $subcategory
            'type' = $type
            'customerDescription' = $customerDescription
        }
    }
    $Body = $Body | ConvertTo-Json -Depth 10
        
    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/procurement/catalog"
    
    $Catalog = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Post -ContentType application/json -Body $Body
    return $Catalog
}
function List-CWContacts {
    <#
    .SYNOPSIS
    This function will list contacts.
    
    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Choose which field to sort the results by

    .PARAMETER childconditions
    Allows searching arrays on endpoints that list childConditions under parameters

    .PARAMETER customfieldconditions
    Allows searching custom fields when customFieldConditions is listed in the parameters

    .PARAMETER page
    Used in pagination to cycle through results

    .PARAMETER pageSize
    Number of results returned per page (Defaults to 25)

    .EXAMPLE
    List-CWContacts -Condition 'firstName = "Chris"'
    Will list all users with the first name of Chris.
    
    .NOTES
    Author: Chris Taylor
    Date: 2/20/2018

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Company&e=Contacts&o=GET
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/company/contacts"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}
    
    $Contact = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Contact
}
function New-CWContact {
    <#
    .SYNOPSIS
    This function will create a new contact.

    .EXAMPLE
    New-CWContact -firstName 'Chris' -lastName 'Taylor' -company @{id = $Company.id}
        Create a new contact.
    
    .NOTES
    Author: Chris Taylor
    Date: 2/20/2018

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Company&e=Contacts&o=CREATE    
    #>
    param(
        [int]$id,
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,30)]
        [string]$firstName,
        [ValidateLength(1,30)]
        [string]$lastName,
        $type,
        $company,
        $site,
        [ValidateLength(1,50)]
        [string]$addressLine1,
        [ValidateLength(1,50)]
        [string]$addressLine2,
        [ValidateLength(1,50)]
        [string]$city,
        [ValidateLength(1,50)]
        [string]$state,
        [ValidateLength(1,12)]
        [string]$zip,
        [ValidateLength(1,50)]
        [string]$country,
        $relationship,
        $department,
        [bool]$inactiveFlag,
        [int]$defaultMergeContactId,
        [ValidateLength(1,184)]
        [string]$securityIdentifier,
        [int]$managerContactId,
        [int]$assistantContactId,
        [ValidateLength(1,100)]
        [string]$title,
        [ValidateLength(1,50)]
        [string]$school,
        [ValidateLength(1,30)]
        [string]$nickName,
        [bool]$marriedFlag,
        [bool]$childrenFlag,
        [ValidateLength(1,30)]
        [string]$significantOther,
        [ValidateLength(1,15)]
        [string]$portalPassword,
        [int]$portalSecurityLevel,
        [bool]$disablePortalLoginFlag,
        [bool]$unsubscribeFlag,
        $gender,
        [string]$birthDay,
        [string]$anniversary,
        $presence,
        [GUID]$mobileGuid,
        [string]$facebookUrl,
        [string]$twitterUrl,
        [string]$linkedInUrl,
        [bool]$defaultBillingFlag,
        [bool]$defaultFlag,
        $communicationItems,
        $_info,
        $customFields
    )
    # Check for connection
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    #Build body
    $Body = @{
            firstName = $firstName
            lastName = $lastName
            company = $company
    }
    $Body = ConvertTo-Json $Body -Depth 10 
        
    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/company/contacts"
    
    $Contact = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Post -ContentType application/json -Body $Body
    return $Contact
}
function Update-CWCompany {
    <#
    .SYNOPSIS
    This will update a company.
        
    .PARAMETER CompanyID
    The ID of the company that you are updating. List-CWCompanies

    .PARAMETER Operation
    What you are doing with the value. 
    replace

    .PARAMETER Path
    The value that you want to perform the operation on.

    .PARAMETER Value
    The value of that operation.

    .EXAMPLE
    $UpdateParam = @{
        CompanyID = $Company.id
        Operation = 'replace'
        Path = 'name'
        Value = $NewName
    }
    Update-CWCompany @UpdateParam

    .NOTES
    Author: Chris Taylor
    Date: 2/21/2018
    
    .LINK
    http://labtechconsulting.com
    https://service.itnow.net/v4_6_release/services/apitools/apidocumentation/?a=Company&e=Companies&o=UPDATE
    #>
    param(
        [Parameter(Mandatory=$true)]
        $CompanyID,
        [Parameter(Mandatory=$true)]
        $Operation,
        [Parameter(Mandatory=$true)]
        $Path,
        [Parameter(Mandatory=$true)]
        $Value
    )

    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $Body =@(
        @{            
            op = $Operation
            path = $Path
            value = $Value      
        }
    )

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/company/companies/$CompanyID"
    $Addition = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Patch -Body $(ConvertTo-Json $Body) -ContentType application/json
    
    return $Addition
}