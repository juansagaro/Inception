FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Copy config
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Create runtime dir for MariaDB socket
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

COPY tools/db_start.sh /usr/local/bin/db_start.sh
RUN chmod +x /usr/local/bin/db_start.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/db_start.sh"]
