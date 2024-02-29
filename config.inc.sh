#!/bin/bash

# Run initial tests
source lib_tests.inc.sh "config_on-load"

# Get local host variables
source config-local.inc.sh "host"

# Stop processing configuration if only syncing files from backup server
if [[ $subcommand = 'sync-backup' ]]; then
    return
fi

# Get local application variables
source config-local.inc.sh "${pkpApp}"

# Define directory for upgrade version plugin files
pkpAppDownloads_plugins="${pkpAppDownloadsPath}/plugins-${pkpAppUpgradeVersion}"
        
## No variables to edit below this line ##

# Run checks and tests on configured files and directories variables
source lib_tests.inc.sh "config_check-dir-file"

### BEGIN To-Do: commented out on 20240131 - delete if not needed ###
# # Configuration post-processing
# for key in ${!configPostProcessing[@]}; do
# 
#     value="${configPostProcessing["${key}"]}"
# 
# done
### END To-Do: commented out on 20240131 - delete if not needed ###

# Define version number of app's local instance
getLocalInstanceAppCodeVersion
