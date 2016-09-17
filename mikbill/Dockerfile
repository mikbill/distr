From centos:6.8
RUN update -y && \
yum install -y  wget \
                http://194.125.224.7/6/x86_64/perl-PHP-Serialization-0.34-6.el6.art.noarch.rpm \
                http://194.125.224.7/6/x86_64/mikbill-freeradius-2.2.6-1.el6.x86_64.rpm \
                http://194.125.224.7/6/x86_64/mikbill-freeradius-mysql-2.2.6-1.el6.x86_64.rpm \
                http://194.125.224.7/6/x86_64/mikbill-freeradius-perl-2.2.6-1.el6.x86_64.rpm \
                http://194.125.224.7/6/x86_64/mikbill-freeradius-utils-2.2.6-1.el6.x86_64.rpm && \
yum clean all && \
mkdir /usr/local/zend && \
wget https://github.com/mikbill/distr/blob/master/mikbill/ZendGuardLoader.so?raw=true -O /usr/local/zend/ZendGuardLoader.so
EXPOSE 1812 1813 67 68 2007
