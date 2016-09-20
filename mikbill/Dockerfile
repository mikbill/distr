From centos:6.8
RUN mkdir -p /usr/local/zend /var/www/mikbill && \
useradd nginx && \
yum update -y && \
yum install -y  wget crontabs && \
wget https://github.com/mikbill/distr/raw/master/mikbill/sudoers -O /etc/sudoers && \
wget https://github.com/mikbill/distr/raw/master/mikbill/mikbill_run.sh -O /usr/local/sbin/mikbill_run.sh && \
wget https://github.com/mikbill/distr/raw/master/mikbill/init.d/mikbill -O /etc/init.d/mikbill && \
wget https://github.com/mikbill/distr/blob/master/mikbill/ZendGuardLoader.so?raw=true -O /usr/local/zend/ZendGuardLoader.so

EXPOSE 1812 1813 67 68 2007

RUN yum install -y php php-bcmath php-devel php-embedded php-gd php-imap php-mbstring php-mysql php-process \
            php-pspell php-recode php-snmp php-soap php-xml php-xmlrpc php-fpm libdbi-dbd-mysql php-pear && \
yum clean all && \
pear channel-discover pear.phing.info && \
pear upgrade && \
pear -q install phing/phing

LABEL version="0.1" \
      name="Mikbill image"

RUN chmod +x /usr/local/sbin/mikbill_run.sh
CMD         service crond start && \
            service php-fpm start && \
            /usr/local/sbin/mikbill_run.sh

RUN mc /var/run/php-socket
