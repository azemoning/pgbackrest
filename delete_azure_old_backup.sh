#!/bin/bash

## export environment variable into cron env
export $(cat /root/pg_backup/env.env | xargs)

###########################
####### LOAD CONFIG #######
###########################
 
while [ $# -gt 0 ]; do
        case $1 in
                -c)
                        if [ -r "$2" ]; then
                                source "$2"
                                shift 2
                        else
                                ${ECHO} "Unreadable config file \"$2\"" 1>&2
                                exit 1
                        fi
                        ;;
                *)
                        ${ECHO} "Unknown Option \"$1\"" 1>&2
                        exit 2
                        ;;
        esac
done
 
if [ $# = 0 ]; then
        SCRIPTPATH=$(cd ${0%/*} && pwd -P)
        source $SCRIPTPATH/pg_backup.config
fi;
 
###########################
#### PRE-DELETE CHECKS ####
###########################
 
# Make sure we're running as the required backup user
if [ "$BACKUP_USER" != "" -a "$(id -un)" != "$BACKUP_USER" ]; then
	echo "This script must be run as $BACKUP_USER. Exiting." 1>&2
	exit 1;
fi;
 
 
###########################
### INITIALISE DEFAULTS ###
###########################
 
if [ ! $HOSTNAME ]; then
	HOSTNAME="localhost"
fi;
 
if [ ! $USERNAME ]; then
	USERNAME="postgres"
fi;

if [ ! $PORT ]; then
	PORT=5432
fi;
 
 
###########################
##### STARTING DELETE #####
###########################
 
TARGET_DATE=`date -d "-5 day" +%Y-%d-%m` 
 
FULL_BACKUP_QUERY="select datname from pg_database where not datistemplate and datallowconn order by datname;"
 
echo -e "\n\nPerforming delete"
echo -e "--------------------------------------------\n"
 
for DATABASE in `psql -h "$HOSTNAME" -U "$USERNAME" -p $PORT -At -c "$FULL_BACKUP_QUERY" postgres`
do
	if [ $ENABLE_CUSTOM_BACKUPS = "yes" ]
	then
        /root/pg_backup/azcopy rm $BLOB_URL"/$TARGET_DATE/$DATABASE/old/$BLOB_SAS" --include "*.dump"
	fi
 
done