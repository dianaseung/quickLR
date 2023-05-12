#!/bin/bash
# Project: Quick LR - Liferay DXP setup automation for Support CSE
DATE=$(date +%y%m%d%H%M)
# CHECK: GLOBAL VARIABLES (set in bashrc)
if [ -z ${LRDIR+x} ]; then
    echo "WARN: Please set LRDIR in ~/.bashrc first!"
    exit 1
else
    echo "CHECK: LRDIR is ${LRDIR}"
fi
if [ -z ${PROJECTDIR+x} ]; then
    echo "WARN: Please set PROJECTDIR in ~/.bashrc first!"
    exit 1
else
    echo "CHECK: PROJECTDIR is ${PROJECTDIR}"
fi
# if [ -z ${MYSQLUSER+x} ]; then
#     echo "WARN: Please set MYSQLUSER in ~/.bashrc first!"
#     exit 1
# else
#     echo "CHECK: MYSQLUSER is ${MYSQLUSER}"
# fi

# CHECK: MYSL DB VERSION/PORT
MYSQLPORTLN=`grep 'jdbc.default.url' ${LRDIR}/portal-ext.properties`
propPrefix='jdbc.default.url=jdbc:mysql://localhost:'
propSuffix='?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true'
dbNameA=${MYSQLPORTLN/$propPrefix/}
dbNameB=${dbNameA/$propSuffix/}
dbPort=${dbNameB%/*}
echo "CHECK: Current MYSQL Port is $dbPort"
echo -e "\n---"

# NAME THE PROJECT DIR
read -p 'Project Code: ' project
mkdir -p "${PROJECTDIR}"/"$project"/
if [[ -e "${PROJECTDIR}"/"$project"/ ]]; then
    echo -e "SUCCESS: Project created at ${PROJECTDIR}/$project/"
else
    echo -e "ERROR: Project dir not created. Please manually make dir."
    xdg-open "${PROJECTDIR}"
fi

# FUNCTIONS
checkDir () {
    # CHECK IF BUNDLE EXISTS ALREADY - append date if so
    if [ -d "${PROJECTDIR}"/"${project}"/"${BUNDLED}" ]; then
        BUNDLED="${BUNDLED}.${DATE}"
        SCHEMA="${SCHEMA}_${DATE}"
        echo "Project $project with "$1" "$update" folder already exists! Appending date..."
    else
        echo "Project $project with "$1" "$update" folder does not exist yet!"
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
        echo -e "\tSUCCESS: Updated the Patching Tool folder to 3.0.37"
    elif [[ $version == "7.2.10" ]]; then
        # v2.0.16 PATCHING TOOL
        cp -r ${LRDIR}/Patching/patching-tool-2.0.16/patching-tool/ ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
        echo -e "\tSUCCESS: Updated the Patching Tool folder to 2.0.16"
    else
        # v1.0.23 PATCHING TOOL
        cp -r ${LRDIR}/Patching/patching-tool-1.0.23/patching-tool/ ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
        echo -e "\tSUCCESS: Updated the Patching Tool folder to 1.0.23"
    fi
}

createDB () {
    # MAKE THE MYSQL SCHEMA
    echo -e "DEBUG: Starting to create MySQL database..."
    mysql -e "CREATE SCHEMA ${SCHEMA}";
    # echo -e "mysql -u${MYSQLUSER} -e "CREATE SCHEMA ${SCHEMA};"
    CHECKDB=`mysql -e "SHOW DATABASES" | grep $SCHEMA`
    echo -e "DEBUG: CHECKDB - ${CHECKDB}"
    if [[ $CHECKDB == $SCHEMA ]]; then
        echo -e "\tSUCCESS: Created database ${SCHEMA}"
    else
        echo -e "\tFAIL: Database ${SCHEMA} not created. Please create manually."
    fi
}

updatePortalExtDB () {
    sed -i "s/SCHEMA/$SCHEMA/g" ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties
    echo -e "\tSUCCESS: Updated portal-ext.properties with $SCHEMA"
}

patchInstall () {
    # COPY FP + PATCH + CLEAN TEMP FILES
    FPZIP="liferay-fix-pack-dxp-$update-$versiontrim.zip"
    cp ${LRDIR}/$version/FP/$FPZIP ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
    # If FP copied properly, then install 
    if [ -e ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP ]; then
        echo -e "\tSUCCESS: Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP\n\tStarting Fix Pack Installation...\n---\n"
        ( cd ${PROJECTDIR}/$project/$BUNDLED/patching-tool/ && ./patching-tool.sh install && ./patching-tool.sh info)
        # CLEAN TEMP FILES
        ( cd ${PROJECTDIR}/$project/$BUNDLED && lrclean)
        echo -e "\n---\n\tSUCCESS: Fix Pack dxp-$update install completed! Temp Folders cleaned"
    else
        echo -e "\tFAIL: Fix Pack not placed. Please manually install Fix Pack."
        xdg-open ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
    fi
}

createBundle () {
    checkDir $1
    # CREATE FOLDER
    cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
    echo -e "\tSUCCESS: DXP $version $1 $update folder created at $project/$BUNDLED"
    if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
        # Install Portal-Ext - Always Needed
        cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
        if [[ -e ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties ]]; then
            echo -e "\tSUCCESS: Portal-ext placed"
        else
            echo -e "\tFAIL: Please manually place portal-ext files"
            xdg-open ${PROJECTDIR}/$project/$BUNDLED/
        fi
        # Install License - Only if !branch / + Update Patching Tool, Create DB, Update Portal-Ext
        if [[ $1 == 'Branch' ]]; then
            echo -e "\tINFO: No license needed for Branch/Master"
        else
            cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
            if [[ -e ${PROJECTDIR}/$project/$BUNDLED/deploy/$version.xml ]]; then
                echo -e "\tSUCCESS: License placed"
            else
                echo -e "\tFAIL: Please manually place license files"
                xdg-open ${PROJECTDIR}/$project/$BUNDLED/deploy/
            fi
            updatePatchingTool
            createDB
            updatePortalExtDB
        fi
        # Update Patching Tool - Only if FP
        if [[ $1 == 'FP' ]]; then
            patchInstall
        else
            echo -e "\tINFO: No patching needed"
        fi
    else
        echo -e "\tFAIL: Folder not created"
        echo -e "\tDEBUG: Source ${LRDIR}/${SRC}"
        echo -e "\tDEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
    fi
}

# Select DXP version
echo -e "\n---\nChoose Liferay version to install:"
DXP=("7.4.13" "7.3.10" "7.2.10" "7.1.10" "7.0.10" "6.2" "6.1" "Config" "Exit")
select version in "${DXP[@]}"; do
    versiontrim=${version//.}
    case $version in
        "7.4.13")
            versiontrimx=${versiontrim//13}
            read -p "Select DXP $version patch level: " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|master) ]]; do
                echo -e "\tERROR: Invalid Input. Valid Inputs: Update or master.\n"
                read -p "Select DXP $version patch level (Update): " update
            done
            echo -e "\n---\n"
            if [ $update == 'master' ]; then
                SRC="Branch/liferay-portal-tomcat-master-all/liferay-portal-master-all"
                BUNDLED="liferay-dxp-$version-$update"
                SCHEMA="${versiontrimx}_${project}_$update"
                createBundle Branch
            else
                SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                BUNDLED="liferay-dxp-$version.u$update"
                SCHEMA="${versiontrimx}_${project}_U${update}"
                createBundle Update
            fi
            break
            ;;
        "7.3.10")
            # START 73 - USES UPDATES, SP and FP
            versiontrimx=${versiontrim//10}
            read -p "Select DXP $version patch level: " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|branch) ]]; do
                echo -e "ERROR: Invalid Input. Valid Inputs: Update, FP or branch.\n"
                read -p "Select DXP $version patch level: " update
            done
            echo -e "\n---\n"
            if (( $update > 3 )); then
                SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                BUNDLED="liferay-dxp-$version.u$update"
                SCHEMA="${versiontrimx}_${project}_U${update}"
                createBundle Update
            elif (( $update == 1 )) || (( $update == 3 )); then
                # -- IF SP
                SRC="$version/liferay-dxp-tomcat-$version-sp$update/liferay-dxp-$version.$update-sp$update"
                BUNDLED="liferay-dxp-$version-sp$update"
                SCHEMA="${versiontrimx}_${project}_SP${update}"
                createBundle SP
            elif [ $update == 'branch' ]; then
                versiontrim=${version//.10}
                SRC="Branch/liferay-portal-tomcat-${versiontrim}.x-private-all/liferay-portal-${versiontrim}.x-private-all"
                BUNDLED="liferay-$version-$update"
                SCHEMA="${versiontrimx}_${project}_$update"
                createBundle Branch
            else
                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                BUNDLED="liferay-dxp-$version.dxp-$update"
                SCHEMA="${versiontrimx}_${project}_dxp${update}"
                createBundle FP
            fi
            break
            ;;
        "7.2.10" | "7.1.10" | "7.0.10")
            versiontrimx=${versiontrim//10}
            read -p "Select DXP $version patch level: " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|branch) ]]; do
                echo -e "ERROR: Invalid Input. Valid Inputs: Update, FP or branch\n"
                read -p "Select DXP $version patch level: " update
            done
            echo -e "\n---\n"

            if [ $update == 'branch' ]; then
                versiontrim=${version//.10}
                SRC="Branch/liferay-portal-tomcat-$versiontrim.x-private-all/liferay-portal-$versiontrim.x-private-all"
                BUNDLED="liferay-$versiontrim-$update"
                SCHEMA="${versiontrimx}_${project}_$update"
                createBundle Branch
            else
                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                BUNDLED="liferay-dxp-$version.dxp-$update"
                SCHEMA="${versiontrimx}_${project}_dxp${update}"
                createBundle FP
            fi
            break
            ;;
        "6.2" | "6.1")
            versiontrimx=${versiontrim//10}
            # CHOOSE A SP
            read -p "Select Portal $version patch level (SP #): " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|branch) ]]; do
                echo -e "\tERROR: Invalid Input. Valid Inputs: SP # or branch\n"
                read -p "Select Portal $version patch level: " update
            done
            echo -e "\n---\n"
            # TODO: consider hashmap / lookup table to make FP to SP
            # declare -A fixpacks
            # fixpacks=( ["SP20"]=154 ["SP19"]=148 ["SP18"]=138)
            if (( $update > 20 )); then
                echo -e "\tWARN: Service Pack needed, no fix pack support yet."
            elif [ $update == 'branch' ]; then
                echo -e "\tWARN: No branch support yet for Portal 6.2 or 6.1"
            else
                echo "Ok, setting up a $project folder with Portal $version SP $update bundle..."
                SRC="$version/liferay-portal-tomcat-$version-ee-sp$update/liferay-portal-$version-ee-sp$update"
                BUNDLED="liferay-portal-tomcat-$version.ee-sp$update"
                SCHEMA="${versiontrim}_${project}_SP${update}"
                createBundle SP
            fi
            break
            ;;
        "Config")
            echo "DBDeployer versions command:"
            dbdeployer versions
            # Send list of installed DBDeployer servers to .txt
            # TODO: check if dbdeployer; if yes, use SANDBOX_HOME / if no, 3306?
            mysqlserverlist=mysqlserverlist.txt
            ls "${DBDEPLOYER_HOME}/servers/" > $mysqlserverlist
            # Check if 3306 in server list, if not add
            if grep -Fxq "3306" $mysqlserverlist
                then
                    echo -e "\tCHECK: 3306 already in $mysqlserverlist"
                else
                    echo -e "\tCHECK: 3306 not yet in $mysqlserverlist -- inserting 3306 as an option"
                    echo -e "3306" >> $mysqlserverlist
                fi
            # Define array of available MySQL servers available to choose from  
            mysqlarray=(`cat "$mysqlserverlist"`)

            select mysqlserver in "${mysqlarray[@]}"; do
                DBDserver_DIR=$DBDEPLOYER_HOME/servers/$mysqlserver/
                # echo -e "\tThe DBDeployer server dir is $DBDserver_DIR"
                # UPDATE portal-ext with selected server
                sed -i "s!localhost:.*/SCHEMA!localhost:$mysqlserver/SCHEMA!g" ${LRDIR}/portal-ext.properties
                echo -e "\tSUCCESS: Master portal-ext.properties updated! MySQL Server set at localhost:${mysqlserver}\n---\n"
                if [ $mysqlserver == '3306' ]; then
                    # This is on by default if mysql installed
                    echo "Nothing else to do"
                else
                    # Start the DBDeployer server
                    read -rsn1 -p"Press any key to start $mysqlserver server... or Ctrl-C to exit";echo
                    cd $DBDserver_DIR && ./start
                fi

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

echo -e "\tSUCCESS: Completed setup of $project/$BUNDLED"
echo -e "\n---\n"
# START BUNDLE OR EXIT SCRIPT
read -rsn1 -p"Press any key to start $BUNDLED bundle... or Ctrl-C to exit";echo
cd ${PROJECTDIR}/$project/$BUNDLED/tomcat*/bin/ && ./catalina.sh run