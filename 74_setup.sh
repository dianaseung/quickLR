#!/bin/bash
# for DXP 7.4 setup automation
source /home/dia/Downloads/Liferay/setenv.sh | tee ./log.dat
# GLOBAL VARIABLES
rootpw="${MYSQL_PW}"
DATE=$(date +%Y%m%d)
echo "---"
echo

# NAME THE PROJECT
read -p 'Project Code: ' project

# CHOOSE A FIX PACK / UPDATE
read -p 'Select DXP 7.4 patch level (Update): ' update
until [[ $update =~ ^[+]?[0-9]+$ ]]
do
    echo "Please input the Update #"
    echo
    read -p 'Select DXP 7.4 patch level (Update): ' update
done
echo
echo "---"
echo

SCHEMA="74_${project}_U${update}"
echo "Ok, setting up a $project folder with DXP 7.4 Update $update bundle..."
# CHECK IF DIRECTORY EXISTS ALREADY
if [ -d "/home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update/" ]; then
    echo "Project Directory $project with Update u$update folder exists already"
    echo "Creating Update u$update folder with Date appended... /$project/liferay-dxp-7.4.13.u$update.${DATE}"

    \cp -r /home/${USER}/Downloads/Liferay/DXP/7.4/liferay-dxp-tomcat-7.4.13.u$update/liferay-dxp-7.4.13.u$update /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}
    \cp /home/${USER}/Downloads/Liferay/DXP/Keys/7.4.xml /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}/deploy/
    \cp /home/${USER}/Downloads/Liferay/DXP/portal-ext.properties /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}/
    echo "COMPLETE: Directory created at /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}"
    # MAKE THE MYSQL DB
    if [ -f /root/.my.cnf ]; then
        mysql -e "CREATE ${SCHEMA}_${DATE};"
    else
        rootpw="${MYSQL_PW}"
        echo "Rootpw is ${rootpw}"
        mysql -uroot -p${rootpw} -e "CREATE SCHEMA ${SCHEMA}_${DATE}"
    fi
    echo "COMPLETE: Database schema ${SCHEMA}_${DATE} made!"
    # UPDATE PORTAL-EXT WITH NEW DB
    sed -i "s/SCHEMA/$project/g" /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}/portal-ext.properties
    echo "COMPLETE: portal-ext.properties updated with newly made schema!"
else
    echo "Project Directory $project with Update folder u$update does not exist yet"
    echo "Creating Update folder... /$project/liferay-dxp-7.4.13.u$update"
    \cp -r /home/${USER}/Downloads/Liferay/DXP/7.4/liferay-dxp-tomcat-7.4.13.u$update/liferay-dxp-7.4.13.u$update /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update
    \cp /home/${USER}/Downloads/Liferay/DXP/Keys/7.4.xml /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update/deploy/
    \cp /home/${USER}/Downloads/Liferay/DXP/portal-ext.properties /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update/
    # MAKE THE MYSQL SCHEMA
    if [ -f /root/.my.cnf ]; then
        mysql -e "CREATE SCHEMA ${SCHEMA}"
    else
        mysql -uroot -p${rootpw} -e "CREATE SCHEMA ${SCHEMA}"
    fi
    echo "COMPLETE: Database schema ${SCHEMA} made!"
    # UPDATE PORTAL-EXT WITH NEW DB
    sed -i "s/SCHEMA/$project/g" /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update/portal-ext.properties
    echo "COMPLETE: portal-ext.properties updated with newly made schema!"
fi

echo
echo "---"
echo
echo "Success -- Finished setup of DXP 7.4 u${update} folder for $project"
xdg-open /home/${USER}/Downloads/Liferay/PROJECTS/$project
