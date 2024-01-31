#!/bin/bash
# Project: Quick LR - Liferay DXP setup automation for Support CSE

# ==============================================================
# --------------------------------------------------------------

# Date format to append for duplicate LR installs
DATE=$(date +%y%m%d%H%M)

# CHECK: GLOBAL VARIABLES (set in bashrc)
if [ -z ${LRDIR+x} ]; then
    echo "WARN: Please set LRDIR in ~/.bashrc first!"
    exit 1
else
    echo -e "\tCHECK: LRDIR is ${LRDIR}"
fi
if [ -z ${PROJECTDIR+x} ]; then
    echo "WARN: Please set PROJECTDIR in ~/.bashrc first!"
    exit 1
else
    echo -e "\tCHECK: PROJECTDIR is ${PROJECTDIR}"
fi
# if [ -z ${MYSQLUSER+x} ]; then
#     echo "WARN: Please set MYSQLUSER in ~/.bashrc first!"
#     exit 1
# else
#     echo "CHECK: MYSQLUSER is ${MYSQLUSER}"
# fi

# CHECK: MYSL DB VERSION/PORT in portal-ext.properties
MYSQLPORTLN=$(grep 'jdbc.default.url' "${LRDIR}"/portal-ext.properties)
propPrefix='jdbc.default.url=jdbc:mysql://localhost:'
propSuffix='?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true'
dbNameA=${MYSQLPORTLN/$propPrefix/}
dbNameB=${dbNameA/$propSuffix/}
dbPort=${dbNameB%/*}
echo -e "\tCHECK: Current MYSQL Port is $dbPort"
echo -e "\t---"


# --------------------------------------------------------------

# FUNCTIONS
checkDir () {
    # CHECK IF BUNDLE EXISTS ALREADY - append date if so
    if [ -d "${PROJECTDIR}"/"${project}"/"${BUNDLED}" ]; then
        BUNDLED="${BUNDLED}.${DATE}"
        SCHEMA="${SCHEMA}_${DATE}"
        echo -e "\tWARNING: Project $project with $1 $update folder already exists! Appending date..."
    else
        echo -e "\tCHECK: Project $project with $1 $update folder does not exist yet!"
    fi
}

updatePatchingTool () {
    # REMOVE PATCHING-TOOL DIR
    # use readlink instead
    rm -rf "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
    # INSTALL LATEST PATCHING TOOL BASED ON VERSION
    # Phase 1. hardcode in PT version for now
    # Phase 2, search for highest available number patching tool folder in directory
    if [[ $version == "Quarterly Release" ]]; then
        # v3.0.37 PATCHING TOOL
        FINDPATCHDIR=($(find "${LRDIR}"/Patching -maxdepth 2 -type d -name patching-tool-4.0.* | sort -n | head -2))
        PATCHDIRRAW=${FINDPATCHDIR[-1]}
        PATCHDIR=$(echo "$PATCHDIRRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
        cp -rf "${LRDIR}"/$PATCHDIR/patching-tool/ "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
        echo -e "\tSUCCESS: Updated the Patching Tool folder to $PATCHDIR"
    elif [[ $version == "7.4.13" ]] || [[ $version == "7.3.10" ]]; then
        # v3.0.37 PATCHING TOOL
        FINDPATCHDIR=($(find "${LRDIR}"/Patching -maxdepth 2 -type d -name patching-tool-3.0.* | sort -n | head -2))
        PATCHDIRRAW=${FINDPATCHDIR[-1]}
        PATCHDIR=$(echo "$PATCHDIRRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
        cp -rf "${LRDIR}"/$PATCHDIR/patching-tool/ "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
        echo -e "\tSUCCESS: Updated the Patching Tool folder to $PATCHDIR"
    else
        # v2.0.16 PATCHING TOOL
        FINDPATCHDIR=($(find "${LRDIR}"/Patching -maxdepth 2 -type d -name patching-tool-2.0.* | sort -n | head -2))
        PATCHDIRRAW=${FINDPATCHDIR[-1]}
        PATCHDIR=$(echo "$PATCHDIRRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
        cp -r "${LRDIR}"/$PATCHDIR/patching-tool/ "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
        echo -e "\tSUCCESS: Updated the Patching Tool folder to $PATCHDIR"
    fi
}

createDB () {
    # MAKE THE MYSQL SCHEMA
    echo -e "\tStarting to create MySQL database..."
    if [[ $dbPort == '3306' ]]; then
        mysql -e "CREATE SCHEMA ${SCHEMA};"
        CHECKDB=$(mysql -e "SHOW DATABASES" | grep "$SCHEMA")
    else
        mysql --socket=/tmp/mysql_sandbox"$dbPort".sock --port "$dbPort" -e "CREATE SCHEMA ${SCHEMA};"
        CHECKDB=$(mysql --socket=/tmp/mysql_sandbox"$dbPort".sock --port "$dbPort" -e 'SHOW DATABASES;' | grep "${SCHEMA}")
    fi
    # echo -e "mysql -u${MYSQLUSER} -e "CREATE SCHEMA ${SCHEMA};"
    echo -e "\tCHECK: Checking if ${CHECKDB} exists on $dbPort"
    # TODO: fix case sensitivity
    if [[ $CHECKDB == "$SCHEMA" ]]; then
        echo -e "\tSUCCESS: Created database ${SCHEMA}"
    else
        echo -e "\tFAIL: Database ${SCHEMA} not created. Please create manually."
    fi
}

updatePortalExtDB () {
    sed -i "s/SCHEMA/$SCHEMA/g" "${PROJECTDIR}"/"$project"/"$BUNDLED"/portal-ext.properties
    if [ "$version" == '7.0.10' ]; then
        # com.mysql.jdbc.Driver
        # sed -i "s/original/new/g" ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties
        sed -i "s/com.mysql.cj.jdbc.Driver/com.mysql.jdbc.Driver/g" "${PROJECTDIR}"/"$project"/"$BUNDLED"/portal-ext.properties
        sed -i "s/&serverTimezone=GMT//g" "${PROJECTDIR}"/"$project"/"$BUNDLED"/portal-ext.properties
        sed -i "s/DBUSER/$DBDUSER/g" "${PROJECTDIR}"/"$project"/"$BUNDLED"/portal-ext.properties
        sed -i "s/DBPW/$DBDPW/g" "${PROJECTDIR}"/"$project"/"$BUNDLED"/portal-ext.properties
        # sed -i "s!localhost:.*/SCHEMA!localhost:$mysqlserver/SCHEMA!g" ${LRDIR}/portal-ext.properties
        echo -e "\tSUCCESS: Portal-ext changed for 7.0 MySQL, DBDeployer login used"
    else
        sed -i "s/DBUSER/$MYSQLUSER/g" "${PROJECTDIR}"/"$project"/"$BUNDLED"/portal-ext.properties
        sed -i "s/DBPW/$MYSQLPW/g" "${PROJECTDIR}"/"$project"/"$BUNDLED"/portal-ext.properties
    fi
    echo -e "\tSUCCESS: Updated portal-ext.properties with $SCHEMA"
}

patchInstall () {
    # COPY FP + PATCH + CLEAN TEMP FILES
    if [ "$version" == '7.0.10' ]; then
        # liferay-fix-pack-de-87-7010
        FPZIP="liferay-fix-pack-de-$update-$versiontrim.zip"
    else
        FPZIP="liferay-fix-pack-dxp-$update-$versiontrim.zip"
    fi
    cp "${LRDIR}"/"$version"/FP/"$FPZIP" "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/patches/
    # If FP copied properly, then install 
    if [ -e "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/patches/"$FPZIP" ]; then
        echo -e "\tSUCCESS: Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP\n\tStarting Fix Pack Installation...\n---\n"
        ( cd "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/ && ./patching-tool.sh install && ./patching-tool.sh info)
        # CLEAN TEMP FILES
        ( cd "${PROJECTDIR}"/"$project"/"$BUNDLED" && lrclean)
        echo -e "\n---\n\tSUCCESS: Fix Pack dxp-$update install completed! Temp Folders cleaned"
    else
        echo -e "\tFAIL: Fix Pack not placed. Please manually install Fix Pack."
        xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
    fi
}

createBundle () {
    checkDir "$1"
    # CREATE FOLDER
    cp -r "${LRDIR}"/"$SRC" "${PROJECTDIR}"/"$project"/"$BUNDLED"
    if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
        echo -e "\tSUCCESS: DXP $version $1 $update folder created at $project/$BUNDLED"
        # Install Portal-Ext - Always Needed
        cp "${LRDIR}"/portal-ext.properties "${PROJECTDIR}"/"$project"/"$BUNDLED"/
        if [[ -e ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties ]]; then
            echo -e "\tSUCCESS: Portal-ext placed"
        else
            echo -e "\tFAIL: Please manually place portal-ext files"
            xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/
        fi
        # Install License - Only if !branch / + Update Patching Tool, Create DB, Update Portal-Ext
        if [[ $1 == 'Branch' ]]; then
            echo -e "\tINFO: No license needed for Branch/Master"
            createDB
            updatePortalExtDB
        elif [[ $1 == 'FP' ]]; then
            cp "${LRDIR}"/License/"$version".xml "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            if [[ -e ${PROJECTDIR}/$project/$BUNDLED/deploy/$version.xml ]]; then
                echo -e "\tSUCCESS: License placed"
            else
                echo -e "\tFAIL: Please manually place license files"
                xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            fi
            # Update Patching Tool - Only if FP
            updatePatchingTool
            patchInstall
            createDB
            updatePortalExtDB
        elif [[ $1 == 'QR' ]]; then
            cp "${LRDIR}"/License/7.4.13.xml "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            if [[ -e ${PROJECTDIR}/$project/$BUNDLED/deploy/7.4.13.xml ]]; then
                echo -e "\tSUCCESS: License placed"
            else
                echo -e "\tFAIL: Please manually place license files"
                xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            fi
            updatePatchingTool
            createDB
            updatePortalExtDB
        else
            cp "${LRDIR}"/License/"$version".xml "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            if [[ -e ${PROJECTDIR}/$project/$BUNDLED/deploy/$version.xml ]]; then
                echo -e "\tSUCCESS: License placed"
            else
                echo -e "\tFAIL: Please manually place license files"
                xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            fi
            updatePatchingTool
            createDB
            updatePortalExtDB
        fi
        echo -e "\tSUCCESS: Completed setup of $project/$BUNDLED"
        echo -e "\n---\n"
        # START BUNDLE OR EXIT SCRIPT
        read -rsn1 -p"Press any key to start $BUNDLED bundle... or Ctrl-C to exit";echo
        cd "${PROJECTDIR}"/"$project"/"$BUNDLED"/tomcat*/bin/ && ./catalina.sh run
    else
        echo -e "\tFAIL: Folder not created"
        echo -e "\tDEBUG: Source ${LRDIR}/${SRC}"
        echo -e "\tDEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
    fi
}

changeMysqlVersion () {
        echo -e "\tCHECK: Current MYSQL Port is $dbPort"
        echo -e "\tAvailable DBDeployer versions:"
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
                echo -e "\tCHECK: 3306 not in $mysqlserverlist -- inserting 3306 as option"
                echo -e "3306" >> $mysqlserverlist
            fi
        echo -e "\t---\n"
        # Define array of available MySQL servers available to choose from  
        mysqlarray=($(cat "$mysqlserverlist"))

        echo -e "[SELECT] Choose DBDeployer MySQL server"
        select mysqlserver in "${mysqlarray[@]}"; do
            DBDserver_DIR=$DBDEPLOYER_HOME/servers/$mysqlserver/
            # echo -e "\tThe DBDeployer server dir is $DBDserver_DIR"
            # UPDATE portal-ext with selected server
            sed -i "s!localhost:.*/SCHEMA!localhost:$mysqlserver/SCHEMA!g" "${LRDIR}"/portal-ext.properties
            echo -e "\tSUCCESS: master portal-ext.properties updated! localhost:${mysqlserver}"
            break
        done
        MYSQLPORTLN=$(grep 'jdbc.default.url' "${LRDIR}"/portal-ext.properties)
        propPrefix='jdbc.default.url=jdbc:mysql://localhost:'
        propSuffix='?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true'
        dbNameA=${MYSQLPORTLN/$propPrefix/}
        dbNameB=${dbNameA/$propSuffix/}
        dbPort=${dbNameB%/*}
        echo -e "\tCHECK: Current MYSQL Port is $dbPort\n---\n"
    }

    setDLR () {
        echo -e "[SELECT] Setup two Liferay bundles?"
        select dlr_choice in "y" "n"; do
            dlr_status=$DBDEPLOYER_HOME/servers/$mysqlserver/
            sed -i "s!localhost:.*/SCHEMA!localhost:$mysqlserver/SCHEMA!g" "${LRDIR}"/portal-ext.properties
            echo -e "\tSUCCESS: master portal-ext.properties updated! localhost:${mysqlserver}"
            break
        done
    }

# --------------------------------------------------------------


if [[ $1 == "config" ]]; then
    echo -e "\nSelect Config to Change:"
    select config_menu in "MySQL" "2LR"; do
        case $config_menu in
            "MySQL")
                changeMysqlVersion
                if [ "$mysqlserver" == '3306' ]; then
                    # This is on by default if mysql installed
                    echo -e "\tMySQL update complete"
                else
                    # Start the DBDeployer server
                    read -rsn1 -p"Press any key to start $mysqlserver server... or Ctrl-C to exit";echo
                    cd "$DBDserver_DIR" && ./start
                fi
                exit
                ;; 
            
            "2LR")
                echo "double setup WIP"
                DLR=true

                exit
                ;;
        esac
    done

elif [[ $# -eq 0 ]]; then
    # if no positional parameter or any other arg given
    echo -e "\tCtrl-C and Run 'quickLR config' to change config settings"
    echo -e "\t---\n"

    # NAME THE PROJECT DIR
    read -p 'Project Code: ' project
    mkdir -p "${PROJECTDIR}"/"$project"/
    if [[ -e "${PROJECTDIR}"/"$project"/ ]]; then
        echo -e "SUCCESS: Project created at ${PROJECTDIR}/$project/"
    else
        echo -e "ERROR: Project dir not created. Please manually make dir."
        xdg-open "${PROJECTDIR}"
    fi



    # Select DXP version
    echo -e "\n---\n[SELECT] Choose Liferay version to install:"
    DXP=("Quarterly Release" "7.4.13" "7.3.10" "7.2.10" "7.1.10" "7.0.10" "6.2" "6.1" "Exit")
    select version in "${DXP[@]}"; do
        versiontrim=${version//.}
        case $version in
            "Quarterly Release")
                if ! [[ $dbPort == '3306' ]]; then
                    changeMysqlVersion
                else
                    echo "INFO: dbPort is $dbPort"
                fi
                versiontrimx=${version// }
                read -p "Select DXP 7.4 $version patch level: " update
                numcheck='^[0-9]+\.q[0-9]+\.[0-9]+'
                until [[ $update =~ ($numcheck) ]]; do
                    echo -e "\tERROR: Invalid Input. Valid Inputs: YYYY.q#.# (ie 2023.q3.0)\n"
                    read -p "Select DXP $version patch level (Update): " update
                done
                updatemysql=${update//./}
                echo -e "\n---\n"
                if [ "$update" == 'master' ]; then
                    SRCTEST=($(find "${LRDIR}"/Branch -maxdepth 2 -type d -name *portal-master* | sort -r | head -2))
                    SRCRAW=${SRCTEST[0]}
                    SRC=$(echo "$SRCRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
                    echo -e "\tDEBUG: SRC location is $SRC"
                    # SRC="Branch/liferay-portal-tomcat-master-all/liferay-portal-master-all"
                    BUNDLED="liferay-dxp-$version-$update"
                    SCHEMA="${versiontrimx}_${project}_$update"
                    createBundle Branch
                elif [ "$update" == 'nightly' ]; then
                    SRCTEST=($(find "${LRDIR}"/Branch -maxdepth 2 -type d -name *nightly* | sort -r | head -2))
                    SRCRAW=${SRCTEST[0]}
                    SRC=$(echo "$SRCRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
                    echo -e "\tDEBUG: SRC location is $SRC"
                    # SRC="Branch/liferay-dxp-tomcat-7.4.13.nightly/liferay-portal-7.4.13.nightly"
                    BUNDLED="liferay-dxp-$version-$update"
                    SCHEMA="${versiontrimx}_${project}_$update"
                    createBundle Branch
                elif [ "$update" == 'q3' ] || [ "$update" == 'q4' ]; then
                    SRCTEST=($(find "${LRDIR}"/7.4.13 -maxdepth 2 -type d -name liferay-dxp-tomcat-*"$update"* | sort -r | head -2))
                    SRCRAW=${SRCTEST[0]}
                    SRC=$(echo "$SRCRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
                    # SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                    # liferay-dxp-tomcat-2023.q4.0-1701894289
                    BUNDLED="liferay-dxp-tomcat-2023.$update"
                    SCHEMA="${versiontrimx}_${project}_U${update}"
                    createBundle Update
                else
                    SRCTEST=($(find "${LRDIR}"/7.4.13 -maxdepth 2 -type d -name liferay-dxp-tomcat-*"$update"* | sort -r | head -2))
                    SRCRAW=${SRCTEST[0]}
                    # echo -e "DEBUG: SRCTEST0 - ${SRCTEST[0]} \n SRCTEST1 - ${SRCTEST[1]}"
                    PRESRC=$(echo "$SRCRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
                    SRC=$PRESRC/liferay-dxp/
                    echo -e "\tDEBUG: SRC location is $SRC"
                    # SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                    BUNDLED="liferay-dxp-tomcat-$update"
                    SCHEMA="QR_${project}_${updatemysql}"
                    createBundle QR
                fi
                break
                ;;
            "7.4.13")
                if ! [[ $dbPort == '3306' ]]; then
                    changeMysqlVersion
                else
                    echo "INFO: dbPort is $dbPort"
                fi
                versiontrimx=${versiontrim//13}
                read -p "Select DXP $version patch level: " update
                numcheck='^[0-9]+$'
                until [[ $update =~ ($numcheck|master|night|q3|q4) ]]; do
                    echo -e "\tERROR: Invalid Input. Valid Inputs: Update or master.\n"
                    read -p "Select DXP $version patch level (Update): " update
                done
                echo -e "\n---\n"
                if [ "$update" == 'master' ]; then
                    SRCTEST=($(find "${LRDIR}"/Branch -maxdepth 2 -type d -name *portal-master* | sort -r | head -2))
                    SRCRAW=${SRCTEST[0]}
                    SRC=$(echo "$SRCRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
                    echo -e "\tDEBUG: SRC location is $SRC"
                    # SRC="Branch/liferay-portal-tomcat-master-all/liferay-portal-master-all"
                    BUNDLED="liferay-dxp-$version-$update"
                    SCHEMA="${versiontrimx}_${project}_$update"
                    createBundle Branch
                elif [ "$update" == 'nightly' ]; then
                    SRCTEST=($(find "${LRDIR}"/Branch -maxdepth 2 -type d -name *nightly* | sort -r | head -2))
                    SRCRAW=${SRCTEST[0]}
                    SRC=$(echo "$SRCRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
                    echo -e "\tDEBUG: SRC location is $SRC"
                    # SRC="Branch/liferay-dxp-tomcat-7.4.13.nightly/liferay-portal-7.4.13.nightly"
                    BUNDLED="liferay-dxp-$version-$update"
                    SCHEMA="${versiontrimx}_${project}_$update"
                    createBundle Branch
                elif [ "$update" == 'q3' ] || [ "$update" == 'q4' ]; then
                    SRCTEST=($(find "${LRDIR}"/7.4.13 -maxdepth 2 -type d -name liferay-dxp-tomcat-*"$update"* | sort -r | head -2))
                    SRCRAW=${SRCTEST[0]}
                    SRC=$(echo "$SRCRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
                    # SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                    # liferay-dxp-tomcat-2023.q4.0-1701894289
                    BUNDLED="liferay-dxp-tomcat-2023.$update"
                    SCHEMA="${versiontrimx}_${project}_U${update}"
                    createBundle Update
                else
                    SRCTEST=($(find "${LRDIR}"/7.4.13 -maxdepth 2 -type d -name liferay-dxp-tomcat-*"$update"* | sort -r | head -2))
                    echo "srctest: $SRCTEST"
                    SRCRAW=${SRCTEST[0]}
                    echo "srcraw: $SRCRAW"
                    PRESRC=$(echo "$SRCRAW" | sed -e "s!/home/dia/Downloads/Liferay/DXP/!!g")
                    SRC=$PRESRC/liferay-dxp-$version.u$update
                    echo "DEBUG SRC: $SRC"
                    # SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
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
                    # -- IF SP = liferay-dxp-tomcat-7.3.10.1-sp1/liferay-dxp-7.3.10.1-sp1
                    SRC="$version/liferay-dxp-tomcat-$version.$update-sp$update/liferay-dxp-$version.$update-sp$update"
                    BUNDLED="liferay-dxp-$version-sp$update"
                    SCHEMA="${versiontrimx}_${project}_SP${update}"
                    createBundle SP
                elif [ "$update" == 'branch' ]; then
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
                if [ "$version" == '7.0.10' ]; then
                    echo -e "\tWARN: Update Config - DXP 7.0 is only compatible with MySQL 5.6 or 5.7."
                    if [[ $dbPort == '3306' ]]; then
                        changeMysqlVersion
                    else
                        echo -e "\tINFO: dbPort is $dbPort"
                    fi
                else
                    echo -e "\tINFO: dbPort is $dbPort"
                fi
                versiontrimx=${versiontrim//10}
                versionshort=${version//.10}
                updateTypeList=("Update" "FP" "SP" "Branch")
                echo -e "[SELECT] Choose an Update Type:"
                select updateType in "${updateTypeList[@]}"; do
                    echo -e "\tCHECK: UpdateType set as $updateType\n---\n"
                    read -p "Select DXP $version patch level: ($updateType)" update
                    numcheck='^[0-9]+$'
                    until [[ $update =~ ($numcheck|branch) ]]; do
                        echo -e "ERROR: Invalid Input. Valid Inputs: Number or branch\n"
                        read -p "Select DXP $version patch level: " update
                    done
                    echo -e "\n---\n"

                    if [ "$update" == 'branch' ]; then
                        SRC="Branch/liferay-portal-tomcat-$versionshort.x-private-all/liferay-portal-$versionshort.x-private-all"
                        BUNDLED="liferay-$versionshort-$update"
                        SCHEMA="${versiontrimx}_${project}_$update"
                        createBundle Branch
                    else
                        if [ "$version" == '7.0.10' ]; then
                            # liferay-dxp-digital-enterprise-tomcat-7.0-ga1/liferay-dxp-digital-enterprise-7.0-ga1
                            if [ "$updateType" = 'FP' ]; then
                                SRC="$version/liferay-dxp-digital-enterprise-tomcat-$versionshort-ga1/liferay-dxp-digital-enterprise-$versionshort-ga1"
                            elif [ "$updateType" = 'SP' ]; then
                                # liferay-dxp-digital-enterprise-tomcat-7.0.10.17-sp17/liferay-dxp-digital-enterprise-7.0.10.17-sp17
                                SRC="$version/liferay-dxp-digital-enterprise-tomcat-$version.$update-sp$update/liferay-dxp-digital-enterprise-$version.$update-sp$update"
                            else 
                                SRC="$version/liferay-dxp-digital-enterprise-tomcat-$versionshort-ga1/liferay-dxp-digital-enterprise-$versionshort-ga1"
                            fi
                            
                            BUNDLED="liferay-dxp-$version.$updateType-$update"
                            SCHEMA="${versiontrimx}_${project}_$updateType${update}"
                            createBundle "$updateType"
                            
                            # Manually place the MySQL JDBC connector since https issue
                            tomcatdir=$(cd "${PROJECTDIR}"/"$project"/"$BUNDLED" && ls | grep tomcat)
                            echo -e "\tINFO: tomcatdir is $tomcatdir"
                            cp "${LRDIR}"/mysql.jar "${PROJECTDIR}"/"$project"/"$BUNDLED"/"$tomcatdir"/lib/ext/
                            if [[ -e "${PROJECTDIR}/$project/$BUNDLED/$tomcatdir/lib/ext/mysql.jar" ]]; then
                                echo -e "\tSUCCESS: MySQL JDBC connector placed at $tomcatdir/lib/ext/mysql.jar"
                            else
                                echo -e "\tFAIL: Please manually place MySQL JDBC connector jar"
                                xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/"$tomcatdir"/lib/ext/
                            fi
                            # Start MySQL 5.7 and update port
                            # dbdeployer deploy single 5.7
                        else
                            if [ "$updateType" = 'FP' ]; then
                                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                            elif [ "$updateType" = 'SP' ]; then
                                SRC="$version/liferay-dxp-tomcat-$version.$update-sp$update/liferay-dxp-$version.$update-sp$update"
                            else 
                                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                            fi

                            BUNDLED="liferay-dxp-$version.$updateType-$update"
                            SCHEMA="${versiontrimx}_${project}_$updateType${update}"
                            createBundle "$updateType"
                        fi
                    fi
                    break
                done
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
                elif [ "$update" == 'branch' ]; then
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
            # "Config")
            #     changeMysqlVersion
            #     if [ $mysqlserver == '3306' ]; then
            #         # This is on by default if mysql installed
            #         echo "Nothing else to do"
            #     else
            #         # Start the DBDeployer server
            #         read -rsn1 -p"Press any key to start $mysqlserver server... or Ctrl-C to exit";echo
            #         cd $DBDserver_DIR && ./start
            #     fi
            #     exit
            #     ;;
            "Exit")
                echo "User requested exit"
                exit
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done

else
    echo "Invalid argument"

fi