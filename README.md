# Like-Cluster-Set
- This is an experimental script to control a group like Cluster Set of Windows Server Failover Cluster.

## Configuration
```
  +---------------------------------+
  | cluster #0                      |
  |     +-------------------------+ |
  |     | Name: server1           | |
  | +---+ IP address: 192.168.1.1 | |
  | |   | OS: Windows Server 2019 | |
  | |   |                         | |
  | |   | EXPRESSCLUSTER X 5.0    | |
  | |   | - Custom monitor        | |
+---+   |   - genw.bat            | |
| | |   |     - Recover-Group.ps1 | |
| | |   +-------------------------+ |
| | |                               |
| | |   +-------------------------+ |
| | |   | Name: server2           | |
| | +---+ IP address: 192.168.1.2 | |
| |     | OS: Windows Server 2019 | |
| |     |                         | |
| |     | EXPRESSCLUSTER X 5.0    | |
| |     | - Custom monitor        | |
| |     |   - genw.bat            | |
| |     |     - Recover-Group.ps1 | |
| |     +-------------------------+ |
| +---------------------------------+
|
| +---------------------------------+
| | cluster #1                      |
| |     +-------------------------+ |
| |     | Name: server3           | |
| | +---+ IP address: 192.168.1.3 | |
| | |   | OS: Windows Server 2019 | |
| | |   |                         | |
| | |   | EXPRESSCLUSTER X 5.0    | |
| | |   | - Custom monitor        | |
+---+   |   - genw.bat            | |
  | |   |     - Recover-Group.ps1 | |
  | |   +-------------------------+ |
  | |                               |
  | |   +-------------------------+ |
  | |   | Name: server4           | |
  | +---+ IP address: 192.168.1.4 | |
  |     | OS: Windows Server 2019 | |
  |     |                         | |
  |     | EXPRESSCLUSTER X 5.0    | |
  |     | - Custom monitor        | |
  |     |   - genw.bat            | |
  |     |     - Recover-Group.ps1 | |
  |     +-------------------------+ |
  +---------------------------------+
```
- Recover-Group.ps1 uses EXPRESSCLUSTER's RESTful API to control failover groups.
  - Check if failover groups are running on cluster servers.
  - If a failover group does not run on any server, Recover-Group.ps1 will start the failover group on some server.
