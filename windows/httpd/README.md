# Apache HTTP Server
This is Apache HTTP Server Windows binary distribution brought to you by [mod_proxy_cluster](http://modcluster.io) community. See ```htdocs\index.html``` for more information.

The zip package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the LICENSE, COPYING, NOTICE or README files packaged in the directory ```.\licenses``` in this zip archive.

## Installation
### Prerequisites

 * powershell on your PATH
 * up-to-date Windows 2012 R2 server or newer

### Installation steps

 * Unzip the archive in an arbitrary location, although, please, keep in mind these possible limitations:
   * ```cache``` directory must not be located on NFS or Samba disk
   * beware of UAC when installing into restricted locations (e.g. ```Program Files```)
 * Open command prompt (cmd), cd into the directory where the zip archive was extracted and run:
 * ```postinstall.bat```

### Start the server
 * ```cd bin```
 * ```httpd.exe```
 * Open [https://localhost/](https://localhost/)

The aforementioned ```postinstall.bat```
 * downloads and installs [Microsoft Visual C++ Redistributable libraries](https://www.microsoft.com/en-us/download/details.aspx?id=53587) from Microsoft website
 * configures httpd's paths
 * generates *test* certificates and configures https://localhost for you

The following section is generated and it is parsed by the ```postinstall.bat``` script.
# Component versions
