#!/bin/bash
MYSQL_USER="root"
MYSQL_PASSWORD=""
WWW_ROOT="/srv/www"
CMD_MASTER_STATUS="SHOW MASTER STATUS"
CMD_SLAVE_STATUS="SHOW SLAVE STATUS\G"
OUTPUT_DIR="/backup"
#LOG=${OUTPUT_DIR}/dump.log
LOCK="SET GLOBAL read_only = 1"
UNLOCK="UNLOCK TABLES"
FT=date +%Y-%m-%d_%H%M
REMOTE_OUTPUT_DIR="/mnt/backup"

if ! mountpoint -q -- ${REMOTE_OUTPUT_DIR}; then 
	echo "${REMOTE_OUTPUT_DIR} is't mount" | mail -s "Backup error" audit@corp.net
	exit 1
fi 

if ! mountpoint -q -- ${OUTPUT}; then
	echo "${OUTPUT_DIR} is't mount" | mail -s "Backup error" audit@corp.net
	exit 1
fi

rm ${OUTPUT_DIR}/dump.sql.gz
rm ${OUTPUT_DIR}/master.mysql.log
rm ${OUTPUT_DIR}/slave.mysql.log
#GET REPLICATION STATUSES
echo -e "/bin/date LOG master and slave\n" 
mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e"${CMD_MASTER_STATUS}" > ${OUTPUT_DIR}/master.mysql.log${FT}
mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e"${CMD_SLAVE_STATUS}" > ${OUTPUT_DIR}/slave.mysql.log${FT}

#DUMPING MYSQL
echo -e "/bin/date dumping....\n" 
mysqldump —extended-insert —single-transaction —user=${MYSQL_USER} —password=${MYSQL_PASSWORD} —databases telemetry ep portal_health | gzip > ${OUTPUT_DIR}/dump${FT}.sql.gz
#mysqldump —extended-insert —single-transaction —user=${MYSQL_USER} —password=${MYSQL_PASSWORD} —databases ep portal_health > "${OUTPUT_DIR}/dump1${FT}.sql"
echo -e "/bin/date dump complete\n" 

# Move dumps to remote server
cp ${OUTPUT_DIR}/dump${FT}.sql.gz       ${REMOTE_OUTPUT_DIR}/dump${FT}.sql.gz
cp ${OUTPUT_DIR}/master.mysql.log${FT}  ${REMOTE_OUTPUT_DIR}/master.mysql.log${FT}
cp ${OUTPUT_DIR}/slave.mysql.log${FT}   ${REMOTE_OUTPUT_DIR}/slave.mysql.log${FT}
mv ${OUTPUT_DIR}/dump${FT}.sql.gz       ${OUTPUT_DIR}/dump.sql.gz
mv ${OUTPUT_DIR}/master.mysql.log${FT}  ${OUTPUT_DIR}/master.mysql.log
mv ${OUTPUT_DIR}/slave.mysql.log${FT}   ${OUTPUT_DIR}/slave.mysql.log
	
echo -e "/bin/date dump.sh finished\n"
