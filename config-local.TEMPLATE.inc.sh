# List of available applications
# all 'case' options below, except 'host'
# do not forget to sync if adding new application!
list_availablePkpApps=( )

# Host and Application specific variables
case "$1" in

# Host configuration
    host)
        pkpRootPath=""
        pkpWebRootPath=""
        pkpStorage="${pkpRootPath}/${pkpApp}/storage"
        pkpAppBackupPath="${pkpRootPath}/${pkpApp}/backup"

        pkpConfigFilePath="${pkpStorage}/${pkpApp}/config-files"

        # Database settings
        pkpAppDatabaseUser=""
        pkpAppDatabasePassword=""
    ;;

# Apps configuration
    app1)
        pkpAppName=""
        appWebRootDirName=""
        appCodePath=""
        appDataPath=""

        pkpAppDatabaseName=""
        pkpAppDatabaseUser=""
        pkpAppDatabasePassword=""
        
        pkpAppPhpPoolUser=""
        pkpAppPhpPoolGroup=""
    ;;

    app2)
        pkpAppName=""
        appWebRootDirName=""
        appCodePath=""
        appDataPath=""
        
        pkpAppDatabaseName=""
        pkpAppDatabaseUser=""
        pkpAppDatabasePassword=""

        pkpAppPhpPoolUser=""
        pkpAppPhpPoolGroup=""
    ;;

esac

# Comon (generated) variables
pkpAppCodePath="${pkpWebRootPath}/${appWebRootDirName}/${appCodePath}"
pkpAppDataPath="${pkpWebRootPath}/${appWebRootDirName}/${appDataPath}"
