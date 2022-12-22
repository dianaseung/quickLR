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
            versiontrim=${version//.}
            # 7413 USES UPDATES ONLY
            read -p "Select DXP $version patch level (Update): " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|master|nightly) ]]
            do
                echo "ERROR: Invalid Input. Please input the Update #, master or nightly"
                echo
                read -p "Select DXP $version patch level (Update): " update
            done

            echo
            echo "---"
            echo

            if [ $update == 'master' ]; then
                # liferay-portal-master-20221221
                # CHECK IF DIRECTORY EXISTS ALREADY - append date if so
                if [ -d "${PROJECTDIR}/$project/liferay-$update-20221221/" ]; then
                    BUNDLED="liferay-$update-20221221.${DATE}"
                    echo "Project Directory $project with $update folder exists already"
                    SCHEMA="74_${project}_master_${DATE}"
                else
                    BUNDLED="liferay-$update-20221221"
                    echo "Project Directory $project with Update folder u$update does not exist yet"
                    SCHEMA="74_${project}_master"
                fi

                # --- UNIVERSAL
                echo "Creating $version $update folder... /$project/$BUNDLED"
                echo "---"
                # CREATE FOLDER
                cp -r ${LRDIR}/Branch/liferay-portal-$update-20221221/liferay-portal-$update-all ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
                else
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/Branch/liferay-portal-$update-20221221/liferay-portal-master-all"
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
            elif [ $update == 'nightly' ]; then
                # liferay-dxp-tomcat-7.4.13.nightly-20221220
                # CHECK IF DIRECTORY EXISTS ALREADY - append date if so
                if [ -d "${PROJECTDIR}/$project/liferay-master-$update-20221220/" ]; then
                    BUNDLED="liferay-master-$update-20221220.${DATE}"
                    echo "Project Directory $project with $update folder exists already"
                    SCHEMA="74_${project}_nightly_${DATE}"
                else
                    BUNDLED="liferay-master-$update-20221220"
                    echo "Project Directory $project with $update folder does not exist yet"
                    SCHEMA="74_${project}_nightly"
                fi

                # --- UNIVERSAL
                echo "Creating $version $update folder... /$project/$BUNDLED"
                echo "---"
                # CREATE FOLDER
                cp -r ${LRDIR}/Branch/liferay-dxp-tomcat-$version.nightly-20221220/liferay-portal-$version.nightly ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
                else
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/Branch/liferay-dxp-tomcat-$version.nightly-20221220/liferay-portal-$version.nightly"
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
            else

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
            fi
            break
            ;;
        "7.3.10")
            versiontrim=${version//.}
            # CHOOSE A FIX PACK / UPDATE
            read -p "Select DXP $version patch level (Update or FP #): " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|branch) ]]
            do
                echo "ERROR: Invalid Input. Please input the Update/FP # (integer only) or branch"
                echo
                read -p "Select DXP $version patch level (Update or FP #): " update
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
            elif (( $update == 1 )) || (( $update == 3 )); then
            # -- START IF SP
                echo "Patch level is an SP: sp$update"
                echo "Ok, setting up a $project folder with DXP $version SP$update bundle..."
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version-sp$update/" ]; then
                    BUNDLED="liferay-dxp-$version-sp$update.${DATE}"
                    echo "Project Directory $project with Update sp$update folder exists already"
                    SCHEMA="73_${project}_SP${update}_${DATE}"
                else
                    BUNDLED="liferay-dxp-$version-sp$update"
                    echo "Project Directory $project with Update folder sp$update does not exist yet"
                    SCHEMA="73_${project}_SP${update}"
                fi

                echo "Creating Update sp$update folder... /$project/$BUNDLED"
                echo "---"
                # UNIVERSAL for UPDATE
                cp -r ${LRDIR}/$version/liferay-dxp-tomcat-$version-sp$update/liferay-dxp-$version.$update-sp$update ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
                else
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/$version/liferay-dxp-tomcat-$version-sp$update/$BUNDLED"
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
            # -- END IF SP
            elif [ $update == 'branch' ]; then
            # -- START IF 73 BRANCH
                # liferay-portal-tomcat-7.3.x-private-all
                # liferay-portal-7.3.x-private-all
                # CHECK IF DIRECTORY EXISTS ALREADY - append date if so
                if [ -d "${PROJECTDIR}/$project/liferay-$update-20221221/" ]; then
                    BUNDLED="liferay-$version-$update.${DATE}"
                    echo "Project Directory $project with $version $update folder exists already"
                    SCHEMA="73_${project}_$update_${DATE}"
                else
                    BUNDLED="liferay-$version-$update"
                    echo "Project Directory $project with $version $update folder does not exist yet"
                    SCHEMA="73_${project}_$update"
                fi

                # --- UNIVERSAL
                echo "Creating $version $update folder... /$project/$BUNDLED"
                echo "---"
                # CREATE FOLDER
                cp -r ${LRDIR}/Branch/liferay-portal-tomcat-7.3.x-private-all/liferay-portal-7.3.x-private-all ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
                else
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/Branch/liferay-portal-tomcat-7.3.x-private-all/liferay-portal-7.3.x-private-all"
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
            # -- ENDIF BRANCH
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
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|branch) ]]
            do
                echo "ERROR: Invalid Input. Please input the Update/FP # (integer only) or branch"
                echo
                read -p "Select DXP $version patch level (Update or FP #): " update
            done
            echo
            echo "---"
            echo

            if [ $update == 'branch' ]; then
                versiontrim=${version//.10}
                # -- START IF BRANCH
                # liferay-portal-tomcat-7.1.x-private-all
                # liferay-portal-7.3.x-private-all
                echo "$project Patch level is: DXP $version dxp-$update"
                SRC="Branch/liferay-portal-tomcat-$versiontrim.x-private-all/liferay-portal-$versiontrim.x-private-all"

                # CHECK IF DIRECTORY EXISTS ALREADY - append date if so
                if [ -d "${PROJECTDIR}/$project/liferay-$versiontrim-$update" ]; then
                    BUNDLED="liferay-$versiontrim-$update.${DATE}"
                    SCHEMA="73_${project}_$update_${DATE}"
                    echo "Project Directory $project with $version $update folder exists already"
                else
                    BUNDLED="liferay-$versiontrim-$update"
                    SCHEMA="73_${project}_$update"
                    echo "Project Directory $project with $version $update folder does not exist yet"
                fi

                # --- UNIVERSAL
                echo "Creating $versiontrim $update folder... /$project/$BUNDLED"
                echo "---"
                # CREATE FOLDER
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
                else
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/Branch/liferay-portal-tomcat-$versiontrim.x-private-all/liferay-portal-$versiontrim.x-private-all"
                    echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
                fi
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
            # -- ENDIF BRANCH
            else
                versiontrim=${version//.}
                echo "$project Patch level is: DXP $version dxp-$update"
                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                
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
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED" ]; then
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
                else
                    echo "FAIL: Folder not created"
                fi

                # INSTALL ACTIVATION KEY + PORTAL-EXT FILE
                cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                echo "COMPLETE: Directory created at ${PROJECTDIR}/$project/$BUNDLED"
                
                # COPY FP
                # liferay-fix-pack-dxp-1-7310
                FPZIP="liferay-fix-pack-dxp-$update-$versiontrim.zip"
                echo "Fix Pack sourced from ${LRDIR}/$FPZIP"
                cp ${LRDIR}/$version/FP/$FPZIP ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
                if [ -e ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP ]; then
                    echo "Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP"
                else
                    echo "FAIL: Fix Pack not placed. Please manually install Fix Pack."
                    xdg-open ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
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
            fi
            break
            ;;
        "6.2" | "6.1")
            versiontrim=${version//.}
            # CHOOSE A SP
            read -p "Select Portal $version patch level (SP #): " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|branch) ]]
            do
                echo "ERROR: Invalid Input. Please input the SP # (integer only) or branch"
                echo
                read -p "Select Portal $version patch level (SP #): " update
            done
            echo
            echo "---"
            echo

            # consider lookup table to make FP to SP
            # declare -A fixpacks
            # fixpacks=( ["SP20"]=154 ["SP19"]=148 ["SP18"]=138)

            if (( $update > 20 )); then
                echo "Service Pack needed, no fix pack support yet."
            elif [ $update == 'branch' ]; then
                # -- START IF 62 61 BRANCH
                echo "No branch support yet for Portal 6.2 or 6.1"
                # -- ENDIF BRANCH
            else
                # -- START IF FP
                # liferay-portal-tomcat-6.2-ee-sp3
                # liferay-portal-6.2-ee-sp3
                echo "Patch level is Portal $version SP $update"
                echo "Ok, setting up a $project folder with Portal $version SP $update bundle..."
                SRC="Branch/liferay-portal-tomcat-$version-ee-sp$update/liferay-portal-$version-ee-sp$update"
                
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-portal-tomcat-$version.ee-sp$update/" ]; then
                    BUNDLED="liferay-portal-tomcat-$version.ee-sp$update.${DATE}"
                    SCHEMA="${versiontrim}_${project}_SP${update}_${DATE}"
                    echo "Project Directory $project with $version SP $update folder exists already"
                else
                    BUNDLED="liferay-portal-tomcat-$version.ee-sp$update"
                    SCHEMA="${versiontrim}_${project}_SP${update}"
                    echo "Project Directory $project with $version SP $update does not exist yet"
                fi

                echo "Creating Update u$update folder... /$project/$BUNDLED"
                echo "---"
                # UNIVERSAL FOR FP
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
                else
                    echo "FAIL: Folder not created"
                fi

                cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                echo "COMPLETE: Directory created at ${PROJECTDIR}/$project/$BUNDLED"
                
                # ! COPY FP - NO FP SUPPORT YET
                # liferay-fix-pack-portal-173-6210
                # echo "Fix Pack sourced from ${LRDIR}/$version/FP/liferay-fix-pack-portal-$update-${versiontrim}10.zip"
                # cp ${LRDIR}/$version/FP/liferay-fix-pack-portal-$update-${versiontrim}10.zip ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
                # if [ -e ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/liferay-fix-pack-dxp-$update-7310.zip ]; then
                #     echo "Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/liferay-fix-pack-dxp-$update-7310.zip"
                # else
                #     echo "FAIL: Fix Pack not placed. Please manually install Fix Pack."
                #     xdg-open ${PROJECTDIR}/$project
                # fi
                
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