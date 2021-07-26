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

## No variables to edit below this line ##

## Directories
pkpAppBackupRootPath="${pkpBackupRootPath}/${appWebRootDirName}"
pkpAppCodePath="${pkpWebRootPath}/${pkpApp}"
pkpAppDataPath="${pkpAppBackupRootPath}/${appDataPath}"
pkpAppStorage="${pkpStorage}/${pkpApp}"
pkpAppDownloads="${pkpAppStorage}/downloads"

pkpAppDatabaseBackupFile="$(find ${pkpBackupRootPath}/backups/ -type f -name "${pkpApp}*")"

# Run checks and tests on configured files and directories variables
source lib_tests.inc.sh "config_check-dir-file"
