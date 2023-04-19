# quickLR

---

Linux bash script to help Customer Support Engineers to quickly setup basic Liferay Tomcat bundles

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

---

## USAGE AND SETUP

## Setup
- Download [this Liferay.zip](/sample/Liferay.zip) and extract to desired destination to quickly setup a Folder Structure like above.
- Download activation xml licenses for DXP 7.0.10, 7.1.10, 7.2.10, 7.3.10 and 7.4.13 from Help Center, and place in `Liferay/DXP/License/` directory. Rename the xml licenses as DXP version names. (See image)
![Liferay Licenses](https://drive.google.com/file/d/1CP3Z-xHrRz0upGbhp9f3-TCSAyvnX1FY/view?usp=sharing)
- Download sample [portal-ext.properties](/sample/portal-ext.properties) and place in `Liferay/DXP/` directory. Edit `DBUSER` and `DBPW` with MySQL credentials; edit port (default 3306) if needed. Do **not** edit the `SCHEMA` keyword, as that will be auto-updated with the quickLR script.

### Setup: Set Environment Variables

Use `nano ~/.bashrc`to set the following environmental variables:
```
# Environment Variables for quickLR usage (github.com/dianaseung/quickLR)
export LRDIR=[liferay_directory]
export PROJECTDIR=[project_directory]
export MYSQLUSER=[username]
export DBDEPLOYER_HOME=[dbdeployer_directory]
```
Replace `[liferay_directory]`, `[project_directory]`, `[username]` and `[dbdeployer_directory]` with the appropriate values.

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
- Add user/password to .my.cnf file to allow script to create MySQL database:

```
user=
password=
```

---

## Recent Updates
- 4/8/23 - Refactor (functions) - originally planned as a 2.0 rework
- 4/8/23 - Updates to latest patching-tool when installing bundle - P1: Currently hardcoded to cp specific patching-tool version based on DXP version
- 2/22/23 - Auto start bundle from tomcat dir
- 2/22/23 - Auto install Fix Packs (for both 7.3 and 7.0-7.2) & run lrclean function (clear temp folders)
- 2/22/23 - Updated 7.0-7.2 to cp portal-ext.properties file from version dir ($LRDIR/$version/) instead of a central generalized porta-ext.properties file from $LRDIR, to account for different database settings, especially for database (MySQL)
- 12/22/22 - Support for Portal 6.2 and 6.1 added - SP ONLY
- 12/22/22 - Support for DXP 7.3, 7.2, 7.1 and 7.0 branches added
- 12/21/22 - Support for master and nightly (DXP 7.4) added
- 12/20/22 - Refactored code for improved readability and maintenance
- 12/16/22 - Support for SP1 and SP3 for DXP 7.3 added
- Support for DXP 7.2, 7.1, 7.0 added

## Upcoming Planned v1.0 Features
- DBDeployer compatibility (Note: ./Liferay/MySQL/servers/####/use -u root) -- 1) create database based on MySQL server version, and 2) update portal-ext based on MySQL server version

### Minor Changes Planned
- Refactor - Set var (bundleType) to check if update/SP/FP/branch or master; Merge createBundle/createBranch/createFPBundle into one function and have components run conditionally based on bundleType 
- Update README instructions for more explicit setup instructions (.my.cnf setup, DBDeployer/MySQL install/setup)
- Update sample portal-ext.properties to allow for quicker testing setup (disable TOS, setup wiz, pw change, etc)
- Update sample recommended folder structure zip
- Link to lrclean setup confluence doc
- Potential: set license, branch directory in .bashrc

## Possible v2.0 Features
- Update to latest patching-tool available with any new bundle - P2: grep highest number dir
- Second bundle setup (update server.xml file ports from 8xxx to 9xxx, cp com.liferay.portal.search.elasticsearch7.configuration.ElasticsearchConfiguration.config file to /osgi/configs/) - Note: writing the functionality is easy, but need to figure out logic for how to add to script menu (maybe need to flesh out the config menu)
- Fix Pack Support for Portal 6.2 and 6.1 (currently SP support only)
- Automated script to check, move and rename new Liferay downloads (Update, SP, Fixpack) to appropriate Liferay folder upon download to Downloads folder
- Cleanup script to automate deleting database and bundle(s) (either by whole project code or individual bundle)