FROM httpd:2.4
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update
RUN apt-get -y install software-properties-common

RUN echo 'deb http://httpredir.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/bash'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

ENV JAVA_VERSION 8u72
ENV JAVA_DEBIAN_VERSION 8u72-b15-1~bpo8+1

# see https://bugs.debian.org/775775
# and https://github.com/docker-library/java/issues/19#issuecomment-70546872
ENV CA_CERTIFICATES_JAVA_VERSION 20140324

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		openjdk-8-jdk="$JAVA_DEBIAN_VERSION" \
		ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
	&& rm -rf /var/lib/apt/lists/* \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

#RUN add-apt-repository ppa:openjdk-r/ppa
#RUN apt-get update && apt-get install -y openjdk-8-jdk
# set default java environment variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64    
RUN apt-get update \
    && apt-get install -y --no-install-recommends libaprutil1-ldap cron rsyslog \
    && apt-get -y install php5 php5-cli php5-mysqlnd php5-curl php5-ldap php5-mcrypt libapache2-mod-php5 vim && apt-get clean \
    && rm -r /var/lib/apt/lists/*
# Enable apache mods.
RUN a2enmod php5
RUN a2enmod rewrite

# create those directory for default log files locations
# You should change the logs location to /mnt/share/html/logs/whatever -see install doc      
RUN mkdir -p /euronews/app/html \
	&& mkdir -p /var/log/euronews/wfe \
	&& mkdir -p /var/log/euronews/intranet \
	&& mkdir -p /var/log/euronews/mam \
	&& mkdir -p /var/log/euronews/diffusion \
	&& mkdir -p /var/log/euronews/eventshandler \
	&& mkdir -p /var/log/euronews/intranet \
	&& mkdir -p /var/log/euronews/mixnewsapi \
	&& mkdir -p /var/log/euronews/cms \
	&& mkdir -p /var/log/euronews/euronews \
	&& mkdir -p /var/log/euronews/euronews \
	&& chmod -Rf 777 /var/log/euronews/ 
		
# Rename and copy the httpd.conf configured  it is necessary 
#COPY ./env/apache/my-httpd.conf /usr/local/apache2/apache2.conf
# copy the apache virtual hosts confs 
COPY ./env/apache/* /etc/apache2/conf-enabled/
# copy the host files to resolve cnames
ADD ./env/hosts.txt /etc/hosts
# copy the php.ini configured with errors on 
COPY ./env/php.ini /etc/php5/apache2/php.ini
# Add the crontab to run crons
ADD ./env/crontab /etc/cron.d/crontab
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/crontab

# Create the log file to be able to run tail
RUN touch /var/log/cron.log
# push bootstrap script at rootfs
COPY ./env/bootstrap.sh /
#give execution rights 
RUN chmod a+x /bootstrap.sh
VOLUME /euronews/app/html    
EXPOSE 80
CMD ["/bootstrap.sh"]