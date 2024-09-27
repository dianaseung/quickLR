#!/bin/bash
# Project: Quick LR - Liferay DXP setup automation for Support CSE
# Last Updated: 8/7/2024

# ==============================================================
# --------------------------------------------------------------

# Date format to append
DATE=$(date +%y%m%d%H%M)
# Turn on/off verbose logging (optional, comment out if you want it off by default)
debug_logging=true

echo "refactor branch"

log_echo() {
  if [[ $debug_logging == true ]]; then
    echo -e "[DEBUG] $@"  # Use "$@" to capture all arguments
  fi
}

master_file='liferay-portal-tomcat-master-private-all'
nightly_file='liferay-dxp-tomcat-7.4.13.nightly.tar.gz'

log_echo "LRDIR: $LRDIR"
log_echo "PROJECTDIR: $PROJECTDIR"

if [ -z ${LRDIR+x} ]; then
    echo -e "Run 'quickLR init' first\n---\n"
else
    # [CHECK] MYSL DB VERSION/PORT in portal-ext.properties
    MYSQLPORTLN=$(grep 'jdbc.default.url' "${LRDIR}"/portal-ext.properties)
    propPrefix='jdbc.default.url=jdbc:mysql://localhost:'
    propSuffix='?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true'
    dbNameA=${MYSQLPORTLN/$propPrefix/}
    dbNameB=${dbNameA/$propSuffix/}
    dbPort=${dbNameB%/*}
    log_echo "Current MYSQL Port: $dbPort\n---"
fi

# --------------------------------------------------------------

# FUNCTIONS

lrclean() {
    echo "Cleaning up Temp/Work..."
    rm -rf ./osgi/state/*
    echo "OSGi State Folder Cleared!"
    wait
    rm -rf ./tomcat*/temp/*
    echo "Temp Folder Cleared!"
    wait
    rm -rf ./tomcat*/work/*
    echo "Work Folder Cleared!"
    echo "Temp/Work Folders Cleared!"
}

add_to_bashrc() {
  local variable_name="$1"
  local value="$2"
  echo "export $variable_name=\"$value\"" >> ~/.bashrc
}

downloadPatchingTools() {
    if [ -z ${LRDIR+x} ]; then
        LRDIR="$LRDIRinit"
    else
        log_echo "$LINENO LRDIR is $LRDIC"
    fi

    if [ -z ${PROJECTDIR+x} ]; then
        PROJECTDIR="$projectdir_init"
    else
        log_echo "$LINENO PROJECTDIR is $PROJECTDIR"
    fi

    echo -e "\n---\nDownloading latest Patching Tools to $LRDIR/Patching"
    # Download latest patching-tools
    # from https://releases-cdn.liferay.com/tools/patching-tool/
    latest_4xPT=$(curl -s https://releases-cdn.liferay.com/tools/patching-tool/LATEST-4.0.txt)
    log_echo "$LINENO Latest QR Patching Tool version available: [latest_4xPT] $latest_4xPT"
    
    # if highest available in $LRDIR/Patching != latest_4xPT, wget
    if [ ! -d "$LRDIR/Patching/patching-tool-$latest_4xPT" ]; then
        wget -nH -q --show-progress -P "$LRDIR/Patching" https://releases-cdn.liferay.com/tools/patching-tool/patching-tool-$latest_4xPT.zip
        unzip -q "$LRDIR"/Patching/patching-tool-"$latest_4xPT".zip -d "${LRDIR}"/Patching/patching-tool-"$latest_4xPT"
        if [ -d "$LRDIR/Patching/patching-tool-$latest_4xPT" ]; then
            log_echo "$LINENO Patching Tool $latest_4xPT successfully downloaded and extracted"
        else
            log_echo "$LINENO Something went wrong with Patching Tool extract"
        fi
    else
        log_echo "$LINENO Patching Tool $latest_4xPT already available"
    fi

    latest_3xPT=$(curl -s https://releases-cdn.liferay.com/tools/patching-tool/LATEST-3.0.txt)
    log_echo "[latest_3xPT] $latest_3xPT"

    # if highest available in $LRDIR/Patching != latest_3xPT, wget
    if [ ! -d "$LRDIR/Patching/patching-tool-$latest_3xPT" ]; then
        wget -nH -q --show-progress -P "$LRDIR/Patching" https://releases-cdn.liferay.com/tools/patching-tool/patching-tool-$latest_3xPT.zip
        unzip -q "$LRDIR"/Patching/patching-tool-"$latest_3xPT".zip -d "${LRDIR}"/Patching/patching-tool-"$latest_3xPT"
        if [ -d "$LRDIR/Patching/patching-tool-$latest_3xPT" ]; then
            log_echo "$LINENO Patching Tool $latest_3xPT successfully downloaded and extracted"
        else
            log_echo "$LINENO Something went wrong with Patching Tool extract"
        fi
    else
        log_echo "$LINENO Patching Tool $latest_3xPT already available"
    fi

    latest_2xPT=$(curl -s https://releases-cdn.liferay.com/tools/patching-tool/LATEST-2.0.txt)
    log_echo "[latest_2xPT] $latest_2xPT"

    # if highest available in $LRDIR/Patching != latest_2xPT, wget
    if [ ! -d "$LRDIR/Patching/patching-tool-$latest_2xPT" ]; then
        wget -nH -q --show-progress -P "$LRDIR/Patching" https://releases-cdn.liferay.com/tools/patching-tool/patching-tool-$latest_2xPT.zip
        unzip -q "$LRDIR"/Patching/patching-tool-"$latest_2xPT".zip -d "${LRDIR}"/Patching/patching-tool-"$latest_2xPT"
        if [ -d "$LRDIR/Patching/patching-tool-$latest_2xPT" ]; then
            log_echo "$LINENO Patching Tool $latest_2xPT successfully downloaded and extracted"
        else
            log_echo "$LINENO Something went wrong with Patching Tool extract"
        fi
    else
        log_echo "$LINENO Patching Tool $latest_2xPT already available"
    fi

    log_echo "$LINENO Completed updating downloaded Patching Tools!"
}


init () {
    # Check env
    source ~/.bashrc
    echo -e "Running 'quickLR init'..."
    # [CHE,CK] GLOBAL VARIABLES (set in bashrc)
    if [ -z ${LRDIR+x} ]; then
        # If no LRDIR, PROJECTDIR, prompt desired path
        # if not selected, by default, create directories in ~/
        defaultLRDIR="$HOME/Liferay/DXP"
        echo -e "[Default] If not specified, LRDIR will be set to $defaultLRDIR"
        read -p 'Input Liferay Source Directory path ('LRDIR'): ' LRDIRinit
        LRDIRinit="${LRDIRinit:-$defaultLRDIR}"
        echo -e "\n# quickLR env variables (github.com/dianaseung/quickLR)" >> ~/.bashrc
        add_to_bashrc LRDIR "$LRDIRinit"
        log_echo "$LINENO Liferay Source Dir set to: $LRDIRinit"

        # mkdir Liferay/DXP/
        mkdir -p "$LRDIRinit"
        
        # mkdir Quarterly Release, 7.4, 7.3, 7.2, 7.1, 7.0
        mkdir "$LRDIRinit/Quarterly Release"
        mkdir "$LRDIRinit/7.4.13"
        mkdir "$LRDIRinit/7.3.10"
        mkdir "$LRDIRinit/7.2.10"
        mkdir "$LRDIRinit/7.1.10"
        mkdir "$LRDIRinit/7.0.10"
        mkdir "$LRDIRinit/6.2"
        mkdir "$LRDIRinit/6.1"
        mkdir "$LRDIRinit/Branch"
        mkdir "$LRDIRinit/Patching"
        mkdir "$LRDIRinit/License"
        echo -e "[SUCCESS]: Created LRDIR folders"

        # Copy sample portal-ext.properties from quickLR/sample/
        script_dir=$(dirname "$0")
        cp "$script_dir/sample/portal-ext.properties" "$LRDIRinit/portal-ext.properties"
        echo -e "[SUCCESS]: Copied Portal-ext.properties template"
    else
        echo -e "[CHECK] LRDIR is ${LRDIR}"
    fi

    if [ -z ${PROJECTDIR+x} ]; then
        default_projectdir="$HOME/Liferay/Project"
        echo -e "\n---\n[Default] If not specified, PROJECTDIR will be set to $default_projectdir"
        read -p 'Input Project Directory path ('PROJECTDIR'): (Press enter for default)' projectdir_init
        # Use the provided projectdir or the default
        projectdir_init="${projectdir_init:-$default_projectdir}"

        add_to_bashrc PROJECTDIR "$projectdir_init"
        log_echo "Project directory set to: $projectdir_init"

        # mkdir Liferay/Project
        mkdir "$projectdir_init"
    else
        echo -e "[CHECK] PROJECTDIR is ${PROJECTDIR}"
    fi

    source ~/.bashrc

    # Download latest patching-tools
    downloadPatchingTools

    echo -e "[COMPLETE] quickLR init completed!"
    exec bash
}

checkDestinationDir () {
    # CHECK IF BUNDLE EXISTS ALREADY - append date if so
    if [ -d "${PROJECTDIR}"/"${project}"/"${BUNDLED}" ]; then
        BUNDLED="${BUNDLED}.${DATE}"
        SCHEMA="${SCHEMA}_${DATE}"
        echo -e "WARNING: Project $project with $1 $update folder already exists! Appending date..."
    else
        echo -e "[CHECK] Project $project with $1 $update folder does not exist yet!"
    fi
}

updateServerXML () {
    projectlist=projectlist.txt
    ls "${PROJECTDIR}" > $projectlist
    # Define array of available MySQL servers available to choose from  
    projectarray=($(cat "$projectlist"))

    echo -e "[SELECT] Choose Project"
    select projectname in "${projectarray[@]}"; do
        echo -e "\n---\nProject Name: ${projectname}"
        selected_project=$PROJECTDIR/$projectname/
        echo -e "The selected project dir is $selected_project\n---\n"
        # UPDATE portal-ext with selected server
        # sed -i "s!localhost:.*/SCHEMA!localhost:$projectname/SCHEMA!g" "${LRDIR}"/portal-ext.properties
        break
    done

    bundlelist=bundlelist.txt
    ls "${selected_project}" > $bundlelist
    # Define array of available MySQL servers available to choose from  
    bundlearray=($(cat "$bundlelist"))

    echo -e "[SELECT] Choose Project"
    select bundle in "${bundlearray[@]}"; do
        echo -e "\n---\nBundle Name: ${bundle}"
        selected_bundle=$PROJECTDIR/$projectname/$bundle
        echo -e "The selected bundle dir is $selected_bundle\n---\n"
        break
    done

    FINDSERVERXML=($(find "$selected_bundle" -name server.xml | sort -n | head -2))
    echo -e "Updating the file $FINDSERVERXML"

    # UPDATE server.xml with 9xxx ports
    sed -i "s!8005!9005!g" "${FINDSERVERXML}"
    echo -e "Updated 8005 port to 9005"
    sed -i "s!8080!9080!g" "${FINDSERVERXML}"
    echo -e "Updated 8080 port to 9080"
    sed -i "s!8443!9443!g" "${FINDSERVERXML}"
    echo -e "Updated 8443 port to 9443"
    echo -e "[SUCCESS] Completed updating $projectname server.xml file"

    # Create ES osgi config
    printf 'sidecarHttpPort="AUTO"' > "$selected_bundle"/osgi/configs/com.liferay.portal.search.elasticsearch7.configuration.ElasticsearchConfiguration.config
    echo -e "[SUCCESS] Created osgi config: ES auto sidecar port"
}

applyTunneling () {
    # Append Tunneling properties to portal-ext.properties
    tunnelcheck=$(grep tunnel "$selected_bundle"/portal-ext.properties)
    if [[ $tunnelcheck ]]; then
        echo -e "[INFO] Tunnel properties already exist! Tunnel properties will not be appended."
    else
        echo -e "\ntunnel.servlet.hosts.allowed=127.0.0.1" >> "$selected_bundle"/portal-ext.properties
        echo -e "tunneling.servlet.shared.secret=6162636465666768696a6b6c6d6e6f70" >> "$selected_bundle"/portal-ext.properties
        echo -e "tunneling.servlet.shared.secret.hex=true" >> "$selected_bundle"/portal-ext.properties
        echo -e "[SUCCESS] Appended tunnel properties to portal-ext.properties"
    fi 
}

applyClustering () {
    # Append Clustering properties to portal-ext.properties
        # cluster.link.enabled=true
        # dl.store.impl=com.liferay.portal.store.db.DBStore
        # cluster.link.autodetect.address=localhost:3306
    # ---
    # Future Feature: 
        # Consider prompting master node, slave node
        # master node = append cluster properties to portal-ext.properties
        # cp master's portal-ext.properties to slave 
        # prompt starting master first
    tunnelcheck=$(grep cluster "$selected_bundle"/portal-ext.properties)
    if [[ $tunnelcheck ]]; then
        echo -e "[INFO] Tunnel properties already exist! Tunnel properties will not be appended."
    else
        echo -e "\ncluster.link.enabled=true" >> "$selected_bundle"/portal-ext.properties
        echo -e "dl.store.impl=com.liferay.portal.store.db.DBStore" >> "$selected_bundle"/portal-ext.properties
        echo -e "cluster.link.autodetect.address=localhost:3306" >> "$selected_bundle"/portal-ext.properties
        echo -e "[SUCCESS] Appended clustering properties to portal-ext.properties"
    fi 
}


hotfixInstall() {
if [[ -f *.zip ]]; then
    ./patching-tool.sh info 
    ./patching-tool.sh install 
    ./patching-tool.sh info 
    cd .. 
    lrclean 
    startTomcat
else
    echo "[ERROR] Something went wrong with hotfix install"
fi
}
startTomcat() {
    cd tomcat*/bin && ./catalina.sh run
}

patchBundle() {
    current_dir="$(basename "$PWD")"
    if [[ $current_dir =~ "patching-tool" ]]; then
        patchStart
    elif [[ $current_dir =~ "patches" ]]; then
        cd ..
        patchStart
    else
        cd $PROJECTDIR/
        echo "[ERROR]: Run "
    fi
}

startLR () {
    projectlist=projectlist.txt
    ls "${PROJECTDIR}" > $projectlist
    # Define array of available MySQL servers available to choose from  
    projectarray=($(cat "$projectlist"))

    echo -e "[SELECT] Choose Project"
    select projectname in "${projectarray[@]}"; do
        echo -e "\n---\nProject Name: ${projectname}"
        selected_project=$PROJECTDIR/$projectname/
        echo -e "The selected project dir is $selected_project\n---\n"
        # UPDATE portal-ext with selected server
        # sed -i "s!localhost:.*/SCHEMA!localhost:$projectname/SCHEMA!g" "${LRDIR}"/portal-ext.properties
        break
    done

    bundlelist=bundlelist.txt
    ls "${selected_project}" > $bundlelist
    # Define array of available MySQL servers available to choose from  
    bundlearray=($(cat "$bundlelist"))

    echo -e "[SELECT] Choose Project"
    select bundle in "${bundlearray[@]}"; do
        echo -e "\n---\nBundle Name: ${bundle}"
        selected_bundle=$PROJECTDIR/$projectname/$bundle
        echo -e "The selected bundle dir is $selected_bundle\n---\n"
        break
    done

    echo -e "\n---\n"
    # START BUNDLE OR EXIT SCRIPT
    read -rsn1 -p"Press any key to start $selected_bundle bundle... or Ctrl-C to exit";echo
    cd "${selected_bundle}"
    cd patching-tool/

    cd "${selected_bundle}"
    startTomcat
    # google-chrome --incognito http://localhost:8080
}

updatePatchingTool () {
    # REMOVE PATCHING-TOOL DIR
    # use readlink instead
    rm -rf "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
    # INSTALL LATEST PATCHING TOOL BASED ON VERSION
    if [[ $version == "Quarterly Release" ]]; then
        # v4.0.x PATCHING TOOL
        FINDPATCHDIR=($(find "${LRDIR}"/Patching -maxdepth 2 -type d -name patching-tool-4.0.* | sort -n | head -2))
        PATCHDIRRAW=${FINDPATCHDIR[-1]}
        PATCHDIR=$(echo "$PATCHDIRRAW" | sed -e "s!$LRDIR!!g")
        cp -rf "${LRDIR}"/"$PATCHDIR"/patching-tool/ "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
        echo -e "[SUCCESS] Updated the Patching Tool folder to $PATCHDIR"
    elif [[ $version == "7.4.13" ]] || [[ $version == "7.3.10" ]]; then
        # v3.0.x PATCHING TOOL
        FINDPATCHDIR=($(find "${LRDIR}"/Patching -maxdepth 2 -type d -name patching-tool-3.0.* | sort -n | head -2))
        PATCHDIRRAW=${FINDPATCHDIR[-1]}
        PATCHDIR=$(echo "$PATCHDIRRAW" | sed -e "s!$LRDIR!!g")
        cp -rf "${LRDIR}"/"$PATCHDIR"/patching-tool/ "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
        echo -e "[SUCCESS] Updated the Patching Tool folder to $PATCHDIR"
    else
        # v2.0.x PATCHING TOOL
        FINDPATCHDIR=($(find "${LRDIR}"/Patching -maxdepth 2 -type d -name patching-tool-2.0.* | sort -n | head -2))
        PATCHDIRRAW=${FINDPATCHDIR[-1]}
        PATCHDIR=$(echo "$PATCHDIRRAW" | sed -e "s!$LRDIR!!g")
        cp -r "${LRDIR}"/"$PATCHDIR"/patching-tool/ "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
        echo -e "[SUCCESS] Updated the Patching Tool folder to $PATCHDIR"
    fi
}

createDB () {
    # MAKE THE MYSQL SCHEMA
    echo -e "Starting to create MySQL database..."
    if [[ $dbPort == '3306' ]]; then
        mysql -e "CREATE SCHEMA ${SCHEMA};"
        CHECKDB=$(mysql -e "SHOW DATABASES" | grep "$SCHEMA")
    else
        mysql --socket=/tmp/mysql_sandbox"$dbPort".sock --port "$dbPort" -e "CREATE SCHEMA ${SCHEMA};"
        CHECKDB=$(mysql --socket=/tmp/mysql_sandbox"$dbPort".sock --port "$dbPort" -e 'SHOW DATABASES;' | grep "${SCHEMA}")
    fi
    # echo -e "mysql -u${MYSQLUSER} -e "CREATE SCHEMA ${SCHEMA};"
    log_echo "$LINENO Checking if ${CHECKDB} exists on $dbPort"
    # TODO: fix case sensitivity
    if [[ $CHECKDB == "$SCHEMA" ]]; then
        echo -e "[SUCCESS] Created database ${SCHEMA}"
    else
        echo -e "[ERROR] Database ${SCHEMA} not created. Please create manually."
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
        echo -e "[SUCCESS] Portal-ext changed for 7.0 MySQL, DBDeployer login used"
    else
        sed -i "s/DBUSER/$MYSQLUSER/g" "${PROJECTDIR}"/"$project"/"$BUNDLED"/portal-ext.properties
        sed -i "s/DBPW/$MYSQLPW/g" "${PROJECTDIR}"/"$project"/"$BUNDLED"/portal-ext.properties
    fi
    echo -e "[SUCCESS] Updated portal-ext.properties with $SCHEMA"
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
        echo -e "[SUCCESS] Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP\n\tStarting Fix Pack Installation...\n---\n"
        ( cd "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/ && ./patching-tool.sh install && ./patching-tool.sh info)
        # CLEAN TEMP FILES
        ( cd "${PROJECTDIR}"/"$project"/"$BUNDLED" && lrclean)
        echo -e "\n---\n\t[SUCCESS] Fix Pack dxp-$update install completed! Temp Folders cleaned"
    else
        echo -e "[ERROR] Fix Pack not placed. Please manually install Fix Pack."
        xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/patching-tool/
    fi
}

checkSRCdir () {
    echo -e "[checkSRCdir] - Checking if Source DXP directory exists."
    log_echo "$LINENO Parameter passed: 1 is $1 / version is $version"
    if [[ $version == 'Branch' ]]; then
        SRCDIR_FINDS=$(find "${LRDIR}"/"$version" -maxdepth 2 -type d -name $master_file* | sort -r | head -2)
    elif [[ $1 == 'QR' ]]; then
        # For QR?
        SRCDIR_FINDS=$(find "${LRDIR}"/"$version" -maxdepth 2 -type d -name liferay-dxp-tomcat-"$update"* | sort -r | head -2)
    elif [[ $1 == 'Update' ]]; then
        # For Update releases
        SRCDIR_FINDS=$(find "${LRDIR}"/"$version" -maxdepth 2 -type d -name liferay-dxp-tomcat-"$version".u"$update"* | sort -r | head -2)
    elif [[ $version == '6.2' ]]; then
        # "liferay-portal-tomcat-$version-ee-sp$update-*.zip" or use file_format
        log_echo "$LINENO $version SRCDIR_FIND"
        SRCDIR_FINDS=$(find "${LRDIR}"/"$version" -maxdepth 2 -type d -name liferay-portal-tomcat-$version.ee-sp$update* | sort -r | head -2)
    elif [[ $1 == 'SP' ]]; then
        # liferay-dxp-tomcat-$version-sp$update
        SRCDIR_FINDS=$(find "${LRDIR}"/"$version" -maxdepth 2 -type d -name liferay-dxp-tomcat-"$version".$update-sp"$update"* | sort -r | head -2)
    else    
        # liferay-dxp-tomcat-$version-sp$update
        SRCDIR_FINDS=$(find "${LRDIR}"/"$version" -maxdepth 2 -type d -name liferay-dxp-tomcat-"$version"-ga1* | sort -r | head -2)
    fi

    for key in "${!SRCDIR_FINDS[@]}"
        do
        log_echo "All Results of SRC dir find: Key '$key'  => Value '${SRCDIR_FINDS[$key]}'"
        done
    SRCRAW=${SRCDIR_FINDS[0]}
    log_echo "$LINENO Selecting first result of SRC dir find => $SRCRAW"
    src_basename_test=$(basename -- "$SRCRAW")
    echo "$LINENO basename SRCRAW $src_basename_test"
    SRC_PROCESSED=$(echo "$SRCRAW" | sed -e "s!$LRDIR!!g")
    # SRC_PROCESSED=$(basename -- "$SRCRAW")
    log_echo "$LINENO SRC_PROCESSED: $SRC_PROCESSED"
    if [[ $update == 'master' ]]; then
        SRC=$SRC_PROCESSED/liferay-portal-master-private-all/
    elif [[ $1 == 'QR' ]]; then
        SRC=$SRC_PROCESSED/liferay-dxp/
    elif [[ $1 == 'Update' ]]; then
        SRC=$SRC_PROCESSED/liferay-dxp-$version.u$update/
    elif [[ $version == '6.2' ]]; then
        # liferay-portal-6.2-ee-sp20
        SRC=$SRC_PROCESSED/liferay-portal-$version-ee-sp$update/
    elif [[ $1 == 'SP' ]]; then
        SRC=$SRC_PROCESSED/liferay-dxp-$version.$update-sp$update/
    else
        SRC=$SRC_PROCESSED/liferay-dxp-$version-ga1/
    fi

    # if [[ -d "$SRC" ]]; then
    #     echo "[CHECK] SRC IS VALID"
    # else
    #     SRC=$SRC_PROCESSED/liferay-dxp/
    # fi

    log_echo "$LINENO Final SRC location => $SRC"
}

checkArchive () {
    echo -e "[checkArchive] - Checking if .zip or .tar.gz archive file exists."
    log_echo "$LINENO Parameters passed: 1 is $1 ; BUNDLED = $BUNDLED"
    # First search for the archive file (whether zip or tar.gz) to extract
    log_echo "$LINENO Looking in $LRDIR/$version for $1"
    if [[ $update == 'master' ]]; then
        archive_find=$(find "${LRDIR}"/Branch -maxdepth 1 -name $master_file.tar.gz | sort -r | head -2)
    elif [[ $1 == 'QR' ]]; then
        archive_find=$(find "${LRDIR}"/"$version"/ -maxdepth 1 -name liferay-dxp-tomcat-"$update"-*.* | sort -r | head -2)
    elif [[ $1 == 'Update' ]]; then
        archive_find=$(find "${LRDIR}"/"$version"/ -maxdepth 1 -name liferay-dxp-tomcat-"$version"*u"$update"-*.* | sort -r | head -2)
    elif [[ $version == '6.2' ]]; then 
        # "liferay-portal-tomcat-$version-ee-sp$update-*.zip" or use file_format
        archive_find=$(find "${LRDIR}"/"$version"/ -maxdepth 1 -name liferay-portal-tomcat-$version-ee-sp"$update"*.* | sort -r | head -2)
    elif [[ $1 == 'SP' ]]; then
        archive_find=$(find "${LRDIR}"/"$version"/ -maxdepth 1 -name liferay-dxp-tomcat-$version.$update-sp"$update"*.* | sort -r | head -2)
    else
        archive_find=(`find "${LRDIR}"/"$version"/ -maxdepth 1 -name liferay-dxp-tomcat-"$version"-ga1*.*`)
    fi

    
    # For debugging purposes: Display the found file
    for key in "${!archive_find[@]}"
        do
        log_echo "$LINENO Archive Find Result: Key $key => Value ${archive_find[$key]}"
        done

    # Select the first result; ideally there should only be one result
    archive_file=${archive_find[0]}
    log_echo "$LINENO archive_file: $archive_file"
    archive_final=$(echo "$archive_file" | sed -e "s!$LRDIR/$version/!!g")
    log_echo "$LINENO archive_final: $archive_final"
}

downloadArchive () {
    log_echo "$LINENO Parameter passed: 1 is $1"
    if [[ -f $archive_find ]]; then
        echo "[Archive found] zip or tar.gz file found, skip download. Next step: extract file"
    else
        echo "[Archive not found] Attempting download from releases-cdn.liferay.com..."
        curlCheck $1
        checkArchive $1
    fi
}

curlCheck () {
    echo -e "[curlCheck] - Check if Liferay is up first"
    status="$(curl -Is https://releases-cdn.liferay.com/ | head -1)"
    validate=( $status )
    if [ "${validate[-2]}" == "200" ]; then
        echo "OK"
        downloadBundle $1
    else
        echo "NOT RESPONDING -- Liferay may be down."
    fi
}

# Use this for validating $update later
# -----------------------------------------------------------------------

# Define empty arrays for versions
declare -a versions_qr=()
declare -a versions_74=()
declare -a versions_73=()
declare -a versions_72=()
declare -a versions_71=()
declare -a versions_70=()

getReleaseTags() {
    # URL to fetch DXP Release targetPlatformVersion
    url="https://releases-cdn.liferay.com/releases.json"

    # Capture JSON data using curl (more reliable than wget)
    json_data=$(curl -sSL "$url")

    # Check for successful retrieval
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to retrieve data from $url"
        exit 1
    fi

    # Extract tag names using jq (assuming jq is installed)
    release_tag_list=()
    while read -r name; do
        if [[ -n "$name" && ! " ${release_tag_list[*]} " =~ " $name " ]]; then
            release_tag_list+=("$name")
        fi
    done < <(jq -r '.[] | .targetPlatformVersion' <<< "$json_data")
}

sortReleaseTags() {
    for release_tag in "${release_tag_list[@]}"; do
        if [[ "$release_tag" =~ ^[0-9]+\.q[0-9]+\.[0-9]+ ]]; then
            versions_qr+=("$release_tag")
        elif [[ "$release_tag" =~ ^7.4.13 ]]; then
            versions_74+=("$release_tag")
        elif [[ "$release_tag" =~ ^7.3.10 ]]; then
            versions_73+=("$release_tag")
        elif [[ "$release_tag" =~ ^7.2.10 ]]; then
            versions_72+=("$release_tag")
        elif [[ "$release_tag" =~ ^7.1.10 ]]; then
            versions_71+=("$release_tag")
        elif [[ "$release_tag" =~ ^7.0.10 ]]; then
            versions_70+=("$release_tag")
        fi
    done
}

printReleaseTags() {
    # Print the tags
    echo "Available Tags:"
    # for tag in "${release_tag_list[@]}"; do
    #     echo -e "  - $tag"
    # done
    echo "${release_tag_list[@]}"

    # Print the contents of the versions_QR array (optional)
    echo -e "\n---\nVersions in QR array:"
    # echo "${versions_qr[@]}"
    for tag in "${versions_qr[@]}"; do
        echo -e "  - $tag"
    done

    # Print the contents of the versions_74 array (optional)
    echo "Versions in 7.4 array:"
    echo "${versions_74[@]}"

    # Print the contents of the versions_73 array (optional)
    echo "Versions in 7.3 array:"
    echo "${versions_73[@]}"

    # Print the contents of the versions_72 array (optional)
    echo "Versions in 7.2 array:"
    echo "${versions_72[@]}"

    # Print the contents of the versions_71 array (optional)
    echo "Versions in 7.1 array:"
    echo "${versions_71[@]}"

    # Print the contents of the versions_70 array (optional)
    echo "Versions in 7.0 array:"
    echo "${versions_70[@]}"

}

selectReleaseTag() {
    # Example: Print tags with specific prefix (modify as needed)
    if [[ $# -gt 0 ]]; then
    prefix="$1"
    echo "Tags starting with '$prefix':"
    for tag in "${release_tag_list[@]}"; do
        if [[ "$tag" =~ ^"$prefix" ]]; then
        echo "  - $tag"
        fi
    done
    fi
}

checkValidDXP() {
    echo -e "Pulling all current Liferay DXP Release Tags: https://releases-cdn.liferay.com/releases.json"
    getReleaseTags
    sortReleaseTags
    # printReleaseTags
    read -p "Input Release Tag: " release_tag

    until [[ -n "$release_tag" ]]; do
        echo "Input cannot be empty."
        read -p "Input Release Tag: " release_tag
    done

    while [[ ! " ${release_tag_list[@]} " =~ " $release_tag " ]]; do
        echo -e "[ERROR] Invalid Release Tag. Did you mean:\n"
        selectReleaseTag $release_tag

        # Ask user again to input docker tag
        read -p "Input Release Tag: " release_tag
        if [[ "$release_tag" == "" ]]; then
            echo "Input cannot be empty."
        fi
    done

    echo -e "\033[31m\nFinal Release Tag Choice:\033[0m $release_tag"

    echo -e "FYI: Other related docker tags:"
    selectReleaseTag $release_tag
}

# -----------------------------------------------------------------------------------------------------------------------------------

extractBundle () {
    # needs a checkArchive first
    echo -e "[extractBundle] - Unzipping the .tar.gz or .zip archive file."
    # Extract the file depending if it's .tar.gz or .zip (all other formats invalidated)
    if [[ -f "$LRDIR/$version/$archive_final" ]]; then
        case "$archive_final" in
            *.tar.gz)
                log_echo  "307: LR $version $update file finished downloading in $LRDIR/$version/$archive_final"
                mkdir "${LRDIR}"/"$version"/"$BUNDLED"
                log_echo "$LINENO Extracting to $LRDIR/$version/$BUNDLED..."
                if [[ -e "${LRDIR}/$version/$BUNDLED" ]]; then
                    tar xf "$LRDIR"/"$version"/"$archive_final" -C "${LRDIR}"/"$version"/"$BUNDLED"
                    log_echo "$LINENO File $LRDIR/$version/$archive_final was extracted to $LRDIR/$version/$BUNDLED"
                else
                    echo -e "[ERROR]: Not properly extracted, manually extract"
                fi
                # rm "$LRDIR/$version/$archive_final"
                ;;
            *.zip)
                echo "LR $version $update file finished downloading in $LRDIR/$version/$archive_final"
                mkdir "${LRDIR}"/"$version"/"$BUNDLED"
                if [[ -e "${LRDIR}/$version/$BUNDLED" ]]; then
                    # unzip filename.zip -d /path/to/directory
                    unzip -q "$LRDIR"/"$version"/"$archive_final" -d "${LRDIR}"/"$version"/"$BUNDLED"
                    log_echo "$LINENO File $LRDIR/$version/$archive_final was extracted to $LRDIR/$version/$BUNDLED"

                else
                    echo -e "[ERROR]: Not properly extracted, manually extract"
                fi
                # rm "$LRDIR/$version/$archive_final"
                ;;
            *)
                echo -e "[ERROR]: Unknown file format in $archive_final, not extracted"
                ;;
        esac
    else
        echo -e "[ERROR]: File not written to disk: $archive_final"
    fi
if [ -d "${LRDIR}"/"$version"/"$BUNDLED" ]; then
    echo "[Extract Successful] Unzip completed. Next step: Copying from $SRC"
else
    echo "[Extract Fail] Something went wrong."
fi
}

downloadBundle () {
    echo -e "[downloadBundle] - Download file from Liferay"
    if [[ $update == 'master' ]]; then
        log_echo -e "$LINENO Master file is $master_file.tar.gz"
        file_format=$master_file
        master_download_url=https://releases.liferay.com/portal/snapshot-master-private/latest/
        url=$master_download_url
        dl_tar_dir=$LRDIR/Branch
    elif [[ $1 == 'QR' ]]; then
        file_format="liferay-dxp-tomcat-$update-*"
        qr_download_url=https://releases-cdn.liferay.com/dxp/$update/
        url=$qr_download_url
        dl_tar_dir=$LRDIR/$version
    elif [[ $1 == 'Update' ]]; then
        file_format=liferay-dxp-tomcat-$version*u$update-*
        update_download_url=https://releases-cdn.liferay.com/dxp/$version-u$update/
        url="$update_download_url"
        dl_tar_dir="$LRDIR/$version"
    elif [[ $version == '6.2' ]]; then
        # https://releases-cdn.liferay.com/dxp/6.2.10.21/liferay-portal-tomcat-6.2-ee-sp20-20170717160924965.zip
        file_format="liferay-portal-tomcat-$version-ee-sp$update-*"
        portal_update=$((update + 1))
        sp_download_url=https://releases-cdn.liferay.com/dxp/$version.10.$portal_update/
        url=$sp_download_url
        dl_tar_dir=$LRDIR/$version
    elif [[ $1 == 'SP' ]]; then
        # https://releases.liferay.com/dxp/7.2.10.7/liferay-dxp-tomcat-7.2.10.7-sp7-20220627032045494.tar.gz
        file_format="liferay-dxp-tomcat-$version.$update-sp$update-*"
        sp_download_url=https://releases-cdn.liferay.com/dxp/$version.$update/
        url=$sp_download_url
        dl_tar_dir=$LRDIR/$version
    else
        echo "DXP releases under 7.3 not supported yet"
    fi
    
    zip_file_format="$file_format.tar.gz"
    # Check first if .tar.gz file exists
    log_echo "checking spider if file exists on releases - $url/$file_format"
    wget -S --spider -A "$zip_file_format" "$url" &> /dev/null

    if [[ $? -eq 0 ]]; then
        log_echo "Continuing to download .tar.gz $file_format..."
    else
        zip_file_format="$file_format.zip"
        log_echo ".tar.gz file doesn't exist, Downloading $file_format instead."
    fi

    log_echo "$version file_format = $zip_file_format ; url = $url ; dl_tar_dir = $dl_tar_dir"
    echo -e "\n---\n$1 File WGET downloading to $dl_tar_dir (Indexes auto-rejected)"
    wget -r -np -nd -nH -q --show-progress -A "$zip_file_format" "$url" -P "$dl_tar_dir"
}

createBundle () {
    makeProjectDir

    # Set Defaults
    if [[ $update == 'master' ]]; then
        log_echo -e "$LINENO Master file is $master_file.tar.gz"
        file_format=$master_file
    elif [[ $1 == 'QR' ]]; then
        file_format="liferay-dxp-tomcat-$update-*"
    elif [[ $1 == 'Update' ]]; then
        file_format=liferay-dxp-tomcat-$version*u$update-*
    elif [[ $version == '6.2' ]]; then
        file_format="liferay-portal-tomcat-$version-ee-sp$update-*"
    elif [[ $1 == 'SP' ]]; then
        file_format="liferay-dxp-tomcat-$version.$update-sp$update-*"
    else
        file_format="liferay-dxp-*"
    fi

    echo -e "[createBundle] - Start creating Project bundle"
    checkDestinationDir "$1"
    if [[ $update == 'master' ]]; then
        echo "[CHECK] check if master exists; if not, download today's master..."
        checkSRCdir $1
        checkArchive $1
        downloadArchive $1
        extractBundle
        MASTER_FIND=$(find "${LRDIR}"/Branch -maxdepth 2 -type d -name *"$update"* | sort -r | head -2)
        for key in "${!MASTER_FIND[@]}"
            do
            log_echo "$LINENO Result $key) ${MASTER_FIND[$key]}"
            done
        MASTER_GRAB=${MASTER_FIND[0]}
        log_echo "$LINENO First result of master find: $MASTER_GRAB"
        MASTER_RAW=$(echo "$MASTER_GRAB" | sed -e "s!$LRDIR!!g")
        MASTER_RESULT=$MASTER_RAW/liferay-dxp/
        cp -r "${LRDIR}"/"$MASTER_RESULT"/ "${PROJECTDIR}"/"$project"/"$BUNDLED"
    else
        checkSRCdir $1
        if [ -d "${LRDIR}"/"$SRC" ]; then
            echo "[SRC Directory found] Copying from $SRC"
            log_echo "$LINENO copying from $LRDIR/$SRC"
            cp -r "${LRDIR}"/"$SRC" "${PROJECTDIR}"/"$project"/"$BUNDLED"
        else
            echo "[SRC Directory not found] Checking if archive file (zip or tar.gz) exists in $version"
            checkArchive $1
            downloadArchive $1
            extractBundle
            checkSRCdir $1
            if [ -d "${LRDIR}"/"$SRC" ]; then
                echo "[SRC Directory found] Copying to Project bundle"
                if [[ $1 == 'QR' ]]; then
                    cp -r "${LRDIR}"/"$version"/"$BUNDLED"/liferay-dxp/ "${PROJECTDIR}"/"$project"/"$BUNDLED"
                else
                    cp -r "${LRDIR}"/"$SRC"/ "${PROJECTDIR}"/"$project"/"$BUNDLED"
                fi
            else
                echo "[SRC Directory not found] Something went wrong."
            fi
        fi
    fi
    # place portal-ext, install license ... if dest dir exists
    if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
        echo -e "\n---\n[SUCCESS] DXP $version $1 $update folder created at $project/$BUNDLED"
        # Install Portal-Ext - Always Needed
        cp "${LRDIR}"/portal-ext.properties "${PROJECTDIR}"/"$project"/"$BUNDLED"/
        if [[ -e ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties ]]; then
            echo -e "[SUCCESS] Portal-ext file placed in new bundle"
        else
            echo -e "[ERROR] Please manually place portal-ext file"
            xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/
        fi
        # Install License - Only if !branch / + Update Patching Tool, Create DB, Update Portal-Ext
        if [[ $1 == 'Branch' ]]; then
            echo -e "INFO: No license needed for Branch/Master"
            createDB
            updatePortalExtDB
        elif [[ $1 == 'FP' ]]; then
            cp "${LRDIR}"/License/"$version".xml "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            if [[ -e ${PROJECTDIR}/$project/$BUNDLED/deploy/$version.xml ]]; then
                echo -e "[SUCCESS] License XML placed in deploy folder"
            else
                echo -e "[ERROR] Please manually place license files"
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
                echo -e "[SUCCESS] License placed"
            else
                echo -e "[ERROR] Please manually place license files"
                xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            fi
            updatePatchingTool
            createDB
            updatePortalExtDB
        else
            cp "${LRDIR}"/License/"$version".xml "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            if [[ -e ${PROJECTDIR}/$project/$BUNDLED/deploy/$version.xml ]]; then
                echo -e "[SUCCESS] License placed"
            else
                echo -e "[ERROR] Please manually place license files"
                xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/deploy/
            fi
            updatePatchingTool
            createDB
            updatePortalExtDB
        fi
        
        # if 7.0, Manually place the MySQL JDBC connector since https issue
        if [ "$version" == '7.0.10' ]; then
            tomcatdir=$(cd "${PROJECTDIR}"/"$project"/"$BUNDLED" && ls | grep tomcat)
            echo -e "INFO: tomcatdir is $tomcatdir"
            cp "${LRDIR}"/mysql.jar "${PROJECTDIR}"/"$project"/"$BUNDLED"/"$tomcatdir"/lib/ext/
            if [[ -e "${PROJECTDIR}/$project/$BUNDLED/$tomcatdir/lib/ext/mysql.jar" ]]; then
                echo -e "[SUCCESS] MySQL JDBC connector placed at $tomcatdir/lib/ext/mysql.jar"
            else
                echo -e "[ERROR] Please manually place MySQL JDBC connector jar"
                xdg-open "${PROJECTDIR}"/"$project"/"$BUNDLED"/"$tomcatdir"/lib/ext/
            fi
            # Start MySQL 5.7 and update port
            # dbdeployer deploy single 5.7
        else
            echo -e "[INFO]: No additional JDBC connector placed"
        fi
        echo -e "[SUCCESS] Completed setup of $project/$BUNDLED\n"
        # START BUNDLE OR EXIT SCRIPT
        read -rsn1 -p"Press any key to start $BUNDLED bundle... or Ctrl-C to exit";echo
        echo -e "\n---\n"
        cd "${PROJECTDIR}"/"$project"/"$BUNDLED"
        startTomcat
    else
        echo -e "[ERROR] Folder not created"
        log_echo "$LINENO Source ${LRDIR}/${SRC}"
        log_echo "$LINENO Destination ${PROJECTDIR}/$project/$BUNDLED"
    fi
}

changeMysqlVersion () {
    log_echo "\n---\nFn : changeMysqlVersion"
    echo -e "[CHECK] Current MYSQL Port is $dbPort"
    echo -e "Available DBDeployer versions:"
    dbdeployer versions
    # Send list of installed DBDeployer servers to .txt
    # TODO: check if dbdeployer; if yes, use SANDBOX_HOME / if no, 3306?
    mysqlserverlist=mysqlserverlist.txt
    ls "${DBDEPLOYER_HOME}/servers/" > $mysqlserverlist
    # Check if 3306 in server list, if not add
    if grep -Fxq "3306" $mysqlserverlist
        then
            echo -e "[CHECK] 3306 already in $mysqlserverlist"
        else
            echo -e "[CHECK] 3306 not in $mysqlserverlist -- inserting 3306 as option"
            echo -e "3306" >> $mysqlserverlist
        fi
    echo -e "---\n"
    # Define array of available MySQL servers available to choose from  
    mysqlarray=($(cat "$mysqlserverlist"))

    echo -e "[SELECT] Choose DBDeployer MySQL server"
    select mysqlserver in "${mysqlarray[@]}"; do
        DBDserver_DIR=$DBDEPLOYER_HOME/servers/$mysqlserver/
        # echo -e "The DBDeployer server dir is $DBDserver_DIR"
        # UPDATE portal-ext with selected server
        sed -i "s!localhost:.*/SCHEMA!localhost:$mysqlserver/SCHEMA!g" "${LRDIR}"/portal-ext.properties
        echo -e "[SUCCESS] master portal-ext.properties updated! localhost:${mysqlserver}"
        break
    done
    MYSQLPORTLN=$(grep 'jdbc.default.url' "${LRDIR}"/portal-ext.properties)
    propPrefix='jdbc.default.url=jdbc:mysql://localhost:'
    propSuffix='?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true'
    dbNameA=${MYSQLPORTLN/$propPrefix/}
    dbNameB=${dbNameA/$propSuffix/}
    dbPort=${dbNameB%/*}
    echo -e "[CHECK] Current MYSQL Port is $dbPort\n---\n"
    # Add logic to check query i.e. show databases and if null, execute start command
    if [ "$dbPort" == '3306' ]; then
        # This is on by default if mysql installed
        echo -e "MySQL update complete"
    else
        # Start the DBDeployer server
        read -rsn1 -p"Press any key to start $mysqlserver server... or Ctrl-C to exit";echo
        cd "$DBDserver_DIR" && ./start
    fi
}

setDLR () {
    log_echo "\n---\nFn : setDLR"
    echo -e "[SELECT] Setup two Liferay bundles?"
    select dlr_choice in "y" "n"; do
        dlr_status=$DBDEPLOYER_HOME/servers/$mysqlserver/
        sed -i "s!localhost:.*/SCHEMA!localhost:$mysqlserver/SCHEMA!g" "${LRDIR}"/portal-ext.properties
        echo -e "[SUCCESS] master portal-ext.properties updated! localhost:${mysqlserver}"
        break
    done
}

help() {
    echo "Usage: $0 [-h|--help] [-s|--setup] [-i|--init] [-f|--file <filename>]"
    echo "  -h|--help  Show this help message"
    echo "  -s|--setup  Perform setup operations"
    echo "  -i|--init   Perform initialization"
    echo "  -f|--file  Specify a file (optional)"
    echo "Usage: $0 [options]"
    echo "  -h, --help  Display this help message"
    echo "  -o, --option  Do something with an option"
    echo "  -c, --clean  Do something with an option"
    echo "  -p, --patching  Update Patching Tools"
    echo -e "The following options are available to use for: quickLR [option]"
    echo -e "\t[option]: (Description)"
    echo -e "\t---------------------------------------------------"
    echo -e "\tstart: start existing Liferay bundles in Projects dir"
    echo -e "\tclean: run cleanup script to delete Liferay bundles and MySQL dbs" 
    echo -e "\tconfig: change MySQL version or choose double setup"
    echo -e "\tserverxml: change ports from 8xxx to 9xxx in server.xml"
}


# ---
options="hsifpcms:"  # Define the options (h for help, s for setup, i for init, f for file)

while getopts "$options" opt; do
    case "$opt" in
        h)
            help
            exit;;
        s)
            startLR
            exit;;
        i)
            init
            exit;;
        f)
            file="$OPTARG"
            echo "File specified: $file"
            # Your code to process the file
            exit;;
        p)
            patch
            exit;;
        c)
            echo -e "Running cleanup script: delete Project folder(s) and associated MySQL DB(s)\n---\n"
            bash ./cleanup.sh
            echo "Finished running cleanup"
            exit;;
        m)
            mod_menu=("clustering" "staging")
            echo "[INFO] Mod DXP: $mod_menu[0], $mod_menu[1]"
            select mod_apply in "${mod_menu[@]}"; do
                case $mod_apply in
                "clustering")
                    updateServerXML
                    applyClustering
                    ;;
                "staging")
                    updateServerXML
                    applyTunneling
                    ;;
                esac        
            done
            exit;;
        s)
            startLR
            exit;;
        \?)
            echo "Invalid option: -$OPTARG"
            exit;;
    esac
done
# ---

makeProjectDir() {
    mkdir -p "${PROJECTDIR}"/"$project"/
    if [[ -e "${PROJECTDIR}"/"$project"/ ]]; then
        echo -e "[SUCCESS] Project started at ${PROJECTDIR}/$project/"
    else
        echo -e "ERROR: Project dir not created. Please manually make dir."
        xdg-open "${PROJECTDIR}"
    fi
}


if [ -z ${LRDIR+x} ]; then
    init
    exec bash
else
    # NAME THE PROJECT DIR, if not passed through $1 already
    if [[ -n $1 ]]; then
        project=$1
    # elif [[ $# -eq 0 ]]; then
    else
        echo "Tip: For faster setup, use: $0 [Project Name]"
        echo "[EXAMPLE] quickLR CHICAGOLCS"

        read -p 'Project Code: ' project
    fi

    until [[ -n "$project" ]]; do
        read -p 'Project Code: ' project
    done 
    project=$(echo "$project" | tr '[:lower:]' '[:upper:]')
    echo "Project $project"

    # Select DXP version
    echo -e "\n---\n[SELECT] Choose Liferay version to install:"
    DXP=("Branch" "Quarterly Release" "7.4.13" "7.3.10" "7.2.10" "7.1.10" "7.0.10" "6.2" "6.1" "Exit")
    select version in "${DXP[@]}"; do
        versiontrim=${version//.}
        case $version in
            "Branch")
                echo -e "[SELECT] Choose Branch"
                branches=("master" "nightly")
                select update in "${branches[@]}"; do
                    case $update in
                    "master")
                        # check for master dir
                        SRCTEST=($(find "${LRDIR}"/Branch -maxdepth 2 -type d -name $master_file | sort -r | head -2))
                        SRCRAW=${SRCTEST[0]}
                        log_echo "$LINENO master search result (first only): $SRCRAW"
                        ## FIX THIS
                        if [[ -z "$variable_name" ]]; then
                            echo "No master available."
                            checkArchive $1
                            SRC=$(echo "$SRCRAW" | sed -e "s!$LRDIR!!g")
                            log_echo "$LINENO SRC location is $SRC"
                            BUNDLED="liferay-portal-tomcat-master-private-all"
                            SCHEMA="${project}_master"
                            createBundle Branch
                        else
                            SRC=$(echo "$SRCRAW" | sed -e "s!$LRDIR!!g")
                            log_echo "$LINENO SRC location is $SRC"
                            BUNDLED="liferay-portal-tomcat-master-private-all"
                            SCHEMA="${project}_master"
                            createBundle Branch
                        fi
                        break
                        ;;
                    "nightly")
                        SRCTEST=($(find "${LRDIR}"/Branch -maxdepth 2 -type d -name $nightly_file | sort -r | head -2))
                        for key in "${!SRCTEST[@]}"
                            do
                            echo -e "Key is '$key'  => Value is '${SRCTEST[$key]}'"
                            done
                        SRCRAW=${SRCTEST[0]}
                        SRC=$(echo "$SRCRAW" | sed -e "s!$LRDIR!!g")
                        log_echo "$LINENO SRC location is $SRC"
                        BUNDLED="liferay-dxp-tomcat-7.4.13.nightly"
                        SCHEMA="${versiontrimx}_${project}_$update"
                        createBundle Branch
                        break
                        ;;
                    esac
                done
                break
                ;;
            "Quarterly Release")
                if ! [[ $dbPort == '3306' ]]; then
                    changeMysqlVersion
                else
                    echo -e "\n---\nINFO: dbPort is $dbPort"
                fi
                versiontrimx=${version// }
                read -p "Select DXP 7.4 $version patch level: " update
                numcheck='^[0-9]+\.q[0-9]+\.[0-9]+'
                until [[ $update =~ ($numcheck|nightly|master) ]]; do
                    echo -e "ERROR: Invalid Input. Valid Inputs: YYYY.q#.# (ie 2023.q3.0)\n"
                    read -p "Select DXP $version patch level (Update): " update
                done
                updatemysql=${update//./}
                echo -e "\n---\n"
                BUNDLED="liferay-dxp-tomcat-$update"
                SCHEMA="QR_${project}_${updatemysql}"
                createBundle QR
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
                until [[ $update =~ ($numcheck|master|nightly) ]]; do
                    echo -e "ERROR: Invalid Input. Valid Inputs: Update or master.\n"
                    read -p "Select DXP $version patch level (Update): " update
                done
                echo -e "\n---\n"
                BUNDLED="liferay-dxp-tomcat-$version.u$update"
                SCHEMA="${versiontrimx}_${project}_U${update}"
                createBundle Update
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
                    BUNDLED="liferay-dxp-tomcat-$version.u$update"
                    SCHEMA="${versiontrimx}_${project}_U${update}"
                    createBundle Update
                elif (( $update == 1 )) || (( $update == 3 )); then
                    # -- IF SP = liferay-dxp-tomcat-7.3.10.1-sp1/liferay-dxp-7.3.10.1-sp1
                    SRC="$version/liferay-dxp-tomcat-$version.$update-sp$update/liferay-dxp-$version.$update-sp$update"
                    BUNDLED="liferay-dxp-tomcat-$version-sp$update"
                    SCHEMA="${versiontrimx}_${project}_SP${update}"
                    createBundle SP
                else
                    SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                    BUNDLED="liferay-dxp-tomcat-$version.dxp-$update"
                    SCHEMA="${versiontrimx}_${project}_dxp${update}"
                    createBundle FP
                fi
                break
                ;;
            "7.2.10" | "7.1.10" | "7.0.10")
                if [ "$version" == '7.0.10' ]; then
                    echo -e "WARN: Update Config - DXP 7.0 is only compatible with MySQL 5.6 or 5.7."
                    if [[ $dbPort == '3306' ]]; then
                        changeMysqlVersion
                    else
                        echo -e "INFO: dbPort is $dbPort"
                    fi
                else
                    echo -e "INFO: dbPort is $dbPort"
                fi
                versiontrimx=${versiontrim//10}
                versionshort=${version//.10}
                updateTypeList=("Update" "FP" "SP" "Branch")
                echo -e "[SELECT] Choose an Update Type:"
                select updateType in "${updateTypeList[@]}"; do
                    echo -e "[CHECK] UpdateType set as $updateType\n---\n"
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
    
                        else
                            if [ "$updateType" = 'FP' ]; then
                                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                            elif [ "$updateType" = 'SP' ]; then
                                SRC="$version/liferay-dxp-tomcat-$version.$update-sp$update/liferay-dxp-$version.$update-sp$update"
                            else 
                                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                            fi

                            BUNDLED="liferay-dxp-tomcat-$version.$update-sp$update"
                            SCHEMA="${versiontrimx}_${project}_$updateType${update}"
                            createBundle "$updateType"
                        fi
                    fi
                    break
                done
                break
                ;;
            "6.2" | "6.1")
                if [ "$version" == '6.2' ]; then
                    echo -e "WARN: Update Config - Portal 6.2 is only compatible with MySQL 5.5."
                    if [[ ! $dbPort =~ 55[0-9][0-9] ]]; then
                        changeMysqlVersion
                    else
                        echo -e "INFO: dbPort is $dbPort"
                    fi
                else
                    echo -e "INFO: dbPort is $dbPort"
                fi
                versiontrimx=${versiontrim//10}
                # CHOOSE A SP
                read -p "Select Portal $version patch level (SP #): " update
                numcheck='^[0-9]+$'
                until [[ $update =~ ($numcheck|branch) ]]; do
                    echo -e "ERROR: Invalid Input. Valid Inputs: SP # or branch\n"
                    read -p "Select Portal $version patch level: " update
                done
                echo -e "\n---\n"
                # TODO: consider hashmap / lookup table to make FP to SP
                # declare -A fixpacks
                # fixpacks=( ["SP20"]=154 ["SP19"]=148 ["SP18"]=138)
                if (( $update > 20 )); then
                    echo -e "WARN: Service Pack needed, no fix pack support yet."
                elif [ "$update" == 'branch' ]; then
                    echo -e "WARN: No branch support yet for Portal 6.2 or 6.1"
                else
                    echo "Ok, setting up a $project folder with Portal $version SP $update bundle..."
                    # liferay-portal-tomcat-6.2-ee-sp18/liferay-portal-6.2-ee-sp18/
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
fi