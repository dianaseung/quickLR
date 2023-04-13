#!/bin/bash
# for DXP 7.4 setup automation
# source /home/dia/Downloads/Liferay/setenv.sh | tee ./log.dat
# GLOBAL VARIABLES
DATE=$(date +%Y%m%d)
# TODO: Remove debugging checks
echo "CHECK: LRDIR ${LRDIR}"
echo "CHECK: PROJECTDIR ${PROJECTDIR}"

# NAME THE PROJECT
read -p 'Project Code: ' project
mkdir -p ${PROJECTDIR}/$project/
echo -e "SUCCESS: Project created at ${PROJECTDIR}/$project/\n---\n"

# MAKING FUNCTIONS FOR REUSABLE CODE
checkDir () {
    # CHECK IF BUNDLE EXISTS ALREADY - append date if so
    if [ -d "${PROJECTDIR}/${project}/${BUNDLED}" ]; then
        BUNDLED="${BUNDLED}.${DATE}"
        SCHEMA="${SCHEMA}_${DATE}"
        echo "Project $project with Update u$update folder already exists! Appending date..."
    else
        echo "Project $project with Update u$update folder does not exist yet..."
    fi
}

updatePatchingTool () {
    # REMOVE PATCHING-TOOL DIR
    rm -rf ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
    # INSTALL LATEST PATCHING TOOL BASED ON VERSION
    # Phase 1. hardcode in PT version for now
    # Phase 2, search for highest available number patching tool folder in directory
    if [[ $version == "7.4.13" ]] || [[ $version == "7.3.10" ]]; then
        # v3.0.37 PATCHING TOOL
        cp -rf ${LRDIR}/Patching/patching-tool-3.0.37/patching-tool/ ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
        echo "SUCCESS: Updated the Patching Tool folder to 3.0.37"
    elif [[ $version == "7.2.10" ]]; then
        # v2.0.16 PATCHING TOOL
        cp -r ${LRDIR}/Patching/patching-tool-2.0.16/patching-tool/ ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
        echo "SUCCESS: Updated the Patching Tool folder to 2.0.16"
    else
        # v1.0.23 PATCHING TOOL
        cp -r ${LRDIR}/Patching/patching-tool-1.0.23/patching-tool/ ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
        echo "SUCCESS: Updated the Patching Tool folder to 1.0.23"
    fi
}

createDB () {
    # MAKE THE MYSQL SCHEMA
    mysql -udia -e "CREATE SCHEMA ${SCHEMA}";
    CHECKDB=`mysql -e "SHOW DATABASES" | grep $SCHEMA`
    if [ $CHECKDB == $SCHEMA ]; then
        echo "SUCCESS: Database ${SCHEMA} made!"
    else
        echo "FAIL: Database ${SCHEMA} not created. Please create manually."
    fi
}

createBranch () {
    # No License placed 
    checkDir
    # CREATE FOLDER
    cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
    echo "SUCCESS: DXP $version $update folder created at ${PROJECTDIR}/$project/$BUNDLED"
    if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
        # INSTALL LICENSE + PORTAL-EXT PROPERTIES
        # cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
        cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
        # echo "SUCCESS: License and Portal-ext placed"
        #updatePatchingTool
        createDB
        # UPDATE PORTAL-EXT WITH NEW DB
        sed -i "s/SCHEMA/$SCHEMA/g" ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties
        echo "SUCCESS: portal-ext.properties updated with $SCHEMA"
    else
        echo "FAIL: Folder not created"
        echo "DEBUG: Source ${LRDIR}/${SRC}"
        echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
    fi
}

createBundle () {
    # This should work for both Updates and SP 
    checkDir
    # CREATE FOLDER
    cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
    echo "SUCCESS: DXP $version $update folder created at ${PROJECTDIR}/$project/$BUNDLED"
    if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
        # INSTALL LICENSE + PORTAL-EXT PROPERTIES
        cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
        cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
        echo "SUCCESS: License and Portal-ext placed"
        updatePatchingTool
        createDB
        # UPDATE PORTAL-EXT WITH NEW DB
        sed -i "s/SCHEMA/$SCHEMA/g" ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties
        echo "SUCCESS: portal-ext.properties updated with $SCHEMA"
    else
        echo "FAIL: Folder not created"
        echo "DEBUG: Source ${LRDIR}/${SRC}"
        echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
    fi
}

createFPBundle () {
    checkDir
    # CREATE FOLDER
    cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
    echo "SUCCESS: DXP $version $update folder created at ${PROJECTDIR}/$project/$BUNDLED"
    if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
        # INSTALL LICENSE + PORTAL-EXT PROPERTIES
        cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
        cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
        echo "SUCCESS: License and Portal-ext placed"
        updatePatchingTool
        # COPY FP + PATCH + CLEAN TEMP FILES
        FPZIP="liferay-fix-pack-dxp-$update-$versiontrim.zip"
        echo "DEBUG: Fix Pack sourced from ${LRDIR}/$FPZIP"
        cp ${LRDIR}/$version/FP/$FPZIP ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
        # If FP copied properly, then install 
        if [ -e ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP ]; then
            echo -e "Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP\nStarting Fix Pack Installation..."
            ( cd ${PROJECTDIR}/$project/$BUNDLED/patching-tool/ && ./patching-tool.sh install && ./patching-tool.sh info)
            # CLEAN TEMP FILES
            ( cd ${PROJECTDIR}/$project/$BUNDLED && lrclean)
            echo "SUCCESS: Fix Pack dxp-$update install completed! Temp Folders cleaned"
        else
            echo "FAIL: Fix Pack not placed. Please manually install Fix Pack."
            xdg-open ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
        fi
        createDB
        # UPDATE PORTAL-EXT WITH NEW DB
        sed -i "s/SCHEMA/$SCHEMA/g" ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties
        echo "SUCCESS: portal-ext.properties updated with $SCHEMA"
    else
        echo "FAIL: Folder not created"
        echo "DEBUG: Source ${LRDIR}/${SRC}"
        echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
    fi
}

# Select DXP version
echo -e "\n---\nChoose Liferay version to install:"
DXP=("7.4.13" "7.3.10" "7.2.10" "7.1.10" "7.0.10" "6.2" "6.1" "Config" "Exit")
select version in "${DXP[@]}"; do
    case $version in
        "7.4.13")
            versiontrim=${version//.}
            versiontrimx=${versiontrim//13}
            read -p "Select DXP $version patch level (Update): " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|master) ]]; do
                echo -e "ERROR: Invalid Input. Valid Inputs: Update # or master.\n"
                read -p "Select DXP $version patch level (Update): " update
            done
            echo -e "\n---\n"
            if [ $update == 'master' ]; then
                # TODO: Need to update master
                SRC="Branch/liferay-portal-tomcat-master-all/liferay-portal-master-all"
                BUNDLED="liferay-dxp-$version-$update"
                SCHEMA="${versiontrimx}_${project}_$update"
                createBundle
            else
                SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                BUNDLED="liferay-dxp-$version.u$update"
                SCHEMA="${versiontrimx}_${project}_U${update}"
                createBundle
            fi
            break
            ;;
        "7.3.10")
            # START 73 - USES UPDATES, SP and FP
            versiontrim=${version//.}
            versiontrimx=${versiontrim//10}
            read -p "Select DXP $version patch level (Update or FP #): " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|branch) ]]; do
                echo -e "ERROR: Invalid Input. Valid Inputs: Update/FP # or branch.\n"
                read -p "Select DXP $version patch level (Update or FP #): " update
            done
            echo -e "\n---\n"
            # TODO: Potential Refactor
            # CURRENT LOGIC IS SLIGHTLY DUMB
            if (( $update > 3 )); then
                # -- START IF UPDATE
                echo "Patch level is an Update: u$update"
                SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                BUNDLED="liferay-dxp-$version.u$update"
                SCHEMA="${versiontrimx}_${project}_U${update}"
                createBundle
                # -- END IF UPDATE
            elif (( $update == 1 )) || (( $update == 3 )); then
                # -- START IF SP
                echo "Patch level is an SP: sp$update"
                SRC="$version/liferay-dxp-tomcat-$version-sp$update/liferay-dxp-$version.$update-sp$update"
                BUNDLED="liferay-dxp-$version-sp$update"
                SCHEMA="${versiontrimx}_${project}_SP${update}"
                createBundle
                # -- END IF SP
            elif [ $update == 'branch' ]; then
                # -- START IF 73 BRANCH
                versiontrim=${version//.10}
                SRC="Branch/liferay-portal-tomcat-${versiontrim}.x-private-all/liferay-portal-${versiontrim}.x-private-all"
                BUNDLED="liferay-$version-$update"
                SCHEMA="${versiontrimx}_${project}_$update"
                createBranch
                # -- ENDIF BRANCH
            else
                # -- START IF FP
                echo "Patch level is a FP: DXP $version dxp-$update"
                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                BUNDLED="liferay-dxp-$version.dxp-$update"
                SCHEMA="${versiontrimx}_${project}_dxp${update}"
                createFPBundle
                # -- END IF FP
            fi
            break
            ;;
        "7.2.10" | "7.1.10" | "7.0.10")
            versiontrim=${version//.}
            versiontrimx=${versiontrim//10}
            # 72 71 70 ALL USE FP
            read -p "Select DXP $version patch level (FP #): " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|branch) ]]; do
                echo -e "ERROR: Invalid Input. Valid Inputs: Update/FP # or branch\n"
                read -p "Select DXP $version patch level (Update or FP #): " update
            done
            echo -e "\n---\n"

            if [ $update == 'branch' ]; then
                versiontrim=${version//.10}
                # -- START IF 70-72 BRANCH
                echo "$project Patch level is: DXP $version dxp-$update"
                SRC="Branch/liferay-portal-tomcat-$versiontrim.x-private-all/liferay-portal-$versiontrim.x-private-all"
                BUNDLED="liferay-$versiontrim-$update"
                SCHEMA="${versiontrimx}_${project}_$update"
                createBranch
                # -- ENDIF BRANCH
            else
                # -- START FP
                echo "$project Patch level is: DXP $version dxp-$update"
                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                BUNDLED="liferay-dxp-$version.dxp-$update"
                SCHEMA="${versiontrimx}_${project}_dxp${update}"
                createFPBundle
                # -- END FP
            fi
            break
            ;;
        "6.2" | "6.1")
            versiontrim=${version//.}
            versiontrimx=${versiontrim//10}
            # CHOOSE A SP
            read -p "Select Portal $version patch level (SP #): " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|branch) ]]; do
                echo -e "ERROR: Invalid Input. Valid Inputs: SP # or branch\n"
                read -p "Select Portal $version patch level (SP #): " update
            done
            echo -e "\n---\n"
            # TODO: consider hashmap / lookup table to make FP to SP
            # declare -A fixpacks
            # fixpacks=( ["SP20"]=154 ["SP19"]=148 ["SP18"]=138)

            if (( $update > 20 )); then
                echo "Service Pack needed, no fix pack support yet."
            elif [ $update == 'branch' ]; then
                # -- START IF 62 61 BRANCH
                echo "No branch support yet for Portal 6.2 or 6.1"
                # -- ENDIF BRANCH
            else
                # -- START IF SP
                echo "Ok, setting up a $project folder with Portal $version SP $update bundle..."
                SRC="$version/liferay-portal-tomcat-$version-ee-sp$update/liferay-portal-$version-ee-sp$update"
                BUNDLED="liferay-portal-tomcat-$version.ee-sp$update"
                SCHEMA="${versiontrim}_${project}_SP${update}"
                createBundle
            # -- END IF FP
            fi
            break
            ;;
        "Config")
            mysqlserverlist=mysqlserverlist.txt
            # Send list of installed DBDeployer servers to .txt
            # TODO: check if dbdeployer; if yes, use SANDBOX_HOME / if no, 3306?
            ls '/home/dia/Liferay/MySQL/servers/' > $mysqlserverlist
            # Define array of available MySQL servers available to choose from  
            mysqlarray=(`cat "$mysqlserverlist"`)

            select mysqlserver in "${mysqlarray[@]}"; do
                sed -i "s!localhost:*/SCHEMA!$mysqlserver!g" ${LRDIR}/portal-ext.properties
                echo "MySQL Server set at localhost:${mysqlserver}"
                break
            done
            exit
            ;;
        "Exit")
            echo "User requested exit"
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

echo -e "\n---\n"
echo "SUCCESS: Finished setup of ${PROJECTDIR}/$project/$BUNDLED"
# START BUNDLE OR EXIT SCRIPT
read -rsn1 -p"Press any key to start $BUNDLED bundle... or Ctrl-C to exit";echo
cd ${PROJECTDIR}/$project/$BUNDLED/tomcat*/bin/ && ./catalina.sh run
# [COMMENTED OUT FOR NOW] TODO: If exit and directory exists, open the folder the project was made
# xdg-open ${PROJECTDIR}/$project