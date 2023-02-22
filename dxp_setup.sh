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
intro='Select Liferay version:'
echo "${intro}"
DXP=("7.4.13" "7.3.10" "7.2.10" "7.1.10" "7.0.10" "6.2" "6.1" "Config" "Exit")
select version in "${DXP[@]}"; do
    case $version in
        "7.4.13")
            versiontrim=${version//.}
            versiontrimx=${versiontrim//13}
            # START 74 - USES UPDATES ONLY
            read -p "Select DXP $version patch level (Update): " update
            numcheck='^[0-9]+$'
            until [[ $update =~ ($numcheck|master) ]]
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
                SRC="Branch/liferay-portal-$update-20221221/liferay-portal-$update-all"
                BUNDLED="liferay-$update-20221221"
                SCHEMA="${versiontrimx}_${project}_$update"
                # CHECK IF DIRECTORY EXISTS ALREADY - append date if so
                if [ -d "${PROJECTDIR}/$project/liferay-$update-20221221/" ]; then
                    BUNDLED="${BUNDLED}.${DATE}"
                    echo "Project Directory $project with $update folder exists already"
                    SCHEMA="${SCHEMA}_${DATE}"
                else
                    echo "Project Directory $project with Update folder u$update does not exist yet"
                fi
                # --- UNIVERSAL
                echo "Creating $version $update folder... /$project/$BUNDLED"
                echo "---"
                # CREATE FOLDER
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    # INSTALL PORTAL-EXT PROPERTIES
                    # cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    # cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
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
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/$SRC"
                    echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
                fi
                # END 74 MASTER
            else
                # START 74 NON-MASTER
                SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                BUNDLED="liferay-dxp-$version.u$update"
                SCHEMA="${versiontrimx}_${project}_U${update}"
                # CHECK IF DIRECTORY EXISTS ALREADY - append date if so
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.u$update/" ]; then
                    BUNDLED="${BUNDLED}.${DATE}"
                    SCHEMA="${SCHEMA}_${DATE}"
                    echo "Project Directory $project with Update u$update folder exists already"
                else
                    echo "Project Directory $project with Update folder u$update does not exist yet"
                fi
                # --- UNIVERSAL
                echo "Creating $version $update folder... /$project/$BUNDLED"
                echo "---"
                # CREATE FOLDER
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    # INSTALL LICENSE + PORTAL-EXT PROPERTIES
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED - License and Portal-ext placed"
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
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/${SRC}"
                    echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
                fi
                # END 74 NON-MASTER
            fi
            # END 74
            break
            ;;
        "7.3.10")
            # START 73
            versiontrim=${version//.}
            versiontrimx=${versiontrim//10}
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

            # Potential Refactor: CURRENT LOGIC IS SLIGHTLY DUMB -- maybe should be [if branch - branch], [elif 1 | 3 - SP], [elif 2 - FP] [else - updates].  
            if (( $update > 3 )); then
                # -- START IF UPDATE
                echo "Patch level is an Update: u$update"
                SRC="$version/liferay-dxp-tomcat-$version.u$update/liferay-dxp-$version.u$update"
                BUNDLED="liferay-dxp-$version.u$update"
                SCHEMA="${versiontrimx}_${project}_U${update}"
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.u$update/" ]; then
                    BUNDLED="${BUNDLED}.${DATE}"
                    SCHEMA="${SCHEMA}_${DATE}"
                    echo "Project Directory $project with Update u$update folder exists already"
                else
                    echo "Project Directory $project with Update folder u$update does not exist yet"
                fi
                echo "Creating DXP $version u$update folder... /$project/$BUNDLED"
                echo "---"
                # UNIVERSAL for UPDATE
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    # INSTALL LICENSE + PORTAL-EXT PROPERTIES
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED - License and Portal-ext placed"
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
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/$SRC"
                    echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
                fi
                # -- END IF UPDATE
            elif (( $update == 1 )) || (( $update == 3 )); then
                # -- START IF SP
                echo "Patch level is an SP: sp$update"
                SRC="$version/liferay-dxp-tomcat-$version-sp$update/liferay-dxp-$version.$update-sp$update"
                BUNDLED="liferay-dxp-$version-sp$update"
                SCHEMA="${versiontrimx}_${project}_SP${update}"
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version-sp$update/" ]; then
                    BUNDLED="${BUNDLED}.${DATE}"
                    SCHEMA="${SCHEMA}_${DATE}"
                    echo "Project Directory $project with Update sp$update folder exists already"
                else
                    echo "Project Directory $project with Update folder sp$update does not exist yet"
                fi

                echo "Creating DXP $version SP$update folder... /$project/$BUNDLED"
                echo "---"
                # UNIVERSAL for UPDATE
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    # INSTALL LICENSE + PORTAL-EXT FILE
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED - License and Portal-ext placed"
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
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/${SRC}"
                    echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
                fi
                # -- END IF SP
            elif [ $update == 'branch' ]; then
                # -- START IF 73 BRANCH
                versiontrim=${version//.10}
                # liferay-portal-tomcat-7.3.x-private-all
                # liferay-portal-7.3.x-private-all
                SRC="Branch/liferay-portal-tomcat-${versiontrim}.x-private-all/liferay-portal-${versiontrim}.x-private-all"
                BUNDLED="liferay-$version-$update"
                SCHEMA="${versiontrimx}_${project}_$update"
                # CHECK IF DIRECTORY EXISTS ALREADY - append date if so
                if [ -d "${PROJECTDIR}/$project/liferay-$update-20221221/" ]; then
                    BUNDLED="${BUNDLED}.${DATE}"
                    SCHEMA="${SCHEMA}_${DATE}"
                    echo "Project Directory $project with $version $update folder exists already"
                else
                    echo "Project Directory $project with $version $update folder does not exist yet"
                fi
                # --- UNIVERSAL
                echo "Creating DXP $version $update folder... /$project/$BUNDLED"
                echo "---"
                # CREATE FOLDER
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    # INSTALL PORTAL-EXT FILE
                    # cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED - Portal-ext placed"
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
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/${SRC}"
                    echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
                fi
                # -- ENDIF BRANCH
            else
                # -- START IF FP
                echo "Patch level is a FP: DXP $version dxp-$update"
                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                BUNDLED="liferay-dxp-$version.dxp-$update"
                SCHEMA="${versiontrimx}_${project}_dxp${update}"
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.dxp-$update/" ]; then
                    BUNDLED="${BUNDLED}.${DATE}"
                    SCHEMA="${SCHEMA}_${DATE}"
                    echo "Project Directory $project with Update dxp-$update folder exists already"
                else
                    echo "Project Directory $project with Update folder dxp-$update does not exist yet"
                fi
                echo "Creating DXP $version dxp-$update folder... /$project/$BUNDLED"
                echo "---"
                # UNIVERSAL FOR FP
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.dxp-$update/" ]; then
                    # INSTALL ACTIVATION KEY + PORTAL-EXT FILE
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED - License and Portal-ext placed"

                    # COPY FP
                    FPZIP="liferay-fix-pack-dxp-$update-$versiontrim.zip"
                    echo "Fix Pack sourced from ${LRDIR}/$FPZIP"
                    cp ${LRDIR}/$version/FP/$FPZIP ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
                    if [ -e ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP ]; then
                        echo "Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP"
                        ( cd ${PROJECTDIR}/$project/$BUNDLED/patching-tool/ && ./patching-tool.sh install && ./patching-tool.sh info)
                        echo "COMPLETE: Fix Pack dxp-$update installed!"
                        # xdg-open ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
                    else
                        echo "FAIL: Fix Pack not placed. Please manually install Fix Pack."
                        xdg-open ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
                    fi

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
                    echo "FAIL: Folder not created"
                fi
                # -- END IF FP
            fi
            break
            ;;
        "7.2.10" | "7.1.10" | "7.0.10")
            versiontrim=${version//.}
            versiontrimx=${versiontrim//10}
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
                # -- START IF 70-72 BRANCH
                # liferay-portal-tomcat-7.1.x-private-all
                # liferay-portal-7.3.x-private-all
                echo "$project Patch level is: DXP $version dxp-$update"
                SRC="Branch/liferay-portal-tomcat-$versiontrim.x-private-all/liferay-portal-$versiontrim.x-private-all"
                BUNDLED="liferay-$versiontrim-$update"
                SCHEMA="${versiontrimx}_${project}_$update"
                # CHECK IF DIRECTORY EXISTS ALREADY - append date if so
                if [ -d "${PROJECTDIR}/$project/liferay-$versiontrim-$update" ]; then
                    BUNDLED="${BUNDLED}.${DATE}"
                    SCHEMA="${SCHEMA}_${DATE}"
                    echo "Project Directory $project with $version $update folder exists already"
                else
                    echo "Project Directory $project with $version $update folder does not exist yet"
                fi
                # --- UNIVERSAL
                echo "Creating $versiontrim $update folder... /$project/$BUNDLED"
                echo "---"
                # CREATE FOLDER
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    # INSTALL ACTIVATION KEY + PORTAL-EXT FILE
                    # cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED"
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
                    echo "FAIL: Folder not created"
                    echo "DEBUG: Source ${LRDIR}/$SRC"
                    echo "DEBUG: Destination ${PROJECTDIR}/$project/$BUNDLED"
                fi
                # -- ENDIF BRANCH
            else
                # -- START FP
                echo "$project Patch level is: DXP $version dxp-$update"
                SRC="$version/liferay-dxp-tomcat-$version-ga1/liferay-dxp-$version-ga1"
                BUNDLED="liferay-dxp-$version.dxp-$update"
                SCHEMA="${versiontrimx}_${project}_dxp${update}"
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-dxp-$version.dxp-$update/" ]; then
                    BUNDLED="${BUNDLED}.${DATE}"
                    SCHEMA="${SCHEMA}_${DATE}"
                    echo "Project Directory $project with Update dxp-$update folder exists already"
                else
                    echo "Project Directory $project with Update folder dxp-$update does not exist yet"
                fi
                echo "Creating DXP $version u$update folder... /$project/$BUNDLED"
                echo "---"
                # UNIVERSAL FOR FP
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED" ]; then
                    # INSTALL ACTIVATION KEY + PORTAL-EXT FILE
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    cp ${LRDIR}/$version/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED - License and Portal-ext placed"
                    # COPY FP
                    # liferay-fix-pack-dxp-1-7310
                    FPZIP="liferay-fix-pack-dxp-$update-$versiontrim.zip"
                    echo "Fix Pack sourced from ${LRDIR}/$FPZIP"
                    cp ${LRDIR}/$version/FP/$FPZIP ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
                    if [ -e ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP ]; then
                        echo "Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP"
                        ( cd ${PROJECTDIR}/$project/$BUNDLED/patching-tool/ && ./patching-tool.sh install && ./patching-tool.sh info)
                        echo "COMPLETE: Fix Pack dxp-$update installed!"
                        # xdg-open ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
                    else
                        echo "FAIL: Fix Pack not placed. Please manually install Fix Pack."
                        xdg-open ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
                    fi


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
                    echo "FAIL: Folder not created"
                fi
                # -- END FP
            fi
            break
            ;;
        "6.2" | "6.1")
            versiontrim=${version//.}
            versiontrimx=${versiontrim//10}
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
                # -- START IF SP
                # liferay-portal-tomcat-6.2-ee-sp3
                # liferay-portal-6.2-ee-sp3
                echo "Patch level is Portal $version SP $update"
                echo "Ok, setting up a $project folder with Portal $version SP $update bundle..."
                SRC="$version/liferay-portal-tomcat-$version-ee-sp$update/liferay-portal-$version-ee-sp$update"
                BUNDLED="liferay-portal-tomcat-$version.ee-sp$update"
                SCHEMA="${versiontrim}_${project}_SP${update}"
                # CHECK IF DIRECTORY EXISTS ALREADY
                if [ -d "${PROJECTDIR}/$project/liferay-portal-tomcat-$version.ee-sp$update/" ]; then
                    BUNDLED="${BUNDLED}.${DATE}"
                    SCHEMA="${SCHEMA}_${DATE}"
                    echo "Project Directory $project with $version SP $update folder exists already"
                else
                    echo "Project Directory $project with $version SP $update does not exist yet"
                fi

                echo "Creating DXP $version SP$update folder... /$project/$BUNDLED"
                echo "---"
                # UNIVERSAL FOR FP
                cp -r ${LRDIR}/$SRC ${PROJECTDIR}/$project/$BUNDLED
                if [ -d "${PROJECTDIR}/$project/$BUNDLED/" ]; then
                    # INSTALL ACTIVATION KEY + PORTAL-EXT FILE
                    cp ${LRDIR}/License/$version.xml ${PROJECTDIR}/$project/$BUNDLED/deploy/
                    cp ${LRDIR}/portal-ext.properties ${PROJECTDIR}/$project/$BUNDLED/
                    echo "SUCCESS: Folder created at ${PROJECTDIR}/$project/$BUNDLED - License and Portal-ext placed"

                    # [COPY FP] -- NO FP SUPPORT FOR 6.2 YET -- need to  
                    # liferay-fix-pack-portal-173-6210
                    # FPZIP="liferay-fix-pack-dxp-$update-$versiontrim.zip"
                    # echo "Fix Pack sourced from ${LRDIR}/$version/FP/$FPZIP"
                    # cp ${LRDIR}/$version/FP/$FPZIP ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/
                    # if [ -e ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP ]; then
                    #     echo "Fix Pack placed in ${PROJECTDIR}/$project/$BUNDLED/patching-tool/patches/$FPZIP"
                    # else
                    #     echo "FAIL: Fix Pack not placed. Please manually install Fix Pack."
                    #     xdg-open ${PROJECTDIR}/$project/$BUNDLED/patching-tool/
                    # fi

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
                    echo "FAIL: Folder not created"
                fi
            # -- END IF FP
            fi
            break
            ;;
        "Config")
            mysqlserverlist=mysqlserverlist.txt
            # Send list of installed DBDeployer servers to .txt
            # TODO: check if dbdeployer; if yes, use SANDBOX_HOME / if no, 3306?
            ls '/home/dia/Liferay/MySQL/servers/' > $mysqlserverlist
            # Define array of available MySQL servers available to choose from  
            mysqlarray=(`cat "$mysqlserverlist"`)

            select mysqlserver in "${mysqlarray[@]}"; do
                sed -i "s!localhost:*/SCHEMA!$mysqlserver!g" ${LRDIR}/portal-ext.properties
                echo "MySQL Server set at localhost:${mysqlserver}"
                break
            done
            exit
            ;;
        "Exit")
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
# xdg-open ${PROJECTDIR}/$project
( cd ${PROJECTDIR}/$project/$BUNDLED && lrclean)
cd ${PROJECTDIR}/$project/$BUNDLED/tomcat*/bin/ && ./catalina.sh run