#!/bin/bash

# Get the Functions Library
source lib_pkp-manager.inc.sh

while getopts ":a:v:l:sd:" opt; do

    case $opt in

        a)  # --application / PKP application name
            pkpApp="$OPTARG"
            ;;
    
        v)  # --version / PKP application version
            # If option is 'local' check locally installed PKP application
            if [[ $OPTARG = 'local' ]]; then
#                 checkLocalInstanceAppCodeVersion
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
            else
                parseOutput warning "\t'$OPTARG' is not an valid argument"
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
        checkIf_root "${subcommand}"
        checkIfSSHKey
        syncBackupFiles
#         pkpConvertDatabase
    ;;

    sync-local-app)
        checkIf_root "${subcommand}"
        checkIf_syncDatabaseVersion
        syncAppCode
        fixConfigurationFile
        emptyDatabase
        importDatabase
        fixCodeFilePermissions
        fixDataFilePermissions
    ;;

    upgrade)
        checkIf_root "${subcommand}"
        checkIfVersionSet
        prepareNewVersionCode
        upgradePkpApp
        fixCodeFilePermissions
        fixDataFilePermissions
    ;;

    compare-files)

        # Check the installed PKP app version
        # Returns $pkpAppVersion

        getLocalInstanceAppCodeVersion
#         checkLocalInstanceAppCodeVersion

        # Checks/Prepares $pkpAppVersion release files
        checkPkpVersionPackage

        # Find all directories in existing local OMP installation
        parseOutput title "Searching plugins for $pkpApp in ${pkpAppCodePath}"
        parseOutput emphasis "List of plugins that were not found in original release package:"
        
        # To-Do:
        #   PKP Plubins List: http://pkp.sfu.ca/ojs/xml/plugins.xml
        #   bash: xmllint
        #   
        declare -A customPlugins
        declare -A knownCustomPlugins=( ['addThis']="https://github.com/pkp/addThis/releases"
                                        ['piwik']="https://github.com/pkp/piwik/releases"
                                        ['customHeader']="https://github.com/pkp/customHeader/releases"
                                        ['translator']="https://github.com/pkp/translator/releases"
                                        ['citations']='https://github.com/RBoelter/citations/releases'
#                                         ['']=''
#                                         ['']=''
#                                         ['']=''
#                                         ['']=''
        )

        
#         knownCustomPlugins['addThis']="https://github.com/pkp/addThis/releases"
        
        while read versionFile; do

            pluginVersionFile="$(echo "$versionFile" | sed "s|${pkpAppCodePath}/||g")"
            
            # Skip if pluginVersionFile is 'pluginVersionFile'
            if [[ $pluginVersionFile = 'dbscripts/xml/version.xml' ]]; then
                continue
            fi
#             echo $pluginVersionFile

            # Check if pluginVersionFile exist in freshly extracted package of the same version
            # If directory does not exist print pluginVersionFile
            if [[ ! -f ${pkpAppDownloads}/${pkpApp}-${pkpAppVersion%.*}-${pkpAppVersion##*.}/${pluginVersionFile} ]]; then

                echo $pluginVersionFile
                
#                 # To-Do: writen initialy for ojs only
#                 if [[ $pkpApp == 'ojs' ]]; then
#             
#                     
#                     if [[  ]]; then
#                         
#                     fi
#                     
#                 fi

            fi

        done <<<"$(find ${pkpAppCodePath} -type f -name 'version.xml')"

    ;;

    test)
        checkIf_syncDatabaseVersion
        echo "OK!"
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
