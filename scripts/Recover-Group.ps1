#============================================================
# Recover-Group.ps1
# - Check the group status.
# - If the group is offline, the script starts it.
#
# TODO
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
# - Set failover group name and priorities.
# - The following sample has 2 groups.
# - If you want to add one more group, write as below.
#$groups = @(
#    @("failover1", @("server1", "server2", "server3", "server4")),
#    @("failover2", @("server2", "server1", "server4", "server3")),
#    @("failover3", @("server3", "server4", "server1", "server2"))
#)
#------------------------------------------------------------
$groups = @(
    @("failover1", @("server1", "server2", "server3", "server4")),
    @("failover2", @("server2", "server1", "server4", "server3"))
)
#============================================================


#============================================================
# You don't need to change the following lines.
#============================================================
# Get the current hostname.
$hostname = hostname

# Find my server in the clusters matrix.
$clusterid = -1
for ($i = 0; $i -lt $clusters.Length; $i++)
{
    for ($j = 0; $j -lt $clusters[$i].Length; $j++)
    {
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
if ($clusterid -eq -1)
{
    Write-Output "Cannot find the server in the cluster matrix."
    # FIXME: I need to add clplogcmd to show some message.
    exit 1
}

# Check the group status and recover it.
for ($i = 0; $i -lt $groups.Length; $i++)
{
    # running
    # 0: Offline
    # 1: Online
    $running = 0

    $group = $groups[$i][0]

    # Get the group status from my API server.
    $user = $clusters[$clusterid][$serverid][3]
    $pass = $clusters[$clusterid][$serverid][4]
    $uri = "http://" + $clusters[$clusterid][$serverid][1] + ":" + $clusters[$clusterid][$serverid][2] + "/api/v1/groups/" + $group
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
    $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
    if ($ret.groups.status -eq "Online")
    {
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
                    $ipaddress = $clusters[$j][$k][1]
                    $port = $clusters[$j][$k][2]
                    $user = $clusters[$j][$k][3]
                    $pass = $clusters[$j][$k][4]
                    $uri = "http://" + $ipaddress + ":" + $port + "/api/v1/groups/" + $group
                    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
                    $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
                    $status = $ret.groups.status
                    if ($status -eq "Online" -or $status -eq "Online Pending" -or $status -eq "Offline Pending")
                    {
                        $current = $ret.groups.current
                        Write-Output "$group is running on $current."
                        $running = 1
                        break;
                    }
                    if ($status -eq "Online Failure")
                    {
                        # FIXME
                    }
                }
            }        
        }
        # FIXME
        # - Need to add some log? 
        #   - e.g., failover1 is not running on any server.
        Write-Output "$group is not running on any server."
    }

    # Recover the group
    # TODO: Consider priority
    if ($running -eq 0) 
    {
        for ($j = 0; $j -lt $groups[$i][1].Length; $j++)
        {
            $recover = 0
            $found = 0
            $server = $groups[$i][1][$j]
            if ($server -eq $hostname)
            {
                # My server will start the group.
                $recover = 1
                break
            }
            for ($k = 0; $k -lt $clusters.Length; $k++)
            {
                for ($l = 0; $l -lt $clusters[$k].Length; $l++)
                {
                    if ($server -eq $clusters[$k][$l][0])
                    {
                        $ipaddress = $clusters[$k][$l][1]
                        $port = $clusters[$k][$l][2]
                        $user = $clusters[$clusterid][$serverid][3]
                        $pass = $clusters[$clusterid][$serverid][4]
                        $uri = "http://" + $ipaddress + ":" + $port + "/api/v1/servers/" + $server
                        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
                        $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
                        $status = $ret.servers.status
                        if ($status -eq "Online")
                        {
                            $found = 1
                            break
                        }
                    }
                }
                if ($found -eq 1)
                {
                    Write-Output "$server is online and has higher priority."
                    break
                }
            }
            if ($found -eq 1)
            {
                # Found the server ($server) has hgiher priority.
                break
            }
        }
        if ($recover -eq 1)
        {
            Write-Output "$group starts on $hostname."
            $ipaddress = $clusters[$clusterid][$serverid][1]
            $port = $clusters[$clusterid][$serverid][2]
            $user = $clusters[$clusterid][$serverid][3]
            $pass = $clusters[$clusterid][$serverid][4]
            $uri = "http://" + $ipaddress + ":" + $port + "/api/v1/groups/" + $group + "/start"
            $body = [System.Text.Encoding]::UTF8.GetBytes("{ `"target`" : `"$hostname`" }")
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
            $ret = Invoke-RestMethod -Method Post -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri -Body $body
            # FIXME: Error handling
        }
    }
}