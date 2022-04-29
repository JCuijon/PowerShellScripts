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

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force -Confirm:$false
Connect-ExchangeOnline
Connect-AzureAD

$i = 0
$j = 0
$Output = @()
$Mailboxes = Get-EXOMailbox -Resultsize Unlimited -Properties ExternalDirectoryObjectId -Filter {ExternalDirectoryObjectId -ne $null}

foreach ($Mailbox in $Mailboxes) {
    $i++
    Write-Progress -Activity "Gettting Mailbox permissions [$i/$($Mailboxes.Count)]" -Status "Currently Processing: Mailbox $($Mailbox.DisplayName)" -PercentComplete ($i/$Mailboxes.Count*100) -Id 0
    
    $ADUser = Get-AzureADUser -ObjectId $Mailbox.UserPrincipalName

    $Permissions = Get-MailboxPermission -Identity $Mailbox.ExternalDirectoryObjectId | Where-Object {$_.AccessRights -like "*FullAccess" -and $_.User -ne "NT AUTHORITY\SYSTEM" -and $_.User -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false -and $_.User -notlike "S-1-*"}
    foreach ($Permission in $Permissions) {
        $SID = (Get-AzureADUser -ObjectId $Permission.User).ObjectID

        $objectClass = Get-AzureADObjectByObjectId -ObjectIds $SID
        If ($objectClass.ObjectType -like 'Group') {
            $ADObject = Get-AzureADGroup -ObjectId $objectClass.ObjectId
        }
        ElseIf ($objectClass.ObjectType -like 'User') {
            $ADObject = Get-AzureADUser -ObjectId $objectClass.ObjectId
        }

        j++
        Write-Progress -Activity "Gettting Permissions [$j/$($Permissions.Count)]" -Status "Currently Processing: Permission $($ADObject.DisplayName)" -PercentComplete ($j/$Permissions.Count*100) -Id 1 -ParentId 0

        $UserObj = New-Object PSObject
        $UserObj | Add-Member NoteProperty -Name "MailboxDisplayName" -Value $Mailbox.DisplayName
        $UserObj | Add-Member NoteProperty -Name "MailboxAzureADObjectId" -Value $Mailbox.ExternalDirectoryObjectId
        $UserObj | Add-Member NoteProperty -Name "MailboxUserPrincipalName" -Value $Mailbox.UserPrincipalName
        $UserObj | Add-Member NoteProperty -Name "MailboxAlias" -Value $Mailbox.Alias
        $UserObj | Add-Member NoteProperty -Name "GrantedUserDisplayName" -Value $ADObject.DisplayName
        $UserObj | Add-Member NoteProperty -Name "GrantedUserAccountEnabled" -Value $ADObject.AccountEnabled
        $UserObj | Add-Member NoteProperty -Name "GrantedUserObjectId" -Value $ADObject.ObjectId
        $UserObj | Add-Member NoteProperty -Name "GrantedUserUPN" -Value $ADObject.UserPrincipalName
        $UserObj | Add-Member NoteProperty -Name "GrantedUser" -Value $Permission.User
        $Output += $UserObj
    }
}

$Output | Export-Csv ".\Desktop\MailboxPermissions-Mailboxes.csv" -Delimiter ";" -NoTypeInformation -Encoding:UTF8