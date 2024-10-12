FROM owncloud/ocis:dev

USER root
COPY ./remote_files/ocis/ocis-config /etc/ocis
COPY ./remote_files/ocis/ocis-data /var/lib/ocis
RUN chmod -R 777 /var/lib/ocis