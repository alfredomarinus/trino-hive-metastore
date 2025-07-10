FROM apache/hive:4.0.0

ENV HIVE_HOME=/opt/hive
ENV SCHEMA_TYPE=mysql

ADD https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar /opt/hive/lib/

USER root
RUN chmod 644 /opt/hive/lib/mysql-connector-j-8.0.33.jar
USER hive

CMD bash -c "\
  until mysqladmin ping -hmysql --silent; do sleep 2; done && \
  if ! schematool -dbType mysql -info | grep -q 'Hive schema version'; then \
    schematool -dbType mysql -initSchema --verbose; \
  fi && \
  hive --service metastore"