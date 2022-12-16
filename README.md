# quickLR

---

Linux bash script to help Liferay CSE quickly setup bundles

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
    │   ├── License                             # 
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
    │   ├── LRWWW                               # End-to-end, integration tests (alternatively `e2e`)
    │   ├── ...                                 # End-to-end, integration tests (alternatively `e2e`)
    └── ...


---

## Usage

### Setup: Set Environment Variables

Use `nano ~/.bashrc`to set the following environmental variables:
```
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