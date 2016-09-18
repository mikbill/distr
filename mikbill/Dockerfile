From centos:6.8
LABEL version="0.1" \
      name="Mikbill image"
RUN mkdir -p /usr/local/zend /var/www/mikbill && \
useradd nginx && \
yum update -y && \
yum install -y  wget crontabs && \
wget https://github.com/mikbill/distr/raw/master/mikbill/sudoers -O /etc/sudoers && \
wget https://github.com/mikbill/distr/raw/master/mikbill/mikbill_run.sh -O /usr/local/sbin/mikbill_run.sh && \
wget https://github.com/mikbill/distr/raw/master/mikbill/radiusd_run.sh -O /usr/local/sbin/radiusd_run.sh && \
wget https://github.com/mikbill/distr/blob/master/mikbill/ZendGuardLoader.so?raw=true -O /usr/local/zend/ZendGuardLoader.so

EXPOSE 1812 1813 67 68 2007

RUN yum install -y  http://194.125.224.7/6/x86_64/perl-PHP-Serialization-0.34-6.el6.art.noarch.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-2.2.6-1.el6.x86_64.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-mysql-2.2.6-1.el6.x86_64.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-perl-2.2.6-1.el6.x86_64.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-utils-2.2.6-1.el6.x86_64.rpm

RUN yum install -y php php-bcmath php-devel php-embedded php-gd php-imap php-mbstring php-mysql php-process \
            php-pspell php-recode php-snmp php-soap php-xml php-xmlrpc php-fpm libdbi-dbd-mysql php-pear && \
yum clean all && \
pear channel-discover pear.phing.info && \
pear upgrade && \
pear -q install phing/phing

CMD   /usr/sbin/crond && \   
      /usr/sbin/php-fpm && \
      /usr/sbin/radiusd && \
      /usr/local/sbin/mikbill_run.sh
