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

            # CHECK IF DIRECTORY EXISTS ALREADY - append date if so
            if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.u$update/" ]; then
                BUNDLED="liferay-dxp-$version.u$update.${DATE}"
                echo "Project Directory $project with Update u$update folder exists already"
                echo "Creating Update u$update folder with Date appended... /$project/$BUNDLED"
                echo "---"
                SCHEMA="74_${project}_U${update}_${DATE}"
            else
                BUNDLED="liferay-dxp-$version.u$update"
                echo "Project Directory $project with Update folder u$update does not exist yet"
                echo "Creating Update folder... /$project/$BUNDLED"
                echo "---"
                SCHEMA="74_${project}_U${update}"
            fi

            # --- UNIVERSAL

            # CREATE FOLDER
            cp -r ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update ${PROJECTDIR}/$project/$BUNDLED
            if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
            else
                echo "FAIL: Folder not created"
                echo "DEBUG: Source ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/$BUNDLED"
                echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
            fi
            cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
            cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
            # MAKE THE MYSQL SCHEMA
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
            # -- START IF UPDATE
                echo "Patch level is an Update: u$update"
                echo "Ok, setting up a $project folder with DXP $version Update $update bundle..."
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.u$update/" ]; then
                    BUNDLED="liferay-dxp-$version.u$update.${DATE}"
                    echo "Project Directory $project with Update u$update folder exists already"
                    echo "Creating Update u$update folder with Date appended... /$project/$BUNDLED"
                    echo "---"
                    SCHEMA="73_${project}_U${update}_${DATE}"
                else
                    BUNDLED="liferay-dxp-$version.u$update"
                    echo "Project Directory $project with Update folder u$update does not exist yet"
                    echo "Creating Update folder... /$project/liferay-dxp-$version.u$update"
                    echo "---"
                    SCHEMA="73_${project}_U${update}"
                fi

                # UNIVERSAL for UPDATE
                cp -r ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
                else
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/$version/liferay-dxp-tomcat-$version.u$update/$BUNDLED"
                    echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
                fi
                cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                # MAKE THE MYSQL SCHEMA
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
            # -- END IF UPDATE
            else
            # -- START IF FP
                echo "Patch level is a FP: DXP $version dxp-$update"
                echo "Ok, setting up a $project folder with DXP $version dxp-$update bundle..."
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.dxp-$update/" ]; then
                    BUNDLED="liferay-dxp-$version.dxp-$update.${DATE}"
                    SCHEMA="73_${project}_dxp${update}_${DATE}"
                    echo "Project Directory $project with Update dxp-$update folder exists already"
                else
                    BUNDLED="liferay-dxp-$version.dxp-$update"
                    SCHEMA="73_${project}_dxp${update}"
                    echo "Project Directory $project with Update folder dxp-$update does not exist yet"
                fi

                echo "Creating Update u$update folder... /$project/$BUNDLED"
                echo "---"
                # UNIVERSAL FOR FP
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
                echo "Fix Pack sourced from ${LRDIR}/$version/FP/liferay-fix-pack-dxp-$update-7310.zip"
                cp ${LRDIR}/$version/FP/liferay-fix-pack-dxp-$update-7310.zip ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
                if [ -e ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/liferay-fix-pack-dxp-$update-7310.zip ]; then
                    echo "Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/liferay-fix-pack-dxp-$update-7310.zip"
                else
                    echo "FAIL: Fix Pack not placed. Please manually install Fix Pack."
                    xdg-open ${PROJECTDIR}/$project
                fi
                
                # TODO - see if I can run patching-tool info from script in another directory
                #( cd ${PROJECTDIR}/$project/$BUNDLED/patching-tool/ | ./patching-tool.sh info | ./patching-tool.sh install)
                #echo "${PROJECTDIR}/$project/$BUNDLED/patching-tool/"
                #cat ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patchinfo.txt| grep installed patchinfo.txt
                #echo "COMPLETE: Fix Pack dxp-$update installed!"

                # MAKE THE MYSQL SCHEMA
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
            # -- END IF FP
            fi
            break
            ;;
        "7.2.10" | "7.1.10" | "7.0.10")
            # 72 71 70 ALL USE FP

            # CHOOSE A FIX PACK
            read -p "Select DXP $version patch level (FP #): " update
            until [[ $update =~ ^[+]?[0-9]+$ ]]
            do
                echo "ERROR: Please input valid Fix Pack # (integer only):"
                echo
                read -p "Select DXP $version patch level (FP #): " update
            done
            echo
            echo "---"
            echo

            echo "Patch level is: DXP $version dxp-$update"
            echo "Ok, setting up a $project folder with DXP $version dxp-$update bundle..."
            # CHECK IF DIRECTORY EXISTS ALREADY
            if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.dxp-$update/" ]; then
                BUNDLED="liferay-dxp-$version.dxp-$update.${DATE}"
                SCHEMA="73_${project}_dxp${update}_${DATE}"
                echo "Project Directory $project with Update dxp-$update folder exists already"
            else
                BUNDLED="liferay-dxp-$version.dxp-$update"
                SCHEMA="73_${project}_dxp${update}"
                echo "Project Directory $project with Update folder dxp-$update does not exist yet"
            fi

            echo "Creating Update u$update folder... /$project/$BUNDLED"
            echo "---"

            # UNIVERSAL FOR FP
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
            echo "version trimmed ${version//.}"
            versiontrim=${version//.}
            echo "Fix Pack sourced from ${LRDIR}/$version/FP/liferay-fix-pack-dxp-$update-$versiontrim.zip"
            cp ${LRDIR}/$version/FP/liferay-fix-pack-dxp-$update-$versiontrim.zip ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
            if [ -e ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/liferay-fix-pack-dxp-$update-$versiontrim.zip ]; then
                echo "Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/liferay-fix-pack-dxp-$update-$versiontrim.zip"
            else
                echo "FAIL: Fix Pack not placed. Please manually install Fix Pack."
                xdg-open ${PROJECTDIR}/$project
            fi

            # TODO - see if I can run patching-tool info from script in another directory
            #( cd ${PROJECTDIR}/$project/$BUNDLED/patching-tool/ | ./patching-tool.sh info | ./patching-tool.sh install)
            #echo "${PROJECTDIR}/$project/$BUNDLED/patching-tool/"
            #cat ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patchinfo.txt| grep installed patchinfo.txt
            #echo "COMPLETE: Fix Pack dxp-$update installed!"

            # MAKE THE MYSQL SCHEMA
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
echo "SUCCESS: Finished setup of DXP $version ${update} folder for $project"
xdg-open ${PROJECTDIR}/$project