FROM docker.elastic.co/beats/filebeat:7.17.17

# run as root so we can modify permissions
USER root

# copy your config into the container
COPY filebeat.yml /usr/share/filebeat/filebeat.yml

# fix file permissions (required by filebeat)
RUN chown root:root /usr/share/filebeat/filebeat.yml \
    && chmod 600 /usr/share/filebeat/filebeat.yml

# switch back to filebeat user for security
USER filebeat
