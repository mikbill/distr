From centos:7
EXPOSE 2007
            
RUN mkdir -p /usr/local/zend /var/www/mikbill /var/run/php-socket \
&& useradd nginx \
&& yum update -y \
&& yum install -y  wget \

&& gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 \
&& yum install -y crontabs \

&& wget https://github.com/mikbill/distr/raw/master/mikbill/sudoers -O /etc/sudoers \
&& wget https://github.com/mikbill/distr/raw/master/mikbill/mikbill_run.sh -O /usr/local/sbin/mikbill_run.sh \
&& wget https://github.com/mikbill/distr/raw/master/mikbill/init.d/mikbill -O /etc/init.d/mikbill \
&& wget -P https://github.com/mikbill/distr/raw/master/mikbill/zend/php-5.4.x_x64/ZendGuardLoader.so \
&& wget -P /etc/php.d/ https://github.com/mikbill/distr/raw/master/mikbill/zend/zend.ini \
&& chmod +x /usr/local/sbin/mikbill_run.sh /etc/init.d/mikbill

RUN yum install -y php-cli php-bcmath php-devel php-embedded php-gd php-imap php-mbstring php-mysql php-process \
            php-pspell php-recode php-snmp php-soap php-xml php-xmlrpc php-fpm libdbi-dbd-mysql php-pear \
&& yum clean all 

RUN pear channel-discover pear.phing.info \
&& pear upgrade \
&& pear -q install phing/phing

RUN yum install -y python-setuptools \
&& easy_install supervisor \
&& wget -P /etc https://github.com/mikbill/distr/raw/master/mikbill/init.d/supervisord.conf

CMD ["/usr/bin/supervisord"]

LABEL version="0.1" \
      name="Mikbill image"
