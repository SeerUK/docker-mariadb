FROM ubuntu:trusty
MAINTAINER Elliot Wright <elliot@elliotwright.co>

ENV MARIADB_DATABASE docker
ENV MARIADB_USER docker
ENV MARIADB_PASS docker
ENV TERM dumb

COPY ./docker-entrypoint.sh /

# Install MariaDB
RUN \
    useradd -u 1000 -m -s /bin/bash mysql && \
    apt-get install -y \
        software-properties-common && \
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && \
    add-apt-repository 'deb [arch=amd64,i386] http://mirrors.coreix.net/mariadb/repo/10.1/ubuntu trusty main' && \
    apt-get update && \
    { \
        echo mariadb-server-10.1 mysql-server/root_password password 'unused'; \
        echo mariadb-server-10.1 mysql-server/root_password_again password 'unused'; \
    } | debconf-set-selections && \
    apt-get install -y \
        mariadb-server \
        pwgen && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/mysql && \
    mkdir -p /var/lib/mysql && \
    chown -R mysql: /var/lib/mysql && \
    chmod +x /docker-entrypoint.sh

# Configure MariaDB
RUN \
  sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf && \
  sed -Ei 's/#bind-address\s+=\s+127.0.0.1/bind-address=0.0.0.0/g' /etc/mysql/my.cnf

ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /var/lib/mysql

EXPOSE 3306

CMD ["mysqld"]
