#!/bin/bash

# Get the Functions Library
source lib_pkp-manager.inc.sh

while getopts ":a:v:l:s" opt; do

    case $opt in

        a)  # --application / PKP application name
            pkpApp="$OPTARG"
            ;;
    
        v)  # --version / PKP application version
            # If option is 'local' check locally installed PKP application
            if [[ $OPTARG = 'local' ]]; then
#                 checkAppCodeVersion
#                 pkpAppVersion="${pkpAppCodeVersion}"
                pkpSource="zzff"
            elif [[ $OPTARG = 'latest' ]]; then
                pkpAppVersion="$(getLatestVersionNumber)"
                pkpSource="release"                
            else
                pkpAppVersion="$OPTARG"
                pkpSource="release"
            fi
            ;;
        
        l)  # --locale / PKP application locale
            pkpLocale="$OPTARG"
            ;;
        
#         s)  # --sync / Sync local backup files with backup server
#             checkIfSSHKey
#             syncBackupFiles
#             ;;

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
        pkpConvertDatabase
    ;;

    sync-local-app)
        checkIfRoot "${subcommand}"
#         checkIfSSHKey
        syncAppCode
        fixConfigurationFile
        emptyDatabase
        importDatabase
        fixCodeFilePermissions
        fixDataFilePermissions
    ;;

    upgrade)
        checkIfRoot "${subcommand}"
        checkIfVersionSet
        prepareNewVersionCode
        upgradePkpApp
        fixCodeFilePermissions
        fixDataFilePermissions
    ;;

    compare-files)
        
        # Check the installed PKP app version
        # Returns $pkpAppVersion
        checkAppCodeVersion

        # Checks if $pkpAppVersion release files are present / error
        checkPkpVersionPackage

        # Find all directories in existing local OMP installation
        parseOutput title "Searching directories for $pkpApp in ${pkpAppCodePath}"
        while read existingDir; do

            findDir="$(echo "$existingDir" | sed "s|${pkpAppCodePath}/||g")"

            # Skip if directory root is 'public' or 'cache' / folders where OMP saves data
            if [[ $findDir =~ ^(public/|cache/)+ ]]; then
                continue
            fi

            # Check if directories exist in freshly extracted package of the same version
            if [[ ! -d ${pkpAppDownloads}/${pkpApp}-${pkpAppVersion%.*}-${pkpAppVersion##*.}/$findDir ]]; then
                echo $findDir
            fi

        done <<<"$(find ${pkpAppCodePath} -type d)"

    ;;

    test)
        upgradePkpApp
        fixCodeFilePermissions
        fixDataFilePermissions
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
