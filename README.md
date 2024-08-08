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
Linux bash script quickly sets up a basic Liferay Tomcat bundle and MySQL database for Liferay Support testing from local files.
Alternative to using Docker compose to setup a standard Liferay bundle

Supports nightly, master, and official releases (Quarterly Release, DXP 7.4, DXP 7.3, DXP 7.2, DXP 7.1, and DXP 7.0)

<p align="center">
<img src="/media/quickLR-preview.gif" alt="Preview of quickLR script functionality" />
</p>

---



### DXP Setup Functionality

What does this script do?
1. Creates a Project folder with Project Code (i.e. CHICAGOLC)
2. Copies a DXP bundle to Project
3. Places a copy of activation xml license and portal-ext.properties to DXP bundle
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
1. Clone the repo to your machine
    - Example: Navigate to `/home/$USER/Documents/repo/`
    - Note: Adjust path as desired.
    - run `git clone https://github.com/dianaseung/quickLR.git`
2. Add alias to .bashrc for easy usage
    - run `sudo nano ~/.bashrc`
    - Example: `alias quickLR='cd /home/$USER/Documents/repo/quickLR/ && ./dxp_setup.sh'`
    - Note: Adjust alias name and path as desired.
3. Run `quickLR init` to setup file structure noted above.
    - This will auto-generate empty folders, copy template portal-ext.properties, and download latest patching tools (at time of running init)
    - If you leave paths blank, it will setup in $HOME by default.
2. Download Liferay Licenses
    - Download activation xml licenses for DXP 7.0.10, 7.1.10, 7.2.10, 7.3.10 and 7.4.13 from Help Center
    - Place in `Liferay/DXP/License/` directory. 
    - Rename the xml licenses as DXP version names. ![See Liferay Licenses sample](/media/dir-license-sample.png)
3. Review portal-ext.properties template file
    - A portal-ext.properties template file (to be used when setting up bundles) has been copied to `Liferay/DXP/License/` during init.
    - Adjust properties as desired. Properties convenient for testing has been included by default.
    - Do **not** edit `DBUSER` and `DBPW` keywords in the template file, it will be replaced with your MySQL credentials during when running dxp setup. 
    - Do **not** edit the `SCHEMA` keyword, as that will be auto-updated with the quickLR script.
4. [Setup MySQL](#setup-install-mysql-server)
    - [Setup MySQL credentials in .my.cnf](#setup-edit-mycnf-for-mysql-credentials)
5. Run `chmod +x dxp_setup.sh` (within the quickLR dir) to give current user execute permissions

### Setup: Set Environment Variables

Use `nano ~/.bashrc`to set the following environmental variables:
(Note: LRDIR and PROJECTDIR is auto-set if you ran `quickLR init`!)
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
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'liferay';
exit
```
b) Afterwards, use the following to set back to auth_socket connection:
```
mysql -u root -p
ALTER USER 'root'@'localhost' IDENTIFIED WITH auth_socket;
exit
```
c). Open MySQL prompt to create MySQL user (replace 'user' with your own user) and set permissions
```
sudo mysql
```
```
CREATE USER 'user'@'localhost' IDENTIFIED BY 'liferay';
GRANT ALL PRIVILEGES ON *.* TO 'user'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit
```
d). MySQL credentials to my.cnf to avoid MySQL prompts
- Add your MySQL credentials to either ~/.my.cnf or /etc/mysql/conf.d/mysql.cnf (check /etc/alternatives/my.cnf if neither work)
```
sudo nano ~/.my.cnf
```

- Add user/password to .my.cnf file to allow script to create MySQL database (replace `mysqluser` and `mysqlpw` with the credentials set above)

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

e). Test if it works using one of the following:
```
mysql
```

---

## Usage
### DXP Setup Usage
1. Start DXP setup script using `./dxp_setup.sh` (or use the alias `quickLR`)
2. Input Project code (such as CHICAGOLCS or BRAVO)
3. Select Liferay DXP/Portal version (choose from Quarterly Release, 7.4.13, 7.3.10, 7.2.10, 7.1.10, 7.0.10, 6.2.10, 6.1.10)
4. Input the QR, Update, SP or Fix Pack patch level as a numeric input. (such as 2024.q2.3, 72, 51, 2). 
5. When setup completes, if all steps successful, press any key to start bundle within terminal or press Ctrl-C to exit script.
    - If any adjustments, such as portal-ext.properties changes or hotfix installation, needs to be done, you can make those adjustments now before returning to terminal to start bundle

---

## Cleanup Script
<p align="center">
<img src="/media/quickLR-cleanup.gif" alt="Preview of quickLR cleanup script" />
</p>

- Cleanup Script looks at all folders in $PROJECTDIR within 1 depth, and compare their last modified date to expiration date (set by user).
- The goal is for cleanup to delete both the physical files, as well as the associated MySQL database.  (Please note that this is a WIP.)
- Manually run script to delete all Project directory and MySQL database older than expiration date, based on last modified date. 
    - If last modified date is older than expiration date, check if the MySQL database listed in the portal-ext.properties still exists. 
        - If database still exists, prompt to delete database.
        - Once databases of all Liferay bundles within a project folder are deleted, prompt to delete Project folder.
    - If last modified date has not yet reached expiration date, returns (per Project) how many days left until expiration. 

### Cleanup Usage
1. Start cleanup script using
```
`quickLR clean` (or ./cleanup.sh if alias is not set)
```
2. Select from: Clean all projects, Clean one project, Clean multiple projects, Clean by Last Modified.
3. For 'Clean all projects' option, MySQL database deletion is not yet supported.
4. For 'Clean by Last Modified': Input how many days until expiration date (default is 60 days)
    - If there are any Projects past expiration date, press any key to confirm database deletion.  Then press any key to confirm Project folder deletion. 
    - Press Ctrl-C at any time to cancel deletion.
    - Script will print remaining days until expiration date for remaining.
5. Script will auto-exit once completed.


---

## Planned Upcoming Features
- <img src="https://img.shields.io/badge/Priority-High-red" alt="High Priority" /> [License & Target source] Find target source based on find/grep of $versiontrimx

- <img src="https://img.shields.io/badge/Priority-Medium-yellow" alt="Medium Priority" /> Improve `mod` -- currently modifies a bundle for either staging or clustering. Could use semantic improvement, as well as make more user-friendly.  
    - During clustering setup, prompt which is master node

- <img src="https://img.shields.io/badge/Priority-Medium-yellow" alt="Medium Priority" />  Organize options

- <img src="https://img.shields.io/badge/Priority-Low-green" alt="Low Priority" /> (Low Priority) Fix Pack Support for Portal 6.2 and 6.1 (currently SP support only)

---

## Update History
- 8/7/24 - Added `pt` option to download latest patching tools (run `quickLR pt`)
- 8/7/24 - Modify a bundle for staging or clustering via `mod` (run `quickLR mod`)
- 8/7/24 - Added `help` option to see available options.
- 8/6/24 - Automate quickLR setup via script (create directory structure via script, add quickLR env to bashrc via script)
- 2/6/24 - Download Liferay bundle from releases-cdn.liferay.com and auto-extract.
- 1/30/24 - Updated for Quarterly Release format (including grabbing the highest number of Patching Tool available in {LRDIR}/Patching dir)
- Q4 2023 - Changed config menu to be accessible under 'quickLR config' 
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
