#!/bin/sh

echo "Start UPDATER SOFT!"

VERSION_UPD="131020121779"
ARG1=$1

UPDATE_LOGIN="update"
UPDATE_PASSWORD="upd1355"

UPDATE_URL="http://update253.mikbill.ru/"
UPDATE_FILE="mikbill.tar.gz"
UPDATE_FILE_CHECKSUM="mikbill_checksum"
UPDATE_VERSION_UPDATER="mikbill_rev_up"
UPDATE_VERSION_MIKBILL="mikbill_revision"
UPDATE_VERSION_MIKBILL_CURRENT="mikbill_current"
MIKBILL_CONTACT_MESSAGE="У вас закончились обновления вопросы на info@mikbill.ru"
MIKBILL_PATH_LINUX="/var/www/mikbill"
MIKBILL_PATH_BSD="/usr/local/www/mikbill"
MIKBILL_PATH_LINUX_INST="/var/www"
MIKBILL_PATH_BSD_INST="/usr/local/www"
MIKBILL_LOG_UPDATE="mikbill_update.log"
MIKBILL_UPDATE_PROGRAMM="mikbill_update.sh"
TIME_SERVERS=" ua.pool.ntp.org ru.pool.ntp.org pool.ntp.org"

TEST="0"

UNAME=`which uname`
ARCH=`$UNAME -m`
SYSTEM=`$UNAME`
NULL=" >/dev/null"

APP_ECHO=`which echo`
APP_WGET=`which wget`
APP_GREP=`which grep`
APP_AWK=`which awk`
APP_CAT=`which cat`
APP_RM=`which rm`
APP_LSB_RELEASE="111"
APP_NTPDATE=`which ntpdate`
APP_CHMOD=`which chmod`
APP_CHOWN=`which chown`
APP_TAR=`which tar`
APP_DATE=`which date`
APP_CP=`which cp`

control_version_updater () {
#Выполняем проверку и контроль версии программы обновлений

$APP_WGET -q --user=$UPDATE_LOGIN --password="$UPDATE_PASSWORD" $UPDATE_URL$UPDATE_VERSION_UPDATER $NULL
VERSION_UPDATER=`$APP_CAT ./$UPDATE_VERSION_UPDATER`

if [ $VERSION_UPDATER -ne $VERSION_UPD ];
then
    $APP_RM -f ./$MIKBILL_UPDATE_PROGRAMM $NULL
    $APP_WGET -q --user=$UPDATE_LOGIN --password="$UPDATE_PASSWORD" $UPDATE_URL$MIKBILL_UPDATE_PROGRAMM $NULL
    $APP_CHMOD a+x ./$MIKBILL_UPDATE_PROGRAMM
    ./$MIKBILL_UPDATE_PROGRAMM
    echo "Update UPDATE_PROGRAMM Success"
    exit
fi
}

control_version_mikbill () {
#Проверка версии MikBill
$APP_RM -f ./$UPDATE_VERSION_MIKBILL $NULL
$APP_WGET -q --user=$UPDATE_LOGIN --password="$UPDATE_PASSWORD" $UPDATE_URL$UPDATE_VERSION_MIKBILL $NULL
VERSION_MIKBILL=`$APP_CAT ./$UPDATE_VERSION_MIKBILL`
VERSION_MIKBILL_CURRENT=`$APP_CAT ./$UPDATE_VERSION_MIKBILL_CURRENT`

if [ "$ARG1" != "" ]
then
 exit
fi

if [ -f ./$UPDATE_VERSION_MIKBILL_CURRENT ];
then
    if [ $VERSION_MIKBILL -eq $VERSION_MIKBILL_CURRENT ];
    then
	delete_downloaded_files
	echo "Version is UP to Date"
	exit
    fi
else
    $APP_CAT ./$UPDATE_VERSION_MIKBILL > ./$UPDATE_VERSION_MIKBILL_CURRENT
    echo "version file not found"
    echo "Do current version file"
fi
}

control_cheksum_mikbill () {
#Проверка контрольной суммы скачаного обновления

$APP_WGET -q --user=$UPDATE_LOGIN --password="$UPDATE_PASSWORD" $UPDATE_URL$UPDATE_FILE_CHECKSUM $NULL
FILE_CHECKSUM=`$APP_CAT ./$UPDATE_FILE_CHECKSUM`
$APP_WGET -q --user=$UPDATE_LOGIN --password="$UPDATE_PASSWORD" $UPDATE_URL$UPDATE_FILE $NULL

case $SYSTEM in
Linux)
APP_MD5=`which md5sum`
DOWNLOAD_CHECKSUM=`$APP_MD5 ./$UPDATE_FILE|$APP_AWK {'print $1'}`
;;
FreeBSD)
APP_MD5=`which md5`
DOWNLOAD_CHECKSUM=`$APP_MD5 ./$UPDATE_FILE|$APP_AWK '{print $4}'`
;;
esac

if [ "$DOWNLOAD_CHECKSUM" != "$FILE_CHECKSUM" ];
then
    echo "Update file Cheksumm error $MIKBILL_CONTACT_MESSAGE "
    exit
fi
}

delete_downloaded_files () {
#Удаляет загружаемые файлы

$APP_RM -f ./$UPDATE_FILE $NULL
$APP_RM -f ./$UPDATE_FILE_CHECKSUM $NULL
$APP_RM -f ./$UPDATE_VERSION_UPDATER $NULL

$APP_RM -f ./mikbill.tar.gz.*
$APP_RM -f ./mikbill_checksum.*
$APP_RM -f ./mikbill_rev_up.*
$APP_RM -f ./mikbill_revision.*
$APP_RM -f ./mikbill_update.sh.*
$APP_RM -f ./index.php*
}

detect_linux () {
#Действия после определения Linux системы
APP_NETSTAT=`which netstat`
echo "Detect Linux System $ARCH"
if [ -d $MIKBILL_PATH_LINUX ];
then
    echo "MikBIll Path=$MIKBILL_PATH_LINUX"
else
    echo "Error MikBill Dir Not Found"
    TEST="1"
fi
}

detect_freebsd () {
#Действия после определения FreeBSD системы
APP_SOCKSTAT=`which sockstat`
echo "Detect FreeBSD System $ARCH"
if [ -d $MIKBILL_PATH_BSD ];
then
    echo "MikBIll Path=$MIKBILL_PATH_BSD"
else
    echo "Error MikBill Dir Not Found"
    TEST="1"
fi
}

do_actions_centos () {
#Делать действия для CentOS

if [ "$TEST"=="0" ];
then
    $APP_TAR xzf ./$UPDATE_FILE -C $MIKBILL_PATH_LINUX_INST
    $APP_CHOWN -R apache:apache $MIKBILL_PATH_LINUX
    do_rhel_reload
fi
IS_CENTOS_6=`$APP_CAT /etc/redhat-release|$APP_GREP 6.`
if [ "$IS_CENTOS_6"=="" ];
then
    echo "Detect CenteOS 5.x $ARCH";
else
    echo "Detect CentOS 6.x $ARCH";
fi
}

do_actions_gentoo () {
#Делать действия для Gentoo

echo "Detect Gentoo"
if [ "$TEST"=="0" ];
then
    $APP_TAR xzf ./$UPDATE_FILE -C $MIKBILL_PATH_LINUX_INST
    $APP_CHOWN -R apache:apache $MIKBILL_PATH_LINUX
    do_rhel_reload
fi
}

do_actions_ubuntu () {
#Делать действия для Ubuntu 

echo "Detect $DISTRIBUTOR $VERSION_UBUNTU $ARCH"
if [ "$TEST"=="0" ];
then
    $APP_TAR xzf ./$UPDATE_FILE -C $MIKBILL_PATH_LINUX_INST
    $APP_CHOWN -R www-data:www-data $MIKBILL_PATH_LINUX
    do_debian_reload
fi
}

do_actions_debian () {
#Делать действия для Debian

echo "Detect $DISTRIBUTOR $VERSION_UBUNTU $ARCH"
if [ "$TEST"=="0" ];
then
    $APP_TAR xzf ./$UPDATE_FILE -C $MIKBILL_PATH_LINUX_INST
    $APP_CHOWN -R www-data:www-data $MIKBILL_PATH_LINUX
    do_debian_reload
fi
}

do_actions_freebsd () {
#Делать действия для FreeBSD

if [ "$TEST"=="0" ];
then
    $APP_TAR xzf ./$UPDATE_FILE -C $MIKBILL_PATH_BSD_INST
    $APP_CHOWN -R www:www $MIKBILL_PATH_BSD
    do_bsd_reload
fi
}

check_gentoo () {
#проверка на Gentoo

if [ -f /etc/gentoo-release ];
then
    APP_LSB_RELEASE=""
fi
}

check_centos () {
#проверка на CentOS

if [ -f /etc/redhat-release ];
then
    APP_LSB_RELEASE=""
fi
}

do_final_actions () {
#Выполнить финальные действия

if [ "$TEST"=="0" ];
then
    $APP_CAT ./$UPDATE_VERSION_MIKBILL > ./$UPDATE_VERSION_MIKBILL_CURRENT
    echo "Update Success!"
else
    echo "Update Error $MIKBILL_CONTACT_MESSAGE"
fi
delete_downloaded_files
}

do_final_unknown_linux () {
#ФИнал для неизвестной OS
    delete_downloaded_files
    exit
}

do_rhel_reload () {

cd $MIKBILL_PATH_LINUX"/admin/sys/update"
./mb_sql_upd.sh >> ./mikbill_update.log

#Перезагрузка сервисов rhel like systems
/etc/init.d/radiusd stop $NULL
$APP_NETSTAT -nlp|$APP_GREP 2007
/etc/init.d/mikbill stop $NULL
$APP_NTPDATE $TIME_SERVERS
sleep 1
/etc/init.d/mikbill start $NULL
/etc/init.d/radiusd start $NULL
sleep 1
$APP_NETSTAT -nlp|$APP_GREP 2007
}

do_debian_reload () {

cd $MIKBILL_PATH_LINUX"/admin/sys/update"
./mb_sql_upd.sh >> ./mikbill_update.log

#Перезагрузка сервисов debian
/etc/init.d/freeradius stop $NULL
$APP_NETSTAT -nlp|$APP_GREP 2007
/etc/init.d/mikbill stop $NULL
$APP_NTPDATE $TIME_SERVERS
sleep 1
/etc/init.d/mikbill start $NULL
/etc/init.d/freeradius start $NULL
sleep 1
$APP_NETSTAT -nlp|$APP_GREP 2007
}

do_bsd_reload () {

cd $MIKBILL_PATH_BSD"/admin/sys/update"
./mb_sql_upd.sh >> ./mikbill_update.log

#Перезагрузка сервисов bsd
/usr/local/etc/rc.d/radiusd stop $NULL
$APP_SOCKSTAT -4l|$APP_GREP 2007
/usr/local/etc/rc.d/mikbill stop $NULL
$APP_NTPDATE $TIME_SERVERS
sleep 1
/usr/local/etc/rc.d/mikbill start $NULL
/usr/local/etc/rc.d/radiusd start $NULL
sleep 1
$APP_SOCKSTAT -4l|$APP_GREP 2007
}

delete_downloaded_files
control_version_updater
control_version_mikbill
control_cheksum_mikbill

if [ -f ./$UPDATE_FILE ];
then
    echo "Download Success!"

    case $SYSTEM in
    Linux)
        detect_linux
	check_gentoo
	check_centos

	if [ -z $APP_LSB_RELEASE ];
	then
    	    if [ -f /etc/gentoo-release ];
    	    then
		do_actions_gentoo
    	    else
        	if [ -f /etc/redhat-release ];
    		then
		    do_actions_centos
		else
    		    echo "Uknown Linux"
    		    echo "Stop Update"
    		    TEST="1"
    		    do_final_unknown_linux
    		fi
    	    fi
	else
	    APP_LSB_RELEASE=`which lsb_release`
	    DISTRIBUTOR=`$APP_LSB_RELEASE -a|$APP_GREP Distributor|$APP_AWK '{print $3}'`
	    VERSION_UBUNTU=`$APP_LSB_RELEASE -a|$APP_GREP Release|$APP_AWK '{print $2}'`
	    if [ "$DISTRIBUTOR"=="Ubuntu" ];
	    then
        	do_actions_ubuntu
	    fi
	    if [ "$DISTRIBUTOR"=="Debian" ];
	    then
        	do_actions_debian
	    fi
	fi
    ;;
    FreeBSD)
        detect_freebsd
        do_actions_freebsd
    ;;
    esac

    do_final_actions

else
    echo "Update Don't Download $MIKBILL_CONTACT_MESSAGE"
fi

