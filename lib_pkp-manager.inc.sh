###########
# Functions Library for Managing OMP Test Installation
#

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

function checkIfSourceSet {

    # Checks if $ompSource variable is set and exit if not
    if [[ -z $pkpSource ]]; then
        echo -e "The variable \e[3mpkpSource\e[0m must have a value!"
        exit 1
    fi

}

function checkIfLocaleSet {
    # Checks if $pkpAppLocale variable is set and exit if not
    if [[ -z $pkpAppLocale ]]; then
        echo -e "The variable \e[3mpkpAppLocale\e[0m must have a value!"
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


function checkIf_pkpAppUpgradeVersion {

    # Checks if $pkpAppUpgradeVersion variable is set and exit if not
    if [ -z ${pkpAppUpgradeVersion} ]; then
        echo -e "The variable \e[3m pkpAppUpgradeVersion \e[0m must have a value!"
        echo -e "Please run pkp-manager script with option \e[3m -u \e[0m."
        exit 1
    fi

    check_pkpAppVersionFormat

}


function check_pkpAppVersionFormat {

    # Checks if $pkpAppUpgradeVersion variable is in the right format (three dots) version and exit if not
    if [ "$(echo ${pkpAppUpgradeVersion} | awk -F'.' '{print NF}')" != 4 ]; then
        parseOutput warning "The variable \e[3m pkpAppUpgradeVersion \e[0m is defined in wrong format!"
        echo -e "\tPlease enter version number like \e[3m 3.4.0.5 \e[0m\n\n"
        exit 1
    fi

}


# Sync local app code
function syncAppCode {

    parseOutput title "Syncing ${pkpAppName}files"
    rsync -a --delete --info=progress2 ${pkpAppBackupPath}/${pkpApp}/ ${pkpAppCodePath}

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

function copyConfigurationFiles {

    # Get local instance version: i.e. 3.3.0.13
    getLocalInstanceAppCodeVersion
    
    cp ${pkpAppConfigFilePath}/config.inc.php.${pkpAppVersion} ${pkpAppCodePath}/config.inc.php
    cp ${pkpAppConfigFilePath}/robots.txt ${pkpAppCodePath}/robots.txt

}

function fixConfigurationFile {

    parseOutput emphasis "Fixing config file"
    
    if [[ -z $pkpAppCodeVersion ]]; then

        getLocalInstanceAppCodeVersion

    fi

    if [[ ! -f ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion} ]]; then

        cp ${pkpAppCodePath}/config.inc.php ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}

    fi

    #popravi konfiguracijsko datoteko
    sed "/^\s*base_url/c\base_url = \"http://${pkpAppTestURL}\"" -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*session_cookie_name/c\session_cookie_name = ${pkpApp^^}SID-test" -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^\s*driver/c\driver = mysqli' -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*username/c\username = ${pkpAppDatabaseUser}" -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*password/c\password = ${pkpAppDatabasePassword}" -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*name/c\name = ${pkpAppDatabaseName}" -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*cache/c\cache = none" -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed "/^\s*files_dir/c\files_dir = ${pkpAppDataPath}" -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^\s*force_ssl/c\force_ssl = Off' -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^;*\s*smtp =/c\smtp = On' -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^;*\s*smtp_server/c\smtp_server = no.mail.mitja.kom' -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^\s*oai =/c\oai = Off' -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}
    sed '/^\s*repository_id/c\repository_id = "no.oai.test.kom"' -i ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion}

    cp ${pkpAppConfigFilePath}/config.inc.php.${pkpAppCodeVersion} ${pkpAppCodePath}/config.inc.php

    }

function emptyDatabase {

    parseOutput title "Handling database"
    parseOutput emphasis "Deleting all tables from $pkpAppName ($pkpAppDatabaseName) database."
    
    # Izbriši vse tabele - tudi tiste, ki so bile na novo ustvarjene med poskusi nadgradnje
    mysqldump -u $pkpAppDatabaseUser -p$pkpAppDatabasePassword --add-drop-table --no-data $pkpAppDatabaseName | grep -e '^DROP' | (echo "SET FOREIGN_KEY_CHECKS=0;"; cat; echo "SET FOREIGN_KEY_CHECKS=1;") | mysql -u $pkpAppDatabaseUser -p$pkpAppDatabasePassword $pkpAppDatabaseName

    }

function importDatabase {

    # If: date of database dump is defined with option -d [yyymmdd-hh]
    if [[ -n ${databaseBackupDate} ]]; then
    
        parseOutput emphasis "Importing from database dump version defined with -d option: ${databaseBackupDate}"

        mysqlDump_fileName="${pkpAppStoragePath}/ojs-UL-ojs-${databaseBackupDate}.sql.gz"
        
    # Else: Select the latest backup file that is available in ${pkpAppBackupPath}
    else

        parseOutput emphasis "Importing the latest available database dump version"

        mysqlDump_fileName="$(find ${pkpAppBackupPath} -name "${pkpAppName}-UL-${pkpAppName}-*.sql.gz" | sort | tail -1)"

    fi


    # If: variable syncDatabaseVersion is defined with option -d [full|trim]
    if [[ ${syncDatabaseVersion} = 'full' ]]; then

        parseOutput emphasis "Importing full database dump ${mysqlDump_fileName}"

        zcat ${mysqlDump_fileName} | mysql -u $pkpAppDatabaseUser -p$pkpAppDatabasePassword $pkpAppDatabaseName 

    # Else: import trimmed version by default
    else

        parseOutput emphasis "Importing trimmed database dump ${mysqlDump_fileName}"

        zcat ${mysqlDump_fileName} \
            | sed '/INSERT INTO `metrics`/d' \
            | sed '/INSERT INTO `submission_search_object_keywords`/d' \
            | mysql -u $pkpAppDatabaseUser -p$pkpAppDatabasePassword ${pkpAppDatabaseName}
    fi

}

# ToDo: Change backup script to make databasebackups with mydumper
# function importDatabaseMyDumper {
# 
#     # Import database backup
#     parseOutput emphasis "Importing database dump ${pkpAppDatabaseBackupFile} with MyDumper"
#     pkpAppDatabaseBackupMyDumperFolder="/home/mitja/omara/strezniki/localhost/pkp/storage/ojs/downloads/export-20210202-122624"
#     myloader --database=$pkpAppDatabaseName --verbose=3 --threads 7 --directory=$pkpAppDatabaseBackupMyDumperFolder
# 
#     }

function fixCodeFilePermissions {

    parseOutput title "Handling files"
    parseOutput emphasis "Setting PKP application code file permissions in ${pkpAppCodePath}"

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
    parseOutput emphasis  "Setting PKP application data file permissions in $pkpAppDataPath"
    chown -R ${pkpAppPhpPoolUser}:www-data $pkpAppDataPath
    chmod 640 $pkpAppDataPath
    find $pkpAppDataPath -type d -exec chmod 750 {} +

    }


function getVersionReleaseFiles() {

    local pkpAppVersion="${1}"
    local pkpAppReleaseFileName="${pkpAppName}-${pkpAppVersion%.*}-${pkpAppVersion##*.}.tar.gz"
    local pkpAppReleasePath="${pkpAppDownloadsPath}/${pkpAppName}-${pkpAppVersion}"

    # Checks if supplied version number is in correct format
    check_pkpAppVersionFormat
    
    # Check if version release file exist / download it
    if [[ ! -f ${pkpAppDownloadsPath}/$pkpAppReleaseFileName ]]; then

        local downloadURL="https://pkp.sfu.ca/${pkpAppName}/download/${pkpAppReleaseFileName}"
        wget --directory-prefix=$pkpAppDownloadsPath $downloadURL
        
    else
    
        parseOutput emphasis "Release archive for ${pkpAppName} version $pkpAppVersion is already downloaded in $pkpAppDownloadsPath directory."

    fi

    # Check if version release file was successfuly downloaded
    if [[ ! -f ${pkpAppDownloadsPath}/$pkpAppReleaseFileName ]]; then

        echo -e "Release file ${pkpAppReleaseFileName} download was not successful!"
        exit 1

    fi

    # Delete release folder if exists
    if [[ -d ${pkpAppReleasePath} ]]; then

        rm -R ${pkpAppReleasePath}

    fi

    parseOutput emphasis "Extracting release archive for ${pkpAppName} version $pkpAppVersion to ${pkpAppDownloadsPath}"

    tar -xzf ${pkpAppDownloadsPath}/${pkpAppReleaseFileName} -C ${pkpAppDownloadsPath}

    # Rename the directory name to 'three dots' release version number
    mv ${pkpAppDownloadsPath}/${pkpAppReleaseFileName%.tar.gz} ${pkpAppReleasePath}
}

function prepare_upgradeVersionCode() {

    # Check if config file for upgrade version exist
    if [[ ! -f ${pkpAppConfigFilePath}/config.inc.php.${pkpAppUpgradeVersion} ]]; then
    
        parseOutput warning "Configuration file for version ${pkpAppUpgradeVersion} does not exist"
        echo -e "\tCompare the current cofig file with newest available local version:"

        echo -e "\tcolordiff -y $(find ${pkpAppConfigFilePath} -name 'config.inc.php.*' | sort | tail -1) ${pkpAppDownloadsPath}/${pkpAppName}-${pkpAppUpgradeVersion}/config.TEMPLATE.inc.php"

        exit 1
    fi

    echo "Copying version ${pkpAppUpgradeVersion} code to ${pkpAppNewCodePath} directory"
    cp -R ${pkpAppDownloadsPath}/${pkpAppName}-${pkpAppUpgradeVersion} ${pkpAppNewCodePath}/
    
    # Copy files from local instance to upgrade version
    cp ${pkpAppConfigFilePath}/config.inc.php.${pkpAppUpgradeVersion} ${pkpAppNewCodePath}/config.inc.php
    cp ${pkpAppCodePath}/.htaccess ${pkpAppNewCodePath}/
    cp -R ${pkpAppCodePath}/public ${pkpAppNewCodePath}/
    
    if [[ -d ${pkpAppCodePath}.old ]]; then
      rm -R ${pkpAppCodePath}.old
    fi
    
    mv ${pkpAppCodePath} ${pkpAppCodePath}.old
    mv ${pkpAppNewCodePath} ${pkpAppCodePath}
    chmod -R 777 ${pkpAppCodePath}

    # Checking for files that previously caused erros during upgrade
    declare -a checkDirectory
    checkDirectory+=("${pkpAppDataPath}/usageStats/reject")
    checkDirectory+=("${pkpAppDataPath}/usageStats/usageEventLogs")
    for directory in ${checkDirectory[@]}; do
        if [[ -n $(ls -A ${directory} ) ]]; then
          echo "Cleaning directory: ${directory}"
          rm ${directory}/*
        fi
    done

    parseOutput emphasis1 "Checking the upgrade"
    cd ${pkpAppCodePath}
    sudo -u ${pkpAppPhpPoolUser} php tools/upgrade.php check
}

function prepare_upgradeVersionPlugins {

    if [[ -d ${pkpAppDownloads_plugins}/plugins ]]; then

        parseOutput note "Copying ${pkpAppDownloads_plugins}/plugins to ${pkpAppCodePath}/"
        cp -R ${pkpAppDownloads_plugins}/plugins ${pkpAppCodePath}/

    else
        parseOutput warning "Directory ${pkpAppDownloads_plugins}/plugins is missing."
        exit 1
    fi

}

function upgradePkpApp {

    local upgrade_logFile="/home/administrator/upgrade-logs/upgrade_${pkpAppUpgradeVersion}_$(date +%Y%m%d-%H%M).log"

    parseOutput title "Upgrading ${pkpAppName} to version ${pkpAppUpgradeVersion}"
    parseOutput emphasis "Check logs with:"
    echo -e "\t tail -f ${upgrade_logFile}"

    cd ${pkpAppCodePath}
    sed 's/installed = On/installed = Off/' -i config.inc.php
    sudo -u ${pkpAppPhpPoolUser} bash -c "php tools/upgrade.php upgrade |& tee ${upgrade_logFile}"
    sed 's/installed = Off/installed = On/' -i config.inc.php
    parseOutput emphasis1 "\tUpgrade finished."
    
}


function getLatestVersionNumber {

  # Use the OJS/OMP upgrade script to check for latest available version
  echo "$(php ${pkpAppCodePath}/tools/upgrade.php check | grep 'Latest version' | awk -F':' '{print $2}' | awk '{$1=$1;print}')"

}

function get_customPlugins {

    # Find all directories in existing local PKP app installation
    parseOutput title "Searching plugins for $pkpApp in ${pkpAppCodePath}"
    parseOutput emphasis "List of plugins that were not found in original release package:"

    declare -gA customPlugins

    # Find all version.xml files (every plugin must have one) in current app instance
    echo -e  "\tSearching instance plugins in ${pkpAppCodePath}"
    while read versionFile; do

        # keep only the relative part of path within PKP application
        pluginVersionFile="$(echo "$versionFile" | sed "s|${pkpAppCodePath}/||g")"
        
        # Skip if pluginVersionFile is PKP app's version file
        if [[ $pluginVersionFile = 'dbscripts/xml/version.xml' ]]; then
            continue
        fi

        # Check if pluginVersionFile exist in freshly extracted package of the same version
        # If directory does not exist print pluginVersionFile

        if [[ ! -f ${pkpAppDownloadsPath}/${pkpAppName}-${pkpAppVersion}/${pluginVersionFile} ]]; then

            # Parse plugin version file
            pluginName="$(xmlstarlet sel -t -v '//version/application' -n $versionFile)"
            pluginType="$(xmlstarlet sel -t -v '//version/type' -n $versionFile)"
            
            parseOutput emphasis1 "$pluginName"
            echo -e "\tFile path: $pluginVersionFile"
            echo -e "\tType: $pluginType\n"
            
            customPlugins["$pluginName"]="$pluginType"

        fi

    done <<<"$(find ${pkpAppCodePath} -type f -name 'version.xml')"

    parseOutput note "Found ${#customPlugins[@]} custom plugins."
}

function download_customPlugins {

    parseOutput title "Dowloading custom plugins for version ${pkpAppUpgradeVersion}"

    # Plugin Gallery https://github.com/pkp/plugin-gallery/
    local pluginsUrl="https://pkp.sfu.ca/ojs/xml/plugins.xml"

    pkpAppPluginsXml="${pkpAppDownloadsPath}/plugins.xml"

    # Create directory if missing
    if [[ ! -d ${pkpAppDownloads_plugins} ]]; then
        mkdir ${pkpAppDownloads_plugins}
    fi

    # If: exists -remove plugins subfolder
    if [[ -d ${pkpAppDownloads_plugins}/plugins ]]; then
        rm -R ${pkpAppDownloads_plugins}/plugins
    fi

    # If: plugins.xml file exists and is no more than one day old
    ## Read cached API data
    if [[ -f ${pkpAppPluginsXml} ]] && [[ $(date -r ${pkpAppPluginsXml} +%s) > $(date -d "now -1 day" +%s) ]]; then

        echo "Reading cached plugins data from ${pkpAppPluginsXml}"

    else

        if [[ -f ${pkpAppPluginsXml} ]]; then
            echo "Removing ${pkpAppPluginsXml}"
            rm ${pkpAppPluginsXml}
        fi

        echo "Downloading plugins.xml file to ${pkpAppPluginsXml}"
        wget --directory-prefix=${pkpAppDownloadsPath} ${pluginsUrl}

    fi

    for key in "${!customPlugins[@]}"; do

        parseOutput emphasis "Processing plugin: ${key}"

        pluginCategory="${customPlugins["$key"]}"
        declare -a plugin_Urls
        declare -gA plugins_missingVersion

        xpath_match="//_:plugin[@product=\"${key}\"]/_:release[contains(_:compatibility/_:version, \"3.4.0.\")]"
        xpath_valueOf="_:package"

        plugin_Urls+=($(xmlstarlet sel -t -m "${xpath_match}" -v ${xpath_valueOf} -n ${pkpAppPluginsXml}))

        plugin_numberOfVersions="${#plugin_Urls[@]}"

        # If: no URLs - add to array to display in a list of missing plugin versions
        if [[ ${plugin_numberOfVersions} = 0 ]]; then

            parseOutput warning "Mising plugin version for ${pkpAppUpgradeVersion}"
            xpath_matchHomepage="//_:plugin[@product=\"${key}\"]"
            xpath_valueOfHomepage="_:homepage"
            plugins_missingVersion["${key}"]="$(xmlstarlet sel -t -m "${xpath_matchHomepage}" -v ${xpath_valueOfHomepage} -n ${pkpAppPluginsXml})"

        # If: one URL - check if is laready downloaded and download if it's not
        elif [[ ${plugin_numberOfVersions} = 1 ]]; then

            downloadPluginReleaseFile ${key} ${plugin_Urls[0]}
            prepare_customPlugins ${key}  ${plugin_Urls[0]}

        # If: multiple URLs > download the last one
        else

            i=$((${plugin_numberOfVersions} - 1))
            downloadPluginReleaseFile ${key} ${plugin_Urls[${i}]}
            prepare_customPlugins ${key} ${plugin_Urls[${i}]}

        fi
        
        unset plugin_Urls

    done

    
    parseOutput title "Plugins with no version for ${pkpAppUpgradeVersion}"
    for plugin in "${!plugins_missingVersion[@]}"; do
        echo -e "\t${plugin} -> ${plugins_missingVersion["${plugin}"]}"       
    done

    parseOutput note "From ${#customPlugins[@]} custom plugins, ${#plugins_missingVersion[@]} do not have version available for ${pkpAppUpgradeVersion}."
}

function downloadPluginReleaseFile() {
    
    local plugin_name="${1}"
    local plugin_downloadUrl="${2}"
    local plugin_fileName="$(basename ${plugin_downloadUrl})"

    # If: plugin release file is already dowwnloaded
    if [[ -f ${pkpAppDownloads_plugins}/${plugin_fileName} ]]; then
        echo -e "\tPlugin release file already downloaded in ${pkpAppDownloads_plugins}"
    # Else: download it
    else
        echo -e "\tDownloading ${plugin_downloadUrl} to ${pkpAppDownloads_plugins}"
        wget --directory-prefix=${pkpAppDownloads_plugins} ${plugin_downloadUrl}
    fi

}


function prepare_customPlugins {

    local plugin_name="${1}"
    local plugin_downloadUrl="${2}"
    local plugin_fileName="$(basename ${plugin_downloadUrl})"
    local plugin_versionFile="${pkpAppDownloads_plugins}/${plugin_name}/version.xml"

    # Unpack the plugin files
    tar -xzf ${pkpAppDownloads_plugins}/${plugin_fileName} -C ${pkpAppDownloads_plugins}

    # Parse plugin version file
    pluginType="$(cat $plugin_versionFile | grep -v '<!DOCTYPE' | xmlstarlet sel  -t -v '//version/type' -n)"
    
    # If directory does not exist - create it
    local plugin_directoryPath="${pkpAppDownloads_plugins}/$(echo ${pluginType} | tr '.' '/')"
    if [[ ! -d ${plugin_directoryPath} ]]; then
        mkdir -p ${plugin_directoryPath}
    fi
    # Move them to ${pkpAppDownloadsPath}/plugins-${pkpAppVersion} 
    mv ${pkpAppDownloads_plugins}/${plugin_name} ${plugin_directoryPath}

}


function prepare_missingCustomPlugins() {

    parseOutput title "Preparing plugins with manualy downloaded release file for ${pkpAppUpgradeVersion}"

    for plugin in ${1}; do
        parseOutput emphasis "Processing plugin: ${plugin}"
        local plugin_name="${plugin}"
        local plugin_filePath="$(find ${pkpAppDownloads_plugins} -type f -name "${plugin_name}*.tar.gz")"
        local plugin_fileName="$(basename ${plugin_filePath})"
        local plugin_versionFile="${pkpAppDownloads_plugins}/${plugin_name}/version.xml"

        # Test run
        if [[ -n $testRun ]]; then
            parseOutput emphasis "Initial variables:"
            echo "Parameters passed to function: ${1}"
            echo "plugin_filePath: ${plugin_filePath}"
            echo "plugin_fileName: ${plugin_fileName}"
            echo "plugin_versionFile: ${plugin_versionFile}"
        fi
        if [[ -z ${plugin_filePath} ]]; then
            parseOutput warning "Plugin release file not found. You need to download the file manualy"
            continue
        fi
        # Unpack the plugin files
        tar -xzf ${pkpAppDownloads_plugins}/${plugin_fileName} -C ${pkpAppDownloads_plugins}

        # Parse plugin version file
        pluginType="$(cat $plugin_versionFile | grep -v '<!DOCTYPE' | xmlstarlet sel  -t -v '//version/type' -n)"

        # If directory does not exist - create it
        local plugin_directoryPath="${pkpAppDownloads_plugins}/$(echo ${pluginType} | tr '.' '/')"
        if [[ ! -d ${plugin_directoryPath} ]] && [[ -z $testRun ]]; then
            mkdir -p ${plugin_directoryPath}
        fi
        # Move them to ${pkpAppDownloads}/plugins-${pkpAppVersion} 
        if [[ -z $testRun ]]; then
            mv ${pkpAppDownloads_plugins}/${plugin_name} ${plugin_directoryPath}
        fi

        if [[ -n $testRun ]]; then
            parseOutput emphasis "Commands and variables"
            echo "tar -xzf ${pkpAppDownloads_plugins}/${plugin_fileName} -C ${pkpAppDownloads_plugins}"
            echo "pluginType: ${pluginType}"
            echo "mkdir -p ${plugin_directoryPath}"
            echo "mv ${pkpAppDownloads_plugins}/${plugin_name} ${plugin_directoryPath}"
        fi
    done

}

function testing() {

    echo $testRun

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
#         # Extract files from $ompVersion to ${pkpAppDownloadsPath}/
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

    emphasis1)
      echo -e "\n${green}${italic}" "${2}" "${reset}\n"
    ;;

    warning)
      echo -e "\n${magenta}${italic}" "${2}" "${reset}\n"
    ;;

    note)
      echo -e "\n${purple}${italic}" "${2}" "${reset}\n"
    ;;

  esac
}
