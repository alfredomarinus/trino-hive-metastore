FROM apache/hive:4.0.0

ENV HIVE_HOME=/opt/hive
ENV SCHEMA_TYPE=mysql

ADD https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar /opt/hive/lib/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar /opt/hive/lib/
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.367/aws-java-sdk-bundle-1.12.367.jar /opt/hive/lib/

USER root
RUN chmod 644 /opt/hive/lib/mysql-connector-j-8.0.33.jar \
              /opt/hive/lib/hadoop-aws-3.3.6.jar \
              /opt/hive/lib/aws-java-sdk-bundle-1.12.367.jar && \
    apt-get update && apt-get install -y --no-install-recommends gettext-base netcat-openbsd && \
    rm -rf /var/lib/apt/lists/* && \
    chown hive:hive /opt/hive/conf/hive-site.xml
USER hive

ENTRYPOINT []
CMD ["bash", "-c", "\
  envsubst < /opt/hive/conf/hive-site.xml.template > /opt/hive/conf/hive-site.xml && \
  until nc -z ${HIVE_DB_HOST} 3306; do sleep 2; done && \
  schematool -dbType mysql -initOrUpgradeSchema --verbose && \
  hive --service metastore"]