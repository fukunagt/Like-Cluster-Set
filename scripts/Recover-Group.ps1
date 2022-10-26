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
# - The first cluster number is 0 and the second one is 1.
#------------------------------------------------------------
$clusters = @(
    @(
        @("server1", "192.168.1.1", "29009", "Administrator", "password"),
        @("server2", "192.168.1.2", "29009", "Administrator", "password")
    ),
    @(
        @("server3", "192.168.1.3", "29009", "Administrator", "password"),
        @("server4", "192.168.1.4", "29009", "Administrator", "password")
    )
)
#------------------------------------------------------------
# groups
# - Add failover group in the clusters.
#------------------------------------------------------------
$groups = @(
    @("failover1")
)
#============================================================


#============================================================
# You don't need to change the following lines.
#============================================================

# FIXME:
# This is for test. You need to get the actual server name.
$hostname = "server1"

# Find my server in the clusters matrix.
$clusternumber = -1
Write-Debug $clusters.Length
for ($i = 0; $i -lt $clusters.Length; $i++)
{
    Write-Debug $clusters[$i].Length
    for ($j = 0; $j -lt $clusters[$i].Length; $j++)
    {
        Write-Debug $clusters[$i][$j][0]
        if ($clusters[$i][$j][0] -eq $hostname)
        {
            $clusternumber = $i
            Write-Output "$hostname is in cluster $clusternumber."
            break;
        }
    }
    if ($clusternumber -ne -1)
    {
        break;
    }
}
Write-Debug $clusternumber
if ($clusternumber -eq -1)
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
    
    # FIXME
    # I need to add scripts to do followings.
    # - Run curl command to check the status.
    # - Run curl command to start the group.
}