From centos:7
EXPOSE 2007
            
RUN mkdir -p /usr/local/zend /var/www/mikbill /var/run/php-socket /var/lib/php/session \
&& chown apache:apache /var/lib/php/session \
&& useradd nginx \
&& yum update -y \
&& yum install -y  wget \

&& gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 \
&& yum install -y crontabs \

&& wget -P /etc https://github.com/mikbill/distr/raw/master/mikbill/sudoers \
&& wget -P /usr/local/zend  https://github.com/mikbill/distr/raw/master/mikbill/zend/php-5.4.x_x64/ZendGuardLoader.so \
&& wget -P /etc/php.d/ https://github.com/mikbill/distr/raw/master/mikbill/zend/zend.ini

RUN yum install -y php-cli php-bcmath php-devel php-embedded php-gd php-imap php-mbstring php-mysql php-process \
            php-pspell php-recode php-snmp php-soap php-xml php-xmlrpc php-fpm libdbi-dbd-mysql php-pear \
&& yum clean all 

RUN pear channel-discover pear.phing.info \
&& pear upgrade \
&& pear -q install phing/phing

RUN wget https://github.com/mikbill/distr/raw/master/mikbill/init.d/start.sh \
&& chmod +x start.sh

CMD ["./start.sh"]

LABEL version="0.1" \
      name="Mikbill image"
