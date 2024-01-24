#!/bin/bash

# Get the Functions Library
source lib_pkp-manager.inc.sh

while getopts ":a:v:u:l:sd:" opt; do

    case $opt in

        a)  # --application / PKP application name
            pkpApp="$OPTARG"
            ;;
    
        v)  # --version / PKP application version
            # If option is 'local' check locally installed PKP application
            if [[ $OPTARG = 'local' ]]; then
#                 pkpAppVersion="${pkpAppCodeVersion}"
                pkpSource="zzff"
            elif [[ $OPTARG = 'latest' ]]; then
                configPostProcessing["pkpAppVersion"]="latest"
                #pkpAppVersion="$(getLatestVersionNumber)"
                pkpSource="release"                
            else
                pkpAppVersion="$OPTARG"
                pkpSource="release"
            fi
            ;;
        
        u)  # --upgrade-version / PKP application version to upgrade to
            # i.e. 3.4.0-3
            pkpAppUpgradeVersion="${OPTARG}"
        
        ;;
        l)  # --locale / PKP application locale
            pkpLocale="$OPTARG"
            ;;

#         s)  # --sync / Sync local backup files with backup server
#             checkIfSSHKey
#             syncBackupFiles
#             ;;

        d)  # --database / Use full or trimmed database
            if [[ $OPTARG =~ ^(full|trim)$ ]]; then
                syncDatabaseVersion="$OPTARG"
            elif [[ $OPTARG =~ ^20[0-9]{6}-[0-9]$ ]]; then 
                databaseBackupDate="$OPTARG"
            else
                parseOutput warning "\t'$OPTARG' is not an valid value for option '-d'"
                exit 1
            fi
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

    sync-database)
    
        checkIfRoot "${subcommand}"
        emptyDatabase
        importDatabase
        copyConfigurationFile
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

    prepare-upgrade)
        checkIfRoot "${subcommand}"
        checkIfVersionSet
        prepareNewVersionCode "${pkpAppVersion}"
    ;;

    upgrade)
        checkIfRoot "${subcommand}"
        checkIfVersionSet
        upgradePkpApp
        fixCodeFilePermissions
        fixDataFilePermissions
    ;;

    test)
        getLocalInstanceAppCodeVersion
        copyConfigurationFile
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
#   save-locale-files)
#     
#     # Check if all needed variables are set
#     checkIfVersionSet
#     checkIfLocaleSet
#     
#     # Root folder for language pack
#     if [[ $ompSource == 'zzff' ]]; then
#         langPackRootSource="$ompCode"
#         langPackRootDestination="$languagePackRoot/$ompVersion/$ompLocale-zzff"
#     elif [[ $ompSource == 'release' ]]; then
#         langPackRootSource="${omara}/downloads/omp-$ompVersion"
#         langPackRootDestination="$languagePackRoot/$ompVersion/$ompLocale-release"
#     fi
#     
#     # Check if language package folder already exsist / create it
#     if [[ -d $langPackRootDestination ]]; then
#         echo "Files for version $ompVersion and locale $ompLocale already exist."
# #         exit 1
#     else
#         mkdir -p $langPackRootDestination
#     fi
# 
#     while read localeFile; do
#     
#         # Get relative file path
#         foundFile="$(echo "$localeFile" | sed "s|${langPackRootSource}/||g")"
#         
#         # Check if language pack folder exists / create it
#         if [[ ! -d $(dirname $langPackRootDestination/$foundFile) ]]; then
#             mkdir -p $(dirname $langPackRootDestination/$foundFile)
#         fi
#         
#         # Copy the locale file to $langPackRootDestination
#         cp $localeFile $langPackRootDestination/$foundFile 
#     
#     done <<<"$(listLocaleFiles)"
# 
#     # Change language pack file ownership
#     chown -R mitja:mitja $langPackRootDestination
#     
#   ;;
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
convertsecs $SECONDS
