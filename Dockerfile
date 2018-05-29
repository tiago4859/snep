FROM debian:jessie
MAINTAINER tiago4859 <tiago4859@gmail.com>

ENV MYSQL_ROOT_PASSWORD=123456

ADD asterisk /usr/src
ADD odbc.ini /usr/src
ADD odbcinst.ini /usr/src

RUN DEBIAN_FRONTEND noninteractive apt-get update && apt-get install -y apache2 \
mysql-server vim git curl wget unixodbc unixodbc-dev \
libmyodbc odbcinst1debian2 libcurl3 libncurses5-dev git \
php5 php5-cgi php5-mysql php5-gd php5-curl build-essential \
lshw libjansson-dev libssl-dev sox sqlite3 libsqlite3-dev \
libapache2-mod-php5 libxml2-dev uuid-dev \
&& apt-get clean all && wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-15-current.tar.gz \
&& tar xvf asterisk-15-current.tar.gz \
&& rm -rf asterisk-15-current.tar.gz \
&& cd /usr/src/asterisk-15* \
&& ./configure \
&& make menuselect \
&& make install \
&& cd /usr/src/ \
&& cp asterisk /etc/init.d/ \
&& chmod +X /etc/init.d/asterisk \
&& update-rc.d asterisk defaults \
&& cd /var/www/html \
&& mkdir snep \
&& git clone https://bitbucket.org/snepdev/snep-3.git . \
&& cd /var/www/html \
&& find . -type f -exec chmod 640 {} \; -exec chown www-data:www-data {} \; \
&& find . -type d -exec chmod 755 {} \; -exec chown www-data:www-data {} \; \
&& chmod +x /var/www/html/snep/agi/* && mkdir /var/log/snep \
&& cd /var/log/snep && touch ui.log && touch agi.log \
&& ln -s /var/log/asterisk/full full \
&& chown -R www-data.www-data * && cd /var/www/html/snep/ \
&& ln -s /var/log/snep logs && cd /var/lib/asterisk/agi-bin/ \
&& ln -s /var/www/html/snep/agi/ snep && cd /etc/apache2/sites-enabled/ \
&& ln -s /var/www/html/snep/install/snep.apache2 001-snep \
&& cd /var/spool/asterisk/ && rm -rf monitor \
&& ln -sf /var/www/html/snep/arquivos monitor \
&& cd /etc && rm -rf asterisk && cp -avr /var/www/html/snep/install/etc/asterisk . \
&& cp /var/www/html/snep/install/etc/odbc* . \
&& mkdir -p /var/www/html/snep/sounds && cd /var/www/html/snep/sounds/ \
&& ln -sf /var/lib/asterisk/moh/ moh && ln -sf /var/lib/asterisk/sounds/pt_BR/ pt_BR \
&& service mysql start && cd /var/www/html/snep/install/database \
&& mysql -u root -p$MYSQL_ROOT_PASSWORD < database.sql \
&& mysql -u root -p$MYSQL_ROOT_PASSWORD snep < schema.sql \
&& mysql -u root -p$MYSQL_ROOT_PASSWORD snep < system_data.sql \
&& mysql -u root -p$MYSQL_ROOT_PASSWORD snep < core-cnl.sql \
&& cd /usr/src/ \
&& rm /etc/odbc.ini \
&& rm /etc/odbcinst.ini \
&& cp odbcinst.ini odbc.ini /etc/

VOLUME /var/log/snep/
VOLUME /var/lib/asterisk/
VOLUME /var/spool/asterisk/
VOLUME /etc/asterisk/

EXPOSE 80 443 
EXPOSE 4569 
EXPOSE 5004-5080/tcp
EXPOSE 10000-20000/udp

CMD '/bin/sh' '-c' '/usr/sbin/asterisk -f -U asterisk -G asterisk -vvvg -c' '/etc/init.d/mysql start' '/etc/init.d/apache2 start'
ENTRYPOINT ['/usr/sbin/apache2ctl', '/usr/sbin/mysqld', '/usr/sbin/asterisk']
