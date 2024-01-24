#
# Functions Library for Managing OMP Test Installation
#

# Fixed variables
# rootFolder="/home/strezniki/localhost/knjigeFF"
# ompRoot="${rootFolder}/e-knjige"
# ompCode="${rootFolder}/e-knjige/omp"
# ompData="${rootFolder}/e-knjige/omp-data"
# omara="${rootFolder}/omara"
# backupRoot="${rootFolder}/var/www/e-knjige"
# languagePackRoot="/home/mitja/omara/PROJEKTI/prevajanje/pkp/jezikovni-paketi/omp"
# 
# 
# mysqlBaza="omp"
# mysqlUporabnik="omp"
# mysqlGeslo="geslo"

# Local configuration post-processing array
# Setting variables that require script options and local configuration to be pre-processed
declare -A configPostProcessing 


function checkIfRoot {

    # Checks if script is run as root and exits if not
    if [ $EUID -ne 0 ]; then
        echo -e "Running \e[1m\e[3m${1}\e[0m subcommand requires root privileges!"
        exit 1
    fi

    }


# Check if SSH key for accessing backup server is loaded in SSH agent
function checkIfSSHKey {

    sshKey=0

    while read agentKey; do
        agentFingerprint="$(echo $agentKey | awk '{print $2}')"
        keyFingerprint="$(ssh-keygen -l -f $backupServerSSHKey | awk '{print $2}')"
        
        if [[ $agentFingerprint != $keyFingerprint ]]; then
            continue
        else
            local sshKey=1
        fi
        
    done <<<$(ssh-add -l)

    if [[ $sshKey -eq 0 ]]; then
        echo -e "The required SSH key is not available in ssh-agent."
        exit 1    
    fi

    }


function checkIfSourceSet {

    # Checks if $ompSource variable is set and exit if not
    if [[ -z $pkpSource ]]; then
        echo -e "The variable \e[3mpkpSource\e[0m must have a value!"
        exit 1
    fi

    }


function getLocalInstanceAppCodeVersion {

    pkpAppVersion="$(cat ${pkpAppCodePath}/dbscripts/xml/version.xml | grep '<release>' | awk -F'[<>]' '{print $3}')"

    }


function checkIfVersionSet {

    # Checks if $ompVersion variable is set and exit if not
    if [ -z $pkpAppVersion ]; then
        echo -e "The variable \e[3m pkpAppVersion \e[0m must have a value!"
        exit 1
    fi

    }


# Synchronize local backup files with latest version on backup server
function syncBackupFiles {

    echo "Syncing files from backupserver."
    
    rsync -rlt --delete --info=progress2 ${backupServerUser}:${backupServerDirectory}/ ${pkpBackupRootPath}

    }


# Sync local app code
function syncAppCode {

    parseOutput title "Syncing ${pkpAppName}files"
    rsync -a --delete --info=progress2 ${pkpAppBackupRootPath}/${pkpApp}/ ${pkpAppCodePath}

    }
    
function pkpConvertDatabase {

    parseOutput title "Converting ${pkpAppName}database to mydumper"
    
    # Empty the temporary database (maybe drop & create)
    # mysql -e "DROP DATABASE IF EXISTS "
    # Import database to a temporary database
    # Export the temporary database with mydumper
    ## mydumper --database=zzff_ojs --verbose=3 --threads=12 --outputdir=tmp/export-mydumper-$(date +%Y%m%d)
    # Empty the data 'sql' files for table metrics and submission_search_object_keywords
    ## echo "" > tmp/export-mydumper-$(date +%Y%m%d)/zzff_ojs.metrics.sql
    ## echo "" > tmp/export-mydumper-$(date +%Y%m%d)/zzff_ojs.submission_search_object_keywords.sql

}

# function checkInstalledAppVersions {
# 
#     while read version; do
#         if [[ $(echo $version | awk -F':' '{print $1}') == 'Code version' ]]; then
#             pkpAppLocalCodeVersion="$(echo $version | awk -F':' '{print $2}')"
#             pkpAppLocalCodeVersion="$(convertVersion $pkpAppLocalCodeVersion)"
#         elif [[ $(echo $version | awk -F':' '{print $1}') == 'Database version' ]]; then
#             pkpAppLocalDatabaseVersion="$(echo $version | awk -F':' '{print $2}')"
#             pkpAppLocalDatabaseVersion="$(convertVersion $pkpAppLocalDatabaseVersion)"
#         elif [[ $(echo $version | awk -F':' '{print $1}') == 'Latest version' ]]; then
#             pkpAppLatestVersion="$(echo $version | awk -F':' '{print $2}')"
#             pkpAppLatestVersion="$(convertVersion $pkpAppLatestVersion)"
#         fi
#     done <<<"$(sudo -u www-data /usr/bin/php ${pkpAppCodePath}/tools/upgrade.php check)"
#     
#     if [[ $pkpAppLocalCodeVersion != $pkpAppLocalDatabaseVersion ]]; then
#         echo "Code ($pkpAppLocalCodeVersion) and database ($pkpAppLocalDatabaseVersion) version do not match!"
#         exit 1
#     fi
# 
#     }
# 
# 
# function convertVersion {
# 
#     ompVersionMajor="$(echo $1 | awk -F'.' '{print $1}')"
#     ompVersionMinor="$(echo $1 | awk -F'.' '{print $2}')"
#     ompVersionRevision="$(echo $1 | awk -F'.' '{print $3}')"
#     ompVersionBuild="$(echo $1 | awk -F'.' '{print $4}')"
# 
#     returnOMPVersion="$ompVersionMajor.$ompVersionMinor.$ompVersionRevision"
#     
#     if [[ $ompVersionBuild -ne 0 ]]; then
#         returnOMPVersion+="-$ompVersionBuild"
#     fi
#     
#     echo "$returnOMPVersion"
# 
#     }

function copyConfigurationFile {

    # Get local instance version: i.e. 3.3.0.13
    getLocalInstanceAppCodeVersion
    
    cp ${pkpConfigFilePath}/config.inc.php.${pkpAppVersion} ${pkpAppCodePath}/config.inc.php

}

function fixConfigurationFile {

    parseOutput emphasis "Fixing config file"
    
    if [[ -z $pkpAppCodeVersion ]]; then

        getLocalInstanceAppCodeVersion

    fi

    if [[ ! -f ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion} ]]; then

        cp ${pkpAppCodePath}/config.inc.php ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}

    fi

    #popravi konfiguracijsko datoteko
    sed "/^\s*base_url/c\base_url = \"http://${pkpAppTestURL}\"" -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*session_cookie_name/c\session_cookie_name = ${pkpApp^^}SID-test" -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^\s*driver/c\driver = mysqli' -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*username/c\username = ${pkpAppDatabaseUser}" -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*password/c\password = ${pkpAppDatabasePassword}" -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*name/c\name = ${pkpAppDatabaseName}" -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*cache/c\cache = none" -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*files_dir/c\files_dir = ${pkpAppDataPath}" -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^\s*force_ssl/c\force_ssl = Off' -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^;*\s*smtp =/c\smtp = On' -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^;*\s*smtp_server/c\smtp_server = no.mail.mitja.kom' -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^\s*oai =/c\oai = Off' -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^\s*repository_id/c\repository_id = "no.oai.test.kom"' -i ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion}

    cp ${pkpConfigFilePath}/config.inc.php.${pkpAppCodeVersion} ${pkpAppCodePath}/config.inc.php

    }

function emptyDatabase {

    parseOutput title "Handling database"
    parseOutput emphasis "Deleting all tables from $pkpAppName ($pkpAppDatabaseName) database."
    
    # Izbriši vse tabele - tudi tiste, ki so bile na novo ustvarjene med poskusi nadgradnje
    mysqldump -u $pkpAppDatabaseUser -p$pkpAppDatabasePassword --add-drop-table --no-data $pkpAppDatabaseName | grep -e '^DROP' | (echo "SET FOREIGN_KEY_CHECKS=0;"; cat; echo "SET FOREIGN_KEY_CHECKS=1;") | mysql -u $pkpAppDatabaseUser -p$pkpAppDatabasePassword $pkpAppDatabaseName

    }

function importDatabase {

    if [[ -n ${databaseBackupDate} ]]; then
        parseOutput emphasis "Importing database dump ${pkpStorage}/${pkpApp}/ojs-UL-ojs-${databaseBackupDate}.sql.gz"
        gunzip < "${pkpStorage}/${pkpApp}/ojs-UL-ojs-${databaseBackupDate}.sql.gz" | mysql -u $pkpAppDatabaseUser -p$pkpAppDatabasePassword $pkpAppDatabaseName 
    else
        # Import database backup
#         parseOutput emphasis "Importing database dump ${pkpAppDatabaseBackupFile}"
#         gunzip < $pkpAppDatabaseBackupFile | mysql -u $pkpAppDatabaseUser -p$pkpAppDatabasePassword $pkpAppDatabaseName 
        echo 'Nope'
    fi
    }

function importDatabaseMyDumper {

    # Import database backup
    parseOutput emphasis "Importing database dump ${pkpAppDatabaseBackupFile} with MyDumper"
    pkpAppDatabaseBackupMyDumperFolder="/home/mitja/omara/strezniki/localhost/pkp/storage/ojs/downloads/export-20210202-122624"
    myloader --database=$pkpAppDatabaseName --verbose=3 --threads 7 --directory=$pkpAppDatabaseBackupMyDumperFolder

    }

function fixCodeFilePermissions {

    parseOutput title "Handling files"
    parseOutput emphasis "Setting PKP application code file permissions / ${pkpAppCodePath}"

    # Fix PKP application code ownership and permissions
    chown -R administrator:www-data ${pkpAppCodePath}
    chmod 640 ${pkpAppCodePath}
    find ${pkpAppCodePath} -type d -exec chmod 750 {} +
    chmod -R g+w ${pkpAppCodePath}/public
    chmod -R g+w ${pkpAppCodePath}/cache

    # Posebnost: ker se ob shranjevanju sprememb datoteki spremeni skupina je potrebno dodati pravico branja za www-data
    chmod o+r ${pkpAppCodePath}/config.inc.php

    }


function fixDataFilePermissions {

    # Fix PKP application data ownership and permissions
    parseOutput emphasis  "Setting PKP application data file permissions / $pkpAppDataPath"
    chown -R ${pkpAppPhpPoolUser}:www-data $pkpAppDataPath
    chmod 640 $pkpAppDataPath
    find $pkpAppDataPath -type d -exec chmod 750 {} +

    }


function extractVersionReleaseFiles() {

    local pkpAppVersion="${1}"
    # Check the number of numbers in the version number
    versionVariant="$(echo ${pkpAppVersion} | awk -F'.' '{print NF}')"

    if [[ ${versionVariant} == 4 ]]; then

      pkpAppReleaseFileName="${pkpAppName}-${pkpAppVersion%.*}-${pkpAppVersion##*.}.tar.gz"

    elif [[ ${versionVariant} == 3 ]]; then

      pkpAppReleaseFileName="${pkpAppName}-${pkpAppVersion}.tar.gz"

    fi

    # Check if version release file exist / download it
    if [[ ! -f ${pkpAppDownloads}/$pkpAppReleaseFileName ]]; then

        local downloadURL="https://pkp.sfu.ca/${pkpAppName}/download/${pkpAppReleaseFileName}"
        wget --directory-prefix=$pkpAppDownloads $downloadURL
    else
        parseOutput emphasis "Release archive for ${pkpAppName} version $pkpAppVersion is already downloaded."
    fi

    # Check if version release file was successfuly downloaded
    if [[ ! -f ${pkpAppDownloads}/$pkpAppReleaseFileName ]]; then

        echo -e "Release file ${pkpAppReleaseFileName} download was not successful!"
        exit 1

    fi

    # Delete release folder if exists
    if [[ -d ${pkpAppDownloads}/${pkpAppReleaseFileName%.tar.gz} ]]; then

        rm -R ${pkpAppDownloads}/${pkpAppReleaseFileName%.tar.gz}

    fi

    parseOutput emphasis "Extracting release archive for ${pkpAppName} version $pkpAppVersion to ${pkpAppDownloads}"
#     cd ${pkpAppDownloads}/
#     pwd
#     echo "${pkpAppDownloads}/${pkpAppReleaseFileName}"
    tar -xzf ${pkpAppDownloads}/${pkpAppReleaseFileName} -C ${pkpAppDownloads}

    }

function prepareNewVersionCode() {

    extractVersionReleaseFiles "${1}"

    cp ${pkpAppCodePath}/config.inc.php ${pkpAppDownloads}/${pkpAppReleaseFileName%.tar.gz}/
    cp ${pkpAppCodePath}/.htaccess ${pkpAppDownloads}/${pkpAppReleaseFileName%.tar.gz}/
    cp -R ${pkpAppCodePath}/public ${pkpAppDownloads}/${pkpAppReleaseFileName%.tar.gz}/

    if [[ -d ${pkpAppDownloads}/plugins-${pkpAppVersion} ]]; then
      rsync -a ${pkpAppDownloads}/plugins-${pkpAppVersion}/plugins ${pkpAppDownloads}/${pkpAppReleaseFileName%.tar.gz}/
    fi
    
    if [[ -d ${pkpAppCodePath}.old ]]; then
      rm -R ${pkpAppCodePath}.old
    fi
    mv ${pkpAppCodePath} ${pkpAppCodePath}.old
    mv ${pkpAppDownloads}/${pkpAppReleaseFileName%.tar.gz} ${pkpAppCodePath}
    chmod -R 777 ${pkpAppCodePath}

    }

function getLatestVersionNumber {

  # Use the OJS/OMP upgrade script to check for latest available version
  echo "$(php ${pkpAppCodePath}/tools/upgrade.php check | grep 'Latest version' | awk -F':' '{print $2}' | awk '{$1=$1;print}')"

}

function compareFiles {

#     # Check the installed PKP app version
#     # Returns $pkpAppVersion i.e. 3.3.0.13
# 
#     getLocalInstanceAppCodeVersion
# 
#     # Checks/Prepares $pkpAppVersion release files
#     checkPkpVersionPackage "${pkpAppVersion}"

    # Find all directories in existing local PKP app installation
    parseOutput title "Searching plugins for $pkpApp in ${pkpAppCodePath}"
    parseOutput emphasis "List of plugins that were not found in original release package:"
    
    # To-Do:
    #   PKP Plugins List: http://pkp.sfu.ca/ojs/xml/plugins.xml
    #   bash: xmllint
    #   
#         # Get plugin data from plugins.xml file
#         
#         # If: plugins.xml file exists and is no more than one day old
#         ## Read cached API data
#         if [[ -f ${pkpAppDownloads}/${pkpAppPluginsXml} ]] && [[ $(date -r ${pkpAppDownloads}/${pkpAppPluginsXml} +%s > $(date -d "now -1 day" +%s) ]]; then
# 
#             echo "Reading cached plugins data"
#             
# 
#         # Else: 
#         ## Download new plugins.xml file
#         else
#             echo "Downloading plugins.xml file"
#             
#         fi
    
    declare -A customPlugins
    declare -A knownCustomPlugins=( ['addThis']="https://github.com/pkp/addThis/releases"
                                    ['piwik']="https://github.com/pkp/piwik/releases"
                                    ['customHeader']="https://github.com/pkp/customHeader/releases"
                                    ['translator']="https://github.com/pkp/translator/releases"
                                    ['citations']='https://github.com/RBoelter/citations/releases'
                                    ['quickSubmit']='https://github.com/pkp/quickSubmit'
                                    ['crossrefReferenceLinking']='https://github.com/pkp/crossrefReferenceLinking'
                                    ['defaultTranslation']='https://github.com/pkp/defaultTranslation'
                                    ['plagiarism']='https://github.com/pkp/plagiarism'
                                    ['funding']='https://github.com/ajnyga/funding'
                                    ['bootstrap3']='https://github.com/pkp/bootstrap3'
                                    ['inlineHtmlGalley']='https://github.com/ulsdevteam/inlineHtmlGalley'
#                                         ['']=''
    )

    
#         knownCustomPlugins['addThis']="https://github.com/pkp/addThis/releases"
    # Find all version.xml files (every plugin must have one) in current app instance
    while read versionFile; do

        # keep only the relative part of path within PKP application
        pluginVersionFile="$(echo "$versionFile" | sed "s|${pkpAppCodePath}/||g")"
        
        # Skip if pluginVersionFile is PKP app's version file
        if [[ $pluginVersionFile = 'dbscripts/xml/version.xml' ]]; then
            continue
        fi

        # Check if pluginVersionFile exist in freshly extracted package of the same version
        # If directory does not exist print pluginVersionFile
                
        if [[ ! -f ${pkpAppDownloads}/${pkpAppName}-${pkpAppVersion%.*}-${pkpAppVersion##*.}/${pluginVersionFile} ]]; then

            pluginName="$(cat $versionFile | grep -v 'DOCTYPE version' | xmlstarlet sel -t -m "/version" -v application -n)"
            
            echo "$pluginName — ${knownCustomPlugins["$pluginName"]}"
            echo -e "\t$pluginVersionFile\n\n"

#             for key in "${!knownCustomPlugins[@]}"; do
#                 if [[ $key = $pluginName ]]; then
#                     echo "${key} - ${knownCustomPlugins["$key"]}"
#                 fi
#             done

        fi

    done <<<"$(find ${pkpAppCodePath} -type f -name 'version.xml')"
    
#     for key in "${!knownCustomPlugins[@]}"; do
#         echo "$key"
#         echo ${knownCustomPlugins["$key"]}
#     done
}

function upgradePkpApp {

    # Upgrade PKP application
    cd ${pkpAppCodePath}
    sed 's/installed = On/installed = Off/' -i config.inc.php
    sudo -u ${pkpAppPhpPoolUser} php tools/upgrade.php upgrade
    sed 's/installed = Off/installed = On/' -i config.inc.php

    }

function checkPkpVersionPackage {

    # Check if all needed variables are set
    checkIfSourceSet
    checkIfVersionSet

    extractVersionReleaseFiles "${1}"

}


function convertsecs() {
  ((h=${1}/3600))
  ((m=(${1}%3600)/60))
  ((s=${1}%60))
  printf "\n |—> Executed in: %02d:%02d:%02d \n" $h $m $s
}

##
##  Functions below are not yet ported or tested with pkp-manager scripts
##

# function checkIfLocaleSet {
#     # Checks if $ompLocale variable is set and exit if not
#     if [[ -z $ompLocale ]]; then
#         echo -e "The variable \e[3mompLocale\e[0m must have a value!"
#         exit 1
#     fi
# }

# 
# function checkOMPVersionPackage {
# 
#     # Check if all needed variables are set
#     checkIfSourceSet
#     checkIfVersionSet
#     
#     # check if $ompVersion package exists and extract it
#     if [[ -f ${omara}/downloads/${pkpAppName}-${pkpAppVersion}.tar.gz ]]; then
#     
#         # Check if package is already extracted / if it is: delete it
#         if [[ -d ${omara}/downloads/${pkpAppName}-${pkpAppVersion} ]]; then
#             echo -e "Removing existing folder ${omara}/downloads/${pkpAppName}-${pkpAppVersion} \n"
#             rm -R ${omara}/downloads/${pkpAppName}-${pkpAppVersion}
#         fi
#         
#         # Extract files from $ompVersion to ${pkpAppDownloads}/
#         echo -e "Extracting version $ompVersion code \n"
#         tar -xzf ${omara}/downloads/${pkpAppName}-${pkpAppVersion}.tar.gz -C ${omara}/downloads
# 
#     else
#         # Output error message
#         echo "Version $ompVersion is not yet downloaded"
#         exit 1
#     fi
#     
# }
# 
# function convertVersion {
# 
#     ompVersionMajor="$(echo $1 | awk -F'.' '{print $1}')"
#     ompVersionMinor="$(echo $1 | awk -F'.' '{print $2}')"
#     ompVersionRevision="$(echo $1 | awk -F'.' '{print $3}')"
#     ompVersionBuild="$(echo $1 | awk -F'.' '{print $4}')"
# 
#     returnOMPVersion="$ompVersionMajor.$ompVersionMinor.$ompVersionRevision"
#     
#     if [[ $ompVersionBuild -ne 0 ]]; then
#         returnOMPVersion+="-$ompVersionBuild"
#     fi
#     
#     echo "$returnOMPVersion"
# 
# }

# function listLocaleFiles {
# 
#     # Check if all needed variables are set
#     checkIfSourceSet
#     checkIfLocaleSet
#     checkIfVersionSet
# 
#     if [[ $ompSource == 'zzff' ]]; then
#         sourceDir="${ompCode}"
#     elif [[ $ompSource == 'release' ]]; then
#         sourceDir="${omara}/downloads/${pkpAppName}-${pkpAppVersion}"
#         if [[ ! -d $sourceDir ]]; then
#             checkOMPVersionPackage
#         fi
#     fi
#     
#     for directory in $(find $sourceDir -type d -name "*${ompLocale}*"); do
# 
#         find $directory -mindepth 1 -type f
#     
#     done
# 
# }
# 
# function checkForLatestBackup {
# 
#     checkIfSSHKey
# 
#     backupDate="$(date +%Y%m%d-%w)"
#     latestBackup="omp-zzff-${backupDate}.tar"
#     
# 
#     if [[ ! -f ${omara}/backups/${latestBackup} ]]; then
# 
#         echo -e "Downloading $latestBackup to ${omara}/backups"
#         scp www-backup:/home/backuper/backups/zalozba/${latestBackup} ${omara}/backups
#         
#     fi
#     
#     if [[ ! -d ${omara}/backups/${latestBackup%.*} ]]; then
#         
#         echo -e "Extracting $latestBackup to ${omara}/backups"
#         echo -E "Expecting to finish in 15 minutes."
#         tar -xf ${omara}/backups/${latestBackup} -C ${omara}/backups
#         chown -R mitja:mitja ${omara}/backups/${latestBackup%.*}
#         cd ${omara}/backups/${latestBackup%.*}
#         gunzip knjige-${backupDate}.sql.gz
#         tar -xzf ${omara}/backups/${latestBackup%.*}/omp-${backupDate}.tar.gz -C ${omara}/backups/${latestBackup%.*}
#         tar -xzf ${omara}/backups/${latestBackup%.*}/omp-data-${backupDate}.tar.gz -C ${omara}/backups/${latestBackup%.*}
#     
#     fi
#     
# #     echo "Rsyncing code"
# # #     rsync -a --info=progress2 --delete ${omara}/backups/${latestBackup%.*}/omp/ ${omara}/backups/e-knjige/omp
# #     echo "Rsyncing data"
# #     rsync -a --info=progress2 --delete ${omara}/backups/${latestBackup%.*}/omp-data/ ${omara}/backups/e-knjige/omp-data
# #     echo "Copy database"
#     cp ${omara}/backups/${latestBackup%.*}/knjige-${backupDate}.sql ${omara}/backups/e-knjige
# }

function parseOutput() {

## https://en.wikipedia.org/wiki/ANSI_escape_code

## First number
# 0     reset
# 1     bold (increased intensity)
# 2     faint (decreased intensity)
# 3     italic
# 4     underline

reset=$'\e[0m'
bold=$'\e[1m'
faint=$'\e[2m'
italic=$'\e[3m'
underline=$'\e[4m'

# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37

red=$'\e[0;31m'
green=$'\e[0;32m'
blue=$'\e[0;34m'
magenta=$'\e[0;35m'
purple=$'\e[0;35m'
cyan=$'\e[0;36m'
white=$'\e[0;37m'

  case "$1" in

    title)
      echo -e "\n${red}${bold}${underline}${2}${reset}\n"
    ;;

    emphasis)
      echo -e "\n${cyan}${italic}" "${2}" "${reset}\n"
    ;;

    warning)
      echo -e "\n${magenta}${italic}" "${2}" "${reset}\n"
    ;;

  esac
}
