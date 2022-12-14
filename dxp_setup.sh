#!/bin/bash
# for DXP 7.4 setup automation
source /home/dia/Downloads/Liferay/setenv.sh | tee ./log.dat
# GLOBAL VARIABLES
dbpw="${MYSQL_PW}"
DATE=$(date +%Y%m%d)
echo "---"
echo

# NAME THE PROJECT
read -p 'Project Code: ' project

intro='what dxp version?'
echo "${intro}"
DXP=("7.4" "7.3" "7.2" "7.1" "7.0" "Exit")
select version in "${DXP[@]}"; do
    case $version in
        "7.4")
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
                SCHEMAUNQ=${SCHEMA}_${DATE}
                mysql -udia -e "CREATE SCHEMA ${SCHEMAUNQ}";
                CHECKDB=`mysql -e "SHOW DATABASES" | grep ${SCHEMAUNQ}`
                if [ $CHECKDB == ${SCHEMAUNQ} ]; then
                    echo "COMPLETE: Database ${SCHEMAUNQ} made!"
                else
                    echo "FAIL: Database ${SCHEMAUNQ} not created. Please create manually."
                fi
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
                # mysql -udia -e "CREATE SCHEMA ${SCHEMA}"
                # CHECKDB=`mysql -udia -e "SHOW DATABASES" | grep $SCHEMA`
                mysql -udia -e "CREATE SCHEMA ${SCHEMA}";
                CHECKDB=`mysql -e "SHOW DATABASES" | grep $SCHEMA`
                if [ $CHECKDB == $SCHEMA ]; then
                    echo "COMPLETE: Database ${SCHEMA} made!"
                else
                    echo "FAIL: Database ${SCHEMA} not created. Please create manually."
                fi
                # UPDATE PORTAL-EXT WITH NEW DB
                sed -i "s/SCHEMA/$project/g" /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update/portal-ext.properties
                echo "COMPLETE: portal-ext.properties updated with newly made schema!"
            fi
            break
            ;;
        "Quit")
            echo "User requested exit"
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

echo
echo "---"
echo
echo "Success -- Finished setup of DXP 7.4 u${update} folder for $project"
xdg-open /home/${USER}/Downloads/Liferay/PROJECTS/$project