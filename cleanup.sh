#!/bin/bash
# Automate cleaning up Liferay bundles

# ---
# Variables
debug_logging=false


# DEBUG LOGGING
# allow turning debug logging on (true) or off (false) 
log_echo() {
  if [[ $debug_logging == true ]]; then
    echo -e "$@"  # Use "$@" to capture all arguments
  fi
}

# Tmp file for all projects list
# Method 1 - outputs full path i.e. /home/dia/Downloads/Liferay/PROJECTS/tester
find "$PROJECTDIR" -type d -maxdepth 1 > /tmp/tmp.out
sed -i '1d' /tmp/tmp.out
# Method 2 - outputs folder name only i.e. tester
# ls $PROJECTDIR > /tmp/tmp.out
# Result: store list of projects as array? variable?
allproj=$(cat /tmp/tmp.out)
log_echo "All Current Projects:\n$allproj\n---\n"

# Today's Date -- to give context to how many days to delete
today=$(date)

# Functions
findDB () {
# Find the DB name from portal-ext first
    mysqlProp=$(find "$folder" -type f -name 'portal-ext.properties' -exec grep 'jdbc.default.url' {} \;)
    log_echo "[DEBUG] 34: mysqlProp - $mysqlProp"
    # jdbc.default.url=jdbc:mysql://localhost:3306/
    propPrefix='jdbc.default.url=jdbc:mysql://localhost:'
    # ?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true
    propSuffix='?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true'
    dbNameA=${mysqlProp#"$propPrefix"}
    log_echo "dbNameA - $dbNameA"
    dbNameB=${dbNameA/$propSuffix/}
    log_echo "dbNameB - $dbNameB"
    dbNameC=${dbNameB#*/}
    echo -e "DB: $dbNameC"
    # Check if MYSQL DB exists first
    CHECKDB=$(mysql -u"$MYSQLUSER" -e "SHOW DATABASES" | grep "$dbNameC")
    log_echo "checkdb result: $CHECKDB"
}
dropDB () {
    if [[ $CHECKDB != $dbNameC ]]; then
        echo -e "[WARN]: DB already deleted!"
    else
        # -- DROP THE MYSQL DB after confirm --
        read -rsn1 -p"Press any key to confirm $dbNameC DB delete";echo
        mysql -u"$MYSQLUSER" -e "DROP DATABASE ${dbNameC}";
        # Final check if MYSQL DB exists
        CHECKDB=$(mysql -u"$MYSQLUSER" -e "SHOW DATABASES" | grep "$dbNameC")
        if [[ $CHECKDB == $dbNameC ]]; then
            echo -e "[FAIL]: Database ${dbNameC} not deleted -- please manually delete"
        else
            echo -e "[SUCCESS]: Database ${dbNameC} deleted!"
        fi
    fi
}

# --- MAIN SCRIPT ---

# Let's change it to a select instead
# First: ls 
# Option: Delete all projects, Delete one project, Delete multiple[?], Delete by Last Modified
# For Delete multiple: 
    # 1. cat list of projects, 
    # 2. (input which folders) -> temp txt file, 
    # 3. for each item in tmp file, rm -rf 

cleanOptions=("Clean all projects" "Clean one project" "Clean multiple projects" "Clean by Last Modified")
select cleanChoice in "${cleanOptions[@]}"; do
    case $cleanChoice in
        "Clean all projects")
            echo -e "\n---\n[WARNING]: This will delete ALL Project dir and databases. Please make sure you want to proceed deleting the following projects...\n"
            project_path=$(find "$PROJECTDIR" -mindepth 1 -maxdepth 1 -type d)
            proj_name="${project_path//\/home\/dia\/Downloads\/Liferay\/PROJECTS\//}"
            if [[ ! -z "$project_path" ]]; then
                # echo -e "\nSubdirectories in '$PROJECTDIR':"
                # echo -e "\t$project_path"
                log_echo -e "$proj_name\n---\n"
            else
                echo "No subdirectories found in '$$PROJECTDIR'."
            fi
            # Confirm twice
            read -r -p "Confirm again to clean up all projects: (y/N) " deleteAllAgain
            if [[ $deleteAllAgain =~ ^[Yy]$ ]]; then
                rm -rf "$PROJECTDIR"/*
                # TODO: remove all mysql databases
                if [ -e "$project" ]; then
                    echo -e "\FAIL: Project deletion failed, please manually delete"
                    xdg-open "$PROJECTDIR"
                else
                    echo -e "[SUCCESS]: All Projects deleted!"
                fi
                break
            else
                echo "Canceling all project cleanup"
            fi
            ;;
        "Clean one project")

            ;;
        "Clean multiple projects")
            ;;
        "Clean by Last Modified")
            echo "Today's date is: $today"
            read -p 'Set how many days before Project Deletion: (default 60)' expirydays
            expirydays=${expirydays:-60}
            echo "$expirydays"
            expirydate=$(date --date="$expirydays days ago")
            expirydatesec=$(date --date="$expirydays days ago" +%s)
            echo "Expiration date is: $expirydate ($expirydatesec)"

            i=0
            for project in $allproj; do
                i=$((++i))
                origin='/home/dia/Downloads/Liferay/PROJECTS/'
                log_echo "[DEBUG]: Project - $project"
                log_echo "[DEBUG]: origin - $origin"
                simplified=${project/$origin/}
                log_echo "[DEBUG]: simplified - $simplified"
                lastmod=$(date -r "$project")
                lastmodsec=$(date -r "$project" +%s)
                echo -e "$i. \t Project: $simplified"
                echo -e "\t Last modified $lastmod ($lastmodsec)"

                # Delete if last modified date is less than expiry date
                if [[ $lastmodsec < $expirydatesec ]]; then
                    echo -e "\t$(( ($expirydatesec - $lastmodsec) / 86400 )) days over expiry date - slated for deletion\n"
                    # confirm project deletion again
                    read -r -p "Confirm deletion of $simplified directory (y/N): " confirmDelete
                    
                    # if yes...
                    if [[ $confirmDelete =~ ^[Yy]$ ]]; then
                    # find all folders within project
                    find "$project" -type d -maxdepth 1 > /tmp/$simplified-folders.out
                    sed -i '1d' /tmp/$simplified-folders.out
                    # Result: store list of projects as array? variable?
                    allfolders=$(cat /tmp/$simplified-folders.out)
                    log_echo "Folders within $simplified:\n$allfolders\n---\n"

                    # For each folder within project
                    for folder in $allfolders; do
                        log_echo "[DEBUG]: Dropping the db for $folder"
                            findDB
                            dropDB
                            # then rm -rf (jk see below)
                    done
                    # actually just delete the whole Project, no need to rm -r each folder 
                    rm -r "$project"
                    
                    if [ -e "$project" ]; then
                        echo -e "[FAIL]: Project deletion failed, please manually delete"
                        xdg-open "$project"
                    else
                        echo -e "[SUCCESS]: $simplified Project deleted!\n---\n"
                        fi
                    # else...
                    else
                        # days until deletion
                        echo -e "Skipping Project deletion."
                    fi
                else
                    # echo "last modified date is greater than expiry date - KEEP"
                    echo -e "\t $(( ($lastmodsec - $expirydatesec) / 86400 )) days until deletion\n"
                fi
            done
            break
            ;;
        *) echo "invalid option";;
    esac
done