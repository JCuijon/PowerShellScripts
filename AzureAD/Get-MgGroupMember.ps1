Connect-MgGraph -Scopes User.ReadBasic.All, User.Read.All, GroupMember.Read.All, Group.Read.All, Device.Read.All

function Get-MgGroupMembers {
    param(
        [Parameter(Mandatory=$true)][string]$GroupId
    )

    $MgGroup = Get-MgGroup -GroupId $GroupId
    $MgGroupMembers = Get-MgGroupMember -GroupId $MgGroup.Id -All
    foreach ($MgGroupMember in $MgGroupMembers) {
        if ($MgGroupMember.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.user") {
            $Type = "User"
        }
        elseif ($MgGroupMember.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.group") {
            $Type = "Group"
        }
        elseif ($MgGroupMember.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.device") {
            $Type = "Device"
        }

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

        $UserObj = New-Object PSObject
        $UserObj | Add-Member -MemberType NoteProperty -Name "Member displayName" -Value $MgGroupMember.AdditionalProperties["displayName"]
        $UserObj | Add-Member -MemberType NoteProperty -Name "Member userPrincipalName" -Value $MgGroupMember.AdditionalProperties["userPrincipalName"]
        $UserObj | Add-Member -MemberType NoteProperty -Name "Member id" -Value $MgGroupMember.Id
        $UserObj | Add-Member -MemberType NoteProperty -Name "Member type" -Value $Type
        $UserObj | Add-Member -MemberType NoteProperty -Name "Group displayName" -Value $MgGroup.displayName
        $UserObj | Add-Member -MemberType NoteProperty -Name "Group id" -Value $MgGroup.Id
        $UserObj | Add-Member -MemberType NoteProperty -Name "Group type" -Value $MgGroupType
        $UserObj | Add-Member -MemberType NoteProperty -Name "Group Membership type" -Value $MgMembershipGroupType
        $UserObj
    }
}

$i = 0
$Output = @()
$MgGroups = Get-MgGroup -All:$true

ForEach ($MgGroup in $MgGroups) {
    $i++
    Write-Progress -Activity "Progress: [$i/$($MgGroups.Count)]" -Status "Export members for group: $($MgGroup.displayName)" -PercentComplete ($i/$MgGroups.Count*100)
    
    $Output += Get-MgGroupMembers $MgGroup.Id
}

$Output | Export-CSV .\AllGroupsMembers_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv -Delimiter ";" -NoTypeInformation -Encoding:UTF8