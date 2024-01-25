<#
    MIT License

    Copyright (c) 2022 JCuijon

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>

#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force -Confirm:$false

#Url
$FilePath = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"

#Create variable for csv
$ProdcutPlans = @()
$ProdcutPlans = Invoke-WebRequest $FilePath | ConvertFrom-Csv -Delimiter ',' | Select-Object 'Product_Display_Name','String_Id','GUID' | Sort-Object 'String_Id' | Get-Unique -AsString

#Connect to MgGraph
#Connect-MgGraph
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","Devices.Read.All"

$i = 0
$j = 0
$Output = @()

$MgUsers = Get-MgUser -Filter "UserType eq 'Member'" -All

foreach ($MgUser in $MgUsers) {
    Write-Progress -Activity "Processing user:" -Status $($MgUser.DisplayName) -PercentComplete ([Int32](([Array]::IndexOf($MgUsers, $MgUser)/($MgUsers.Count))*100)) -Id 1
    $i++

    $MgUserLicenses = Get-MgUserLicenseDetail -UserId $MgUser.UserPrincipalName
    foreach ($MgUserLicense in $MgUserLicenses) {
        $FriendlyName = (Get-Culture).TextInfo.ToTitleCase(($ProdcutPlans.Where({[string]$_.String_Id -eq $MgUserLicense.SkuPartNumber})).Product_Display_Name.ToLower())
        
        Write-Progress -Activity "Processing license:" -Status $($FriendlyName) -PercentComplete ([Int32](([Array]::IndexOf($MgUserLicenses, $MgUserLicense)/($MgUserLicenses.Count))*100)) -ParentId 1
        $j++

        $Obj = "" | Select-Object DisplayName,UserPrinciPalName,LicensePlan,FriendlyNameofLicensePlan
        $Obj.DisplayName = $MgUser.DisplayName
        $Obj.UserPrinciPalName = $MgUser.UserPrincipalName
        $Obj.LicensePlan = $MgUserLicense.SkuPartNumber
        $Obj.FriendlyNameofLicensePlan = $FriendlyName
        $Output += $Obj
    }
}

$Output | Export-Csv -Path ".\O365UserLicenseReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv" -NoTypeInformation -Delimiter ';'

Disconnect-MgGraph