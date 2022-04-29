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

Connect-MgGraph -Scopes User.ReadBasic.All, User.Read.All, GroupMember.Read.All, Group.Read.All

function Get-MgGroupMemberRecursively {
    param(
        [Parameter(Mandatory=$true)][string]$GroupId
    )

    $MgGroupMembersSearch = Get-MgGroupMember -GroupId $GroupId -All
    foreach ($MgGroupMember in $MgGroupMembersSearch) {
        if ($MgGroupMember.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.user") {
            if ($null -ne $MgParentGroup) {$MgParentGroup = $MgParentGroup} else {$MgParentGroup = "N/A"}

            if ($MgGroup.groupTypes -eq "Unified") {
                $MgGroupType = "Microsoft 365"
                $MgMembershipGroupType = "Assigned"
            }
            elseif ($MgGroup.groupTypes -eq "DynamicMembership,Unified") {
                $MgGroupType = "Microsoft 365"
                $MgMembershipGroupType = "Dynamic"
            }
            elseif ($MgGroup.groupTypes -eq "DynamicMembership" -and $MgGroup.securityEnabled -eq $True) {
                $MgGroupType = "Security"
                $MgMembershipGroupType = "Dynamic"
            }
            elseif ("" -eq $MgGroup.groupTypes -and $MgGroup.securityEnabled -eq $True) {
                $MgGroupType = "Security"
                $MgMembershipGroupType = "Assigned"
            }
            elseif ("" -eq $MgGroup.groupTypes -and $MgGroup.securityEnabled -eq $False) {
                $MgGroupType = "Distribution"
                $MgMembershipGroupType = "Assigned"
            }

            Foreach-Object {
                $UserObj = New-Object PSObject
                $UserObj | Add-Member -MemberType NoteProperty -Name "Member displayName" -Value $MgGroupMember.AdditionalProperties["displayName"]
                $UserObj | Add-Member -MemberType NoteProperty -Name "Member userPrincipalName" -Value $MgGroupMember.AdditionalProperties["userPrincipalName"]
                $UserObj | Add-Member -MemberType NoteProperty -Name "Group displayName" -Value $MgGroup.DisplayName
                $UserObj | Add-Member -MemberType NoteProperty -Name "Group id" -Value $MgGroup.Id
                $UserObj | Add-Member -MemberType NoteProperty -Name "Group type" -Value $MgGroupType
                $UserObj | Add-Member -MemberType NoteProperty -Name "Group Membership type" -Value $MgMembershipGroupType
                $UserObj
            }
        }
        elseif ($MgGroupMember.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.group") {
            $MgGroup = Get-MgGroup -GroupId $GroupId
            Get-MgGroupMemberRecursively -GroupId $MgGroupMember.Id
        }
    }
}

$i = 0
$Output = @()
$MgGroups = Get-MgGroup -All:$true

ForEach ($MgGroup in $MgGroups) {
    $i++
    Write-Progress -Activity "Progress: [$i/$($MgGroups.Count)]" -Status "Export members for group: $($MgGroup.displayName)" -PercentComplete ($i/$MgGroups.Count*100)
    
    $Output += Get-MgGroupMemberRecursively $MgGroup.Id
}

$Output | Export-CSV .\AllGroupsMembers_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv -Delimiter ";" -NoTypeInformation -Encoding:UTF8