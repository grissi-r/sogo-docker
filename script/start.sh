#!/bin/bash

source /usr/local/bin/common.sh


log() {
    printf "$(date +"%F %T,%3N") $1$NC\n"
}

check_require() {
    if [[ -z ${2//[[:blank:]]/} ]]; then
        log_error "$1 is required"
        exit 1
    fi
}

update_conf(){
     log "setting value for $1"
     sed -i '$d' /etc/sogo/sogo.conf
     echo "   $1 = $2;" >> /etc/sogo/sogo.conf
     echo "}" >> /etc/sogo/sogo.conf
}

WORKERS_COUNT=${WORKERS_COUNT:-5}

# reset config
echo -en '{\n}' > /etc/sogo/sogo.conf

for conf in $(printenv| grep -i SOGO_ | cut -d= -f1);do
    update_conf "${conf:5}" "${!conf}"
done

log "DB .."
dockerize -timeout 60s -wait tcp://${MYSQL_SERVER}:${MYSQL_PORT}
if [[ $? -ne 0 ]]; then
    log ".. Cannot connect"
    exit 1
fi
log ".. connected"

if [[ -z "`mysql -h$MYSQL_SERVER -P${MYSQL_PORT:-3306} -uroot -p$MYSQL_ROOT_PASSWORD -qfsBe "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$MYSQL_USER'" 2>&1`" ]];then
log ".. not existing -> Creating"
mysql -h$MYSQL_SERVER -P$MYSQL_PORT -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE $MYSQL_DATABASE_NAME CHARACTER SET='utf8mb4';"
mysql -h$MYSQL_SERVER -P$MYSQL_PORT -uroot -p$MYSQL_ROOT_PASSWORD -e "
  CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PASSWORD';
  GRANT ALL PRIVILEGES ON $MYSQL_DATABASE_NAME.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;"
mysql -h$MYSQL_SERVER -P$MYSQL_PORT -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE_NAME < /usr/local/bin/mysql-utf8mb4.sql
else
log ".. exist"
fi

update_conf "SOGoProfileURL"        \"mysql://$MYSQL_USER:$MYSQL_USER_PASSWORD@$MYSQL_SERVER:$MYSQL_PORT/$MYSQL_DATABASE_NAME/sogo_user_profile\"
update_conf "OCSFolderInfoURL"      \"mysql://$MYSQL_USER:$MYSQL_USER_PASSWORD@$MYSQL_SERVER:$MYSQL_PORT/$MYSQL_DATABASE_NAME/sogo_folder_info\"
update_conf "OCSSessionsFolderURL"  \"mysql://$MYSQL_USER:$MYSQL_USER_PASSWORD@$MYSQL_SERVER:$MYSQL_PORT/$MYSQL_DATABASE_NAME/sogo_sessions_folder\"


log "Apache Server .."

mkdir /var/log/apache2/
echo "ServerName ${APACHE_SERVER_NAME}"
echo "ServerName ${APACHE_SERVER_NAME}" > /etc/apache2/conf-available/servername.conf
a2enmod proxy_http
a2enmod headers
a2enconf servername
if [ ! -f /etc/apache2/conf-available/SOGo.conf ]
then
    cp /etc/apache2/conf.d/SOGo.conf /etc/apache2/conf-available/
fi
a2enconf SOGo

cp /usr/local/bin/index.html /var/www/html/index.html

service apache2 restart

log ".. started"

log "Memcached .."
/etc/init.d/memcached start


log "Launching SOGo .."
su -l sogo -s /bin/bash -c "/usr/sbin/sogod -WOWorkersCount ${WORKERS_COUNT} -WONoDetach YES -WOLogFile - -WOPidFile /tmp/sogo.pid"

