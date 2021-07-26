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
    
    app1)
        appWebRootDirName=""
        appCodePath="${pkpApp}"
        appDataPath=""
        pkpAppDatabaseName=""
        pkpAppTestURL=""
    ;;
    
    app2)
        appWebRootDirName=""
        appCodePath="${pkpApp}"
        appDataPath=""
        pkpAppDatabaseName=""
        pkpAppTestURL=""
    ;;

esac
