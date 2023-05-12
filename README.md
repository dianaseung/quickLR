# quickLR

---

Linux Bash script to help Customer Support Engineers to quickly setup basic Liferay Tomcat bundles (non-Docker)

<img src="/media/quickLR-preview.gif" alt="Preview of quickLR script functionality" style="text-align: center;"/>

---

## About QuickEnv: Overview

### Functionality

This bash script (Linux) quickly sets up a basic Liferay Tomcat bundle and environment for Liferay Customer Support work.
Alternative to using Docker compose to setup a standard Liferay bundle

What does this script do?
1. Creates a Project folder with Project Code (i.e. CHICAGOLC)
2. Copies DXP bundle to Project
3. Puts a copy of activation xml license and portal-ext.properties to DXP bundle
4. If Fix Pack needed, places Fix Pack in patching folder, auto-installs FP and clears temp folders. (xdg-open if fail) SP and Updates don't need patching.
4. Creates a MySQL database
5. Updates portal-ext.properties with newly created MySQL DB
6. Auto starts Tomcat bundle through ./catalina.sh run

### Folder Structure

<details>
<summary>Folder Structure</summary>
<br>

    LIFERAY
    ├── DXP                                     # Parent folder for all clean DXP Bundle
    │   ├── 7.4                                 # Liferay Version
    │   │   ├── liferay-dxp-tomcat-7.4.13.u5    # (What is extracted from 'Bundled with Tomcat' .tar.gz downloads from HC with 'Extract Here' option)
    │   │   │   ├── liferay-dxp-7.4.13.u5       # 
    │   │   │   │   ├── data                    # 
    │   │   │   │   ├── deploy                  # 
    │   │   │   │   ├── osgi                    # 
    │   │   │   │   ├── portal-ext.properties   # 
    │   │   │   │   ├── ...                     # 
    │   │   ├── liferay-dxp-tomcat-7.4.13.u35   # 
    │   │   │   ├── liferay-dxp-7.4.13.u35      # 
    │   ├── 7.3                                 # 
    │   ├── 7.2                                 # 
    │   ├── 7.1                                 # 
    │   ├── 7.0                                 # 
    │   ├── License                             # Where licenses are stored
    ├── PROJECT                                 # Parent folder for all Projects
    │   ├── CHICAGOLCS                          # Project Code 
    │   │   ├── liferay-dxp-7.4.13.u5           # 
    │   │   │   ├── data                        # 
    │   │   │   ├── deploy                      # 
    │   │   │   ├── osgi                        # 
    │   │   │   ├── portal-ext.properties       # 
    │   │   │   ├── ...                         # 
    │   │   ├── liferay-dxp-7.4.13.u30          # 
    │   │   │   ├── data                        # 
    │   │   │   ├── deploy                      # 
    │   │   │   ├── osgi                        # 
    │   │   │   ├── portal-ext.properties       # 
    │   │   │   ├── ...                         # 
    │   ├── LRWWW                               # Project Code
    │   ├── ...                                 # 
    └── ...
</details>

<h5 align="center">
Sample DXP directory ($LRDIR)
<img src="/media/dir-dxp-sample.png" alt="Sample DXP folder" />
</h5>

<h5 align="center">
Sample Project directory ($PROJECTDIR)
<img src="/media/dir-project-sample.png" alt="Sample Project folder" />
</h5>

---

## USAGE AND SETUP

## quickLR Installation / Setup
1. Create Folder Structure
    - Download [/sample/Liferay.zip](/sample/Liferay.zip) and extract to desired destination to quickly setup a Folder Structure like above.
2. Setup Liferay Licenses
    - Download activation xml licenses for DXP 7.0.10, 7.1.10, 7.2.10, 7.3.10 and 7.4.13 from Help Center
    - Place in `Liferay/DXP/License/` directory. 
    - Rename the xml licenses as DXP version names. ![See Liferay Licenses sample](/media/dir-license-sample.png)
3. Setup portal-ext.properties file
    - Download [/sample/portal-ext.properties](/sample/portal-ext.properties) and place in `Liferay/DXP/` directory. 
    - Update `DBUSER` and `DBPW` with MySQL credentials. 
    - Do **not** edit the `SCHEMA` keyword, as that will be auto-updated with the quickLR script.
4. [Setup MySQL](#setup-install-mysql)
    - [Setup MySQL credentials in .my.cnf](#setup-edit-mycnf-for-quick-sql-setup)
5. Run `chmod +x dxp_setup.sh` to give current user execute permissions
6. Start script using `./dxp_setup.sh`
7. When done with projects, delete Project directories and MySQL databases using `./cleanup.sh`

### Setup: Set Environment Variables

Use `nano ~/.bashrc`to set the following environmental variables:
```
# Environment Variables for quickLR usage (github.com/dianaseung/quickLR)
export LRDIR=[liferay_directory]
export PROJECTDIR=[project_directory]
export DBDEPLOYER_HOME=[dbdeployer_directory]
```
Replace `[liferay_directory]`, `[project_directory]`, and `[dbdeployer_directory]` with the appropriate values.

---

### Setup: Install mysql
See for more installation detail: https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-20-04
- Install the mysql-server package
```
sudo apt install mysql-server
```
- Ensure the server is running
```
sudo systemctl start mysql.service
```


----

### Setup: Edit .my.cnf for quick SQL setup
See for more configuration detail: https://www.inmotionhosting.com/support/server/databases/edit-mysql-my-cnf/
- Open the .my.cnf file
```
nano ~/.my.cnf
```

- Add user/password to .my.cnf file to allow script to create MySQL database (replace `mysqluser` and `mysqlpw`)

```
[client]
user=mysqluser
password=mysqlpw
```

- Ensure proper file permissions
```
chmod 600 ~/.my.cnf 
```

---

## Cleanup Script
Manually run to delete all Project directory and MySQL database based on last modified date older than X days

```
./cleanup.sh
```

<img src="/media/quickLR-cleanup.gif" alt="Preview of quickLR cleanup script" style="text-align: center;"/>

---

## Upcoming Planned v1.0 Features
- <img src="https://img.shields.io/badge/Priority-High-red" alt="High Priority" /> DBDeployer compatibility (Note: ./Liferay/MySQL/servers/####/use -u root) -- 1) create database based on MySQL server version, and 2) update portal-ext based on MySQL server version
- <img src="https://img.shields.io/badge/Priority-High-red" alt="Medium Priority" /> Investigate whether Liferay bundles could be pulled via API or consider source code method - curl from VPN
- <img src="https://img.shields.io/badge/Priority-High-red" alt="Medium Priority" /> [License & Target source] Find target source based on find/grep of $versiontrimx

### Minor Changes Planned
- Update sample recommended folder structure zip (currently missing Patching dir)
- Link to lrclean setup confluence doc
- Potential: set License, Branch and Patching directory in .bashrc

## Possible v2.0 Features - Tagged with Priority
- <img src="https://img.shields.io/badge/Priority-High-red" alt="High Priority" /> Automated script to check, move and rename new Liferay downloads (Update, SP, Fixpack) to appropriate Liferay folder upon download to Downloads folder (Alternatively, curl from VPN)
- <img src="https://img.shields.io/badge/Priority-Medium-yellow" alt="Medium Priority" /> Update to latest patching-tool available with any new bundle - P2: grep highest number dir
- <img src="https://img.shields.io/badge/Priority-Medium-yellow" alt="Medium Priority" />  Separate Config:
    - Second bundle setup (update server.xml file ports from 8xxx to 9xxx, cp com.liferay.portal.search.elasticsearch7.configuration.ElasticsearchConfiguration.config file to /osgi/configs/) - Note: writing the functionality is easy, but need to figure out logic for how to add to script menu (maybe need to flesh out the config menu)
    - Copy `com.liferay.portal.search.elasticsearch7.configuration.ElasticsearchConfiguration.config` config file to /$LIFERAY_HOME/osgi/config/for remote elasticsearch setup
- <img src="https://img.shields.io/badge/Priority-Low-green" alt="Low Priority" />  Fix Pack Support for Portal 6.2 and 6.1 (currently SP support only)

---

## Recent Updates
- 5/11/23 - Updated installation instructions based on testing on clean Ubuntu VM install
- 5/10/23 - Refactor: Updated createBundle function to accept parameter (Update, FP, Branch) to determine setup; Merged createBundle/createBranch/createFPBundle into single createBundle function
- 5/6/23 - Added cleanup script to delete Project folders and databases if last modified older than set date (default 30)
- 4/8/23 - Refactor (functions) - originally planned as a 2.0 rework
- 4/8/23 - Updates to latest patching-tool when installing bundle - P1: Currently hardcoded to cp specific patching-tool version based on DXP version
- 2/22/23 - Auto start bundle from tomcat dir
- 2/22/23 - Auto install Fix Packs (for both 7.3 and 7.0-7.2) & run lrclean function (clear temp folders)
- 2/22/23 - Updated 7.0-7.2 to cp portal-ext.properties file from version dir ($LRDIR/$version/) instead of a central generalized porta-ext.properties file from $LRDIR, to account for different database settings, especially for database (MySQL)
- 12/22/22 - Support for Portal 6.2 and 6.1 added - SP ONLY
- 12/22/22 - Support for DXP 7.3, 7.2, 7.1 and 7.0 branches added
- 12/21/22 - Support for master and nightly (DXP 7.4) added
- 12/20/22 - Refactored code for improved readability and maintenance
- 12/20/22 - Support for DXP 7.2, 7.1, 7.0 added
- 12/16/22 - Support for SP1 and SP3 for DXP 7.3 added
- 12/14/22 - Support for DXP 7.4 added