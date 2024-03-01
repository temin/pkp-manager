# List of available applications
# do not forget to sync if adding new application!
list_availablePkpApps=( ojs omp )

# Host and Application specific variables
case "$1" in

# Host configuration
    host)
        pkpRootPath="/root/pkp" # directory path where pkp-manager script will store files
        pkpWebRootPath="/var/www" # web server root path

        pkpAppStoragePath="${pkpRootPath}/${pkpApp}/storage"
        pkpAppBackupPath="${pkpRootPath}/${pkpApp}/backup" # for storing app backups
        pkpAppDownloadsPath="${pkpRootPath}/${pkpApp}/downloads" # for files downloaded from web ( pKP releases, plugins,...)
        pkpAppTmpPath="${pkpRootPath}/${pkpApp}/tmp" # for temporary files
        pkpAppConfigFilePath="${pkpRootPath}/${pkpApp}/config-files" # for storing versions of local configuration files

        # Database settings
        # define if one user has access to all databases defined below
        pkpAppDatabaseUser=""
        pkpAppDatabasePassword=""
    ;;

# Apps configuration
    ojs)
        pkpAppName="ojs" # PKP app name: ojs, omp, ops, ...
        appWebRootDirName="" # Directory name (in web root) where app code an files are stored
        appCodePath="ojs" # directory name for PKP app code
        appDataPath="ojs-data" # directory name for PKP app files

        pkpAppDatabaseName=""
        pkpAppDatabaseUser=""
        pkpAppDatabasePassword=""
        
        pkpAppPhpPoolUser="www-data"
        pkpAppPhpPoolGroup="www-data"
    ;;

    omp)
        pkpAppName="omp"
        appWebRootDirName=""
        appCodePath="omp"
        appDataPath="omp-data"
        
        pkpAppDatabaseName=""
        pkpAppDatabaseUser=""
        pkpAppDatabasePassword=""

        pkpAppPhpPoolUser="www-data"
        pkpAppPhpPoolGroup="www-data"
    ;;

esac

# Comon (generated) variables
pkpAppCodePath="${pkpWebRootPath}/${appWebRootDirName}/${appCodePath}" # Full path to PKP app code
pkpAppDataPath="${pkpWebRootPath}/${appWebRootDirName}/${appDataPath}" # Full path to PKP app files: files_dir
pkpAppNewCodePath="${pkpAppCodePath}.new" # Full path to dirctory where PKP app's new version code is assembled for upgrade
