From centos:6.8
RUN yum update -y && \
yum install -y  wget && \
wget -P /usr/local/sbin https://github.com/mikbill/distr/raw/master/mikbill/radiusd_run.sh && \
wget -P /etc/raddb https://github.com/mikbill/distr/raw/master/radius/mikbill.conf && \
chmod +x /usr/local/sbin/radiusd_run.sh

CMD /usr/local/sbin/radiusd_run.sh

EXPOSE 1812/udp 1813/udp 67 68

RUN yum install -y  http://194.125.224.7/6/x86_64/perl-PHP-Serialization-0.34-6.el6.art.noarch.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-2.2.6-1.el6.x86_64.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-mysql-2.2.6-1.el6.x86_64.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-perl-2.2.6-1.el6.x86_64.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-utils-2.2.6-1.el6.x86_64.rpm && \
yum clean all

RUN cp -R /usr/share/freeradius /tmp/freeradius

LABEL version="0.1" \
      name="Mikbill-radius image"
