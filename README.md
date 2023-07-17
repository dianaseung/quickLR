<h1 align="center">quickLR</h1>

<p align="center">
<img src="https://img.shields.io/maintenance/yes/2023?style=for-the-badge" alt="Maintenance" />
<img src="https://img.shields.io/github/last-commit/dianaseung/quickLR?style=for-the-badge" alt="Last Commit" />
<img src="https://img.shields.io/github/v/tag/dianaseung/quickLR?style=for-the-badge" alt="Latest Tag" />
<img src="https://img.shields.io/github/license/dianaseung/quickLR?style=for-the-badge" alt="License" />
</p>

---

## About QuickLR: Overview
---
Linux bash script quickly sets up a basic Liferay Tomcat bundle and MySQL database for Liferay Support testing.
Alternative to using Docker compose to setup a standard Liferay bundle

<p align="center">
<img src="/media/quickLR-preview.gif" alt="Preview of quickLR script functionality" />
</p>

---



### DXP Setup Functionality

What does this script do?
1. Creates a Project folder with Project Code (i.e. CHICAGOLC)
2. Copies DXP bundle to Project
3. Places copy of activation xml license and portal-ext.properties to DXP bundle
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

## SETUP

### quickLR Installation / Setup
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
4. [Setup MySQL](#setup-install-mysql-server)
    - [Setup MySQL credentials in .my.cnf](#setup-edit-mycnf-for-mysql-credentials)
5. Run `chmod +x dxp_setup.sh` to give current user execute permissions

### Setup: Set Environment Variables

Use `nano ~/.bashrc`to set the following environmental variables:
```
# Environment Variables for quickLR usage (github.com/dianaseung/quickLR)
export LRDIR=[liferay_directory]
export PROJECTDIR=[project_directory]
export DBDEPLOYER_HOME=[dbdeployer_directory]
```
Replace `[liferay_directory]`, `[project_directory]`, and `[dbdeployer_directory]` with the appropriate values.

- Add LRCLEAN function to bashrc:
```
function lrclean() {
echo "Cleaning up Temp/Work..."
rm -rf ./osgi/state/*
echo "OSGi State Folder Cleared!"
wait
rm -rf ./temp/*
echo "Temp Folder Cleared!"
wait
rm -rf ./work/*
echo "Work Folder Cleared!"
echo "Temp/Work Folders Cleared!"
}
export -f lrclean
```


### Setup: Install mysql-server
- Install the mysql-server package
```
sudo apt install mysql-server
```
- Ensure the server is running
```
sudo systemctl start mysql.service
```
- Set password 
See https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-20-04 for more installation detail
a). Open the MySQL prompt to alter root's password and then exit MySQL
```
sudo mysql
```
```
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
exit
```
b). Use the password set in a) to run the security script to change password, and follow the prompts. 
```
sudo mysql_secure_installation
```

c). Open MySQL prompt to create MySQL user (replace 'user' with your own user) and set permissions
```
sudo mysql
```
```
CREATE USER 'user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'sammy'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit
```
e). Test if it works using one of the following:
```
systemctl status mysql.service
```
```
sudo mysqladmin -p -u user version
```


### Setup: Add MySQL credentials to .my.cnf to avoid MySQL prompts
- Open the .my.cnf file
```
nano ~/.my.cnf
```

- Add user/password to .my.cnf file to allow script to create MySQL database (replace `mysqluser` and `mysqlpw` with credentials set above)

```
[mysql]
user=mysqluser
password=mysqlpw
```

- Ensure proper file permissions
```
chmod 600 ~/.my.cnf 
```
See for more configuration detail: https://www.inmotionhosting.com/support/server/databases/edit-mysql-my-cnf/

---

## Usage
### DXP Setup Usage
1. Start DXP setup script using `./dxp_setup.sh`
2. Input Project code (such as CHICAGOLCS or BRAVO)
3. Select Liferay DXP/Portal version (choose from 7.4.13, 7.3.10, 7.2.10, 7.1.10, 7.0.10, 6.2.10, 6.1.10)
4. Input the Update, SP or Fix Pack patch level as a numeric input. (such as 72, 51, 2). Please note that DXP 7.2 only supports SP installs (no Fix Pack support yet)
5. When setup completes, if all steps successful, press any key to start bundle within terminal or press Ctrl-C to exit script.
    - If any adjustments, such as portal-ext.properties changes or hotfix installation, needs to be done, you can make those adjustments now before returning to terminal to start bundle

---

## Cleanup Script
<p align="center">
<img src="/media/quickLR-cleanup.gif" alt="Preview of quickLR cleanup script" />
</p>

- Cleanup Script looks at all folders in $PROJECTDIR within 1 depth, and compare their last modified date to expiration date (set by user).
- Manually run script to delete all Project directory and MySQL database older than expiration date, based on last modified date. 
    - If last modified date is older than expiration date, check if the MySQL database listed in the portal-ext.properties still exists. 
        - If database still exists, prompt to delete database.
        - Once databases of all Liferay bundles within a project folder are deleted, prompt to delete Project folder.
    - If last modified date has not yet reached expiration date, returns (per Project) how many days left until expiration. 

### Cleanup Usage
1. Start cleanup script using
```
./cleanup.sh
```
2. Input how many days until expiration date (default is 60 days)
3. If there are any Projects past expiration date, press any key to confirm database deletion.  Then press any key to confirm Project folder deletion. 
    - Press Ctrl-C at any time to cancel deletion.
4. Script will print remaining days until expiration date for remaining.
5. Script will auto-exit once completed.


---

## Upcoming Planned Features (v1.0)
- <img src="https://img.shields.io/badge/Priority-High-red" alt="High Priority" /> DBDeployer compatibility (Note: ./Liferay/MySQL/servers/####/use -u root) -- 1) create database based on MySQL server version, and 2) update portal-ext based on MySQL server version
- <img src="https://img.shields.io/badge/Priority-High-red" alt="Medium Priority" /> Investigate whether Liferay bundles could be pulled via API or consider source code method - curl from VPN
- <img src="https://img.shields.io/badge/Priority-High-red" alt="Medium Priority" /> [License & Target source] Find target source based on find/grep of $versiontrimx
- <img src="https://img.shields.io/badge/Priority-Low-green" alt="Low Priority" /> Consider setting License, Branch and Patching directory in .bashrc

## Possible v2.0 Features
- <img src="https://img.shields.io/badge/Priority-High-red" alt="High Priority" /> Automated script to check, move and rename new Liferay downloads (Update, SP, Fixpack) to appropriate Liferay folder upon download to Downloads folder (Alternatively, curl from VPN)
- <img src="https://img.shields.io/badge/Priority-Medium-yellow" alt="Medium Priority" /> Update to latest patching-tool available with any new bundle - P2: grep highest number dir
- <img src="https://img.shields.io/badge/Priority-Medium-yellow" alt="Medium Priority" />  Separate Config:
    - Second bundle setup (update server.xml file ports from 8xxx to 9xxx, cp com.liferay.portal.search.elasticsearch7.configuration.ElasticsearchConfiguration.config file to /osgi/configs/) - Note: writing the functionality is easy, but need to figure out logic for how to add to script menu (maybe need to flesh out the config menu)
    - Copy `com.liferay.portal.search.elasticsearch7.configuration.ElasticsearchConfiguration.config` config file to /$LIFERAY_HOME/osgi/config/for remote elasticsearch setup
- <img src="https://img.shields.io/badge/Priority-Low-green" alt="Low Priority" />  Fix Pack Support for Portal 6.2 and 6.1 (currently SP support only)

---

## Update History
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
