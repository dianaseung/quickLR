#!/bin/bash
# Automate cleaning up Liferay bundles

find $PROJECTDIR -type d -maxdepth 1 > /tmp/tmp.out
sed -i '1d' /tmp/tmp.out

allproj=$(cat /tmp/tmp.out)

echo -e "\n---\n"

today=$(date)
echo "Today's date is: $today"
read -p 'Set how many days before Project Deletion: (default 60)' expirydays
expirydays=${expirydays:-60}
echo $expirydays
expirydate=`date --date="$expirydays days ago"`
expirydatesec=`date --date="$expirydays days ago" +%s`
echo "Expiration date is: $expirydate ($expirydatesec)"

read -rsn1 -p"Press any key to run cleanup (or press Ctrl-C to change expiration date)";echo

dropDB () {
    # Find the Portal.exp property first
    # findportal=`find $project -type f -name 'portal-ext.properties'`
    # echo "Where portal: $findportal"
    mysqlProp=($(find $project -type f -name 'portal-ext.properties' -exec grep 'jdbc.default.url' {} \;))
    for eachProjPort in ${mysqlProp[@]};do
        # echo $eachProjPort
        propPrefix='jdbc.default.url=jdbc:mysql://localhost:'
        propSuffix='?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true'
        dbNameA=${eachProjPort/$propPrefix/}
        dbNameB=${dbNameA/$propSuffix/}
        dbNameC=${dbNameB#*/}
        echo -e "\n\tDB: $dbNameC"
        # DROP THE MYSQL DATABASE
        CHECKDB=`mysql -u$MYSQLUSER -e "SHOW DATABASES" | grep $dbNameC`
        # echo "checkdb result: $CHECKDB"
        if [[ $CHECKDB != $dbNameC ]]; then
            echo -e "\tWARN: DB already deleted!"
        else
            read -rsn1 -p"Press any key to confirm DB delete";echo
            mysql -u$MYSQLUSER -e "DROP DATABASE ${dbNameC}";
            CHECKDB=`mysql -u$MYSQLUSER -e "SHOW DATABASES" | grep $dbNameC`
            if [[ $CHECKDB == $dbNameC ]]; then
                echo -e "\tFAIL: Database ${dbNameC} not deleted -- please manually delete"
            else
                echo -e "\tSUCCESS: Database ${dbNameC} deleted!"
            fi
        fi
    done
}

i=0

for project in $allproj; do
    i=$((++i))
    origin='/home/dia/Downloads/Liferay/PROJECTS/'
    simplified=${project/$origin/}
    lastmod=`date -r $project`
    lastmodsec=`date -r $project +%s`
    echo -e "$i. \t Project: $simplified"
    echo -e "\t Last modified $lastmod ($lastmodsec)"
    if [[ $lastmodsec < $expirydatesec ]]; then
        # echo "last modified date is less than expiry date - TO BE DELETED"
        echo -e "\t $(( ($expirydatesec - $lastmodsec) / 86400 )) days over expiry date - slated for deletion\n"
        dropDB
        echo -e "\n"
        read -rsn1 -p"Press any key to confirm $project directory deletion";echo
        rm -rI $project
        if [ -e $project ]; then
            echo -e "\FAIL: Project deletion failed, please manually delete"
            xdg-open $project
        else
            echo -e "\tSUCCESS: $simplified Project deleted!"
        fi
    else
        # echo "last modified date is greater than expiry date - KEEP"
        echo -e "\t $(( ($lastmodsec - $expirydatesec) / 86400 )) days until deletion\n"
    fi
done