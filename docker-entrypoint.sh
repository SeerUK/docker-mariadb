#!/bin/bash

DATA_HOME="/var/lib/mysql"

SYSTEM_UID=${MARIADB_UID:-"1000"}
SYSTEM_UID_TYPE=$( [ ${MARIADB_UID} ] && echo "preset" || echo "default" )

echo "==> Updating mysql system user's ID to ${SYSTEM_UID} (${SYSTEM_UID_TYPE})"
usermod -u ${SYSTEM_UID} mysql > /dev/null 2>&1 &

echo "==> Updating ownership of data directory"
chown -R mysql /var/lib/mysql

if [[ ! -d "${DATA_HOME}/mysql" ]]; then
    echo "==> An empty or uninitialized MariaDB installation is detected in '${DATA_HOME}'"
    echo "==> Installing MariaDB data..."
    mysql_install_db > /dev/null 2>&1
    echo "==> Done!"

    /usr/bin/mysqld_safe > /dev/null 2>&1 &

    RET=1
    while [[ RET -ne 0 ]]; do
        echo "==> Waiting for confirmation of MariaDB service startup..."
        sleep 2
        mysql -uroot -e "status" > /dev/null 2>&1
        RET=$?
    done

    USER=${MARIADB_USER:-"admin"}
    PASS=${MARIADB_PASS:-$(pwgen -s 12 1)}
    PASS_TYPE=$( [ ${MARIADB_PASS} ] && echo "preset" || echo "random" )

    echo "==> Creating MariaDB user with username ${USER}"
    echo "==> Updating MariaDB user '${USER}' with ${PASS_TYPE} password"

    mysql -uroot -e "CREATE USER '${USER}'@'%' IDENTIFIED BY '${PASS}'"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'%' WITH GRANT OPTION"

    echo "==> Done!"

    if [[ ! -z "${MARIADB_DATABASE}" ]]; then
        echo "==> Creating database '${MARIADB_DATABASE}'"
        mysql -uroot -e "CREATE DATABASE ${MARIADB_DATABASE} CHARACTER SET utf8"
        echo "==> Done!"
    fi

    echo "========================================================================"
    echo "You can now connect to this MariaDB Server using:"
    echo ""
    echo "    mysql -u${USER} -p${PASS} -h<host> -P<port>"
    echo ""
    echo "MariaDB user 'root' has no password but only allows local connections"
    echo "========================================================================"

    mysqladmin -uroot shutdown
else
    echo "==> Using an existing volume of MariaDB"
fi

echo "==> Starting MariaDB"
exec mysqld_safe
