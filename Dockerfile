FROM azul/zulu-openjdk:17

ARG TALEND_RE_VERSION

RUN mkdir -p /opt/talend
# ADD automatically extracts tar archives, so no manual tar command is needed
ADD Talend-RemoteEngine-V${TALEND_RE_VERSION}-*.tar.gz /opt/talend/

# ADD Automatically extracts tar.gz file, so no manual extraction is needed for Talend RunTime
ADD Talend-Runtime-*.tar.gz /opt/talend/
# Use a wildcard to handle directories that contain a build suffix
RUN mv /opt/talend/Talend-RemoteEngine-V${TALEND_RE_VERSION}* /opt/talend/remote-engine/
RUN mv /opt/talend/Talend-Runtime-* /opt/talend/runtime-engine/

# Backup original configs so we can copy them back if a user mounts an empty local directory to /etc
RUN cp -r /opt/talend/remote-engine/etc /opt/talend/remote-engine/etc.default && \
    cp -r /opt/talend/runtime-engine/etc /opt/talend/runtime-engine/etc.default

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/opt/talend/remote-engine/bin/trun", "server"]
