#!/bin/bash

# Get the Functions Library
source lib_pkp-manager.inc.sh

while getopts ":a:v:u:l:d:t" opt; do

    case $opt in

        a)  # --application / PKP application name
            #   as defined in config-local.inc.sh
            pkpApp="$OPTARG"
            ;;

### BEGIN To-Do: commented out on 20240131 - delete if not needed ###
### Variable pkpAppVersion now defined in config.inc.sh
#         v)  # --version / PKP application version
#             # If option is 'local' check locally installed PKP application
#             if [[ $OPTARG = 'local' ]]; then
# #                 pkpAppVersion="${pkpAppCodeVersion}"
#                 pkpSource="zzff"
#             elif [[ $OPTARG = 'latest' ]]; then
#                 configPostProcessing["pkpAppVersion"]="latest"
#                 #pkpAppVersion="$(getLatestVersionNumber)"
#                 pkpSource="release"                
#             else
#                 pkpAppVersion="$OPTARG"
#                 pkpSource="release"
#             fi
#             ;;
### END commented out on 20240131 - delete if not needed ###
        
        u)  # --upgrade-version / PKP application version to upgrade to
            # i.e. 3.4.0.5
            pkpAppUpgradeVersion="${OPTARG}"
        
        ;;

        l)  # --locale / PKP application locale
            pkpAppLocale="$OPTARG"
        ;;

        d)  # --database / Use full or trimmed database
            if [[ $OPTARG =~ ^(full|trim)$ ]]; then
                syncDatabaseVersion="$OPTARG"
            elif [[ $OPTARG = 'latest' ]]; then
                databaseBackupDate="$OPTARG"
            elif [[ $OPTARG =~ ^20[0-9]{6}-[0-9]$ ]]; then 
                databaseBackupDate="$OPTARG"
            else
                parseOutput warning "\t'$OPTARG' is not an valid value for option '-d'"
                exit 1
            fi
            ;;

        t)  # --test-run / Run script with commands printed out instead of executed
            testRun=1
        ;;

        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
    
done

# Remove options that have already been handled from $@
shift $((OPTIND -1))

# Parameters
subcommand="${1}"

# Get configurations and application variables
source config.inc.sh "${pkpApp}"

case "$subcommand" in

    sync-backup)
        # Rsync files from backup server
        checkIfRoot "${subcommand}"
        checkIfSSHKey
        syncBackupFiles
#         pkpConvertDatabase
    ;;

    finish-sync)
    
        checkIfRoot "${subcommand}"
        emptyDatabase
        importDatabase
        copyConfigurationFiles
        fixCodeFilePermissions
        fixDataFilePermissions

    ;;

    sync-database)
    
        checkIfRoot "${subcommand}"
        emptyDatabase
        importDatabase
        copyConfigurationFile

    ;;

    fix-file-permissions)
        fixCodeFilePermissions
        fixDataFilePermissions
    ;;

    sync-local-app)
        checkIfRoot "${subcommand}"
        checkIf_syncDatabaseVersion
        syncAppCode
        fixConfigurationFile
        emptyDatabase
        importDatabase
        fixCodeFilePermissions
        fixDataFilePermissions
    ;;

    prepare-upgrade-core)
        checkIfRoot "${subcommand}"
        checkIf_pkpAppUpgradeVersion
        getVersionReleaseFiles $pkpAppVersion
        getVersionReleaseFiles $pkpAppUpgradeVersion
        get_customPlugins
        download_customPlugins
    ;;

    upgrade-core)
        checkIfRoot "${subcommand}"
        checkIf_pkpAppUpgradeVersion
        prepare_upgradeVersionCode
        upgradePkpApp
    ;;

    prepare-upgrade-plugins)
        checkIfRoot "${subcommand}"
        checkIf_pkpAppUpgradeVersion
        prepare_missingCustomPlugins "paperbuzz dates"
    ;;

    upgrade-plugins)
        checkIfRoot "${subcommand}"
        checkIf_pkpAppUpgradeVersion
        prepare_upgradeVersionPlugins
        fixCodeFilePermissions
        upgradePkpApp
    ;;

    cleanup-failed-upgrade)
    
        parseOutput title "Cleaning up after failed update"
        mysqlDump_fileName="$(find ../journals-test.uni-lj.si/ -name "${pkpAppName}-UL-${pkpAppName}-*.sql.gz" | sort | tail -1)"
    
        # Drop database
        parseOutput emphasis "Droping all tables from ${mysqlDump_fileName}"
        mysqldump --add-drop-table --no-data ${pkpAppDatabaseName} \
            | grep -e '^DROP TABLE' \
            | (echo "SET FOREIGN_KEY_CHECKS=0;"; cat; echo "SET FOREIGN_KEY_CHECKS=1;") \
            | mysql ${pkpAppDatabaseName}

        # Import latest local database backup copy
        parseOutput emphasis "Importing ${mysqlDump_fileName} to ${mysqlDump_fileName} "
        zcat ${mysqlDump_fileName} \
            | sed '/INSERT INTO `metrics`/d' \
            | sed '/INSERT INTO `submission_search_object_keywords`/d' \
            | mysql ${pkpAppDatabaseName}

    ;;

    fix-file-permissions)
        fixCodeFilePermissions
        fixDataFilePermissions
    ;;
    
    test)
        checkUpgradePkpApp
    ;;
    
    *)
        echo "The subcommand is missing!"
        exit 1
    ;;

##
##  Options below are not yet ported or tested with pkp-manager scripts
##
#   
#   check-locale)
#     
#     # Check the installed OMP version
#     # Returns $ompCodeVersion $ompDatabaseVersion $ompLatestVersion
#     checkInstalledOMPVersions
#     
#     while read localeFile; do
#     
#         foundFile="$(echo "$localeFile" | sed "s|${ompCode}/||g")"
#         
#         # Compare with language pack generated from OMP admin interface using Translate plugin
# #         if [[ -f ${languagePackRoot}/${ompCodeVersion}/${ompLocale}/$foundFile ]]; then
#         # Compare with files in freshly unpacked version package
#         if [[ -f ${omara}/downloads/omp-$ompCodeVersion/$foundFile ]]; then
#         
#             echo 'OK'
#             
#         else
#         
#             echo "Missing: $foundFile"
#         
#         fi
#     
#     done <<<"$(listLocaleFiles "$ompLocale")"
#   ;;
#   
  save-locale-files)
    
    # Check if all needed variables are set
    checkIfVersionSet
    checkIfLocaleSet
    
    # Root folder for language pack
    if [[ $ompSource == 'zzff' ]]; then
        langPackRootSource="$ompCode"
        langPackRootDestination="$languagePackRoot/$ompVersion/$ompLocale-zzff"
    elif [[ $ompSource == 'release' ]]; then
        langPackRootSource="${omara}/downloads/omp-$ompVersion"
        langPackRootDestination="$languagePackRoot/$ompVersion/$ompLocale-release"
    fi
    
    # Check if language package folder already exsist / create it
    if [[ -d $langPackRootDestination ]]; then
        echo "Files for version $ompVersion and locale $ompLocale already exist."
#         exit 1
    else
        mkdir -p $langPackRootDestination
    fi

    while read localeFile; do
    
        # Get relative file path
        foundFile="$(echo "$localeFile" | sed "s|${langPackRootSource}/||g")"
        
        # Check if language pack folder exists / create it
        if [[ ! -d $(dirname $langPackRootDestination/$foundFile) ]]; then
            mkdir -p $(dirname $langPackRootDestination/$foundFile)
        fi
        
        # Copy the locale file to $langPackRootDestination
        cp $localeFile $langPackRootDestination/$foundFile 
    
    done <<<"$(listLocaleFiles)"

    # Change language pack file ownership
    chown -R mitja:mitja $langPackRootDestination
    
  ;;
#   
#   *)
#     echo -e "\n NAME"
#     echo -e "\t manage-omp-test-installation.sh - Bash script for managing OMP instlation(s)"
#     echo -e "\n SYNOPSIS"
#     echo -e "\t manage-omp-test-installation.sh [option]... [command]..."
#     echo -e "\n DESCRIPTION"
#     echo -e "\t Manage local OMP installation. First list options, then specify the command to be executed."
#     echo -e "\n\t -l"
#     echo -e "\t\t specify locale"
#     echo -e "\n\t -v"
#     echo -e "\t\t specify OMP version"
#     echo -e "\n"
#     exit 3
#   ;;

esac


# Izpis časa trajanja
printf "\n |—> Script finished in %d seconds" $SECONDS
convertsecs $SECONDS
