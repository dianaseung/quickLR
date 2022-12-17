#!/bin/bash
# for DXP 7.4 setup automation
# source /home/dia/Downloads/Liferay/setenv.sh | tee ./log.dat
# GLOBAL VARIABLES
DATE=$(date +%Y%m%d)
echo "CHECK: LRDIR ${LRDIR}"
echo "CHECK: PROJECTDIR ${PROJECTDIR}"

# NAME THE PROJECT
read -p 'Project Code: ' project
mkdir -p ${PROJECTDIR}/$project/
echo "SUCCESS: Project created at ${PROJECTDIR}/$project/"

# Select DXP version
intro='what dxp version?'
echo "${intro}"
DXP=("7.4.13" "7.3.10" "7.2.10" "7.1.10" "7.0.10" "Exit")
select version in "${DXP[@]}"; do
    case $version in
        "7.4.13")
            # 74 USES UPDATES ONLY
            read -p 'Select DXP 7.4 patch level (Update): ' update
            # until [[ $update =~ ^[+]?[0-9]+$ ]]
            # do
            #     echo "Please input the Update #"
            #     echo
            #     read -p 'Select DXP $version patch level (Update): ' update
            # done

            case ${update#[-+]} in
                *[!0-9]* | '') echo "ERROR: Please input the Update #:" ;;
                * ) echo "STATUS: Setting up a $project folder with DXP $version Update $update bundle..." ;;
            esac

            echo
            echo "---"
            echo

            SCHEMA="74_${project}_U${update}"
            # echo "Ok, setting up a $project folder with DXP 7.4 Update $update bundle..."
            # CHECK IF DIRECTORY EXISTS ALREADY
            if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.u$update/" ]; then
                echo "Project Directory $project with Update u$update folder exists already"
                echo "Creating Update u$update folder with Date appended... /$project/liferay-dxp-$version.u$update.${DATE}"
                echo "---"
                cp -r ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}
                cp ${LRDIR}/DXP/License/$version.xml ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}/deploy/
                cp ${LRDIR}/DXP/portal-ext.properties ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}/
                echo "COMPLETE: Directory created at ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}"
                
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
                sed -i "s/SCHEMA/${SCHEMAUNQ}/g" ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}/portal-ext.properties
                echo "COMPLETE: portal-ext.properties updated with newly made schema!"
            else
                echo "Project Directory $project with Update folder u$update does not exist yet"
                echo "Creating Update folder... /$project/liferay-dxp-$version.u$update"
                echo "---"
                cp -r ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update ${PROJECTDIR}/$project/liferay-dxp-$version.u$update
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.u$update/" ]; then
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/liferay-dxp-$version.u$update"
                else
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                    echo "DEBUG: Destination ${PROJECTDIR}/$project/liferay-dxp-$version.u$update"
                fi
                cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/liferay-dxp-$version.u$update/deploy/
                cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/liferay-dxp-$version.u$update/
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
                sed -i "s/SCHEMA/$SCHEMA/g" ${PROJECTDIR}/$project/liferay-dxp-$version.u$update/portal-ext.properties
                echo "COMPLETE: portal-ext.properties updated with newly made schema!"
            fi
            break
            ;;
        "7.3.10")
            # CHOOSE A FIX PACK / UPDATE
            read -p 'Select DXP 7.3 patch level (Update or FP #): ' update
            until [[ $update =~ ^[+]?[0-9]+$ ]]
            do
                echo "ERROR: Please input valid Update # (integer only):"
                echo
                read -p 'Select DXP 7.3 patch level (Update or FP #): ' update
            done
            echo
            echo "---"
            echo

            if (( $update > 3 )); then
                echo "Patch level is an Update: u$update"
                SCHEMA="73_${project}_U${update}"
                echo "Ok, setting up a $project folder with DXP $version Update $update bundle..."
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.u$update/" ]; then
                    echo "Project Directory $project with Update u$update folder exists already"
                    echo "Creating Update u$update folder with Date appended... /$project/liferay-dxp-$version.u$update.${DATE}"
                    echo "---"
                    cp -r ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}/
                    echo "COMPLETE: Directory created at ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}"
                    
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
                    sed -i "s/SCHEMA/${SCHEMAUNQ}/g" ${PROJECTDIR}/$project/liferay-dxp-$version.u$update.${DATE}/portal-ext.properties
                    echo "COMPLETE: portal-ext.properties updated with newly made schema!"
                else
                    echo "Project Directory $project with Update folder u$update does not exist yet"
                    echo "Creating Update folder... /$project/liferay-dxp-$version.u$update"
                    echo "---"
                    cp -r ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update ${PROJECTDIR}/$project/liferay-dxp-$version.u$update
                    if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.u$update/" ]; then
                        echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/liferay-dxp-$version.u$update"
                    else
                        echo "FAIL: Folder not created"
                        echo "DEBUG: Source ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                        echo "DEBUG: Destination ${PROJECTDIR}/$project/liferay-dxp-$version.u$update"
                    fi
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/liferay-dxp-$version.u$update/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/liferay-dxp-$version.u$update/
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
                    sed -i "s/SCHEMA/$SCHEMA/g" ${PROJECTDIR}/$project/liferay-dxp-$version.u$update/portal-ext.properties
                    echo "COMPLETE: portal-ext.properties updated with newly made schema!"
                fi
            else
                echo "Patch level is a FP: dxp-$update"
                SCHEMA="73_${project}_dxp${update}"
                echo "Ok, setting up a $project folder with DXP $version Update $update bundle..."
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.dxp-$update/" ]; then
                    echo "Project Directory $project with Update dxp-$update folder exists already"
                    BUNDLED="liferay-dxp-$version.dxp-$update.${DATE}"
                    echo "Creating Update u$update folder... /$project/$BUNDLED"
                    echo "---"
                    cp -r ${LRDIR}/$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1 ${PROJECTDIR}/$project/$BUNDLED
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "COMPLETE: Directory created at ${PROJECTDIR}/$project/$BUNDLED"
                    
                    # COPY FP
                    cp ${LRDIR}/$version/FP/liferay-fix-pack-dxp-$update-7310.zip ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
                    sh ./patching-tool.sh info
                    sh ./patching-tool.sh install
                    sh ./patching-tool.sh info > patchinfo.txt 
                    cat ./patchinfo.txt| grep installed patchinfo.txt
                    echo "COMPLETE: Fix Pack dxp-$update installed!"

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
                    sed -i "s/SCHEMA/${SCHEMAUNQ}/g" ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties
                    echo "COMPLETE: portal-ext.properties updated with newly made schema!"
                else
                    echo "Project Directory $project with Update folder dxp-$update does not exist yet"
                    BUNDLED="liferay-dxp-$version.dxp-$update"
                    echo "Creating Update folder... /$project/liferay-dxp-$version.dxp-$update"
                    echo "---"
                    cp -r ${LRDIR}/$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1 ${PROJECTDIR}/$project/$BUNDLED
                    if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.dxp-$update/" ]; then
                        echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
                    else
                        echo "FAIL: Folder not created"
                    fi
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "COMPLETE: Directory created at ${PROJECTDIR}/$project/$BUNDLED"
                    
                    # COPY FP
                    # liferay-fix-pack-dxp-1-7310
                    echo "${LRDIR}/DXP/$version/FP/liferay-fix-pack-dxp-$update-7310.zip"
                    cp ${LRDIR}/$version/FP/liferay-fix-pack-dxp-$update-7310.zip ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
                    
                    #( cd ${PROJECTDIR}/$project/$BUNDLED/patching-tool/ | ./patching-tool.sh info | ./patching-tool.sh install)
                    #echo "${PROJECTDIR}/$project/$BUNDLED/patching-tool/"
                    #cat ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patchinfo.txt| grep installed patchinfo.txt
                    #echo "COMPLETE: Fix Pack dxp-$update installed!"

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
                    sed -i "s/SCHEMA/$SCHEMA/g" ${PROJECTDIR}/$project/$BUNDLED/portal-ext.properties
                    echo "COMPLETE: portal-ext.properties updated with newly made schema!"
                fi
            fi


            
            break
            ;;
        "7.2.10" | "7.1.10" | "7.0.10")
            # 72 71 70 ALL USE FP
            echo "Work in Progress"
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
# TODO: If directory exists, success msg + xdg-open; else error msg 
echo "SUCCESS: Finished setup of DXP $version u${update} folder for $project"
xdg-open ${PROJECTDIR}/$project