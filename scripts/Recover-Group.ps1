#============================================================
# Recover-Group.ps1
# - Check the group status.
# - If the group is offline, the script starts it.
#============================================================

#============================================================
# To Do
# - If there is a proxy server, need to add noproxy option.
#============================================================

#============================================================
# Set the following parameters
#------------------------------------------------------------
# clusters
# - Add cluster servers.
# - The following sample has 2 clusters.
# - If you want to add one more cluster that has server5 and
#   server6, write as below.
#$clusters = @(
#    @(
#        @("server1", "192.168.1.1", "29009", "Administrator", "Passw0rd"),
#        @("server2", "192.168.1.2", "29009", "Administrator", "Passw0rd")
#    ),
#    @(
#        @("server3", "192.168.1.3", "29009", "Administrator", "Passw0rd"),
#        @("server4", "192.168.1.4", "29009", "Administrator", "Passw0rd")
#    ),
#    @(
#        @("server5", "192.168.1.5", "29009", "Administrator", "Passw0rd"),
#        @("server6", "192.168.1.6", "29009", "Administrator", "Passw0rd")
#    )
#)
#------------------------------------------------------------
$clusters = @(
    @(
        @("server1", "192.168.1.1", "29009", "Administrator", "Passw0rd"),
        @("server2", "192.168.1.2", "29009", "Administrator", "Passw0rd")
    ),
    @(
        @("server3", "192.168.1.3", "29009", "Administrator", "Passw0rd"),
        @("server4", "192.168.1.4", "29009", "Administrator", "Passw0rd")
    )
)

#------------------------------------------------------------
# groups
# - Add failover group in the clusters.
# - The following sample has 2 groups.
# - If you want to add one more group, write as below.
#$groups = @(
#    @("failover1"),
#    @("failover2"),
#    @("failover3")
#)
#------------------------------------------------------------
$groups = @(
    "failover1",
    "failover2"
)
#============================================================


#============================================================
# You don't need to change the following lines.
#============================================================
# Get the current hostname.
$hostname = hostname

# Find my server in the clusters matrix.
$clusterid = -1
Write-Debug $clusters.Length
for ($i = 0; $i -lt $clusters.Length; $i++)
{
    Write-Debug $clusters[$i].Length
    for ($j = 0; $j -lt $clusters[$i].Length; $j++)
    {
        Write-Debug $clusters[$i][$j][0]
        if ($clusters[$i][$j][0] -eq $hostname)
        {
            $clusterid = $i
            $serverid = $j
            Write-Output "$hostname is in cluster ID: $clusterid."
            Write-Output "$hostname is server ID: $serverid."
            break;
        }
    }
    if ($clusterid -ne -1)
    {
        break;
    }
}
Write-Debug $clusterid
if ($clusterid -eq -1)
{
    Write-Output "Cannot find the server in the cluster matrix."
    # FIXME: I need to add clplogcmd to show some message.
    exit 1
}

# Check the group status and recover it.
Write-Debug $groups.Length
for ($i = 0; $i -lt $groups.Length; $i++)
{
    Write-Debug $groups[$i]

    # running
    # 0: Offline
    # 1: Online
    $running = 0

    # Get the group status from my API server.
    $user = $clusters[$clusterid][$serverid][3]
    $pass = $clusters[$clusterid][$serverid][4]
    $uri = "http://" + $clusters[$clusterid][$serverid][1] + ":" + $clusters[$clusterid][$serverid][2] + "/api/v1/groups/" + $groups[$i]
    Write-Output $user
    Write-Debug $pass
    Write-Output $uri
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
    $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
    Write-Output $ret.groups.status
    if ($ret.groups.status -eq "Online")
    {
        $group = $groups[$i]
        $current = $ret.groups.current
        Write-Output "$group is running on $current."
        $running = 1
    }
    # FIXME
    # - I need to consider the other status (pending, failure)

    # Get the group status from API server on the other clusters.
    if ($running -eq 0)
    {
        for ($j = 0; $j -lt $clusters.Length; $j++)
        {
            if ($j -eq $clusterid)
            {
                # Do nothing
            }
            else
            {
                for ($k = 0; $k -lt $clusters[$k].Length; $k++)
                {
                    Write-Output $clusters[$j][$k][0]
                    $user = $clusters[$j][$k][3]
                    $pass = $clusters[$j][$k][4]
                    $uri = "http://" + $clusters[$j][$k][1] + ":" + $clusters[$j][$k][2] + "/api/v1/groups/" + $groups[$i]
                    Write-Output $user
                    Write-Debug $pass
                    Write-Output $uri
                    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
                    $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
                    Write-Output $ret
                    Write-Output $ret.groups.status
                    if ($ret.groups.status -eq "Online")
                    {
                        $group = $groups[$i]
                        $current = $ret.groups.current
                        Write-Output "$group is running on $current."
                        $running = 1
                        break;
                    }
                }
                # FIXME
                # - Need to consider the other status (pending, failure)
            }        
        }
        # FIXME
        # - Need to add some log? 
        #   - e.g., failover1 is not running on any server.
    }

    # Recover the group
    if ($running -eq 0)
    {
        $user = $clusters[$clusterid][$serverid][3]
        $pass = $clusters[$clusterid][$serverid][4]
        $uri = "http://" + $clusters[$clusterid][$serverid][1] + ":" + $clusters[$clusterid][$serverid][2] + "/api/v1/groups/" + $groups[$i] + "/start"
        $body = [System.Text.Encoding]::UTF8.GetBytes("{ `"target`" : `"$hostname`" }")
        Write-Output $user
        Write-Debug $pass
        Write-Output $uri
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
        Invoke-RestMethod -Method Post -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri -Body $body
        # FIXME
        # - Need to add error handling

        # Check the group status
        $uri = "http://" + $clusters[$clusterid][$serverid][1] + ":" + $clusters[$clusterid][$serverid][2] + "/api/v1/groups/" + $groups[$i]
        $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
        Write-Output "$groups[$i] : $ret.groups.status"
    }
}