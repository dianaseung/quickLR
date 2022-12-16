# quickLR

---

Linux bash script to help Customer Support Engineers to quickly setup basic Liferay bundles for ticketing work

---

## About QuickEnv: Overview

### Functionality

This bash script (Linux) quickly sets up a basic Liferay bundle and environment for CS tickets.
1. Create a Project folder with Project Code (i.e. CHICAGOLC)
2. Copy DXP Update folder to Project
3. Put a copy of License and Portal-ext.properties to DXP folder
4. Create a MySQL database
5. Update portal-ext.properties with newly created MySQL DB
6. Open Project folder

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
- Download Liferay Licenses for DXP 7.0, 7.1, 7.2, 7.3 and 7.4 from Help Centerand place in `Liferay/DXP/License/` directory. Rename the xml licenses as DXP version names. (See image)
![Liferay Licenses](https://drive.google.com/file/d/1CP3Z-xHrRz0upGbhp9f3-TCSAyvnX1FY/view?usp=sharing)
- Download sample [portal-ext.properties](/sample/portal-ext.properties) and place in `Liferay/DXP/` directory. Edit `DBUSER` and `DBPW` with MySQL credentials; edit port (default 3306) if needed. Do *not* edit `SCHEMA` keyword, as that will auto-update with the quickLR script.

### Setup: Set Environment Variables

Use `nano ~/.bashrc`to set the following environmental variables:
```
# Environment Variables for quickLR usage (github.com/dianaseung/quickLR)
export LRDIR=[liferay_directory]
export PROJECTDIR=[project_directory]
```
Replace `[liferay_directory]` and `[project_directory]` with the appropriate paths.

---

### Setup: Edit .my.cnf for quick SQL setup


###

---

# Upcoming Project Features

- instructions for .my.cnf setup
- set license directory in .bashrc
- include example portal-ext.properties
- instructions for MySQL install/setup

- cleanup script to delete database and delete (choose either project or bundle)
- automated script to rename and move Liferay .tar.gz files to the appropriate `Liferay/DXP/` directory upon download to Downloads folder