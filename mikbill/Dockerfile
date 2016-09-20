From centos:6.8
EXPOSE 2007
CMD         service crond start && \
            service php-fpm start && \
            /usr/local/sbin/mikbill_run.sh
            
RUN mkdir -p /usr/local/zend /var/www/mikbill /var/run/php-socket && \
useradd nginx && \
yum update -y && \
yum install -y  wget crontabs && \
wget https://github.com/mikbill/distr/raw/master/mikbill/sudoers -O /etc/sudoers && \
wget https://github.com/mikbill/distr/raw/master/mikbill/mikbill_run.sh -O /usr/local/sbin/mikbill_run.sh && \
wget https://github.com/mikbill/distr/raw/master/mikbill/init.d/mikbill -O /etc/init.d/mikbill && \
wget -P /usr/local/zend https://github.com/mikbill/distr/raw/master/mikbill/zend/zendGL_x64/ZendGuardLoader.so && \
wget -P /etc/php.d/ https://github.com/mikbill/distr/raw/master/mikbill/zend/zend.ini && \
chmod +x /usr/local/sbin/mikbill_run.sh /etc/init.d/mikbill

RUN yum install -y php php-bcmath php-devel php-embedded php-gd php-imap php-mbstring php-mysql php-process \
            php-pspell php-recode php-snmp php-soap php-xml php-xmlrpc php-fpm libdbi-dbd-mysql php-pear && \
yum clean all && \
pear channel-discover pear.phing.info && \
pear upgrade && \
pear -q install phing/phing

LABEL version="0.1" \
      name="Mikbill image"



