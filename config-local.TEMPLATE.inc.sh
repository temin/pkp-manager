# Host and Application specific variables
case "$1" in

    host)
        pkpRootPath=""
        pkpBackupRootPath="${pkpRootPath}/backup"
        pkpWebRootPath="${pkpRootPath}/www"
        pkpConfigFilePath="${pkpRootPath}/config-files/${pkpApp}"

        backupServerSSHKey=""
        backupServerUser=""
        backupServerDirectory=""

        pkpStorage="${pkpRootPath}/storage"

        # Database settings
        pkpAppDatabaseUser=""
        pkpAppDatabasePassword=""
    ;;
    
    ojs)
        appWebRootDirName=""
        appCodePath="${pkpApp}"
        appDataPath=""
        pkpAppDatabaseName=""
        pkpAppTestURL=""
        pkpAppCodePath=""
        pkpAppDataPath=""
        pkpAppBackupRootPath=""
    ;;
    
    omp)
        appWebRootDirName=""
        appCodePath="${pkpApp}"
        appDataPath=""
        pkpAppDatabaseName=""
        pkpAppTestURL=""
    ;;

esac
