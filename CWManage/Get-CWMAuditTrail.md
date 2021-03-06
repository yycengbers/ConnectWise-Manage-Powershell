# Get-CWMAuditTrail
## SYNOPSIS
This function will get the audit trail of an item in ConnectWise.
## SYNTAX
```powershell
Get-CWMAuditTrail [-Type] <Object> [-ID] <String> [[-deviceIdentifier] <Object>] [[-childconditions] <String>] [[-page] <Int32>] [[-pageSize] <Int32>] [<CommonParameters>]
```
## PARAMETERS
### -Type &lt;Object&gt;
Ticket, ProductCatalog, Configuration, PurchaseOrder, Expense
```
Required                    true
Position                    1
Default value
Accept pipeline input       false
Accept wildcard characters  false
```
### -ID &lt;String&gt;
The id the the item you want the audit trail of.
```
Required                    true
Position                    2
Default value
Accept pipeline input       false
Accept wildcard characters  false
```
### -deviceIdentifier &lt;Object&gt;
?
```
Required                    false
Position                    3
Default value
Accept pipeline input       false
Accept wildcard characters  false
```
### -childconditions &lt;String&gt;

```
Required                    false
Position                    4
Default value
Accept pipeline input       false
Accept wildcard characters  false
```
### -page &lt;Int32&gt;
Used in pagination to cycle through results
```
Required                    false
Position                    5
Default value                0
Accept pipeline input       false
Accept wildcard characters  false
```
### -pageSize &lt;Int32&gt;
Number of results returned per page (Defaults to 25)
```
Required                    false
Position                    6
Default value                0
Accept pipeline input       false
Accept wildcard characters  false
```
## EXAMPLES
### EXAMPLE 1
```powershell
PS C:\>Get-CWMAuditTrail

Will return the audit trail
```

## NOTES
Author: Chris Taylor

Date: 10/29/2018



No support for forward only pagination at this time. 
## LINKS
http://labtechconsulting.com

https://developer.connectwise.com/products/manage/rest?a=System&e=AuditTrail&o=GET
