From centos:6.8
RUN yum update -y && \
yum install -y  wget && \
wget https://github.com/mikbill/distr/raw/master/mikbill/radiusd_run.sh -O /usr/local/sbin/radiusd_run.sh && \
chmod +x /usr/local/sbin/radiusd_run.sh

CMD /usr/local/sbin/radiusd_run.sh

EXPOSE 1812 1813 67 68

RUN yum install -y  http://194.125.224.7/6/x86_64/perl-PHP-Serialization-0.34-6.el6.art.noarch.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-2.2.6-1.el6.x86_64.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-mysql-2.2.6-1.el6.x86_64.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-perl-2.2.6-1.el6.x86_64.rpm \
                    http://194.125.224.7/6/x86_64/mikbill-freeradius-utils-2.2.6-1.el6.x86_64.rpm && \
yum clean all

LABEL version="0.1" \
      name="Mikbill-radius image"
