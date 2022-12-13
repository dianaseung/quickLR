#!/bin/bash
# for DXP 7.4 setup automation
source /home/dia/Downloads/Liferay/setenv.sh | tee ./log.dat
# GLOBAL VARIABLES
rootpw="${MYSQL_PW}"
DATE=$(date +%Y%m%d)
echo "Date: ${DATE}"

# CHOOSE A FIX PACK / UPDATE
read -p 'Select DXP 7.4 patch level (Update): ' update
until [[ $update =~ ^[+]?[0-9]+$ ]]
do
    echo "Please input the Update #"
    echo
    read -p 'Select DXP 7.4 patch level (Update): ' update
done
echo "Ok, setting up a DXP 7.4 Update $update bundle..."
echo

# NAME THE PROJECT
read -p 'Project Code: ' project
SCHEMA="74_${project}_u${update}"
echo

# ADD-ON?
echo "Is this adding to an existing project?"
addon=('no' 'yes')
select addonchoice in "${addon[@]}"; do
    case $addonchoice in
        "no")
            \cp -r /home/${USER}/Downloads/Liferay/DXP/7.4/liferay-dxp-tomcat-7.4.13.u$update /home/${USER}/Downloads/Liferay/PROJECTS/$project
            \cp /home/${USER}/Downloads/Liferay/DXP/Keys/7.4.xml /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update/deploy/
            \cp /home/${USER}/Downloads/Liferay/DXP/portal-ext.properties /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update/
            echo
            # MAKE THE MYSQL SCHEMA
            if [ -f /root/.my.cnf ]; then
                mysql -e "CREATE SCHEMA ${SCHEMA}"
            else
                mysql -uroot -p${rootpw} -e "CREATE SCHEMA ${SCHEMA}"
            fi
            echo "Database schema ${SCHEMA} made!"
            echo
            # UPDATE PORTAL-EXT WITH NEW DB
            sed -i "s/SCHEMA/$project/g" /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update/portal-ext.properties
            echo "portal-ext.properties updated with newly made schema!"
            break
            ;;
        "yes")
            \cp -r /home/${USER}/Downloads/Liferay/DXP/7.4/liferay-dxp-tomcat-7.4.13.u$update/liferay-dxp-7.4.13.u$update /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}
            \cp /home/${USER}/Downloads/Liferay/DXP/Keys/7.4.xml /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}/deploy/
            \cp /home/${USER}/Downloads/Liferay/DXP/portal-ext.properties /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}/
            echo "Directory created at /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}"
            echo
            # MAKE THE MYSQL DB
            if [ -f /root/.my.cnf ]; then
                mysql -e "CREATE ${SCHEMA}_${DATE};"
            else
                echo "Rootpw is ${rootpw}"
                mysql -uroot -p${rootpw} -e "CREATE SCHEMA ${SCHEMA}_${DATE}"
            fi
            echo "Database schema ${SCHEMA}_${DATE} made!"
            echo
            # UPDATE PORTAL-EXT WITH NEW DB
            sed -i "s/SCHEMA/$project/g" /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update.${DATE}/portal-ext.properties
            echo "portal-ext.properties updated with newly made schema!"
            break
            ;;
        "cancel")
            echo "canceling..."
            break
            ;;
    esac
done

echo "---"
echo
echo "Success -- Finished setup of DXP 7.4 u${update} folder for $project"
xdg-open /home/${USER}/Downloads/Liferay/PROJECTS/$project
