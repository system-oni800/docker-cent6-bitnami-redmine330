FROM centos:centos6
MAINTAINER systemoni800

ENV PW radminpass00
ENV ZABBIX_SVR 172.17.0.1
# _SET_ZABBIX_SERVER_ADDRESS_WITH_INTERNAL_IP_
# ENV http_proxy="_SET_YOUR_PRXY_ADDRESS_"
# "http://10.1.0.1:80"
# Install bitnami-redmine 3.2.2-0

RUN yum update -y -q
RUN yum install -y -q sudo tar passwd expect spawn patch yum-cron logrotate which gcc git scp unzip
RUN yum install -y -q openssh-server httpd php php-mbstring mysql-server php-mysql python-setuptools

RUN rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm
RUN yum install -y -q zabbix-agent
RUN yum clean all

ADD bitnami-redmine-linux-x64.run /root/bitnami-redmine-linux-x64.run
RUN chmod +x /root/bitnami-redmine-linux-x64.run

ADD install_bitnami.sh /root/install_bitnami.sh
run chmod +x /root/install_bitnami.sh
RUN sed -ri "s/_SET_YOUR_PASSWORD_/$PW/" /root/install_bitnami.sh
RUN cat -n /root/install_bitnami.sh | grep pass

ADD service-patch.txt	/root/service-patch.txt
ADD httpd-patch.txt	/root/httpd-patch.txt
ADD rails-patch.txt	/root/rails-patch.txt
ADD cal-html-patch.txt 	/root/cal-html-patch.txt
ADD cal-css-patch.txt	/root/cal-css-patch.txt
ADD redmine-config.diff	/root/redmine-config.diff
ADD myCal-rb.patch	/root/myCal-rb.patch
ADD calHtml-rb.patch	/root/calHtml-rb.patch

ADD index.html		/root/index.html

# Timezone
RUN localedef -f UTF-8 -i ja_JP ja_JP
RUN mv /etc/localtime /etc/localtime.org
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# zabbix_agentd
RUN sed -ri "s/Server=127.0.0.1/Server=$ZABBIX_SVR/" /etc/zabbix/zabbix_agentd.conf
RUN sed -ri "s/^ServerActive/#ServerActive/" /etc/zabbix/zabbix_agentd.conf

# cron tasks
ADD cron.redmine        /etc/cron.d/redmine
ADD cron.redmine-mail   /etc/cron.d/redmine-mail
RUN chmod 600 /etc/cron.d/redmine /etc/cron.d/redmine-mail
ADD redmine_dbbkup.sh   /root/redmine_dbbkup.sh
ADD daytime_dbbkup.sh   /root/daytime_dbbkup.sh
RUN chmod +x /root/redmine_dbbkup.sh /root/daytime_dbbkup.sh

# logrotate
ADD logrotate.redmine   /etc/logrotate.d/redmine
ADD logrotate.syslog    /etc/logrotate.d/syslog
ADD logrotate.zabbix-agent  /etc/logrotate.d/zabbix-agent
RUN rm -rf /etc/logrotate.d/httpd

# ssh
RUN chmod +w /etc/sudoers
RUN echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
RUN chmod -w /etc/sudoers
ADD redmine_install.sh  /root/redmine_install.sh
RUN sed -ri "s/_SET_YOUR_PASSWORD_/$PW/" /root/redmine_install.sh

# Mount host file 
VOLUME ["/var/redmine3", "/var/logarchive"]

RUN chmod +x /root/redmine_install.sh
RUN sh /root/redmine_install.sh
