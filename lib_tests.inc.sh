#####
# Tests and checks #
               #####
case "$1" in

    config_on-load)
    
        # Check if application type is specified
        if [[ -z $pkpApp  && $subcommand != 'sync-backup' ]]; then
            printf "\n\t%s\n\n" "PKP application is not defined"
            # To-Do: print apps configured in config-local.inc.sh
#             for app in ${list_availablePkpApps}; do
#                 echo "${app}
#             done
            exit 1
        fi
        
        # To-Do: 
        # Check/Compare the config-local.inc.sh  and config-local.TEMPLATE.inc.sh files
        # Variables in both files should be same
        
    ;;
    
    config_check-dir-file)
    
        # Check if necessary directories/files exist
        checkDirectories=($pkpRootPath $pkpBackupRootPath $pkpWebRootPath $pkpAppBackupRootPath $pkpAppCodePath $pkpAppDataPath $pkpAppStorage $pkpAppDownloads $pkpAppDownloadsTmp)
        checkFiles=($backupServerSSHKey $pkpAppDatabaseBackupFile)

        #####
        # Directories and files checks #
                                #####
        a=0
        for d in ${checkDirectories[@]}; do
            a=$((a+1))
            if [[ ! -d $d ]]; then
                echo -e "\n Folder \e[3m\e[1m$d\e[0m is missing! \n"
                echo $a
                exit 1
            fi
        done

        for f in ${checkFiles[@]}; do
            if [[ ! -f $f ]]; then
                echo -e "\n File \e[3m\e[1m$f\e[0m is missing! \n"
                exit 1
            fi
        done
        
    ;;

esac
