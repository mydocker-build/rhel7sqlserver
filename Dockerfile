# mssql-server-rhel
# Maintainers: Travis Wright (twright-msft on GitHub)
# GitRepo: https://github.com/twright-msft/mssql-server-rhel

# Base OS layer: latest RHEL 7
FROM registry.access.redhat.com/rhel7

# Proxy Setting
# ENV PROXY http://<proxy address>:8080

### Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="microsoft/mssql-server-linux" \
      vendor="Microsoft" \
      version="14.0" \
      release="1" \
      summary="MS SQL Server" \
      description="MS SQL Server is ....." \
### Required labels above - recommended below
      url="https://www.microsoft.com/en-us/sql-server/" \
      run='docker run --name ${NAME} \
        -e ACCEPT_EULA=Y -e SA_PASSWORD=P@ssw0rd#1 \
        -p 1433:1433 \
        -d  ${IMAGE}' \
      io.k8s.description="MS SQL Server is ....." \
      io.k8s.display-name="MS SQL Server"

### add licenses to this directory
COPY licenses /licenses

# Set proxy setting
#RUN echo "proxy = https://<proxy address>:8080" >> /etc/yum.conf

# Install latest mssql-server package
## add option "-x ${PROXY}" with "curl" if you use proxy
RUN REPOLIST=rhel-7-server-rpms,packages-microsoft-com-mssql-server-2017,packages-microsoft-com-prod && \
    curl --insecure -o /etc/yum.repos.d/mssql-server.repo -L https://packages.microsoft.com/config/rhel/7/mssql-server-2017.repo && \
    curl --insecure -o /etc/yum.repos.d/msprod.repo -L https://packages.microsoft.com/config/rhel/7/prod.repo && \
    ACCEPT_EULA=Y yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs \
      mssql-server mssql-tools unixODBC-devel && \
    yum clean all

COPY uid_entrypoint /opt/mssql-tools/bin/
ENV PATH=${PATH}:/opt/mssql/bin:/opt/mssql-tools/bin
RUN mkdir -p /var/opt/mssql/data && \
    chmod +x /opt/mssql-tools/bin/uid_entrypoint && \
    chmod -R g=u /var/opt/mssql /etc/passwd

### Run container as root
USER 0

# Default SQL Server TCP/Port
EXPOSE 1433

VOLUME /var/opt/mssql/data

### user name recognition at runtime w/ an arbitrary uid - for OpenShift deployments
ENTRYPOINT [ "uid_entrypoint" ]

# Run SQL Server process
CMD sqlservr

