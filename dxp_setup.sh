#!/bin/bash
# for DXP 7.4 setup automation
echo $USER | source /home/dia/Downloads/Liferay/setenv.sh | tee ./log.dat

echo "User is $USER"
echo "PW is $MYSQL_PW"

DATE=$(date +%Y%m%d)
echo "Date: ${DATE}"

intro='what dxp version?'
echo "${intro}"
DXP=("7.4" "7.3" "7.2" "7.1" "7.0" "Exit")
select version in "${DXP[@]}"; do
    case $version in
        "7.4")
            echo "Ok, DXP $version was selected"
            
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
                            mysql -e "CREATE SCHEMA 74_$project;"
                        else
                            # echo "Enter root user MySQL pw:"
                            # read -sp 'Enter root user MySQL pw: ' rootpw
                            rootpw = $MYSQL_PW
                            mysql -uroot -p${rootpw} -e "CREATE SCHEMA 74_${project}"
                        fi
                        echo "Database schema 74_${project} made!"
                        sed -i "s/SCHEMA/$project/g" /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update/portal-ext.properties
                        echo "portal-ext.properties updated with newly made schema!"
                        echo "---"
                        echo
                        echo "Success -- Finished setup of DXP 7.4 u$update folder for $project"
                        xdg-open /home/${USER}/Downloads/Liferay/PROJECTS/$project
                        break
                        ;;
                    "yes")
                        \cp -r /home/${USER}/Downloads/Liferay/DXP/7.4/liferay-dxp-tomcat-7.4.13.u$update/liferay-dxp-tomcat-7.4.13.u$update /home/${USER}/Downloads/Liferay/PROJECTS/$project//liferay-dxp-tomcat-7.4.13.u$update_${DATE}
                        \cp /home/${USER}/Downloads/Liferay/DXP/Keys/7.4.xml /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update_${DATE}/deploy/
                        \cp /home/${USER}/Downloads/Liferay/DXP/portal-ext.properties /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update_${DATE}/
                        echo
                        # MAKE THE MYSQL SCHEMA
                        if [ -f /root/.my.cnf ]; then
                            mysql -e "CREATE SCHEMA 74_$project;"
                        else
                            # echo "Enter root user MySQL pw:"
                            # read -sp 'Enter root user MySQL pw: ' rootpw
                            rootpw = $MYSQL_PW
                            mysql -uroot -p${rootpw} -e "CREATE SCHEMA 74_${project}"
                        fi
                        echo "Database schema 74_${project} made!"
                        sed -i "s/SCHEMA/$project/g" /home/${USER}/Downloads/Liferay/PROJECTS/$project/liferay-dxp-7.4.13.u$update_${DATE}/portal-ext.properties
                        echo "portal-ext.properties updated with newly made schema!"
                        echo "---"
                        echo
                        echo "Success -- Finished setup of DXP 7.4 u$update folder for $project"
                        xdg-open /home/${USER}/Downloads/Liferay/PROJECTS/$project
                        break
                        ;;
                    "cancel")
                        echo "canceling..."
                        break
                        ;;
                esac
            done
        "Quit")
            echo "User requested exit"
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

