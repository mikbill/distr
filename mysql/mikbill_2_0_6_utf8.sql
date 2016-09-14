-- phpMyAdmin SQL Dump
-- version 3.4.7.1
-- http://www.phpmyadmin.net
--
-- Хост: localhost
-- Время создания: Июл 19 2013 г., 19:44
-- Версия сервера: 5.5.31
-- Версия PHP: 5.2.17

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- База данных: `mikbill`
--

DELIMITER $$
--
-- Процедуры
--
CREATE PROCEDURE `del_ip_pool_us_by_ip`(IN input_ip VARCHAR(15))
    DETERMINISTIC
    COMMENT 'Удалить IP из pool_use'
BEGIN
  DELETE
  FROM
    ip_pools_pool
  WHERE
    poolip LIKE input_ip;
END$$

CREATE PROCEDURE `do_post_auth`(IN uid INT, IN username VARCHAR(32), IN pass VARCHAR(32), IN packettypeid INT, IN replymessageid INT, IN nasid INT, IN nasportid INT, IN callingstationid VARCHAR(64))
    DETERMINISTIC
BEGIN
  INSERT INTO `radpostauthnew` VALUES (NULL, uid, username, pass, packettypeid, replymessageid, nasid, nasportid, callingstationid, current_timestamp);
END$$

CREATE PROCEDURE `do_radnas_log`(IN nasipaddress   VARCHAR(15),
                               IN acctstatustype VARCHAR(32),
                               IN nasIdentifier  VARCHAR(64)
                               )
    DETERMINISTIC
    COMMENT 'делать лог включения NAS'
BEGIN
  INSERT INTO radnaslog VALUES (NULL, current_timestamp, nasipaddress, acctstatustype, nasIdentifier);
END$$

CREATE PROCEDURE `do_switch_log`(IN uid INT, IN swid INT, IN port INT, IN mac VARCHAR(17), IN vlan INT(5))
    DETERMINISTIC
    COMMENT 'Выполнить логирование события на свиче'
BEGIN
  INSERT INTO `switch_logs` VALUES (NULL, current_timestamp, uid, swid, port, mac, vlan);
END$$

CREATE PROCEDURE `get_user_proper_by_login_from_users`(IN input_login VARCHAR(32))
    DETERMINISTIC
    COMMENT 'Получить данные пользователя для ядра mikbill по login из users'
BEGIN
  SELECT *
  FROM
    users
  WHERE
    user = input_login;
END$$

CREATE PROCEDURE `ip_pool_insert_del_ip_1`(IN input_ip VARCHAR(15), IN input_poolid INT, IN input_time INT, IN input_acctsessionid VARCHAR(64), IN input_acctuniqueid VARCHAR(32), IN input_uid INT)
    DETERMINISTIC
    COMMENT 'Вставить в use и удалить из pool'
BEGIN
  INSERT INTO ip_pools_pool_use VALUES (input_ip, input_poolid, input_time, input_acctsessionid, input_acctuniqueid, input_uid);
  DELETE
  FROM
    ip_pools_pool
  WHERE
    poolip LIKE input_ip;
END$$

CREATE PROCEDURE `update_ip_pool_use_by_acct_packet`(IN input_uid           INT,
                                                   IN input_acctsessionid VARCHAR(64),
                                                   IN input_acctuniqueid  VARCHAR(32),
                                                   IN input_last_change   INT
                                                   )
    DETERMINISTIC
    COMMENT 'Обновить ip_pool_use во время acct пакетов из radius'
BEGIN
  UPDATE ip_pools_pool_use
  SET
    last_change = input_last_change, acctsessionid = input_acctsessionid, acctuniqueid = input_acctuniqueid
  WHERE
    uid = input_uid;
END$$

CREATE PROCEDURE `update_ip_pool_use_only_time`(IN input_uid INT, IN input_last_change INT)
    DETERMINISTIC
    COMMENT 'Обновить ip_pool_use только время по UID'
BEGIN
  UPDATE ip_pools_pool_use
  SET
    last_change = input_last_change
  WHERE
    uid = input_uid;
END$$

CREATE PROCEDURE `kurva`()
    DETERMINISTIC
begin

declare id int;
declare name2 varchar(50);
declare oldname varchar(50);
declare number2 int;
DECLARE done INT DEFAULT 0;

declare cr cursor for
select a.uid, b.user
  from users a
 inner join users b
    on a.houseid = b.houseid
   and a.app = b.app
 where a.app != 0 and b.app != 0
   and a.gid = 37 and b.gid != 37
order by b.user;

DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

open cr;


REPEAT


FETCH cr INTO id, name2;

if name2 != oldname then
    set number2 = 0;
end if;

set number2 = number2 + 1;

update users
   set user = concat(name2, "-", number2)
 where uid = id;

set oldname = name2;

UNTIL done END REPEAT;
close cr;

end$$

--
-- Функции
--
CREATE FUNCTION `check_blocked_func`(input_uid INT) RETURNS int(11)
    DETERMINISTIC
    COMMENT 'Проверка на блокировку абонента'
BEGIN
  DECLARE return_value INT DEFAULT 0;

  SELECT blocked
  INTO
    return_value
  FROM
    users
  WHERE
    uid = input_uid;

  RETURN return_value;

END$$

CREATE FUNCTION `check_ip_pool_simul_use`(input_uid INT, input_ip VARCHAR(15)) RETURNS int(11)
    DETERMINISTIC
    COMMENT 'Проверить на колличество IP по UID в пуле'
BEGIN
  DECLARE return_value INT DEFAULT 0;

  SELECT count(uid)
  INTO
    return_value
  FROM
    ip_pools_pool_use
  WHERE
    uid = input_uid
    AND
    poolip LIKE input_ip;
  RETURN return_value;
END$$

CREATE FUNCTION `check_ip_pool_simul_use_by_ip`(input_ip VARCHAR(15)) RETURNS int(11)
    DETERMINISTIC
    COMMENT 'Проверить на колличество IP по IP в пуле'
BEGIN
  DECLARE return_value INT DEFAULT 0;

  SELECT count(uid)
  INTO
    return_value
  FROM
    ip_pools_pool_use
  WHERE
    poolip LIKE input_ip;
  RETURN return_value;
END$$

CREATE FUNCTION `check_money_func`(input_uid INT) RETURNS int(11)
    DETERMINISTIC
BEGIN
  DECLARE return_value INT DEFAULT 0;

  SELECT sum(deposit + credit)
  INTO
    return_value
  FROM
    users
  WHERE
    uid = input_uid;

  RETURN return_value;

END$$

CREATE FUNCTION `check_simul_usage_func`(input_uid INT) RETURNS int(11)
    DETERMINISTIC
    COMMENT 'Проверить Online абонента по UID (старый формат raddact)'
BEGIN
  DECLARE return_value INT DEFAULT 0;

  SELECT count(uid)
  INTO
    return_value
  FROM
    radacct
  WHERE
    uid = input_uid
    AND acctterminatecause = 'Online';

  RETURN return_value;
END$$

CREATE FUNCTION `check_simul_usage_ip_func`(input_ip VARBINARY(15)) RETURNS int(11)
    DETERMINISTIC
    COMMENT 'Проверить Online абонента по IP (старый формат raddact)'
BEGIN
  DECLARE return_value INT DEFAULT 0;

  SELECT count(uid)
  INTO
    return_value
  FROM
    radacct
  WHERE
    framedipaddress = input_ip
    AND acctterminatecause = 'Online';

  RETURN return_value;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `actions`
--
CREATE TABLE IF NOT EXISTS `actions` (
`user` varchar(32)
,`gid` smallint(5) unsigned
,`id` varchar(64)
,`unique_id` varchar(32)
,`time_on` int(12)
,`start_time` datetime
,`stop_time` datetime
,`in_bytes` bigint(20)
,`out_bytes` bigint(20)
,`ip` varchar(15)
,`server` varchar(15)
,`client_ip` varchar(15)
,`call_to` varchar(50)
,`call_from` varchar(50)
,`connect_info` char(0)
,`terminate_cause` varchar(32)
,`last_change` int(10) unsigned
,`before_billing` double(20,6)
,`billing_minus` double(20,6)
);
-- --------------------------------------------------------

--
-- Структура таблицы `addons_citypay`
--

CREATE TABLE IF NOT EXISTS `addons_citypay` (
  `TransactionExt` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uid` bigint(16) unsigned NOT NULL,
  `TransactionId` bigint(20) unsigned NOT NULL,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `Amount` double(14,2) NOT NULL,
  `TerminalId` int(10) unsigned NOT NULL,
  `status` varchar(6) CHARACTER SET koi8r NOT NULL,
  PRIMARY KEY (`TransactionExt`),
  KEY `time` (`order_date`),
  KEY `uid-time` (`uid`,`order_date`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COLLATE=koi8r_bin AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_compay`
--

CREATE TABLE IF NOT EXISTS `addons_compay` (
  `paymentid` int(14) NOT NULL AUTO_INCREMENT,
  `service_id` int(10) unsigned NOT NULL,
  `accaunt` varchar(32) CHARACTER SET koi8r NOT NULL,
  `id_payment` bigint(16) unsigned NOT NULL,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `sum` double(14,2) NOT NULL,
  `status` char(7) COLLATE koi8r_bin NOT NULL,
  `date` char(14) COLLATE koi8r_bin NOT NULL,
  PRIMARY KEY (`paymentid`),
  KEY `status` (`status`),
  KEY `time` (`order_date`),
  KEY `uid-time` (`accaunt`,`order_date`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COLLATE=koi8r_bin AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_copayco`
--

CREATE TABLE IF NOT EXISTS `addons_copayco` (
  `order_id` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `order_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `sCurrency` char(4) CHARACTER SET koi8r COLLATE koi8r_bin DEFAULT 'UAH',
  `uid` bigint(16) NOT NULL,
  `nAmount` double(14,2) DEFAULT NULL,
  `sCustom` char(128) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `sStatus` char(20) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  PRIMARY KEY (`order_id`),
  KEY `date` (`order_date`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_easysoft`
--

CREATE TABLE IF NOT EXISTS `addons_easysoft` (
  `paymentid` int(14) NOT NULL AUTO_INCREMENT,
  `service_id` int(10) unsigned NOT NULL,
  `uid` bigint(16) unsigned NOT NULL,
  `OrderId` char(64) COLLATE koi8r_bin NOT NULL,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `Amount` double(14,2) NOT NULL,
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `cancel` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`paymentid`),
  KEY `time` (`order_date`),
  KEY `uid-time` (`uid`,`order_date`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COLLATE=koi8r_bin AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_elecsnet`
--

CREATE TABLE IF NOT EXISTS `addons_elecsnet` (
  `prv_txn` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `txn_id` char(64) NOT NULL DEFAULT '',
  `check_time` datetime NOT NULL,
  `time_from_osmp` char(20) DEFAULT NULL,
  `accaunt` char(20) NOT NULL,
  `sum` double(14,2) DEFAULT NULL,
  `time_stamp` datetime NOT NULL,
  `type` varchar(5) CHARACTER SET koi8u NOT NULL,
  PRIMARY KEY (`prv_txn`),
  KEY `time` (`check_time`),
  KEY `timstamp` (`time_stamp`),
  KEY `uid` (`accaunt`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_liqpay`
--

CREATE TABLE IF NOT EXISTS `addons_liqpay` (
  `order_id` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `merchant_id` char(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `currency` char(4) CHARACTER SET koi8r COLLATE koi8r_bin DEFAULT NULL,
  `uid` bigint(16) NOT NULL,
  `amount` double(14,2) DEFAULT NULL,
  `description` char(128) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `status` char(20) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `code` char(20) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `transaction_id` char(64) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `pay_way` char(10) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `sender_phone` char(16) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  PRIMARY KEY (`order_id`),
  KEY `date` (`order_date`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_nonstop`
--

CREATE TABLE IF NOT EXISTS `addons_nonstop` (
  `pay_id` char(64) NOT NULL DEFAULT '',
  `service_id` char(20) NOT NULL,
  `trade_point` char(20) NOT NULL,
  `pay_accaunt` char(20) NOT NULL,
  `pay_amount` double(14,2) DEFAULT NULL,
  `receipt_num` char(32) DEFAULT NULL,
  `time_stamp` char(32) NOT NULL,
  `status_code` char(5) NOT NULL,
  `date` datetime NOT NULL,
  PRIMARY KEY (`pay_id`),
  KEY `date` (`date`),
  KEY `time` (`time_stamp`),
  KEY `uid` (`pay_accaunt`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_onpay`
--

CREATE TABLE IF NOT EXISTS `addons_onpay` (
  `payid` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `uid` bigint(16) unsigned NOT NULL,
  `order_amount` float(14,2) NOT NULL,
  `order_currency` char(3) NOT NULL,
  `type` char(5) CHARACTER SET koi8u NOT NULL,
  `comment` varchar(255) NOT NULL,
  `paymentDateTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `onpay_id` int(32) unsigned NOT NULL,
  `user_phone` varchar(16) NOT NULL,
  PRIMARY KEY (`payid`),
  KEY `paymentDateTime` (`paymentDateTime`,`onpay_id`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_osmp`
--

CREATE TABLE IF NOT EXISTS `addons_osmp` (
  `prv_txn` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `txn_id` char(64) NOT NULL DEFAULT '',
  `check_time` datetime NOT NULL,
  `time_from_osmp` char(20) DEFAULT NULL,
  `accaunt` char(20) NOT NULL,
  `sum` double(14,2) DEFAULT NULL,
  `time_stamp` datetime NOT NULL,
  PRIMARY KEY (`prv_txn`),
  KEY `time` (`check_time`),
  KEY `timstamp` (`time_stamp`),
  KEY `uid` (`accaunt`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_privat24`
--

CREATE TABLE IF NOT EXISTS `addons_privat24` (
  `order_id` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `merchant_id` char(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `currency` char(4) CHARACTER SET koi8r COLLATE koi8r_bin DEFAULT NULL,
  `uid` bigint(16) NOT NULL,
  `amount` double(14,2) DEFAULT NULL,
  `details` char(128) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `status` char(20) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `transaction_id` char(64) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `pay_way` char(10) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `sender_phone` char(16) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  PRIMARY KEY (`order_id`),
  KEY `date` (`order_date`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_robokassa`
--

CREATE TABLE IF NOT EXISTS `addons_robokassa` (
  `order_id` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `uid` int(14) NOT NULL,
  `amount` double(14,2) NOT NULL,
  `status` int(1) unsigned NOT NULL,
  PRIMARY KEY (`order_id`),
  UNIQUE KEY `order_id` (`order_id`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `addons_wqiwiru`
--

CREATE TABLE IF NOT EXISTS `addons_wqiwiru` (
  `prv_txn` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `status` int(10) unsigned NOT NULL DEFAULT '0',
  `check_time` datetime NOT NULL,
  `uid` bigint(16) unsigned NOT NULL,
  `sum` double(14,2) DEFAULT NULL,
  `time_stamp` datetime NOT NULL,
  PRIMARY KEY (`prv_txn`),
  KEY `time` (`check_time`),
  KEY `timstamp` (`time_stamp`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `bugh_cards_log`
--

CREATE TABLE IF NOT EXISTS `bugh_cards_log` (
  `cardslogid` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `uid` bigint(16) unsigned NOT NULL,
  `card` char(64) NOT NULL,
  `cards_id` int(10) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `before_billing` double(20,6) NOT NULL,
  `summa` double(20,6) NOT NULL,
  PRIMARY KEY (`cardslogid`),
  KEY `card-index` (`card`),
  KEY `date` (`date`),
  KEY `uid` (`uid`),
  KEY `uid-date` (`uid`,`date`),
  FULLTEXT KEY `card` (`card`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `bugh_perevod_stat`
--

CREATE TABLE IF NOT EXISTS `bugh_perevod_stat` (
  `bugh_perevod_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `date` datetime NOT NULL,
  `perevod_from` bigint(16) unsigned NOT NULL,
  `perevod_to` bigint(16) unsigned NOT NULL,
  `perevod_comment` char(20) DEFAULT NULL,
  `before_perevod` double(20,6) NOT NULL,
  `summa_perevoda` double(20,6) NOT NULL,
  `comisiya` double(20,6) NOT NULL,
  PRIMARY KEY (`bugh_perevod_id`),
  KEY `date` (`date`),
  KEY `uid` (`perevod_from`),
  KEY `uid2` (`perevod_to`),
  KEY `uid2-date` (`perevod_to`,`date`),
  KEY `uid-date` (`perevod_from`,`date`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COMMENT='bugh peredov stat' AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `bugh_plategi_stat`
--

CREATE TABLE IF NOT EXISTS `bugh_plategi_stat` (
  `plategid` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `uid` bigint(16) unsigned NOT NULL,
  `date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `who` tinyint(6) unsigned DEFAULT NULL,
  `bughtypeid` smallint(10) unsigned NOT NULL,
  `before_billing` double(20,6) NOT NULL,
  `summa` double(20,6) NOT NULL,
  `comment` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`plategid`),
  KEY `bughtypeid` (`bughtypeid`),
  KEY `date` (`date`),
  KEY `date_type` (`date`,`bughtypeid`),
  KEY `summa` (`date`,`bughtypeid`,`summa`),
  KEY `summa-2` (`summa`),
  KEY `uid` (`uid`),
  KEY `uid-date` (`uid`,`date`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `bugh_plategi_type`
--

CREATE TABLE IF NOT EXISTS `bugh_plategi_type` (
  `bughtypeid` smallint(10) unsigned NOT NULL AUTO_INCREMENT,
  `typename` char(128) NOT NULL,
  `fiktivniy` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`bughtypeid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=132 AUTO_INCREMENT=60 ;

--
-- Дамп данных таблицы `bugh_plategi_type`
--

INSERT INTO `bugh_plategi_type` (`bughtypeid`, `typename`, `fiktivniy`) VALUES
(1, 'Абонентская плата за текущий месяц', 0),
(2, 'Абонентская плата за текущий день', 0),
(5, 'Пополнение счета', 0),
(6, 'Ошибка ввода', 0),
(7, 'Снятие со счета', 0),
(9, 'Оплата аренды внешнего IP адреса', 0),
(10, 'Перерасчет', 1),
(15, 'Премия За Общественнополезные работы', 1),
(16, 'ПОДАРОК!', 1),
(17, 'Акция', 1),
(18, 'Кредит', 1),
(20, 'Блокировка интернета в связи с окончанием сердств', 1),
(21, 'Остаточная абонплата за месяц', 0),
(22, 'Остаточная Абонентская плата за текущий месяц', 0),
(23, 'Изменение пакета с нового месяца', 1),
(24, 'Возврат из за перебоев сети', 1),
(25, 'Устранение неисправности по вине клиента', 0),
(26, 'Изменение тарифного пакета', 0),
(27, 'Подключение к компьютерной сети', 0),
(28, 'Пополнение карточкой', 0),
(29, '% за пользование кредитом', 0),
(30, 'Создание второй учетной записи', 0),
(31, 'Пополнение MobyAZS(24NonStop)', 0),
(32, 'Услуга Real IP', 1),
(33, 'Активация Акционного тарифа', 0),
(34, 'Услуга "Турбо"', 0),
(35, 'Активация услуги Кредит', 0),
(36, 'Активация услуги Кредит с %', 0),
(37, 'Пополнение OSMP', 0),
(38, 'Пополнение Liqpay', 0),
(39, 'Оплата замороки', 0),
(40, 'Пополнение Yandex деньги', 0),
(41, 'Пополнение WebMoney', 0),
(42, 'Отключение по задолжености', 0),
(43, 'Удаление по неактивности', 0),
(44, 'Пополнение CoPayCo', 0),
(45, 'Безналичный платеж', 0),
(46, 'Активация учетки абонента', 0),
(47, 'Пополнение МТС-терминал', 0),
(48, 'Оплата Разморозки', 0),
(49, 'Возврат Абонплаты по заморозке', 0),
(50, 'Оплата Dr.Web', 0),
(51, 'Абонентская плата заморозки', 0),
(52, 'Пополнение EasySoft', 0),
(53, 'Пополнение OnePay', 0),
(54, 'Пополнение Privat24', 0),
(55, 'Пополнение CitiPay', 0),
(56, 'Пополнение Elecsnet', 0),
(57, 'Пополнение w.QiWi.ru', 0),
(58, 'Пополнение ComPay', 0),
(59, 'Пополнение RoboKassa', 0);

-- --------------------------------------------------------

--
-- Структура таблицы `bugh_uslugi_stat`
--

CREATE TABLE IF NOT EXISTS `bugh_uslugi_stat` (
  `uslid` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `uid` bigint(16) unsigned NOT NULL,
  `gid` smallint(5) unsigned NOT NULL,
  `usluga` int(5) unsigned NOT NULL DEFAULT '0',
  `date_start` datetime NOT NULL,
  `date_stop` datetime DEFAULT NULL,
  `active` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `before_billing` double(20,6) DEFAULT NULL,
  `before_billing_credit` double(20,6) DEFAULT NULL,
  `credit` double(20,6) DEFAULT NULL,
  `deposit` double(20,6) DEFAULT NULL,
  `summa` double(20,6) DEFAULT NULL,
  PRIMARY KEY (`uslid`),
  KEY `date-start` (`date_start`),
  KEY `date-stop` (`date_stop`),
  KEY `uid` (`uid`),
  KEY `uid-date` (`uid`,`date_start`,`date_stop`),
  KEY `uid-date-start` (`uslid`,`date_start`),
  KEY `uid-date-stop` (`uid`,`date_stop`),
  KEY `uid-usluga` (`uid`,`usluga`,`date_start`,`date_stop`),
  KEY `usl-date-start` (`usluga`,`date_start`),
  KEY `usl-date-stop` (`usluga`,`date_stop`),
  KEY `usluga` (`usluga`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=76 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `bugh_uslugi_stat`
--

INSERT INTO `bugh_uslugi_stat` (`uslid`, `uid`, `gid`, `usluga`, `date_start`, `date_stop`, `active`, `before_billing`, `before_billing_credit`, `credit`, `deposit`, `summa`) VALUES
(1, 5, 1, 5, '2013-07-17 18:22:04', '2013-07-17 00:00:00', 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000),
(2, 6, 2, 5, '2013-07-19 18:01:30', '2013-07-19 00:00:00', 0, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000);

-- --------------------------------------------------------

--
-- Структура таблицы `bugh_uslugi_type`
--

CREATE TABLE IF NOT EXISTS `bugh_uslugi_type` (
  `usluga` int(5) unsigned NOT NULL AUTO_INCREMENT,
  `usluganame` varchar(64) NOT NULL,
  PRIMARY KEY (`usluga`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=26 AUTO_INCREMENT=6 ;

--
-- Дамп данных таблицы `bugh_uslugi_type`
--

INSERT INTO `bugh_uslugi_type` (`usluga`, `usluganame`) VALUES
(1, 'Услуга Кредит'),
(2, 'Услуга Кредит с %'),
(3, 'Услуга "Турбо"'),
(5, 'Услуга "Заморозка"');

-- --------------------------------------------------------

--
-- Структура таблицы `errorcodes`
--

CREATE TABLE IF NOT EXISTS `errorcodes` (
  `code` char(4) NOT NULL,
  `text` blob NOT NULL,
  UNIQUE KEY `code` (`code`),
  FULLTEXT KEY `kode` (`code`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=73 COMMENT='Коды ошибок VPN';

--
-- Дамп данных таблицы `errorcodes`
--

INSERT INTO `errorcodes` (`code`, `text`) VALUES
('600', 0xeec1dec1d4c1d120cfd0c5d2c1c3c9d120cec520dac1cbcfcedec5cec1),
('601', 0xeec5d7c5d2ced9ca20c4c5d3cbd2c9d0d4cfd220d0cfd2d4c12e),
('602', 0xf0cfd2d420d5d6c520cfd4cbd2d9d42e),
('603', 0xe2d5c6c5d220d7d9dad9d7c1c0ddc5c7cf20cbcfcdd0d8c0d4c5d2c120d3ccc9dbcbcfcd20cdc1cc2e),
('604', 0xe4c1ceced9c520dac1c4c1ced920cec5d7c5d2cecf2e),
('605', 0xeec520d5c4c1c5d4d3d120d5d3d4c1cecfd7c9d4d820d0c1d2c1cdc5d4d2d920d0cfd2d4c12e),
('606', 0xf0cfd2d420cec520d0cfc4cbccc0dec5ce2e),
('607', 0xeec5cbcfd2d2c5cbd4cecfc520d3cfc2d9d4c9c52e),
('608', 0xf5d3d4d2cfcad3d4d7cf20cec520d3d5ddc5d3d4d7d5c5d42e),
('609', 0xf5cbc1dac1ceced9ca20d4c9d020d5d3d4d2cfcad3d4d7c120cec520d3d5ddc5d3d4d7d5c5d42e),
('610', 0xeec5d7c5d2cecf20dac1c4c1ce20c2d5c6c5d22e),
('611', 0xedc1d2dbd2d5d420cec5c4cfd3d4d5d0c5ce2e),
('612', 0xedc1d2dbd2d5d420cec520d7d9c4c5ccc5ce2e),
('613', 0xeec5d7c5d2cecf20dac1c4c1ce20d2c5d6c9cd20d3d6c1d4c9d12e),
('614', 0xeec5c4cfd3d4c1d4cfdececf20d0c1cdd1d4c92e),
('615', 0xf0cfd2d420cec520cec1cac4c5ce2e),
('616', 0xe1d3c9cec8d2cfceced9ca20dac1d0d2cfd320d6c4c5d420cfc2d2c1c2cfd4cbc92e),
('617', 0xefd4cbccc0dec5cec9c520d0cfd2d4c120c9ccc920d5d3d4d2cfcad3d4d7c120d5d6c520d0d2cfc9d3c8cfc4c9d42e),
('618', 0xf0cfd2d420cec520cfd4cbd2d9d42e),
('619', 0xf0cfd2d420cfd4cbccc0dec5ce2e),
('620', 0xefd4d3d5d4d3d4d7d5c0d420cbcfcec5deced9c520d4cfdecbc92e),
('621', 0xeec520d5c4c1c5d4d3d120cfd4cbd2d9d4d820c6c1cacc20d4c5ccc5c6cfcececfca20cbcec9c7c92e),
('622', 0xeec520d5c4c1c5d4d3d120dac1c7d2d5dac9d4d820c6c1cacc20d4c5ccc5c6cfcececfca20cbcec9c7c92e),
('623', 0xeec520d5c4c1c5d4d3d120cec1cad4c920dac1d0c9d3d820d720d4c5ccc5c6cfcececfca20cbcec9c7c52e),
('624', 0xeec520d5c4c1c5d4d3d120dac1d0c9d3c1d4d820c6c1cacc20d4c5ccc5c6cfcececfca20cbcec9c7c92e),
('625', 0xf720c6c1caccc520d4c5ccc5c6cfcececfca20cbcec9c7c920cec1cac4c5ced920cec5d7c5d2ced9c520c4c1ceced9c52e),
('626', 0xeec520d5c4c1c5d4d3d120dac1c7d2d5dac9d4d820d3d4d2cfcbd52e),
('627', 0xeec520d5c4c1c5d4d3d120cec1cad4c920d0c1d2c1cdc5d4d22e),
('628', 0xf0cfd2d420c2d9cc20cfd4cbccc0dec5ce2e),
('629', 0xf0cfd2d420c2d9cc20cfd4cbccc0dec5ce20d5c4c1ccc5ceced9cd20cbcfcdd0d8c0d4c5d2cfcd2e),
('630', 0xf0cfd2d420c2d9cc20cfd4cbccc0dec5ce20c9da2ddac120c1d0d0c1d2c1d4cecfc7cf20d3c2cfd12e),
('631', 0xf0cfd2d420c2d9cc20cfd4cbccc0dec5ce20d0cfccd8dacfd7c1d4c5ccc5cd2e),
('632', 0xeec5d7c5d2ced9ca20d2c1dacdc5d220d3d4d2d5cbd4d5d2d92e),
('633', 0xf0cfd2d420d5d6c520c9d3d0cfccd8dad5c5d4d3d120ccc9c2cf20cec520d3cbcfcec6c9c7d5d2c9d2cfd7c1ce20c4ccd120d5c4c1ccc5cececfc7cf20d0cfc4cbccc0dec5cec9d120cb20d3c5d4c92e),
('634', 0xeec520d5c4c1c5d4d3d120dac1d2c5c7c9d3d4d2c9d2cfd7c1d4d820cbcfcdd0d8c0d4c5d220d720d5c4c1ccc5cececfca20d3c5d4c92e),
('635', 0xeec5c9dad7c5d3d4cec1d120cfdbc9c2cbc12e),
('636', 0xeb20d0cfd2d4d520d0cfc4cbccc0dec5cecf20cec5d7c5d2cecfc520d5d3d4d2cfcad3d4d7cf2e),
('637', 0xeec520d5c4c1cccfd3d820d0d2c5cfc2d2c1dacfd7c1d4d820d3d4d2cfcbd52e),
('638', 0xfac1d0d2cfd320d0d2cfd3d2cfdec5ce2e),
('639', 0xe1d3c9cec8d2cfcecec1d120d3c5d4d820cec5c4cfd3d4d5d0cec12e),
('640', 0xefdbc9c2cbc1204e657442494f532e),
('641', 0xf3c5d2d7c5d2d520cec520d5c4c1cccfd3d820d7d9c4c5ccc9d4d8204e657442494f532dd2c5d3d5d2d3d92c20cec5cfc2c8cfc4c9cdd9c520c4ccd120d0cfc4c4c5d2d6cbc920dcd4cfc7cf20cbccc9c5ced4c12e),
('642', 0xefc4cecf20c9da20c9cdc5ce204e657442494f5320d5d6c520dac1d2c5c7c9d3d4d2c9d2cfd7c1cecf20d720d5c4c1ccc5cececfca20d3c5d4c92e),
('643', 0xefdbc9c2cbc120d3c5d4c5d7cfc7cf20c1c4c1d0d4c5d2c120d3c5d2d7c5d2c12e),
('644', 0xf7d3d0ccd9d7c1c0ddc9c520d3c5d4c5d7d9c520d3cfcfc2ddc5cec9d120d0cfccd5dec1d4d8d3d120cec520c2d5c4d5d42e),
('645', 0xf7ced5d4d2c5ceced1d120cfdbc9c2cbc120d0d2c920d0d2cfd7c5d2cbc52e),
('646', 0xf7c8cfc420d720dcd4cf20d7d2c5cdd120c4ced120c4ccd120d0cfccd8dacfd7c1d4c5ccd120d320c4c1cececfca20d5dec5d4cecfca20dac1d0c9d3d8c020cec520d2c1dad2c5dbc5ce2e),
('647', 0xf5dec5d4cec1d120dac1d0c9d3d820cfd4cbccc0dec5cec12e),
('648', 0xf3d2cfcb20c4c5cad3d4d7c9d120d0c1d2cfccd120c9d3d4c5cb2e),
('649', 0xf5dec5d4cec1d120dac1d0c9d3d820cec520d0d2c5c4d5d3cdc1d4d2c9d7c1c5d420d5c4c1ccc5cececfc7cf20d0cfc4cbccc0dec5cec9d120cb20d3c5d4c92e),
('650', 0xf3c5d2d7c5d220d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c120cec520cfd4d7c5dec1c5d42e),
('651', 0xedcfc4c5cd2028c9ccc920c9cecfc520d5d3d4d2cfcad3d4d7cf20d3d7d1dac92920d3cfcfc2ddc1c5d420cfc220cfdbc9c2cbc52e),
('652', 0xefd4cbccc9cb20d5d3d4d2cfcad3d4d7c120cec520d2c1d3d0cfdacec1ce2e),
('653', 0xf4d2c5c2d5c0ddc9cad3d120d5d3d4d2cfcad3d4d7d520cdc1cbd2cfd320cec520cec1cac4c5ce20d720d3cfcfd4d7c5d4d3d4d7d5c0ddc5cd20d2c1dac4c5ccc5204e462dc6c1caccc12e),
('654', 0xebcfcdc1cec4c120c9ccc920cfd4cbccc9cb20d720d3cfcfd4d7c5d4d3d4d7d5c0ddc5cd20d2c1dac4c5ccc520494e462dc6c1caccc120d3d3d9ccc1c5d4d3d120cec120cdc1cbd2cfd32c20cbcfd4cfd2d9ca20cec520c2d9cc20cfd0d2c5c4c5ccc5ce2e),
('655', 0xedc1cbd2cfd32022d3cfcfc2ddc5cec9d12220cec520cec1cac4c5ce20d720d3c5cbc3c9c920494e462dc6c1caccc120d5d3d4d2cfcad3d4d7c12e),
('656', 0xedc1cbd2cfd3202264656661756c746f66662220d720d3cfcfd4d7c5d4d3d4d7d5c0ddc5cd20d2c1dac4c5ccc520494e462dc6c1caccc120d3cfc4c5d2d6c9d420cec5c9dad7c5d3d4ced9ca20cdc1cbd2cfd32e),
('657', 0xeec520d5c4c1c5d4d3d120cfd4cbd2d9d4d820494e462dc6c1cacc20d5d3d4d2cfcad3d4d7c12e),
('658', 0xe9cdd120d5d3d4d2cfcad3d4d7cf20d720494e462dc6c1caccc520c9cdc5c5d420d3ccc9dbcbcfcd20c2cfccd8dbd5c020c4ccc9ced52e),
('659', 0x494e492dc6c1cacc20d3d3d9ccc1c5d4d3d120cec120cec5c9dad7c5d3d4cecfc520d5d3d4d2cfcad3d4d7cf2e),
('660', 0x494e462dc6c1cacc20d5d3d4d2cfcad3d4d7c120cec520d3cfc4c5d2d6c9d420cfd4cbccc9cbcfd720cec120cbcfcdc1cec4d52e),
('661', 0xf720494e462dc6c1caccc520cfd4d3d5d4d3d4d7d5c5d420cbcfcdc1cec4c12e),
('662', 0xf0cfd0d9d4cbc120cfc2d2c1ddc5cec9d120cb20cdc1cbd2cfd3d52c20cec520cfd0d2c5c4c5ccc5cececfcdd520d720494e462dc6c1caccc52e),
('663', 0x494e492dc6c1cacc20d3d3d9ccc1c5d4d3d120cec120cec5c9dad7c5d3d4cecfc520d5d3d4d2cfcad3d4d7cf2e),
('664', 0xeec520d5c4c1c5d4d3d120d7d9c4c5ccc9d4d820d0c1cdd1d4d82e),
('665', 0xf0cfd2d420cec520cec1d3d4d2cfc5ce20cec120d5c4c1ccc5ceced9ca20c4cfd3d4d5d020cb20d3c5d4c92e),
('666', 0xedcfc4c5cd2028c9ccc920c4d2d5c7cfc520d5d3d4d2cfcad3d4d7cf20d3d7d1dac92920cec520d2c1c2cfd4c1c5d42e),
('667', 0xeec520d5c4c1c5d4d3d120d0d2cfdec9d4c1d4d820494e492dc6c1cacc2e),
('668', 0xf3d7d1dad820d0cfd4c5d2d1cec12e),
('669', 0xeec5d7c5d2ced9ca20d0c1d2c1cdc5d4d220d720494e492dc6c1caccc52e),
('670', 0xeec520d5c4c1c5d4d3d120d0d2cfdec9d4c1d4d820cec1dad7c1cec9c520d2c1dac4c5ccc120494e492dc6c1caccc12e),
('671', 0xeec520d5c4c1c5d4d3d120d0d2cfdec9d4c1d4d820d4c9d020d5d3d4d2cfcad3d4d7c120c9da20494e492dc6c1caccc12e),
('672', 0xeec520d5c4c1c5d4d3d120d0d2cfdec9d4c1d4d820c9cdd120d5d3d4d2cfcad3d4d7c120c9da20494e492dc6c1caccc12e),
('673', 0xeec520d5c4c1c5d4d3d120d0d2cfdec9d4c1d4d820d4c9d020c9d3d0cfccd8dacfd7c1cec9d120c9da20494e492dc6c1caccc12e),
('674', 0xeec520d5c4c1c5d4d3d120d0d2cfdec9d4c1d4d820cdc1cbd3c9cdc1ccd8ced5c020d3cbcfd2cfd3d4d820d0c5d2c5c4c1dec920c4ccd120d5d3d4d2cfcad3d4d7c120c9da20494e492dc6c1caccc12e),
('675', 0xeec520d5c4c1c5d4d3d120d0d2cfdec9d4c1d4d820cdc1cbd3c9cdc1ccd8ced5c020cec5d3d5ddd5c020d3cbcfd2cfd3d4d820d5d3d4d2cfcad3d4d7c120c9da20494e492dc6c1caccc12e),
('676', 0xecc9cec9d120dac1ced1d4c12e),
('677', 0xf7cdc5d3d4cf20cdcfc4c5cdc120d4d2d5c2cbc120c2d9ccc120d0cfc4ced1d4c120dec5cccfd7c5cbcfcd2e),
('678', 0xeec5d420cfd4cbccc9cbc12e),
('679', 0xeec5d420cec5d3d5ddc5ca20dec1d3d4cfd4d92e),
('680', 0xefd4d3d5d4d3d4d7d5c5d420c7d5c4cfcb2e),
('681', 0xefdbc9c2cbc120d5d3d4d2cfcad3d4d7c12e),
('682', 0x4552524f522057524954494e472053454354494f4e4e414d45),
('683', 0x4552524f522057524954494e472044455649434554595045),
('684', 0x4552524f522057524954494e472044455649434554595045),
('685', 0x4552524f522057524954494e47204d4158434f4e4e454354425053),
('686', 0x4552524f522057524954494e47204d4158434f4e4e454354425053),
('687', 0x4552524f522057524954494e47205553414745),
('688', 0x4552524f522057524954494e472044454641554c544f4646),
('689', 0x4552524f522052454144494e472044454641554c544f4646),
('690', 0x4552524f5220454d50545920494e492046494c45),
('691', 0xe9cdd120d0cfccd8dacfd7c1d4c5ccd120c9ccc920d0c1d2cfccd820cec520cfd0cfdacec1ced920c4cfcdc5cecfcd2e),
('692', 0xe1d0d0c1d2c1d4ced9ca20d3c2cfca20d0cfd2d4c120c9ccc920d0d2c9d3cfc5c4c9cec5cececfc7cf20cb20cec5cdd520d5d3d4d2cfcad3d4d7c12e),
('693', 0x4552524f52204e4f542042494e415259204d4143524f),
('694', 0x4552524f5220444342204e4f5420464f554e44),
('695', 0x4552524f52205354415445204d414348494e4553204e4f542053544152544544),
('696', 0x4552524f52205354415445204d414348494e455320414c52454144592053544152544544),
('697', 0x4552524f52205041525449414c20524553504f4e5345204c4f4f50494e47),
('698', 0xeec5d7c5d2ced9ca20c6cfd2cdc1d420d0c1d2c1cdc5d4d2c120cfd4cbccc9cbc120d720494e462dc6c1caccc52e),
('699', 0xefd4cbccc9cb20d5d3d4d2cfcad3d4d7c120d7d9dad7c1cc20d0c5d2c5d0cfcccec5cec9c520c2d5c6c5d2c12e),
('700', 0xf2c1d3dbc9d2c5cecec1d120cbcfcdc1cec4c120d720494e462dc6c1caccc520c9cdc5c5d420d3ccc9dbcbcfcd20c2cfccd8dbd5c020c4ccc9ced52e),
('701', 0xf5d3d4d2cfcad3d4d7cf20d0c5d2c5dbcccf20cec120d3cbcfd2cfd3d4d820d0d2c9c5cdc12fd0c5d2c5c4c1dec92c20cec520d0cfc4c4c5d2d6c9d7c1c0ddd5c0d3d120c4d2c1cad7c5d2cfcd20434f4d2dd0cfd2d4c12e),
('702', 0xf0cfccd5dec5ce20cec5cfd6c9c4c1c5cdd9ca20cfd4d7c5d420cfd420d5d3d4d2cfcad3d4d7c12e),
('703', 0x4552524f5220494e544552414354495645204d4f4445),
('704', 0x4552524f52204241442043414c4c4241434b204e554d424552),
('705', 0x4552524f5220494e56414c49442041555448205354415445),
('706', 0x4552524f522057524954494e4720494e4954425053),
('707', 0xe9cec4c9cbc1c3c9d120c4c9c1c7cecfd3d4c9cbc920582e32352e),
('708', 0xe4c1cecec1d120d5dec5d4cec1d120dac1d0c9d3d820d0d2cfd3d2cfdec5cec12e),
('709', 0xefdbc9c2cbc120d0d2c920d3cdc5cec520d0c1d2cfccd120d720c4cfcdc5cec52e),
('710', 0xefdbc9c2cbc920d0c5d2c5d0cfcccec5cec9d120c2d5c6c5d2c120d0cfd2d4c120d0d2c920d2c1c2cfd4c520d320cdcfc4c5cdcfcd2e),
('711', 0xf3c2cfca20c9cec9c3c9c1ccc9dac1c3c9c920c4c9d3d0c5d4dec5d2c120d5c4c1ccc5cececfc7cf20d0cfc4cbccc0dec5cec9d12e20f0d2cfd7c5d2d8d4c520d6d5d2cec1cc20d3cfc2d9d4c9ca2e),
('712', 0xe9cec9c3c9c1ccc9dac1c3c9d120d3c4d7cfc5cececfc7cf20d0cfd2d4c12e20f0cfc4cfd6c4c9d4c520cec5d3cbcfccd8cbcf20d3c5cbd5cec420c920d0c5d2c5dad7cfcec9d4c52e),
('713', 0xeec5d420c4cfd3d4d5d0ced9c820ccc9cec9ca204953444e2e),
('714', 0xeec5d420c4cfd3d4d5d0ced9c8204953444e2dcbc1cec1cccfd720c4ccd120d7d9d0cfcccec5cec9d120dad7cfcecbc12e),
('715', 0xe9da2ddac120cec9dacbcfc7cf20cbc1dec5d3d4d7c120d4c5ccc5c6cfcececfca20ccc9cec9c920d0d2cfc9dacfdbcccf20d3ccc9dbcbcfcd20cdcecfc7cf20cfdbc9c2cfcb2e),
('716', 0x49502dcbcfcec6c9c7d5d2c1c3c9d120d3ccd5d6c2d920d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c120cec5d0d2c9c7cfc4cec120c4ccd120c9d3d0cfccd8dacfd7c1cec9d12e),
('717', 0xeec5d420c4cfd3d4d5d0ced9c82049502dc1c4d2c5d3cfd720d720d3d4c1d4c9dec5d3cbcfcd20d0d5ccc52049502dc1c4d2c5d3cfd720d3ccd5d6c2d920d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c12e),
('718', 0xf0d2c5d7d9dbc5cecf20d7d2c5cdd120cfd6c9c4c1cec9d1205050502e),
('719', 0xf3c5c1ced32050505020d0d2c5d2d7c1ce20d5c4c1ccc5ceced9cd20cbcfcdd0d8c0d4c5d2cfcd2e),
('720', 0xeec5d420cec1d3d4d2cfc5ceced9c820d0d2cfd4cfcbcfcccfd720d5d0d2c1d7ccc5cec9d1205050502e),
('721', 0xf5c4c1ccc5ceced9ca20d5dac5cc2050505020cec520cfd4d7c5dec1c5d42e),
('722', 0xeec5c4cfd0d5d3d4c9cdd9ca20d0c1cbc5d4205050502e),
('723', 0xf4c5ccc5c6cfceced9ca20cecfcdc5d22c20d7cbccc0dec1d120d0d2c5c6c9cbd320c920d3d5c6c6c9cbd32c20d3ccc9dbcbcfcd20c4ccc9ceced9ca2e),
('724', 0x4950582dd0d2cfd4cfcbcfcc20cec520cdcfd6c5d420c2d9d4d820c9d3d0cfccd8dacfd7c1ce20c4ccd120d7d9d0cfcccec5cec9d120c9d3c8cfc4d1ddc9c820dad7cfcecbcfd720cec120c4c1cececfcd20d0cfd2d4d52c20d0cfd3cbcfccd8cbd520cbcfcdd0d8c0d4c5d220d1d7ccd1c5d4d3d1204950582dcdc1d2dbd2d5d4c9dac1d4cfd2cfcd2e),
('725', 0x4950582dd0d2cfd4cfcbcfcc20cec520cdcfd6c5d420c2d9d4d820c9d3d0cfccd8dacfd7c1ce20c4ccd120d7d9d0cfcccec5cec9d120d7c8cfc4d1ddc9c820dad7cfcecbcfd72c20d0cfd3cbcfccd8cbd5204950582dcdc1d2dbd2d5d4c9dac1d4cfd220cec520d5d3d4c1cecfd7ccc5ce2e),
('726', 0x4950582dd0d2cfd4cfcbcfcc20cec520cdcfd6c5d420c2d9d4d820c9d3d0cfccd8dacfd7c1ce20c4ccd120d7d9d0cfcccec5cec9d120c9d3c8cfc4d1ddc9c820dad7cfcecbcfd720cec120c2cfccc5c520dec5cd20cfc4cecfcd20d0cfd2d4d520cfc4cecfd7d2c5cdc5cececf2e),
('727', 0xeec5d420c4cfd3d4d5d0c120cb203f5443504346472e444c4c3f2e),
('728', 0xeec520d5c4c1c5d4d3d120cec1cad4c92049502dc1c4c1d0d4c5d22c20d0d2c9d7d1dac1ceced9ca20cb20d3c5d2d7c5d2d520d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c12e),
('729', 0xf0cfcbc120cec520c2d5c4c5d420d5d3d4c1cecfd7ccc5ce20d0d2cfd4cfcbcfcc2049502c20c9d3d0cfccd8dacfd7c1d4d820d0d2cfd4cfcbcfcc20534c495020cec5d7cfdacdcfd6cecf2e20),
('730', 0xf2c5c7c9d3d4d2c1c3c9d120cbcfcdd0d8c0d4c5d2c120cec520dac1d7c5d2dbc5cec12e),
('731', 0xf0d2cfd4cfcbcfcc20cec520cec1d3d4d2cfc5ce2e),
('732', 0xeec520d5c4c1c5d4d3d120d0d2cfc9dad7c5d3d4c920d3cfc7ccc1d3cfd7c1cec9c5205050502e),
('733', 0xeec120d3c5d2d7c5d2c520cec5c4cfd3d4d5d0c5ce20d5d0d2c1d7ccd1c0ddc9ca20d0d2cfd4cfcbcfcc2050505020c4ccd120c4c1cececfc7cf20d3c5d4c5d7cfc7cf20d0d2cfd4cfcbcfccc12e),
('734', 0xf0d2cfd4cfcbcfcc20d5d0d2c1d7ccc5cec9d1205050502dd3d7d1dad8c020c2d9cc20d0d2c5d2d7c1ce2e),
('735', 0xfac1d0d2cfdbc5ceced9ca20c1c4d2c5d320c2d9cc20cfd4d7c5d2c7ced5d420d3c5d2d7c5d2cfcd2e),
('736', 0xf5c4c1ccc5ceced9ca20cbcfcdd0d8c0d4c5d220dac1d7c5d2dbc9cc20d2c1c2cfd4d520d0d2cfd4cfcbcfccc120d5d0d2c1d7ccc5cec9d12e),
('737', 0xefc2cec1d2d5d6c5cecf20dac1cdd9cbc1cec9c520cec120d3c5c2d12e),
('738', 0xf3c5d2d7c5d220cec520cec1dacec1dec9cc20c1c4d2c5d32e),
('739', 0xf5c4c1ccc5ceced9ca20d3c5d2d7c5d220cec520cdcfd6c5d420c9d3d0cfccd8dacfd7c1d4d820dac1dbc9c6d2cfd7c1ceced9ca20d0c1d2cfccd82057696e646f7773204e542e),
('740', 0xf5d3d4d2cfcad3d4d7c120544150492c20cec1d3d4d2cfc5ceced9c520c4ccd120d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c12c20cec520c9cec9c3c9c1ccc9dac9d2d5c0d4d3d120c9ccc920d5d3d4c1cecfd7ccc5ced920d320cfdbc9c2cbc1cdc92e),
('741', 0xeccfcbc1ccd8ced9ca20cbcfcdd0d8c0d4c5d220cec520d0cfc4c4c5d2d6c9d7c1c5d420dbc9c6d2cfd7c1cec9c52e),
('742', 0xf5c4c1ccc5ceced9ca20d3c5d2d7c5d220cec520d0cfc4c4c5d2d6c9d7c1c5d420dbc9c6d2cfd7c1cec9c52e),
('743', 0xf5c4c1ccc5ceced9ca20d3c5d2d7c5d220d4d2c5c2d5c5d420dbc9c6d2cfd7c1cec9c52e),
('744', 0xf3c9d3d4c5cdc120cec520cdcfd6c5d420c9d3d0cfccd8dacfd7c1d4d820cecfcdc5d220d0cfc4d3c5d4c9204950582c20cec1dacec1dec5ceced9ca20c5ca20d5c4c1ccc5ceced9cd20d3c5d2d7c5d2cfcd2e20f0d2cfd7c5d2d8d4c520d6d5d2cec1cc20d3cfc2d9d4c9ca2e),
('745', 0x4552524f525f494e56414c49445f534d4d),
('746', 0x4552524f525f534d4d5f554e494e495449414c495a4544),
('747', 0x4552524f525f4e4f5f4d41435f464f525f504f5254),
('748', 0x4552524f525f534d4d5f54494d454f5554),
('749', 0x4552524f525f4241445f50484f4e455f4e554d424552),
('750', 0x4552524f525f57524f4e475f4d4f44554c45),
('751', 0xeecfcdc5d220cfc2d2c1d4cecfc7cf20d7d9dacfd7c120d3cfc4c5d2d6c9d420cec5c4cfd0d5d3d4c9cdd9c520d3c9cdd7cfccd92e2020e4cfd0d5d3d4c9cdd920d4cfccd8cbcf20d3ccc5c4d5c0ddc9c520313820dacec1cbcfd73a2020c3c9c6d2d92028cfd4203020c4cf2039292c20542c20502c20572c20282c20292c202d2c204020c920d0d2cfc2c5cc2e),
('752', 0xf0d2c920cfc2d2c1c2cfd4cbc520dcd4cfc7cf20d3c3c5cec1d2c9d120c2d9ccc120cfc2cec1d2d5d6c5cec120d3c9ced4c1cbd3c9dec5d3cbc1d120cfdbc9c2cbc12e),
('753', 0xf0cfc4cbccc0dec5cec9c520cec520cdcfd6c5d420c2d9d4d820d2c1dacfd2d7c1cecf2c20d0cfd3cbcfccd8cbd520cfcecf20d3cfdac4c1cecf20cdd5ccd8d4c9d0d2cfd4cfcbcfccd8ced9cd20cdc1d2dbd2d5d4c9dac1d4cfd2cfcd2e),
('754', 0xf3c9d3d4c5cdc520cec520d5c4c1c5d4d3d120cec1cad4c920cdcecfc7cfcbc1cec1ccd8ced9ca20d0d5decfcb2e),
('755', 0xf3c9d3d4c5cdc120cec520cdcfd6c5d420d7d9d0cfcccec9d4d820c1d7d4cfcdc1d4c9dec5d3cbc9ca20c4cfdad7cfce2c20d0cfd3cbcfccd8cbd520dcd4cf20d0cfc4cbccc0dec5cec9c520c9cdc5c5d420d0c1d2c1cdc5d4d2d920c4ccd120cbcfcecbd2c5d4cecfc7cf20dad7cfced1ddc5c7cf20d0cfccd8dacfd7c1d4c5ccd12e),
('756', 0xfcd4cf20d0cfc4cbccc0dec5cec9c520d5d6c520d7d9d0cfcccec5cecf2e),
('757', 0xf3ccd5d6c2d920d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c120cec520cdcfc7d5d420dac1d0d5d3cbc1d4d8d3d120c1d7d4cfcdc1d4c9dec5d3cbc92e20e4cfd0cfcccec9d4c5ccd8ced5c020c9cec6cfd2cdc1c3c9c020cdcfd6cecf20cec1cad4c920d720d6d5d2cec1ccc520d3cfc2d9d4c9ca2e),
('758', 0xe4ccd120dcd4cfc7cf20d0cfc4cbccc0dec5cec9d120d5d6c520d2c1dad2c5dbc5ce20cfc2ddc9ca20c4cfd3d4d5d020cb20d0cfc4cbccc0dec5cec9c020e9ced4c5d2cec5d4c12028494353292e),
('759', 0xf0d2cfc9dacfdbccc120cfdbc9c2cbc120d0d2c920c9dacdc5cec5cec9c920d0c1d2c1cdc5d4d2cfd720cfc2ddc5c7cf20c4cfd3d4d5d0c120cb20d0cfc4cbccc0dec5cec9c020e9ced4c5d2cec5d4c12e),
('760', 0xf0d2cfc9dacfdbccc120cfdbc9c2cbc120d0d2c920d2c1dad2c5dbc5cec9c920cdc1d2dbd2d5d4c9dac1c3c9c92e),
('761', 0xf0d2cfc9dacfdbccc120cfdbc9c2cbc120d0d2c920d2c1dad2c5dbc5cec9c920cfc2ddc5c7cf20c4cfd3d4d5d0c120cb20d0cfc4cbccc0dec5cec9c020e9ced4c5d2cec5d4c12e20),
('762', 0xf0d2c920cec1d3d4d2cfcacbc520cfc2ddc5c7cf20c4cfd3d4d5d0c120cb20cccfcbc1ccd8cecfca20d3c5d4c920d0d2cfc9dacfdbccc120cfdbc9c2cbc12e20),
('763', 0xeec520d5c4c1c5d4d3d120d2c1dad2c5dbc9d4d820cfc2ddc9ca20c4cfd3d4d5d020cb20d0cfc4cbccc0dec5cec9c020cb20e9ced4c5d2cec5d4d52e2020e2cfccc5c520dec5cd20cfc4cecf20d0cfc4cbccc0dec5cec9c520d0cf20cccfcbc1ccd8cecfca20d3c5d4c920c2d5c4c5d420c9d3d0cfccd8dacfd7c1cecf20d3cfd7cdc5d3d4cecf2e20),
('764', 0xf3dec9d4d9d7c1d4c5ccc920d3cdc1d2d42dcbc1d2d420cec520d5d3d4c1cecfd7ccc5ced92e20),
('765', 0xeec520d5c4c1c5d4d3d120d2c1dad2c5dbc9d4d820cfc2ddc9ca20c4cfd3d4d5d020cb20d0cfc4cbccc0dec5cec9c020cb20e9ced4c5d2cec5d4d52e2020f0cfc4cbccc0dec5cec9c520d0cf20cccfcbc1ccd8cecfca20d3c5d4c920d5d6c520cec1d3d4d2cfc5cecf20cec120c9d3d0cfccd8dacfd7c1cec9c52049502dc1c4d2c5d3c12c20cbcfd4cfd2d9ca20d2c1d3d0d2c5c4c5ccd1c5d4d3d120c1d7d4cfcdc1d4c9dec5d3cbc92e20),
('766', 0xeec520d5c4c1cccfd3d820cec1cad4c920d3c5d2d4c9c6c9cbc1d42e20f0cfc4cbccc0dec5cec9d1cd2c20cbcfd4cfd2d9c520c9d3d0cfccd8dad5c0d420dcd4cfd420d0d2cfd4cfcbcfcc204c32545020dec5d2c5da2049505365632c20d4d2c5c2d5c5d4d3d120d5d3d4c1cecfd7cbc120cec120cbcfcdd0d8c0d4c5d2c520d3c5d2d4c9c6c9cbc1d4c120cbcfcdd0d8c0d4c5d2c12e20),
('767', 0xeec520d5c4c1c5d4d3d120d2c1dad2c5dbc9d4d820cfc2ddc9ca20c4cfd3d4d5d020cb20d0cfc4cbccc0dec5cec9c020cb20e9ced4c5d2cec5d4d52e20f0cfc4cbccc0dec5cec9c520cccfcbc1ccd8cecfca20d3c5d4c92c20d7d9c2d2c1cececfca20d720cbc1dec5d3d4d7c520dec1d3d4cecfca2c20cec1d3d4d2cfc5cecf20cec120c9d3d0cfccd8dacfd7c1cec9c520c2cfccc5c520cfc4cecfc7cf2049502dc1c4d2c5d3c12e2020e9dacdc5cec9d4c520d0c1d2c1cdc5d4d2d920cec1d3d4d2cfcacbc920d0cfc4cbccc0dec5cec9d120cb20cccfcbc1ccd8cecfca20d3c5d4c92e20),
('768', 0xefdbc9c2cbc120dbc9c6d2cfd7c1cec9d120c4c1ceced9c820d0d2c920d0cfd0d9d4cbc520d0cfc4cbccc0dec5cec9d12e20),
('769', 0xf5cbc1dac1cececfc520cec1dacec1dec5cec9c520cec5c4cfd3d4c9d6c9cdcf2e20),
('770', 0xf5c4c1ccc5ceced9ca20cbcfcdd0d8c0d4c5d220cfd4d7c5d2c720d0cfd0d9d4cbc920d0cfc4cbccc0dec5cec9d12e20),
('771', 0xf0cfd0d9d4cbc120d0cfc4cbccc0dec9d4d8d3d120cec520d5c4c1ccc1d3d82c20d0cfd3cbcfccd8cbd520d3c5d4d820d0c5d2c5c7d2d5d6c5cec12e20),
('772', 0xe1d0d0c1d2c1d4d5d2c120d5c4c1ccc5cececfc7cf20cbcfcdd0d8c0d4c5d2c120cec5d3cfd7cdc5d3d4c9cdc120d320d4c9d0cfcd20dac1d0d2c1dbc9d7c1c5cdcfc7cf20d7d9dacfd7c12e20),
('773', 0xf0cfd0d9d4cbc120d0cfc4cbccc0dec9d4d8d3d120cec520d5c4c1ccc1d3d820c9da2ddac120c9dacdc5cec5cec9d120c1c4d2c5d3c120cec1dacec1dec5cec9d12e20),
('774', 0xf0cfd0d9d4cbc120d0cfc4cbccc0dec9d4d8d3d120cec520d5c4c1ccc1d3d8202020c9da2ddac120d7d2c5cdc5cececfca20cfdbc9c2cbc92e),
('775', 0xf0cfc4cbccc0dec5cec9c520c2d9cccf20c2cccfcbc9d2cfd7c1cecf20d5c4c1ccc5ceced9cd20cbcfcdd0d8c0d4c5d2cfcd2e20),
('776', 0xf0cfc4cbccc0dec9d4d8d3d120cec520d5c4c1cccfd3d82c20d0cfd3cbcfccd8cbd520d5c4c1ccc5ceced9ca20cbcfcdd0d8c0d4c5d220d7cfdbc5cc20d720d2c5d6c9cd203feec520c2c5d3d0cfcbcfc9d4d83f2e20),
('777', 0xf0cfd0d9d4cbc120d0cfc4cbccc0dec5cec9d120cec520d5c4c1ccc1d3d82c20d0cfd3cbcfccd8cbd520cec120d5c4c1ccc5cececfcd20cbcfcdd0d8c0d4c5d2c520cec520d2c1c2cfd4c1c5d420cdcfc4c5cd20c9ccc920c4d2d5c7cfc520d5d3d4d2cfcad3d4d7cf20d3d7d1dac92e20),
('778', 0xeec5d7cfdacdcfd6cecf20d0d2cfd7c5d2c9d4d820c9c4c5ced4c9dececfd3d4d820d3c5d2d7c5d2c12e20),
('779', 0xe4ccd120d7d9d0cfcccec5cec9d120c9d3c8cfc4d1ddc9c820dad7cfcecbcfd720d320d0cfcdcfddd8c020dcd4cfc7cf20d0cfc4cbccc0dec5cec9d120c9d3d0cfccd8dad5cad4c520d3cdc1d2d42dcbc1d2d4d52e),
('780', 0xf0d2cfc2cec1d120c6d5cecbc3c9d120cec5c4cfd0d5d3d4c9cdc120c4ccd120dcd4cfc7cf20d0cfc4cbccc0dec5cec9d12e20),
('781', 0xe4ccd120d0cfc4cbccc0dec5cec9d120d4d2c5c2d5c5d4d3d120d3c5d2d4c9c6c9cbc1d42c20c4c5cad3d4d7c9d4c5ccd8ced9ca20d3c5d2d4c9c6c9cbc1d420cec520cec1cac4c5ce2e20eec1d6cdc9d4c520cbcecfd0cbd5203fe4cfd0cfcccec9d4c5ccd8cecf3f20c9ccc920cfc2d2c1d4c9d4c5d3d820d720c3c5ced4d220d0cfc4c4c5d2d6cbc920dac120d0cfcdcfddd8c02c20d5cbc1dac1d720cecfcdc5d220cfdbc9c2cbc92e20),
('782', 0xefc2ddc9ca20c4cfd3d4d5d020cb20d0cfc4cbccc0dec5cec9c020e9ced4c5d2cec5d4c120284943532920c920c2d2c1cec4cdc1d5dcd220d0cfc4cbccc0dec5cec9d120cb20e9ced4c5d2cec5d4d520284943462920cec520cdcfc7d5d420c2d9d4d820d7cbccc0dec5ced92c20d4c1cb20cbc1cb20cec120dcd4cfcd20cbcfcdd0d8c0d4c5d2c520d7cbccc0dec5cec120d3ccd5d6c2c120cdc1d2dbd2d5d4c9dac1c3c9c920c920d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c12e20fed4cfc2d920d7cbccc0dec9d4d82049435320c9ccc9204943462c20d3cec1dec1ccc120cfd4cbccc0dec9d4c520d3ccd5d6c2d520cdc1d2dbd2d5d4c9dac1c3c9c920c920d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c12e20e4cfd0cfcccec9d4c5ccd8ced9c520d3d7c5c4c5cec9d120cf20d3ccd5d6c2c520cdc1d2dbd2d5d4c9dac1c3c9c920c920d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c12c2049435320c92049434620d3cd2e20d720c3c5ced4d2c520d3d0d2c1d7cbc920c920d0cfc4c4c5d2d6cbc92e20),
('783', 0xeec520d5c4c1c5d4d3d120d2c1dad2c5dbc9d4d820cfc2ddc9ca20c4cfd3d4d5d020cb20d0cfc4cbccc0dec5cec9c020cb20e9ced4c5d2cec5d4d52e20f0cfc4cbccc0dec5cec9c520cccfcbc1ccd8cecfca20d3c5d4c92c20d7d9c2d2c1cececfca20d720cbc1dec5d3d4d7c520dec1d3d4cecfca2c20ccc9c2cf20cec520d3d5ddc5d3d4d7d5c5d42c20ccc9c2cf20d2c1dacfd2d7c1cecf2e20f5c2c5c4c9d4c5d3d82c20ded4cf20d0cfc4cbccc0dec5ce20d3c5d4c5d7cfca20c1c4c1d0d4c5d22e2020),
('784', 0xeec5d7cfdacdcfd6cecf20c9d3d0cfccd8dacfd7c1d4d820dcd4cf20d0cfc4cbccc0dec5cec9c520d7cf20d7d2c5cdd120dac1c7d2d5dacbc92c20d0cfd3cbcfccd8cbd520cfcecf20c9d3d0cfccd8dad5c5d420c9cdd120d0cfccd8dacfd7c1d4c5ccd12c20cfd4ccc9dececfc520cfd420d0cfccd8dacfd7c1d4c5ccd120d3cdc1d2d42dcbc1d2d4d92e20e4ccd120c9d3d0cfccd8dacfd7c1cec9d120c5c7cf20d7cf20d7d2c5cdd120dac1c7d2d5dacbc920c9dacdc5cec9d4c520c9d3d0cfccd8dad5c5cdcfc520c9cdd120cec120c9cdd120d7ccc1c4c5ccd8c3c120d3cdc1d2d42dcbc1d2d4d92e),
('785', 0xeec5d7cfdacdcfd6cecf20c9d3d0cfccd8dacfd7c1d4d820dcd4cf20d0cfc4cbccc0dec5cec9c520d7cf20d7d2c5cdd120dac1c7d2d5dacbc92c20d0cfd3cbcfccd8cbd520cfcecf20cec1d3d4d2cfc5cecf20cec120c9d3d0cfccd8dacfd7c1cec9c520d3cdc1d2d42dcbc1d2d4d92e20e9dacdc5cec9d4c520d3d7cfcad3d4d7c120dcd4cfc7cf20d0cfc4cbccc0dec5cec9d12c20ded4cfc2d920c9d3d0cfccd8dacfd7c1ccc9d3d820c4c1ceced9c520d3cdc1d2d42dcbc1d2d4d92e),
('786', 0xf0cfd0d9d4cbc1204c3254502dd0cfc4cbccc0dec5cec9d120cec520d5c4c1ccc1d3d82c20d0cfd3cbcfccd8cbd520cfd4d3d5d4d3d4d7d5c5d420c4cfd0d5d3d4c9cdd9ca20d3c5d2d4c9c6c9cbc1d420cec120d7c1dbc5cd20cbcfcdd0d8c0d4c5d2c520c4ccd120d0d2cfd7c5d2cbc920d0cfc4ccc9cececfd3d4c92e20),
('787', 0xf0cfd0d9d4cbc1204c3254502dd0cfc4cbccc0dec5cec9d120cec520d5c4c1ccc1d3d82c20d0cfd3cbcfccd8cbd520cec520d5c4c1cccfd3d820d0d2cfd7c5d2c9d4d820d0cfc4ccc9cececfd3d4d820d5c4c1ccc5cececfc7cf20cbcfcdd0d8c0d4c5d2c120cec120d5d2cfd7cec520c2c5dacfd0c1d3cecfd3d4c92e20),
('788', 0xf0cfd0d9d4cbc1204c3254502dd0cfc4cbccc0dec5cec9d120cec520d5c4c1ccc1d3d82c20d0cfd3cbcfccd8cbd520cec120d5d2cfd7cec520c2c5dacfd0c1d3cecfd3d4c920cec520d5c4c1cccfd3d820d3cfc7ccc1d3cfd7c1d4d820d0c1d2c1cdc5d4d2d920d320d5c4c1ccc5ceced9cd20cbcfcdd0d8c0d4c5d2cfcd2e20),
('789', 0xf0cfd0d9d4cbc1204c3254502dd0cfc4cbccc0dec5cec9d120cec520d5c4c1ccc1d3d820c9da2ddac120cfdbc9c2cbc92c20d0d2cfc9dacfdbc5c4dbc5ca20cec120d5d2cfd7cec520c2c5dacfd0c1d3cecfd3d4c920d7cf20d7d2c5cdd120d3cfc7ccc1d3cfd7c1cec9ca20d320d5c4c1ccc5ceced9cd20cbcfcdd0d8c0d4c5d2cfcd2e20),
('790', 0xf0cfd0d9d4cbc1204c3254502dd0cfc4cbccc0dec5cec9d120cec520d5c4c1ccc1d3d820c9da2ddac120cfdbc9c2cbc920d0d2cfd7c5d2cbc920d3c5d2d4c9c6c9cbc1d4cfd72e20),
('791', 0xf0cfd0d9d4cbc1204c3254502dd0cfc4cbccc0dec5cec9d120cec520d5c4c1ccc1d3d82c20d0cfd3cbcfccd8cbd520cec520cec1cac4c5cec120d0cfccc9d4c9cbc120c2c5dacfd0c1d3cecfd3d4c92e20),
('792', 0xf0cfd0d9d4cbc1204c3254502dd0cfc4cbccc0dec5cec9d120cec520d5c4c1ccc1d3d82c20d0cfd3cbcfccd8cbd520c9d3d4c5cbcccf20d7d2c5cdd120d3cfc7ccc1d3cfd7c1cec9d120d2c5d6c9cdc120c2c5dacfd0c1d3cecfd3d4c92e20),
('793', 0xf0cfd0d9d4cbc1204c3254502dd0cfc4cbccc0dec5cec9d120cec520d5c4c1ccc1d3d820c9da2ddac120cfdbc9c2cbc920d3cfc7ccc1d3cfd7c1cec9d120d2c5d6c9cdc120c2c5dacfd0c1d3cecfd3d4c92e20),
('794', 0xf5d3d4c1cecfd7ccc5ceced9ca205241444955532dc1d4d2c9c2d5d4203febc1c4d2c9d2cfd7c1ceced9ca20d0d2cfd4cfcbcfcc3f20284672616d65642050726f746f636f6c2920c4ccd120dcd4cfc7cf20d0cfccd8dacfd7c1d4c5ccd120c9cdc5c5d420dacec1dec5cec9c520cec5205050502e20),
('795', 0xf5d3d4c1cecfd7ccc5ceced9ca205241444955532dc1d4d2c9c2d5d4203ff4c9d020d4d5cecec5ccd13f202854756e6e656c20547970652920c4ccd120dcd4cfc7cf20d0cfccd8dacfd7c1d4c5ccd120c9cdc5c5d420cec5cbcfd2d2c5cbd4cecfc520dacec1dec5cec9c52e20),
('796', 0xf5d3d4c1cecfd7ccc5ceced9ca205241444955532dc1d4d2c9c2d5d4203ff4c9d020d3ccd5d6c2d93f20285365727669636520547970652920c4ccd120dcd4cfc7cf20d0cfccd8dacfd7c1d4c5ccd120cec520c9cdc5c5d420dacec1dec5cec9d120cec9203febc1c4d2c9d2cfd7c1ceced9ca3f20284672616d6564292c20cec9203febc1c4d2c9d2cfd7c1ceced9ca20c4ccd120cfd4d7c5d4ced9c820d7d9dacfd7cfd73f202843616c6c6261636b204672616d6564292e20),
('797', 0xeec520d5c4c1ccc1d3d820d0cfc4cbccc0dec9d4d8d3d12c20d0cfd3cbcfccd8cbd520cdcfc4c5cd20cec520cec1cac4c5ce20c9ccc920dac1ced1d42e20eec1d6cdc9d4c520cbcecfd0cbd5203fe4cfd0cfcccec9d4c5ccd8cecf3f20c9ccc920cfc2d2c1d4c9d4c5d3d820d720c3c5ced4d220d0cfc4c4c5d2d6cbc920dac120d0cfcdcfddd8c02c20d5cbc1dac1d720cecfcdc5d220cfdbc9c2cbc92e20),
('798', 0xeec520d5c4c1cccfd3d820cec1cad4c920d3c5d2d4c9c6c9cbc1d42c20cbcfd4cfd2d9ca20c2d9cc20c2d920c9d3d0cfccd8dacfd7c1ce20d320d0d2cfd4cfcbcfcccfcd20d2c1d3dbc9d2c5cececfca20d0d2cfd7c5d2cbc920d0cfc4ccc9cececfd3d4c92028454150292e20),
('799', 0xeec520d5c4c1cccfd3d820d7cbccc0dec9d4d820cfc2ddc9ca20c4cfd3d4d5d020cb20d0cfc4cbccc0dec5cec9c020e9ced4c5d2cec5d4c120284943532920c9da2ddac120cbcfcec6ccc9cbd4c12049502dc1c4d2c5d3cfd720d720d3c5d4c92e2049435320d4d2c5c2d5c5d42c20ded4cfc2d920d5dac5cc20c2d9cc20cec1d3d4d2cfc5ce20cec120c9d3d0cfccd8dacfd7c1cec9c520c1c4d2c5d3c1203139322e3136382e302e312e20f5c2c5c4c9d4c5d3d82c20ded4cf20cec9cbc1cbcfca20c4d2d5c7cfca20cbccc9c5ced420d720d3c5d4c920cec520c9d3d0cfccd8dad5c5d420c1c4d2c5d3203139322e3136382e302e312e20),
('800', 0xeec520d5c4c1cccfd3d820d3cfdac4c1d4d82056504e2dd0cfc4cbccc0dec5cec9c52e202056504e2dd3c5d2d7c5d220cec5c4cfd3d4d5d0c5ce2c20c9ccc920d0c1d2c1cdc5d4d2d920c2c5dacfd0c1d3cecfd3d4c920c4ccd120c4c1cececfc7cf20d0cfc4cbccc0dec5cec9d120cec1d3d4d2cfc5ced920cec5d7c5d2cecf2e20),
('801', 0xe4c1cececfc520d0cfc4cbccc0dec5cec9c520cec1d3d4d2cfc5cecf20cec120d0d2cfd7c5d2cbd520d0cfc4cbccc0dec1c5cdcfc7cf20d3c5d2d7c5d2c12c20cfc4cec1cbcf20d3c9d3d4c5cdc52057696e646f777320cec520d5c4c1c5d4d3d120d0d2cfd7c5d2c9d4d820d0cfc4ccc9cececfd3d4d820c3c9c6d2cfd7cfc7cf20d3c5d2d4c9c6c9cbc1d4c12c20cfd4d0d2c1d7ccc5cececfc7cf20d3c5d2d7c5d2cfcd2e),
('802', 0xe9cdc5c0ddc1d1d3d120d0ccc1d4c120cec520d2c1d3d0cfdacec1cec12e20f0d2cfd7c5d2d8d4c52c20ded4cf20dcd4c120cbc1d2d4c120d7d3d4c1d7ccc5cec120d0d2c1d7c9ccd8cecf20c920d0cccfd4cecf20d3c9c4c9d420d720d2c1dadfc5cdc52e),
('803', 0xeec1d3d4d2cfcacbc120504541502c20c8d2c1ced1ddc1d1d3d120d720c6c1caccc5203f636f6f6b69653f20d3c5c1ced3c12c20cec520d3cfd7d0c1c4c1c5d420d320d4c5cbd5ddc5ca20cec1d3d4d2cfcacbcfca20d3c5c1ced3c12e),
('804', 0xf5c4cfd3d4cfd7c5d2c5cec9c520504541502c20c8d2c1ced1ddc5c5d3d120d720c6c1caccc5203f636f6f6b69653f20d3c5c1ced3c12c20cec520d3cfd7d0c1c4c1c5d420d320d4c5cbd5ddc9cd20d5c4cfd3d4cfd7c5d2c5cec9c5cd20d3c5c1ced3c12e),
('805', 0xeec5d7cfdacdcfd6cecf20d5d3d4c1cecfd7c9d4d820d5c4c1ccc5cececfc520d0cfc4cbccc0dec5cec9c520d7cf20d7d2c5cdd120d7c8cfc4c120d720d3c9d3d4c5cdd520d0cfd4cfcdd520ded4cf20cfcecf20c9d3d0cfccd8dad5c5d420d5dec5d4ced9c520c4c1ceced9c520d0cfccd8dacfd7c1d4c5ccd12e),
('900', 0xedc1d2dbd2d5d4c9dac1d4cfd220cec520d2c1c2cfd4c1c5d42e20),
('901', 0xe9ced4c5d2c6c5cad320d5d6c520d0cfc4cbccc0dec5ce2e20),
('902', 0xf5cbc1dac1ceced9ca20c9c4c5ced4c9c6c9cbc1d4cfd220d0d2cfd4cfcbcfccc120cec5c9dad7c5d3d4c5ce20cdc1d2dbd2d5d4c9dac1d4cfd2d52e20),
('903', 0xe4c9d3d0c5d4dec5d220c9ced4c5d2c6c5cad3c120d7d9dacfd7c120d0cf20d4d2c5c2cfd7c1cec9c020cec520dac1d0d5ddc5ce2e20),
('904', 0xe9ced4c5d2c6c5cad320d320d4c1cbc9cd20c9cdc5cec5cd20d5d6c520dac1d2c5c7c9d3d4d2c9d2cfd7c1ce20cec120cdc1d2dbd2d5d4c9dac1d4cfd2c52e20),
('905', 0xe9ced4c5d2c6c5cad320d320d4c1cbc9cd20c9cdc5cec5cd20cec520dac1d2c5c7c9d3d4d2c9d2cfd7c1ce20cec120cdc1d2dbd2d5d4c9dac1d4cfd2c52e20),
('906', 0xe9ced4c5d2c6c5cad320c5ddc520cec520d0cfc4cbccc0dec5ce2e20),
('907', 0xf2c1c2cfd4c120d320d5cbc1dac1ceced9cd20d0d2cfd4cfcbcfcccfcd20d0d2c9cfd3d4c1cec1d7ccc9d7c1c5d4d3d12e20),
('908', 0xe9ced4c5d2c6c5cad320d0cfc4cbccc0dec5ce2c20c920d0cfdcd4cfcdd520c5c7cf20cec5ccd8dad120d5c4c1ccc9d4d82e),
('909', 0xf5dec5d4ced9c520c4c1ceced9c520c9ced4c5d2c6c5cad3c120cec520c2d9ccc920d5d3d4c1cecfd7ccc5ced92e),
('910', 0xe9ced4c5d2c6c5cad320d5d6c520d0cfc4cbccc0dec1c5d4d3d12e20),
('911', 0xefc2cecfd7ccc5cec9c520c9cec6cfd2cdc1c3c9c920cdc1d2dbd2d5d4c9dac1c3c9c920cec120dcd4cfcd20c9ced4c5d2c6c5cad3c520d5d6c520d0d2cfc8cfc4c9d42e20),
('912', 0xeec5c4cfd0d5d3d4c9cdc1d120cbcfcec6c9c7d5d2c1c3c9d120c9ced4c5d2c6c5cad3c12e20f3d5ddc5d3d4d7d5c5d420c4d2d5c7cfca20c9ced4c5d2c6c5cad32c20d0cfc4cbccc0dec5ceced9ca20cb20d4cfcdd520d6c520c9ced4c5d2c6c5cad3d520cec120d5c4c1ccc5cececfcd20cdc1d2dbd2d5d4c9dac1d4cfd2c52e20),
('913', 0xebccc9c5ced420d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c120d0cfd0d9d4c1ccd3d120d0cfc4cbccc0dec9d4d8d3d120dec5d2c5da20d0cfd2d42c20dac1d2c5dac5d2d7c9d2cfd7c1ceced9ca20d4cfccd8cbcf20c4ccd120cdc1d2dbd2d5d4c9dac1d4cfd2cfd72e20),
('914', 0xedc1d2dbd2d5d4c9dac1d4cfd220d7d9dacfd7cfd720d0cf20d4d2c5c2cfd7c1cec9c020d0cfd0d9d4c1ccd3d120d0cfc4cbccc0dec9d4d8d3d120dec5d2c5da20d0cfd2d42c20cbcfd4cfd2d9ca20dac1d2c5dac5d2d7c9d2cfd7c1ce20d4cfccd8cbcf20c4ccd120cbccc9c5ced4cfd720d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c12e20),
('915', 0xebccc9c5ced4d3cbc9ca20c9ced4c5d2c6c5cad320d320dcd4c9cd20c9cdc5cec5cd20d5d6c520d3d5ddc5d3d4d7d5c5d420c920d720cec1d3d4cfd1ddc9ca20cdcfcdc5ced420d0cfc4cbccc0dec5ce2e20),
('916', 0xe9ced4c5d2c6c5cad320cec1c8cfc4c9d4d3d120d720cfd4cbccc0dec5cececfcd20d3cfd3d4cfd1cec9c92e20),
('917', 0xf0d2cfd4cfcbcfcc20d0d2cfd7c5d2cbc920d0cfc4ccc9cececfd3d4c920c2d9cc20cfd4d7c5d2c7ced5d420d5c4c1ccc5ceced9cd20d5dacccfcd2e20),
('918', 0xefd4d3d5d4d3d4d7d5c0d420c4cfd3d4d5d0ced9c520c4ccd120c9d3d0cfccd8dacfd7c1cec9d120d0d2cfd4cfcbcfccd920d0d2cfd7c5d2cbc920d0cfc4ccc9cececfd3d4c92e20),
('919', 0xf5c4c1ccc5ceced9ca20cbcfcdd0d8c0d4c5d220cfd4cbcccfcec9cc20d0d2c5c4cccfd6c5cec9c520d0d2cfd7c5d2cbc920d0cfc4ccc9cececfd3d4c92c20c9d3d0cfccd8dad5d120dcd4cfd420cec1d3d4d2cfc5ceced9ca20d0d2cfd4cfcbcfcc20d0d2cfd7c5d2cbc920d0cfc4ccc9cececfd3d4c92e20ecc9cec9d120c2d9ccc120cfd4cbccc0dec5cec12e20),
('920', 0xf5c4c1ccc5cecec1d120d5dec5d4cec1d120dac1d0c9d3d820cec520c9cdc5c5d420d0d2c1d720c4ccd120d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c12e20),
('921', 0xf3d2cfcb20c4c5cad3d4d7c9d120d5dec5d4cecfca20dac1d0c9d3c920d0cfccd8dacfd7c1d4c5ccd120c9d3d4c5cb2e20),
('922', 0xf5c4c1ccc5cecec1d120d5dec5d4cec1d120dac1d0c9d3d820cfd4cbccc0dec5cec12e20),
('923', 0xf7c8cfc420d720dcd4cf20d7d2c5cdd120c4ccd120c4c1cececfc7cf20d5c4c1ccc5cececfc7cf20d0cfccd8dacfd7c1d4c5ccd120cec520d2c1dad2c5dbc5ce2e20),
('924', 0xe4cfd3d4d5d020cb20d5c4c1ccc5cececfcdd520d5daccd520dac1d0d2c5ddc5ce2c20d0cfd3cbcfccd8cbd520c9cdd120d0cfccd8dacfd7c1d4c5ccd120c9ccc920d0c1d2cfccd820d1d7ccd1c0d4d3d120cec5c4cfd0d5d3d4c9cdd9cdc920c4ccd120dcd4cfc7cf20c4cfcdc5cec12e20),
('925', 0xefd4d3d5d4d3d4d7d5c0d420d0cfd2d4d92c20d2c1dad2c5dbc5ceced9c520c4ccd120cdc1d2dbd2d5d4c9dac1c3c9c920d320c9d3d0cfccd8dacfd7c1cec9c5cd20dcd4cfc7cf20c9ced4c5d2c6c5cad3c120d7d9dacfd7c120d0cf20d4d2c5c2cfd7c1cec9c02e20),
('926', 0xf0cfd2d420c2d9cc20cfd4cbccc0dec5ce20c1c4cdc9cec9d3d4d2c1d4cfd2cfcd20c9da2ddac120cfd4d3d5d4d3d4d7c9d120c1cbd4c9d7cecfd3d4c92e20),
('927', 0xe9ced4c5d2c6c5cad320d720c4c1ceced9ca20cdcfcdc5ced420cec5c4cfd3d4d5d0c5ce2e20),
('928', 0xf3ccd5d6c2c120d7d9dacfd7c120d0cf20d4d2c5c2cfd7c1cec9c020cec1c8cfc4c9d4d3d120d720d0d2c9cfd3d4c1cecfd7ccc5cececfcd20d3cfd3d4cfd1cec9c92e20),
('929', 0xe9ced4c5d2c6c5cad320c2d9cc20dac1d0d2c5ddc5ce20c1c4cdc9cec9d3d4d2c1d4cfd2cfcd2e20),
('930', 0xf3c5d2d7c5d220d0d2cfd7c5d2cbc920d0cfc4ccc9cececfd3d4c920cec520cfd4d7c5d4c9cc20cec120dac1d0d2cfd3d920cf20d0d2cfd7c5d2cbc520d0cfc4ccc9cececfd3d4c920d720cfd4d7c5c4c5cececfc520d7d2c5cdd12e20),
('931', 0xe4cfd3d4c9c7ced5d4cf20cdc1cbd3c9cdc1ccd8cecf20c4cfd0d5d3d4c9cdcfc520dec9d3cccf20d0cfd2d4cfd720c4ccd120c9d3d0cfccd8dacfd7c1cec9d120d720cdcecfc7cfcbc1cec1ccd8cecfcd20d0cfc4cbccc0dec5cec9c92e20),
('932', 0xe4cfd3d4c9c7ced5d420d0d2c5c4c5cc20d7d2c5cdc5cec920d0cfc4cbccc0dec5cec9d120c4ccd120dcd4cfc7cf20d0cfccd8dacfd7c1d4c5ccd12e20),
('933', 0xe4cfd3d4c9c7ced5d4cf20cdc1cbd3c9cdc1ccd8cecf20d7cfdacdcfd6cecfc520dec9d3cccf20d0cfc4c4c5d2d6c9d7c1c5cdd9c8204c414e2dc9ced4c5d2c6c5cad3cfd72e20),
('934', 0xe4cfd3d4c9c7ced5d4cf20cdc1cbd3c9cdc1ccd8cecf20d7cfdacdcfd6cecfc520dec9d3cccf20d0cfc4c4c5d2d6c9d7c1c5cdd9c820c9ced4c5d2c6c5cad3cfd720d7d9dacfd7c120d0cf20d4d2c5c2cfd7c1cec9c02e20),
('935', 0xe4cfd3d4c9c7ced5d4cf20cdc1cbd3c9cdc1ccd8cecf20d7cfdacdcfd6cecfc520dec9d3cccf20d0cfc4c4c5d2d6c9d7c1c5cdd9c820cbccc9c5ced4cfd720d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c12e20),
('936', 0xf0cfd2d420c2d9cc20cfd4cbccc0dec5ce20c9da2ddac120c4c5cad3d4d7c9d120d0cfccc9d4c9cbc92028424150292e20),
('937', 0xf7c8cfc4d1ddc9c520d0cfc4cbccc0dec5cec9d120cec520cdcfc7d5d420d0d2c9cec9cdc1d4d820d7c1dbc920dac1d0d2cfd3d920cec120d0cfc4cbccc0dec5cec9c52c20d0cfd3cbcfccd8cbd520c9d3d0cfccd8dad5c5d4d3d120c4d2d5c7cfc520d0cfc4cbccc0dec5cec9c520d4c1cbcfc7cf20d6c520d4c9d0c12e20),
('938', 0xf720dcd4cfca20d3c5d4c920cec5d4205241444955532dd3c5d2d7c5d2cfd72e20),
('939', 0xefd4205241444955532dd3c5d2d7c5d2c120d0d2cfd7c5d2cbc920d0cfc4ccc9cececfd3d4c920d0cfccd5dec5ce20cec5c4cfd0d5d3d4c9cdd9ca20cfd4cbccc9cb2e20f5c2c5c4c9d4c5d3d82c20ded4cf20d3c5cbd2c5d4ced9ca20d0c1d2cfccd82028d320d5dec5d4cfcd20d2c5c7c9d3d4d2c12920c4ccd1205241444955532dd3c5d2d7c5d2c120d5d3d4c1cecfd7ccc5ce20d0d2c1d7c9ccd8cecf2e20),
('940', 0xf520d7c1d320cec5d420d2c1dad2c5dbc5cec9d120cec120d0cfc4cbccc0dec5cec9c520d720dcd4cf20d7d2c5cdd12e20),
('941', 0xf520d7c1d320cec5d420d2c1dad2c5dbc5cec9d120cec120d0cfc4cbccc0dec5cec9c520d320c9d3d0cfccd8dacfd7c1cec9c5cd20d4c5cbd5ddc5c7cf20d4c9d0c120d5d3d4d2cfcad3d4d7c12e20),
('942', 0xf520d7c1d320cec5d420d2c1dad2c5dbc5cec9d120cec120d0cfc4cbccc0dec5cec9c520d320c9d3d0cfccd8dacfd7c1cec9c5cd20d7d9c2d2c1cececfc7cf20d0d2cfd4cfcbcfccc120d0d2cfd7c5d2cbc920d0cfc4ccc9cececfd3d4c92e20),
('943', 0xe4ccd120dcd4cfc7cf20d0cfccd8dacfd7c1d4c5ccd120d4d2c5c2d5c5d4d3d120d0d2cfd4cfcbcfcc204241502e20),
('944', 0xf720c4c1cececfc520d7d2c5cdd120cec5c4cfd0d5d3d4c9cdcf20d0cfc4cbccc0dec5cec9c520dcd4cfc7cf20c9ced4c5d2c6c5cad3c12e20),
('945', 0xf3cfc8d2c1cec5cecec1d120cbcfcec6c9c7d5d2c1c3c9d120cdc1d2dbd2d5d4c9dac1d4cfd2c120cec5d3cfd7cdc5d3d4c9cdc120d320d4c5cbd5ddc9cd20cdc1d2dbd2d5d4c9dac1d4cfd2cfcd2e20),
('946', 0xf3ccd5d6c2c120d5c4c1ccc5cececfc7cf20c4cfd3d4d5d0c120cfc2cec1d2d5d6c9ccc120d5d3d4c1d2c5d7dbc9ca20c6cfd2cdc1d420d5dec5d4ced9c820dac1d0c9d3c5ca20d0cfccd8dacfd7c1d4c5ccd12c20cbcfd4cfd2d9c520cec520c2d5c4d5d420cfc2cecfd7ccc5ced920c1d7d4cfcdc1d4c9dec5d3cbc92e2020e4ccd120cfc2cecfd7ccc5cec9d120d7d2d5deced5c020dac1d0d5d3d4c9d4c520585858582e20),
('948', 0xf4d2c1ced3d0cfd2d420d5d6c520d5d3d4c1cecfd7ccc5ce20cec120dcd4cfcd20cdc1d2dbd2d5d4c9dac1d4cfd2c52e20),
('949', 0xefd4205241444955532dd3c5d2d7c5d2c120d0cfccd5dec5cec120d0cfc4d0c9d3d820cec5c4cfd0d5d3d4c9cdcfca20c4ccc9ced92e20),
('950', 0xefd4205241444955532dd3c5d2d7c5d2c120d0cfccd5dec5ce20d0c1cbc5d420d320cec5c4cfd0d5d3d4c9cdcfca20d0cfc4d0c9d3d8c02e20),
('951', 0xefd4205241444955532dd3c5d2d7c5d2c120cec520d0cfccd5dec5cec120d0cfc4d0c9d3d820d7cdc5d3d4c520d3204541502dd3cfcfc2ddc5cec9c5cd2e20),
('952', 0xefd4205241444955532dd3c5d2d7c5d2c120d0cfccd5dec5ce20d0c1cbc5d420d320cec5c4cfd0d5d3d4c9cdcfca20c4ccc9cecfca20c9ccc920cbcfc4cfcd2e20),
('953', 0xefd4205241444955532dd3c5d2d7c5d2c120d0cfccd5dec5ce20d0c1cbc5d420d320c1d4d2c9c2d5d4cfcd20cec5c4cfd0d5d3d4c9cdcfca20c4ccc9ced92e20),
('954', 0xefd4205241444955532dd3c5d2d7c5d2c120d0cfccd5dec5ce20cec5c4cfd0d5d3d4c9cdd9ca20d0c1cbc5d42e20),
('955', 0xe1d5d4c5ced4c9cbc1d4cfd220cec520d3cfcfd4d7c5d4d3d4d7d5c5d420c1d5d4c5ced4c9cbc1d4cfd2d520cfd4205241444955532dd3c5d2d7c5d2c12e);

-- --------------------------------------------------------

--
-- Структура таблицы `holidays`
--

CREATE TABLE IF NOT EXISTS `holidays` (
  `holiday_date` char(5) NOT NULL DEFAULT '',
  `comment` char(64) NOT NULL,
  PRIMARY KEY (`holiday_date`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура таблицы `hotspot_free`
--

CREATE TABLE IF NOT EXISTS `hotspot_free` (
  `hsid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `date` datetime NOT NULL,
  `address` varchar(15) CHARACTER SET koi8r NOT NULL,
  `mac_address` varchar(17) CHARACTER SET koi8r NOT NULL,
  `host_name` varchar(64) CHARACTER SET koi8r NOT NULL,
  PRIMARY KEY (`hsid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8u COMMENT='Free HotSpot Stat' AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `hotspot_free_radacct`
--

CREATE TABLE IF NOT EXISTS `hotspot_free_radacct` (
  `radacctid` bigint(21) NOT NULL AUTO_INCREMENT,
  `acctsessionid` varchar(64) NOT NULL,
  `acctuniqueid` varchar(32) NOT NULL,
  `username` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `uid` bigint(16) unsigned DEFAULT NULL,
  `gid` smallint(5) unsigned DEFAULT NULL,
  `nasipaddress` varchar(15) NOT NULL,
  `nasportid` varchar(15) DEFAULT NULL,
  `acctstarttime` datetime DEFAULT NULL,
  `acctstoptime` datetime DEFAULT NULL,
  `acctsessiontime` int(12) DEFAULT NULL,
  `acctinputoctets` bigint(20) DEFAULT NULL,
  `acctoutputoctets` bigint(20) DEFAULT NULL,
  `calledstationid` varchar(50) NOT NULL,
  `callingstationid` varchar(50) NOT NULL,
  `acctterminatecause` varchar(32) NOT NULL,
  `framedipaddress` varchar(15) NOT NULL,
  `last_change` int(10) unsigned NOT NULL DEFAULT '0',
  `before_billing` double(20,6) NOT NULL,
  `billing_minus` double(20,6) NOT NULL,
  PRIMARY KEY (`radacctid`),
  KEY `acctsessionid` (`acctsessionid`),
  KEY `acctsessiontime` (`acctsessiontime`),
  KEY `acctstarttime` (`acctstarttime`),
  KEY `acctstoptime` (`acctstoptime`),
  KEY `acctuniqueid` (`acctuniqueid`),
  KEY `framedipaddress` (`framedipaddress`),
  KEY `framed-terminate` (`framedipaddress`,`acctterminatecause`),
  KEY `mrtggid` (`gid`,`acctterminatecause`),
  KEY `mrtguid` (`uid`,`acctterminatecause`),
  KEY `nasipaddress` (`nasipaddress`),
  KEY `Online_index` (`acctterminatecause`),
  KEY `ses-user-nas` (`acctsessionid`,`username`,`nasipaddress`),
  KEY `time_user` (`username`,`acctsessionid`,`acctsessiontime`,`acctstarttime`,`acctstoptime`),
  KEY `uid` (`uid`,`gid`),
  KEY `uniq-user-nas` (`acctuniqueid`,`username`,`nasipaddress`),
  KEY `user_uid` (`uid`),
  KEY `username` (`username`),
  KEY `user-start-time` (`username`,`acctstarttime`),
  FULLTEXT KEY `Acctterminatecause` (`acctterminatecause`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `hotspot_free_users`
--

CREATE TABLE IF NOT EXISTS `hotspot_free_users` (
  `user` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `password` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '*',
  `crypt_method` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `uid` bigint(16) unsigned NOT NULL AUTO_INCREMENT,
  `gid` int(5) unsigned NOT NULL DEFAULT '1',
  `deposit` double(20,6) NOT NULL DEFAULT '0.000000',
  `credit` double(20,2) NOT NULL DEFAULT '0.00',
  `fio` char(128) NOT NULL,
  `phone` char(128) NOT NULL,
  `address` char(128) NOT NULL,
  `prim` char(254) NOT NULL,
  `add_date` date NOT NULL DEFAULT '0000-00-00',
  `blocked` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `activated` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `expired` date NOT NULL DEFAULT '0000-00-00',
  `total_time` int(10) NOT NULL DEFAULT '0',
  `total_traffic` bigint(15) NOT NULL DEFAULT '0',
  `total_money` double(20,6) NOT NULL DEFAULT '0.000000',
  `last_connection` date NOT NULL DEFAULT '0000-00-00',
  `framed_ip` char(16) NOT NULL,
  `framed_mask` char(16) NOT NULL DEFAULT '255.255.255.255',
  `callback_number` char(64) NOT NULL,
  `local_ip` char(16) NOT NULL DEFAULT '10.0.',
  `local_mac` char(22) DEFAULT NULL,
  `sectorid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `create_mail` smallint(2) unsigned NOT NULL DEFAULT '1',
  `user_installed` smallint(2) unsigned NOT NULL DEFAULT '1',
  `speed_rate` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_burst` int(10) unsigned NOT NULL DEFAULT '0',
  `gidd` smallint(5) unsigned NOT NULL DEFAULT '0',
  `link_to_ip_mac` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `email` char(64) DEFAULT NULL,
  `passportserie` char(16) DEFAULT NULL,
  `passportpropiska` char(128) DEFAULT NULL,
  `passportvoenkomat` char(128) DEFAULT NULL,
  `passportgdevidan` char(128) DEFAULT NULL,
  `inn` char(64) DEFAULT NULL,
  `real_ip` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `real_price` double(20,6) NOT NULL DEFAULT '0.000000',
  `real_ipfree` tinyint(3) NOT NULL DEFAULT '0',
  `dogovor` tinyint(2) NOT NULL DEFAULT '0',
  `credit_procent` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `rating` smallint(6) NOT NULL DEFAULT '0',
  `mob_tel` char(32) DEFAULT NULL,
  `sms_tel` char(32) DEFAULT NULL,
  `date_birth` date DEFAULT '0000-00-00',
  `date_birth_do` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `languarddisable` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `credit_unlimited` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `dontshowspeed` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `numdogovor` char(16) DEFAULT NULL,
  `app` char(4) NOT NULL,
  `switchport` int(2) unsigned DEFAULT '0',
  `houseid` int(14) unsigned NOT NULL,
  `swid` int(10) unsigned DEFAULT '0',
  `use_router` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_model` char(16) NOT NULL,
  `router_login` char(16) NOT NULL,
  `router_pass` char(16) NOT NULL,
  `router_ssid` char(16) NOT NULL,
  `router_wep_pass` char(16) NOT NULL,
  `router_we_saled` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_use_dual` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_add_date` char(10) NOT NULL DEFAULT '00/00/0000',
  `router_serial` char(16) NOT NULL,
  `router_port` char(16) NOT NULL DEFAULT '8080',
  `credit_stop` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `date_abonka` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `mac_reg` tinyint(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  UNIQUE KEY `uname` (`user`),
  KEY `gid` (`gid`),
  KEY `gidd` (`gidd`),
  KEY `mrtgusname` (`user`,`uid`),
  KEY `sectorid` (`sectorid`),
  KEY `swid` (`swid`),
  KEY `swid-port` (`swid`,`switchport`),
  KEY `swport` (`switchport`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `inetonline`
--
CREATE TABLE IF NOT EXISTS `inetonline` (
`gid` smallint(5) unsigned
,`uid` bigint(16) unsigned
,`user` varchar(32)
,`port` varchar(15)
,`server` varchar(15)
,`ip` varchar(15)
,`call_from` varchar(50)
,`fstart_time` varchar(50)
,`time_on` int(12)
,`in_bytes` bigint(20)
,`out_bytes` bigint(20)
,`billing_minus` double(20,6)
);
-- --------------------------------------------------------

--
-- Дублирующая структура для представления `inetonlinenew`
--
CREATE TABLE IF NOT EXISTS `inetonlinenew` (
`radacctid` bigint(21)
,`acctsessionid` varchar(64)
,`acctuniqueid` varchar(32)
,`username` varchar(32)
,`uid` bigint(16) unsigned
,`gid` smallint(5) unsigned
,`nasipaddress` varchar(15)
,`nasportid` varchar(15)
,`acctstarttime` datetime
,`acctstoptime` datetime
,`acctsessiontime` int(12)
,`acctinputoctets` bigint(20)
,`acctoutputoctets` bigint(20)
,`calledstationid` varchar(50)
,`callingstationid` varchar(50)
,`acctterminatecause` varchar(32)
,`framedipaddress` varchar(15)
,`last_change` int(10) unsigned
,`before_billing` double(20,6)
,`billing_minus` double(20,6)
);
-- --------------------------------------------------------

--
-- Дублирующая структура для представления `inetonlinewithspeed`
--
CREATE TABLE IF NOT EXISTS `inetonlinewithspeed` (
`radacctid` bigint(21)
,`acctsessionid` varchar(64)
,`acctuniqueid` varchar(32)
,`username` varchar(32)
,`uid` bigint(16) unsigned
,`gid` smallint(5) unsigned
,`nasipaddress` varchar(15)
,`nasportid` varchar(15)
,`acctstarttime` datetime
,`acctstoptime` datetime
,`acctsessiontime` int(12)
,`acctinputoctets` bigint(20)
,`acctoutputoctets` bigint(20)
,`calledstationid` varchar(50)
,`callingstationid` varchar(50)
,`acctterminatecause` varchar(32)
,`framedipaddress` varchar(15)
,`last_change` int(10) unsigned
,`before_billing` double(20,6)
,`billing_minus` double(20,6)
,`user_speed_in` int(10) unsigned
,`user_speed_out` int(10) unsigned
,`use_radius_shaper` tinyint(2)
,`tarif_speed_in` int(10) unsigned
,`tarif_speed_out` int(10) unsigned
,`tarif_shaper_prio` tinyint(2) unsigned
);
-- --------------------------------------------------------

--
-- Дублирующая структура для представления `inetspeedlist`
--
CREATE TABLE IF NOT EXISTS `inetspeedlist` (
`username` varchar(32)
,`framedipaddress` char(16)
,`local_ip` char(16)
,`user_speed_in` int(10) unsigned
,`user_speed_out` int(10) unsigned
,`tarif_speed_in` int(10) unsigned
,`tarif_speed_out` int(10) unsigned
);
-- --------------------------------------------------------

--
-- Структура таблицы `ip_lease`
--

CREATE TABLE IF NOT EXISTS `ip_lease` (
  `ip` char(7) COLLATE koi8r_bin NOT NULL DEFAULT '0.0',
  PRIMARY KEY (`ip`),
  FULLTEXT KEY `ip` (`ip`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COLLATE=koi8r_bin;

-- --------------------------------------------------------

--
-- Структура таблицы `ip_pools`
--

CREATE TABLE IF NOT EXISTS `ip_pools` (
  `poolid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `poolname` char(128) NOT NULL,
  PRIMARY KEY (`poolid`),
  KEY `poolname` (`poolname`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=133 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `ip_pools`
--

INSERT INTO `ip_pools` (`poolid`, `poolname`) VALUES
(1, 'Без денег'),
(2, 'Main ip-Pool');

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `ip_pools_counts`
--
CREATE TABLE IF NOT EXISTS `ip_pools_counts` (
`poolname` char(128)
,`poolid` int(10) unsigned
,`ipfree` bigint(21)
,`ipuse` bigint(21)
);
-- --------------------------------------------------------

--
-- Структура таблицы `ip_pools_packets`
--

CREATE TABLE IF NOT EXISTS `ip_pools_packets` (
  `ippoolpacketid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `gid` int(10) unsigned NOT NULL,
  `poolid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`ippoolpacketid`),
  KEY `gid` (`gid`),
  KEY `gid-poolid` (`poolid`,`gid`),
  KEY `poolid` (`poolid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `ip_pools_pool`
--

CREATE TABLE IF NOT EXISTS `ip_pools_pool` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `poolip` char(15) NOT NULL DEFAULT '',
  `poolid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id` (`poolid`),
  KEY `ip` (`poolip`),
  KEY `ip-id` (`poolip`,`poolid`)
) ENGINE=InnoDB DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `ip_pools_pool_use`
--

CREATE TABLE IF NOT EXISTS `ip_pools_pool_use` (
  `poolip` char(15) NOT NULL DEFAULT '',
  `poolid` int(10) unsigned NOT NULL,
  `last_change` int(10) unsigned NOT NULL DEFAULT '0',
  `acctsessionid` varchar(64) DEFAULT NULL,
  `acctuniqueid` varchar(32) DEFAULT NULL,
  `uid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`poolip`),
  KEY `ip-uid-ses-uniq` (`poolip`,`uid`,`acctsessionid`,`acctuniqueid`),
  KEY `poolid` (`poolid`),
  KEY `time` (`last_change`),
  KEY `uid` (`uid`),
  KEY `uid-ip` (`poolip`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура таблицы `ip_real`
--

CREATE TABLE IF NOT EXISTS `ip_real` (
  `real` char(15) COLLATE koi8r_bin NOT NULL DEFAULT '',
  PRIMARY KEY (`real`),
  FULLTEXT KEY `ip` (`real`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COLLATE=koi8r_bin;

-- --------------------------------------------------------

--
-- Структура таблицы `lanes`
--

CREATE TABLE IF NOT EXISTS `lanes` (
  `laneid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `lane` char(64) NOT NULL,
  `settlementid` int(14) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`laneid`),
  UNIQUE KEY `id-lane` (`laneid`,`lane`),
  FULLTEXT KEY `lane` (`lane`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=73 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `lanes`
--

INSERT INTO `lanes` (`laneid`, `lane`, `settlementid`) VALUES
(1, 'Lane 1', 1),
(2, 'Lane 2', 1);

-- --------------------------------------------------------

--
-- Структура таблицы `lanes_houses`
--

CREATE TABLE IF NOT EXISTS `lanes_houses` (
  `houseid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `laneid` int(10) unsigned NOT NULL,
  `neighborhoodid` int(10) unsigned NOT NULL DEFAULT '1',
  `house` char(32) NOT NULL,
  `porches` int(2) unsigned NOT NULL DEFAULT '4',
  `floors` int(3) unsigned NOT NULL DEFAULT '5',
  PRIMARY KEY (`houseid`),
  UNIQUE KEY `laneid-houseid` (`laneid`,`houseid`),
  KEY `lane-house` (`laneid`,`house`),
  KEY `laneid` (`laneid`),
  FULLTEXT KEY `house` (`house`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=53 AUTO_INCREMENT=4 ;

--
-- Дамп данных таблицы `lanes_houses`
--

INSERT INTO `lanes_houses` (`houseid`, `laneid`, `neighborhoodid`, `house`, `porches`, `floors`) VALUES
(1, 1, 1, '1', 4, 5),
(2, 1, 1, '2', 4, 5),
(3, 1, 1, '3', 4, 5);

-- --------------------------------------------------------

--
-- Структура таблицы `lanes_houses_blocks`
--

CREATE TABLE IF NOT EXISTS `lanes_houses_blocks` (
  `houseblockid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `houseblockname` varchar(36) NOT NULL,
  `housingid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`houseblockid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `lanes_housings`
--

CREATE TABLE IF NOT EXISTS `lanes_housings` (
  `housingid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `housingname` varchar(36) NOT NULL,
  `houseid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`housingid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `lanes_neighborhoods`
--

CREATE TABLE IF NOT EXISTS `lanes_neighborhoods` (
  `neighborhoodid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `neighborhoodname` varchar(36) NOT NULL,
  `settlementid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`neighborhoodid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `lanes_settlements`
--

CREATE TABLE IF NOT EXISTS `lanes_settlements` (
  `settlementid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `settlementname` varchar(36) NOT NULL,
  PRIMARY KEY (`settlementid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `logs`
--

CREATE TABLE IF NOT EXISTS `logs` (
  `logid` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `stuffid` tinyint(6) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `logtypeid` int(7) unsigned NOT NULL,
  `uid` bigint(16) unsigned DEFAULT NULL,
  `gid` smallint(5) unsigned DEFAULT NULL,
  `ip` varchar(15) DEFAULT NULL,
  `valuename` varchar(64) NOT NULL,
  `oldvalue` varchar(64) DEFAULT NULL,
  `newvalue` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`logid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=66 AUTO_INCREMENT=49 ;

--
-- Дамп данных таблицы `logs`
--

INSERT INTO `logs` (`logid`, `stuffid`, `date`, `logtypeid`, `uid`, `gid`, `ip`, `valuename`, `oldvalue`, `newvalue`) VALUES
(1, 1, '2013-06-16 13:26:28', 1, 1, 1, '212.66.42.162', 'sectorid', '1', '2'),
(2, 1, '2013-06-16 13:26:37', 1, 1, 1, '212.66.42.162', 'password', '*', 'test22'),
(3, 1, '2013-06-16 13:29:04', 1, 1, 1, '212.66.42.162', 'switchport', '0', '1'),
(4, 1, '2013-06-16 13:29:04', 1, 1, 1, '212.66.42.162', 'swid', '0', '2'),
(5, 1, '2013-06-16 13:29:18', 1, 1, 1, '212.66.42.162', 'user', 'test', 'rb751'),
(6, 1, '2013-06-16 13:30:10', 1, 2, 2, '212.66.42.162', 'user', 'test2', 'rost-test'),
(7, 1, '2013-06-16 13:30:15', 1, 2, 2, '212.66.42.162', 'gid', '2', '1'),
(8, 1, '2013-06-17 12:25:42', 1, 1, 1, '212.66.42.162', 'local_mac', '', 'D4:CA:6D:29:C9:02'),
(9, 1, '2013-06-17 12:25:46', 1, 1, 1, '212.66.42.162', 'framed_ip', '172.16.124.2', '172.16.124.3'),
(10, 1, '2013-06-17 12:25:46', 1, 1, 1, '212.66.42.162', 'local_ip', '192.168.124.2', '192.168.124.3'),
(11, 1, '2013-06-17 20:44:37', 1, 3, 1, '212.66.42.162', 'ADD', '', ''),
(12, 1, '2013-06-17 20:44:42', 1, 3, 1, '212.66.42.162', 'local_mac', '', 'B8:A3:86:70:6E:2E'),
(13, 1, '2013-06-17 20:44:42', 1, 3, 1, '212.66.42.162', 'houseid', '0', '1'),
(14, 1, '2013-06-17 20:46:06', 1, 4, 1, '212.66.42.162', 'ADD', '', ''),
(15, 1, '2013-06-17 20:46:11', 1, 4, 1, '212.66.42.162', 'local_mac', '', '00:04:70:22:03:7E'),
(16, 1, '2013-06-17 20:46:11', 1, 4, 1, '212.66.42.162', 'houseid', '0', '1'),
(17, 1, '2013-06-18 14:59:02', 1, 3, 1, '212.66.42.162', 'local_mac', 'B8:A3:86:70:6E:2E', '00:13:77:BA:A9:4C'),
(18, 1, '2013-06-18 15:29:18', 1, 4, 1, '212.66.42.162', 'local_mac', '00:04:70:22:03:7E', '00:E0:91:13:9B:D6'),
(19, 1, '2013-06-18 17:07:21', 1, 5, 1, '212.66.42.162', 'ADD', '', ''),
(20, 1, '2013-06-18 17:07:26', 1, 5, 1, '212.66.42.162', 'local_mac', '', 'F8:D1:11:06:25:4C'),
(21, 1, '2013-06-18 17:07:26', 1, 5, 1, '212.66.42.162', 'houseid', '0', '1'),
(22, 1, '2013-07-17 18:22:04', 1, 5, 1, '91.214.48.31', 'Freeze', '', ''),
(23, 1, '2013-07-17 18:22:14', 2, NULL, 1, '91.214.48.31', 'CHECK DEL', 'NULL', 'NULL'),
(24, 1, '2013-07-17 18:22:14', 2, NULL, 2, '91.214.48.31', 'CHECK DEL', 'NULL', 'NULL'),
(25, 1, '2013-07-17 18:22:44', 1, 5, 1, '91.214.48.31', 'UNFREEZE', '1', '1'),
(26, 1, '2013-07-19 18:00:25', 1, 6, 2, '109.254.97.152', 'ADD USER', '', ''),
(27, 1, '2013-07-19 18:00:48', 1, 6, 2, '109.254.97.152', 'password', '123', '1231'),
(28, 1, '2013-07-19 18:01:30', 1, 6, 2, '109.254.97.152', 'Freeze', '', ''),
(29, 1, '2013-07-19 18:02:29', 11, NULL, NULL, '109.254.97.152', 'ADD STAFF', 'NULL', 'admin'),
(30, 1, '2013-07-19 18:02:33', 11, NULL, NULL, '109.254.97.152', 'ADD STAFF', 'NULL', 'admin'),
(31, 1, '2013-07-19 18:02:36', 11, NULL, NULL, '109.254.97.152', 'ADD STAFF', 'NULL', 'admin2'),
(32, 1, '2013-07-19 18:03:04', 11, 2, NULL, '109.254.97.152', 'active', '0', '1'),
(33, 1, '2013-07-19 18:03:04', 11, 2, NULL, '109.254.97.152', 'do_credit', '0', '1'),
(34, 1, '2013-07-19 18:03:04', 11, 2, NULL, '109.254.97.152', 'do_payment', '0', '1'),
(35, 1, '2013-07-19 18:03:04', 11, 2, NULL, '109.254.97.152', 'do_show_passwd', '0', '1'),
(36, 1, '2013-07-19 18:03:04', 11, 2, NULL, '109.254.97.152', 'do_minus_payments', '0', '1'),
(37, 1, '2013-07-19 18:03:04', 11, 2, NULL, '109.254.97.152', 'do_change_speed', '0', '1'),
(38, 1, '2013-07-19 18:03:04', 11, 2, NULL, '109.254.97.152', 'do_options', '0', '1'),
(39, 1, '2013-07-19 18:03:04', 11, 2, NULL, '109.254.97.152', 'do_change_tarif', '0', '1'),
(40, 1, '2013-07-19 18:03:04', 11, 2, NULL, '109.254.97.152', 'print_check', '0', '1'),
(41, 1, '2013-07-19 18:03:23', 11, 2, NULL, '109.254.97.152', 'dolgnostid', '1', '3'),
(42, 1, '2013-07-19 18:03:23', 11, 2, NULL, '109.254.97.152', 'ndogovora', '', '25555'),
(43, 1, '2013-07-19 18:03:32', 11, 2, NULL, '109.254.97.152', 'stavka', '0.00', '200'),
(44, 1, '2013-07-19 18:03:32', 11, 2, NULL, '109.254.97.152', 'chasi', '', '40'),
(45, 1, '2013-07-19 18:04:52', 1, 6, 2, '109.254.97.152', 'UNFREEZE', '2', '2'),
(46, 1, '2013-07-19 18:06:47', 1, 6, 2, '109.254.97.152', 'switchport', '0', '22'),
(47, 1, '2013-07-19 18:06:47', 1, 6, 2, '109.254.97.152', 'swid', '', '1'),
(48, 1, '2013-07-19 18:10:14', 1, 7, 2, '109.254.97.152', 'ADD USER', '', '');

-- --------------------------------------------------------

--
-- Структура таблицы `logtype`
--

CREATE TABLE IF NOT EXISTS `logtype` (
  `logtypeid` smallint(10) unsigned NOT NULL AUTO_INCREMENT,
  `logtype` char(32) NOT NULL,
  PRIMARY KEY (`logtypeid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=35 AUTO_INCREMENT=13 ;

--
-- Дамп данных таблицы `logtype`
--

INSERT INTO `logtype` (`logtypeid`, `logtype`) VALUES
(1, 'Абонент'),
(2, 'Тариф'),
(3, 'Карточки'),
(4, 'Товары'),
(5, 'Опции'),
(6, 'WhiteList'),
(7, 'NAS'),
(8, 'Действия'),
(9, 'Справочники'),
(10, 'Email рассылка'),
(11, 'Персонал'),
(12, 'Отчёты');

-- --------------------------------------------------------

--
-- Структура таблицы `map_criterions`
--

CREATE TABLE IF NOT EXISTS `map_criterions` (
  `criterionid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `criterionname` varchar(250) NOT NULL,
  `mapid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`criterionid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `map_maps`
--

CREATE TABLE IF NOT EXISTS `map_maps` (
  `mapid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `parentid` int(14) unsigned NOT NULL DEFAULT '0',
  `stuffid` int(14) unsigned NOT NULL,
  `mapname` varchar(36) NOT NULL,
  `width` int(11) unsigned NOT NULL DEFAULT '1000',
  `height` int(11) unsigned NOT NULL DEFAULT '1000',
  `px` int(11) unsigned NOT NULL DEFAULT '1',
  `m` int(11) unsigned NOT NULL DEFAULT '1',
  `background_visible` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `background_grayscale` tinyint(1) NOT NULL DEFAULT '0',
  `background_alpha` int(3) unsigned NOT NULL DEFAULT '50',
  `background_x` int(11) NOT NULL DEFAULT '0',
  `background_y` int(11) NOT NULL DEFAULT '0',
  `background_scale` int(11) unsigned NOT NULL DEFAULT '100',
  `google_map_visible` tinyint(1) NOT NULL DEFAULT '0',
  `google_map_grayscale` tinyint(1) NOT NULL DEFAULT '0',
  `google_map_alpha` int(3) NOT NULL DEFAULT '100',
  `google_map_type` tinyint(1) NOT NULL DEFAULT '2',
  `google_map_longitude_a` int(2) NOT NULL DEFAULT '0',
  `google_map_longitude_b` int(2) NOT NULL DEFAULT '0',
  `google_map_longitude_c` int(2) NOT NULL DEFAULT '0',
  `google_map_longitude_d` int(2) NOT NULL DEFAULT '0',
  `google_map_latitude_a` int(2) NOT NULL DEFAULT '0',
  `google_map_latitude_b` int(2) NOT NULL DEFAULT '0',
  `google_map_latitude_c` int(2) NOT NULL DEFAULT '0',
  `google_map_latitude_d` int(2) NOT NULL DEFAULT '0',
  `google_map_scale` float NOT NULL DEFAULT '0',
  `grid_visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `grid_alpha` int(3) unsigned NOT NULL DEFAULT '50',
  `grid_width` int(3) unsigned NOT NULL DEFAULT '100',
  `grid_height` int(3) unsigned NOT NULL DEFAULT '100',
  `grid_show_center` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `grid_color` varchar(8) NOT NULL DEFAULT '0x6495ED',
  `objects_layer_x` int(11) NOT NULL DEFAULT '0',
  `objects_layer_y` int(11) NOT NULL DEFAULT '0',
  `houses_visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `houses_labels_visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `houses_labels_name_visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `houses_labels_online_visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `houses_alpha` int(3) unsigned NOT NULL DEFAULT '100',
  `lines_visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `lines_alpha` int(3) unsigned NOT NULL DEFAULT '100',
  `cables_visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `cables_alpha` int(3) unsigned NOT NULL DEFAULT '100',
  `devices_visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `devices_labels_visible` tinyint(1) NOT NULL DEFAULT '1',
  `devices_alpha` int(3) unsigned NOT NULL DEFAULT '100',
  `wifis_visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `wifis_labels_visible` tinyint(1) NOT NULL DEFAULT '1',
  `wifis_cover_visible` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `wifis_alpha` int(3) unsigned NOT NULL DEFAULT '100',
  `serial` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`mapid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AUTO_INCREMENT=2 ;

--
-- Дамп данных таблицы `map_maps`
--

INSERT INTO `map_maps` (`mapid`, `parentid`, `stuffid`, `mapname`, `width`, `height`, `px`, `m`, `background_visible`, `background_grayscale`, `background_alpha`, `background_x`, `background_y`, `background_scale`, `google_map_visible`, `google_map_grayscale`, `google_map_alpha`, `google_map_type`, `google_map_longitude_a`, `google_map_longitude_b`, `google_map_longitude_c`, `google_map_longitude_d`, `google_map_latitude_a`, `google_map_latitude_b`, `google_map_latitude_c`, `google_map_latitude_d`, `google_map_scale`, `grid_visible`, `grid_alpha`, `grid_width`, `grid_height`, `grid_show_center`, `grid_color`, `objects_layer_x`, `objects_layer_y`, `houses_visible`, `houses_labels_visible`, `houses_labels_name_visible`, `houses_labels_online_visible`, `houses_alpha`, `lines_visible`, `lines_alpha`, `cables_visible`, `cables_alpha`, `devices_visible`, `devices_labels_visible`, `devices_alpha`, `wifis_visible`, `wifis_labels_visible`, `wifis_cover_visible`, `wifis_alpha`, `serial`) VALUES
(1, 0, 1, 'asdasd+', 0, 0, 1, 1, 0, 0, 50, 0, 0, 100, 0, 0, 100, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 50, 0, 0, 1, '6591981', 0, 0, 1, 1, 1, 1, 100, 1, 100, 1, 100, 1, 1, 100, 1, 1, 0, 100, '2013-07-19 16:00:22');

-- --------------------------------------------------------

--
-- Структура таблицы `map_maps_criterions`
--

CREATE TABLE IF NOT EXISTS `map_maps_criterions` (
  `mapcriterionid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `mapid` int(14) unsigned NOT NULL,
  `criterionid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`mapcriterionid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `map_maps_permissions`
--

CREATE TABLE IF NOT EXISTS `map_maps_permissions` (
  `mappermissionid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `permissionid` int(14) unsigned NOT NULL,
  `mapid` int(14) unsigned NOT NULL,
  `stuffid` int(14) unsigned NOT NULL,
  `issued` int(14) unsigned NOT NULL,
  PRIMARY KEY (`mappermissionid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `map_maps_permissions`
--

INSERT INTO `map_maps_permissions` (`mappermissionid`, `permissionid`, `mapid`, `stuffid`, `issued`) VALUES
(1, 1, 1, 1, 1),
(2, 2, 1, 1, 1);

-- --------------------------------------------------------

--
-- Структура таблицы `map_objects`
--

CREATE TABLE IF NOT EXISTS `map_objects` (
  `objectid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `mapid` int(14) unsigned NOT NULL,
  `typeid` tinyint(2) unsigned NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `objectname` varchar(32) NOT NULL,
  `description` varchar(256) NOT NULL,
  `serial` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`objectid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AUTO_INCREMENT=10 ;

--
-- Дамп данных таблицы `map_objects`
--

INSERT INTO `map_objects` (`objectid`, `mapid`, `typeid`, `x`, `y`, `objectname`, `description`, `serial`) VALUES
(1, 1, 2, -359, -288, '', '', '2013-07-19 15:52:33'),
(2, 1, 2, -233, -207, '', '', '2013-07-19 15:52:43'),
(3, 1, 2, -122, -261, '', '', '2013-07-19 15:52:53'),
(4, 1, 2, -86, -259, '', '', '2013-07-19 15:53:03'),
(5, 1, 2, 10, -258, '', '', '2013-07-19 15:53:18'),
(6, 1, 2, -233, -119, '', '', '2013-07-19 15:53:31'),
(7, 1, 2, -145, -57, '', '', '2013-07-19 15:53:40'),
(8, 1, 2, -18, -115, '', '', '2013-07-19 15:55:23'),
(9, 1, 2, 69, -34, '', '', '2013-07-19 15:55:31');

-- --------------------------------------------------------

--
-- Структура таблицы `map_objects_cables`
--

CREATE TABLE IF NOT EXISTS `map_objects_cables` (
  `objectcableid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `objectid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`objectcableid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `map_objects_criterions`
--

CREATE TABLE IF NOT EXISTS `map_objects_criterions` (
  `objectcriterionid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `objectid` int(14) unsigned NOT NULL,
  `criterionid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`objectcriterionid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `map_objects_devices`
--

CREATE TABLE IF NOT EXISTS `map_objects_devices` (
  `objectdeviceid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `swid` int(14) unsigned NOT NULL DEFAULT '0',
  `objectid` int(14) unsigned NOT NULL DEFAULT '0',
  `label_x` int(11) NOT NULL DEFAULT '0',
  `label_y` int(11) NOT NULL DEFAULT '0',
  `icontype` int(4) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`objectdeviceid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `map_objects_houses`
--

CREATE TABLE IF NOT EXISTS `map_objects_houses` (
  `objecthouseid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `houseid` int(14) unsigned NOT NULL DEFAULT '0',
  `objectid` int(14) unsigned NOT NULL,
  `label_x` int(14) NOT NULL DEFAULT '0',
  `label_y` int(14) NOT NULL DEFAULT '0',
  PRIMARY KEY (`objecthouseid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `map_objects_lines`
--

CREATE TABLE IF NOT EXISTS `map_objects_lines` (
  `objectlineid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `objectid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`objectlineid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AUTO_INCREMENT=10 ;

--
-- Дамп данных таблицы `map_objects_lines`
--

INSERT INTO `map_objects_lines` (`objectlineid`, `objectid`) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9);

-- --------------------------------------------------------

--
-- Структура таблицы `map_objects_types`
--

CREATE TABLE IF NOT EXISTS `map_objects_types` (
  `typeid` tinyint(2) unsigned NOT NULL AUTO_INCREMENT,
  `typename` varchar(36) NOT NULL,
  PRIMARY KEY (`typeid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=20 AUTO_INCREMENT=4 ;

--
-- Дамп данных таблицы `map_objects_types`
--

INSERT INTO `map_objects_types` (`typeid`, `typename`) VALUES
(1, 'house'),
(2, 'line'),
(3, 'cable');

-- --------------------------------------------------------

--
-- Структура таблицы `map_objects_wifis`
--

CREATE TABLE IF NOT EXISTS `map_objects_wifis` (
  `objectwifiid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `objectid` int(14) NOT NULL,
  `label_x` int(11) NOT NULL DEFAULT '0',
  `label_y` int(11) NOT NULL DEFAULT '0',
  `cover_radius` int(5) NOT NULL DEFAULT '300',
  `cover_degree` int(3) NOT NULL DEFAULT '45',
  `cover_rotation` int(3) NOT NULL DEFAULT '0',
  `cover_color` varchar(8) NOT NULL DEFAULT '0x0000FF',
  `icon_size` int(3) NOT NULL DEFAULT '100',
  `icon_color` varchar(8) NOT NULL DEFAULT '0x000000',
  PRIMARY KEY (`objectwifiid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `map_online`
--
CREATE TABLE IF NOT EXISTS `map_online` (
`radacctid` bigint(21)
,`acctsessionid` varchar(64)
,`acctuniqueid` varchar(32)
,`username` varchar(32)
,`uid` bigint(16) unsigned
,`gid` smallint(5) unsigned
,`nasipaddress` varchar(15)
,`nasportid` varchar(15)
,`acctstarttime` datetime
,`acctstoptime` datetime
,`acctsessiontime` int(12)
,`acctinputoctets` bigint(20)
,`acctoutputoctets` bigint(20)
,`calledstationid` varchar(50)
,`callingstationid` varchar(50)
,`acctterminatecause` varchar(32)
,`framedipaddress` varchar(15)
,`last_change` int(10) unsigned
,`before_billing` double(20,6)
,`billing_minus` double(20,6)
,`app` char(4)
,`swid` int(10) unsigned
,`switchport` int(2) unsigned
,`houseid` int(14) unsigned
,`user_speed_in` int(10) unsigned
,`user_speed_out` int(10) unsigned
,`use_radius_shaper` tinyint(2)
,`tarif_speed_in` int(10) unsigned
,`tarif_speed_out` int(10) unsigned
,`tarif_shaper_prio` tinyint(2) unsigned
);
-- --------------------------------------------------------

--
-- Структура таблицы `map_permissions_types`
--

CREATE TABLE IF NOT EXISTS `map_permissions_types` (
  `permissionid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `permissionname` varchar(45) NOT NULL,
  PRIMARY KEY (`permissionid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=20 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `map_permissions_types`
--

INSERT INTO `map_permissions_types` (`permissionid`, `permissionname`) VALUES
(1, 'map_view'),
(2, 'map_edit');

-- --------------------------------------------------------

--
-- Структура таблицы `map_points`
--

CREATE TABLE IF NOT EXISTS `map_points` (
  `pointid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `parentid` int(14) unsigned NOT NULL,
  `objectid` int(14) unsigned NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `serial` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`pointid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AUTO_INCREMENT=51 ;

--
-- Дамп данных таблицы `map_points`
--

INSERT INTO `map_points` (`pointid`, `parentid`, `objectid`, `x`, `y`, `serial`) VALUES
(1, 2, 1, 0, 0, '2013-07-19 15:52:34'),
(2, 3, 1, 32, 41, '2013-07-19 15:52:34'),
(3, 4, 1, 67, 4, '2013-07-19 15:52:34'),
(4, 0, 1, 6, 85, '2013-07-19 15:52:34'),
(5, 6, 2, 0, 0, '2013-07-19 15:52:43'),
(6, 7, 2, 1, -57, '2013-07-19 15:52:43'),
(7, 8, 2, 22, -30, '2013-07-19 15:52:43'),
(8, 9, 2, 47, -55, '2013-07-19 15:52:43'),
(9, 0, 2, 45, 0, '2013-07-19 15:52:43'),
(10, 11, 3, 0, 0, '2013-07-19 15:52:53'),
(11, 12, 3, -35, -2, '2013-07-19 15:52:53'),
(12, 13, 3, -34, 24, '2013-07-19 15:52:53'),
(13, 14, 3, -6, 26, '2013-07-19 15:52:53'),
(14, 15, 3, -35, 30, '2013-07-19 15:52:53'),
(15, 16, 3, -35, 48, '2013-07-19 15:52:53'),
(16, 0, 3, -6, 50, '2013-07-19 15:52:53'),
(17, 18, 4, 0, 0, '2013-07-19 15:53:03'),
(18, 19, 4, -4, 56, '2013-07-19 15:53:03'),
(19, 20, 4, 1, 24, '2013-07-19 15:53:03'),
(20, 21, 4, 23, 26, '2013-07-19 15:53:03'),
(21, 22, 4, 27, -4, '2013-07-19 15:53:03'),
(22, 0, 4, 25, 51, '2013-07-19 15:53:03'),
(23, 24, 5, -5, 50, '2013-07-19 15:53:22'),
(24, 25, 5, 3, -3, '2013-07-19 15:53:18'),
(25, 26, 5, -22, -4, '2013-07-19 15:53:19'),
(26, 27, 5, -27, 16, '2013-07-19 15:53:19'),
(27, 28, 5, -8, 22, '2013-07-19 15:53:19'),
(28, 0, 5, -30, 47, '2013-07-19 15:53:19'),
(29, 30, 6, 0, 0, '2013-07-19 15:53:31'),
(30, 31, 6, -4, 67, '2013-07-19 15:53:32'),
(31, 32, 6, -2, 29, '2013-07-19 15:53:32'),
(32, 33, 6, 34, 31, '2013-07-19 15:53:32'),
(33, 34, 6, 36, -6, '2013-07-19 15:53:32'),
(34, 0, 6, 30, 59, '2013-07-19 15:53:32'),
(35, 36, 7, 0, 0, '2013-07-19 15:53:40'),
(36, 37, 7, 5, -68, '2013-07-19 15:53:40'),
(37, 38, 7, 62, -64, '2013-07-19 15:53:40'),
(38, 39, 7, 55, 12, '2013-07-19 15:53:40'),
(39, 0, 7, 6, 3, '2013-07-19 15:53:40'),
(40, 41, 8, 0, 0, '2013-07-19 15:55:23'),
(41, 42, 8, -9, 64, '2013-07-19 15:55:23'),
(42, 43, 8, 4, -1, '2013-07-19 15:55:23'),
(43, 44, 8, 34, 1, '2013-07-19 15:55:24'),
(44, 45, 8, 37, 22, '2013-07-19 15:55:24'),
(45, 0, 8, -3, 26, '2013-07-19 15:55:24'),
(46, 47, 9, 0, 0, '2013-07-19 15:55:31'),
(47, 48, 9, 1, -83, '2013-07-19 15:55:31'),
(48, 49, 9, 26, -43, '2013-07-19 15:55:32'),
(49, 50, 9, 60, -83, '2013-07-19 15:55:32'),
(50, 0, 9, 53, -1, '2013-07-19 15:55:32');

-- --------------------------------------------------------

--
-- Структура таблицы `migratenodeny`
--

CREATE TABLE IF NOT EXISTS `migratenodeny` (
  `ip` varchar(15) NOT NULL,
  `user` varchar(32) NOT NULL,
  `password` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin DEFAULT NULL,
  `deposit` double(20,6) NOT NULL DEFAULT '0.000000',
  `credit` double(20,6) NOT NULL DEFAULT '0.000000',
  `gid` int(10) unsigned NOT NULL,
  `packet` varchar(64) DEFAULT NULL,
  `contract_date` date DEFAULT NULL,
  `fio` varchar(128) DEFAULT NULL,
  `numdogovor` varchar(16) DEFAULT NULL,
  `adress` varchar(64) DEFAULT NULL,
  `mac` varchar(32) DEFAULT NULL,
  `email` varchar(64) DEFAULT NULL,
  `prim` varchar(254) NOT NULL,
  `phone` varchar(128) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_cards_act_cards`
--

CREATE TABLE IF NOT EXISTS `mod_cards_act_cards` (
  `cardactid` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `serieid` int(10) unsigned NOT NULL,
  `secret` char(22) COLLATE koi8r_bin NOT NULL,
  `resellerid` int(14) unsigned NOT NULL DEFAULT '0',
  `status` enum('a','l','u') COLLATE koi8r_bin NOT NULL DEFAULT 'a',
  PRIMARY KEY (`cardactid`),
  UNIQUE KEY `secret` (`secret`),
  FULLTEXT KEY `cars-secret` (`secret`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COLLATE=koi8r_bin AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_cards_act_logs`
--

CREATE TABLE IF NOT EXISTS `mod_cards_act_logs` (
  `cardsactid` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `serieid` int(10) unsigned NOT NULL,
  `secret` char(22) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `ip` char(16) DEFAULT NULL,
  `mac` char(22) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `uid` bigint(16) unsigned NOT NULL,
  `gid` smallint(5) unsigned NOT NULL,
  `cardactid` int(20) unsigned NOT NULL,
  PRIMARY KEY (`cardsactid`),
  KEY `time` (`timestamp`),
  FULLTEXT KEY `secr` (`secret`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_cards_act_serie`
--

CREATE TABLE IF NOT EXISTS `mod_cards_act_serie` (
  `serieid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serie` char(5) COLLATE koi8r_bin NOT NULL,
  `gid` smallint(5) unsigned NOT NULL,
  `deposit` double(20,3) NOT NULL DEFAULT '0.000',
  `credit` double(20,3) NOT NULL DEFAULT '0.000',
  `added` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `expired` date NOT NULL DEFAULT '0000-00-00',
  `count` int(10) unsigned NOT NULL,
  `active` tinyint(2) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`serieid`),
  UNIQUE KEY `serie` (`serie`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COLLATE=koi8r_bin AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_cards_cards`
--

CREATE TABLE IF NOT EXISTS `mod_cards_cards` (
  `cards_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `series` char(4) NOT NULL DEFAULT '0',
  `added` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `nominal` double(8,2) NOT NULL DEFAULT '0.00',
  `expired` date NOT NULL DEFAULT '0000-00-00',
  `sn` char(20) NOT NULL DEFAULT '0',
  `resellerid` int(14) unsigned NOT NULL DEFAULT '0',
  `status` enum('a','l','u') NOT NULL DEFAULT 'a',
  PRIMARY KEY (`cards_id`),
  KEY `series` (`sn`,`series`),
  KEY `status` (`status`),
  FULLTEXT KEY `serial` (`sn`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_cards_errors`
--

CREATE TABLE IF NOT EXISTS `mod_cards_errors` (
  `when` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `who` char(255) NOT NULL,
  `what` char(255) NOT NULL,
  `resellerid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`when`),
  KEY `who` (`who`),
  FULLTEXT KEY `who2` (`who`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_cards_params`
--

CREATE TABLE IF NOT EXISTS `mod_cards_params` (
  `series` char(4) NOT NULL DEFAULT '',
  `sectorid` smallint(5) NOT NULL DEFAULT '0',
  `bonus` double(20,6) DEFAULT NULL,
  PRIMARY KEY (`series`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_cards_resellers`
--

CREATE TABLE IF NOT EXISTS `mod_cards_resellers` (
  `resellerid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `resellername` varchar(32) NOT NULL,
  `archived` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`resellerid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_trade_mobile_transactions`
--

CREATE TABLE IF NOT EXISTS `mod_trade_mobile_transactions` (
  `mbtr_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mob_tr_time` datetime NOT NULL,
  `vaucher` char(25) NOT NULL,
  `vaucher_price_in` double(20,6) unsigned DEFAULT NULL,
  `vaucher_price_out` double(20,6) unsigned DEFAULT NULL,
  `uid` bigint(16) NOT NULL,
  `tpmv_id` tinyint(10) unsigned NOT NULL,
  PRIMARY KEY (`mbtr_id`),
  UNIQUE KEY `vaucher` (`vaucher`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COMMENT='transactions' AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_trade_mobile_type`
--

CREATE TABLE IF NOT EXISTS `mod_trade_mobile_type` (
  `tpmv_id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `name_type` char(128) DEFAULT NULL,
  UNIQUE KEY `tpmv_id` (`tpmv_id`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COMMENT='mobile vaucher types' AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `mod_trade_mobile_vauchers`
--

CREATE TABLE IF NOT EXISTS `mod_trade_mobile_vauchers` (
  `vaucher` char(25) NOT NULL,
  `tpmv_id` smallint(6) unsigned DEFAULT NULL,
  `vaucher_price_in` double(20,6) NOT NULL,
  `vaucher_price_out` double(20,6) NOT NULL,
  UNIQUE KEY `vaucher` (`vaucher`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COMMENT='mobile vauchers table';

-- --------------------------------------------------------

--
-- Структура таблицы `notifications`
--

CREATE TABLE IF NOT EXISTS `notifications` (
  `notificationid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `text` varchar(600) NOT NULL,
  `startdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `enddate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `numofrepeats` int(4) NOT NULL DEFAULT '1',
  `showtime` int(3) NOT NULL DEFAULT '20',
  `gidsids` varchar(32) NOT NULL,
  `active` tinyint(1) unsigned NOT NULL,
  PRIMARY KEY (`notificationid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `packets`
--

CREATE TABLE IF NOT EXISTS `packets` (
  `num` char(5) NOT NULL DEFAULT '0',
  `packet` char(128) NOT NULL,
  `prefix` char(4) NOT NULL,
  `gid` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `tos` tinyint(1) NOT NULL DEFAULT '2',
  `do_with_tos` tinyint(1) NOT NULL DEFAULT '1',
  `direction` tinyint(1) NOT NULL DEFAULT '0',
  `fixed` tinyint(1) NOT NULL DEFAULT '0',
  `fixed_cost` double(20,6) NOT NULL DEFAULT '0.000000',
  `blocked` tinyint(1) NOT NULL DEFAULT '0',
  `simultaneous_use` smallint(5) NOT NULL DEFAULT '1',
  `port_limit` smallint(5) NOT NULL DEFAULT '1',
  `session_timeout` int(10) unsigned NOT NULL DEFAULT '86400',
  `idle_timeout` int(10) NOT NULL DEFAULT '30',
  `framed_ip` char(16) NOT NULL,
  `framed_mask` char(16) NOT NULL,
  `no_pass` tinyint(1) NOT NULL DEFAULT '0',
  `no_acct` tinyint(1) NOT NULL DEFAULT '0',
  `floor_traffic` tinyint(1) NOT NULL DEFAULT '0',
  `user_installed` smallint(2) NOT NULL DEFAULT '0',
  `speed_rate` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_burst` int(10) unsigned NOT NULL DEFAULT '0',
  `fixed_cost2` double(20,6) NOT NULL DEFAULT '0.000000',
  `do_block` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `shaper_prio` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `real_ip` tinyint(3) NOT NULL DEFAULT '0',
  `real_price` double(20,6) NOT NULL DEFAULT '0.000000',
  `credit_procent` double(20,6) unsigned NOT NULL DEFAULT '0.000000',
  `mk_limit_sh` smallint(2) unsigned NOT NULL DEFAULT '0',
  `mk_limit_sh_traf` int(10) unsigned DEFAULT '0',
  `limit_shaper_do` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `limit_start_gb` int(20) unsigned NOT NULL DEFAULT '0',
  `limit_speed_in` int(10) unsigned NOT NULL DEFAULT '0',
  `limit_speed_out` int(10) unsigned NOT NULL DEFAULT '0',
  `limit_speed_prio` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `do_shapers` tinyint(2) NOT NULL DEFAULT '0',
  `do_mik_rad_shapers` tinyint(2) NOT NULL DEFAULT '0',
  `do_ippool` tinyint(2) NOT NULL DEFAULT '0',
  `do_perevod_na_tarif` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_turbo` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_shapers_day_night` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `dop_do_interval2` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `dop_do_interval3` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `dop_interval1_time1` char(10) NOT NULL DEFAULT '0',
  `dop_interval1_time2` char(10) NOT NULL DEFAULT '0',
  `dop_interval1_speed_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval1_speed_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval1_prio` int(10) unsigned NOT NULL DEFAULT '1',
  `dop_interval1_burst_limit_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval1_burst_limit_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval1_burst_threshold_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval1_burst_threshold_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval1_burst_time_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval1_burst_time_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval2_time1` char(10) NOT NULL DEFAULT '0',
  `dop_interval2_time2` char(10) NOT NULL DEFAULT '0',
  `dop_interval2_speed_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval2_speed_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval2_prio` int(10) unsigned NOT NULL DEFAULT '1',
  `dop_interval2_burst_limit_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval2_burst_limit_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval2_burst_threshold_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval2_burst_threshold_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval2_burst_time_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval2_burst_time_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval3_time1` char(10) NOT NULL DEFAULT '0',
  `dop_interval3_time2` char(10) NOT NULL DEFAULT '0',
  `dop_interval3_speed_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval3_speed_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval3_prio` int(10) unsigned NOT NULL DEFAULT '1',
  `dop_interval3_burst_limit_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval3_burst_limit_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval3_burst_threshold_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval3_burst_threshold_in` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval3_burst_time_out` int(10) unsigned NOT NULL DEFAULT '0',
  `dop_interval3_burst_time_in` int(10) unsigned NOT NULL DEFAULT '0',
  `do_perevod_akciya` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_perevod_akciya_cena` double(20,6) unsigned NOT NULL DEFAULT '0.000000',
  `acct_interval` int(10) unsigned NOT NULL DEFAULT '300',
  `do_pipe_shapers` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_credit_vremen` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_credit_procent_vremen` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_cards` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_shop` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_perevod` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_change_pass` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_change_data` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `credit_active_cena` double(10,2) NOT NULL DEFAULT '0.00',
  `credit_procent_active_cena` double(10,2) NOT NULL DEFAULT '0.00',
  `turbo_active_cena` double(10,2) NOT NULL DEFAULT '0.00',
  `turbo_speed_in` int(10) unsigned NOT NULL DEFAULT '0',
  `turbo_speed_out` int(10) unsigned NOT NULL DEFAULT '0',
  `turbo_time` int(3) unsigned NOT NULL DEFAULT '24',
  `speed_mik_treshold_in` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_treshold_out` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_burst_in` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_burst_out` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_limit_treshold_in` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_limit_treshold_out` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_limit_burst_in` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_limit_burst_out` int(10) unsigned NOT NULL DEFAULT '0',
  `zapret_uhoda_s_tarifa` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `kabinet_do_freeze` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `cena_freeze` double(20,2) NOT NULL DEFAULT '0.00',
  `cena_unfreeze` double(20,2) NOT NULL DEFAULT '0.00',
  `cena_sutok_freeze` double(20,2) NOT NULL DEFAULT '0.00',
  `freeze_do_return_abonolata` tinyint(2) NOT NULL DEFAULT '0',
  `speed_mik_burst_time_in` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_burst_time_out` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_limit_burst_time_in` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_mik_limit_burst_time_out` int(10) unsigned NOT NULL DEFAULT '0',
  `min_sutok_freeze` int(10) unsigned NOT NULL DEFAULT '7',
  `cena_podklucheniya` double(20,2) NOT NULL DEFAULT '0.00',
  `cena_akt_otkl` double(20,2) NOT NULL DEFAULT '0.00',
  `cena_akt_del` double(20,2) NOT NULL DEFAULT '0.00',
  `enable_vkl_user` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `dont_show_speed` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_drweb` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `freeze_do_ever` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `count_free_freeze` tinyint(5) unsigned NOT NULL DEFAULT '0',
  `do_print_dogovor` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `world_shaper_do` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `world_speed_in` int(10) NOT NULL DEFAULT '0',
  `world_speed_out` int(10) NOT NULL DEFAULT '0',
  `world_speed_prio` int(10) NOT NULL DEFAULT '1',
  `world_speed_burst_in` int(10) NOT NULL DEFAULT '0',
  `world_speed_burst_out` int(10) NOT NULL DEFAULT '0',
  `world_speed_treshold_in` int(10) NOT NULL DEFAULT '0',
  `world_speed_treshold_out` int(10) NOT NULL DEFAULT '0',
  `world_speed_burst_time_in` int(10) NOT NULL DEFAULT '0',
  `world_speed_burst_time_out` int(10) NOT NULL DEFAULT '0',
  `do_credit_vozvrat_aktiv_cena` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_fixed_credit` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_fixed_credit_summa` double(20,2) unsigned NOT NULL DEFAULT '0.00',
  `do_credit_swing_date` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_credit_swing_date_days` int(10) unsigned NOT NULL DEFAULT '7',
  `numgroup` int(5) unsigned NOT NULL DEFAULT '0',
  `do_block_local` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `mikrotik_addr_list` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `do_addrlist` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_acct_interval` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `do_simple_shapers_mikrotik` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `do_session_time_out` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_mik_ip_pool` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `framed_ip_pool` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `do_idle_timeout_out` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `kabinet_do_freeze_balanse_plus` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_cards_auto` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_cards_auto_date` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`gid`),
  UNIQUE KEY `packet` (`packet`),
  KEY `num` (`num`),
  KEY `prefix` (`prefix`),
  FULLTEXT KEY `packetname` (`packet`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=80 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `packets`
--

INSERT INTO `packets` (`num`, `packet`, `prefix`, `gid`, `tos`, `do_with_tos`, `direction`, `fixed`, `fixed_cost`, `blocked`, `simultaneous_use`, `port_limit`, `session_timeout`, `idle_timeout`, `framed_ip`, `framed_mask`, `no_pass`, `no_acct`, `floor_traffic`, `user_installed`, `speed_rate`, `speed_burst`, `fixed_cost2`, `do_block`, `shaper_prio`, `real_ip`, `real_price`, `credit_procent`, `mk_limit_sh`, `mk_limit_sh_traf`, `limit_shaper_do`, `limit_start_gb`, `limit_speed_in`, `limit_speed_out`, `limit_speed_prio`, `do_shapers`, `do_mik_rad_shapers`, `do_ippool`, `do_perevod_na_tarif`, `do_turbo`, `do_shapers_day_night`, `dop_do_interval2`, `dop_do_interval3`, `dop_interval1_time1`, `dop_interval1_time2`, `dop_interval1_speed_out`, `dop_interval1_speed_in`, `dop_interval1_prio`, `dop_interval1_burst_limit_out`, `dop_interval1_burst_limit_in`, `dop_interval1_burst_threshold_out`, `dop_interval1_burst_threshold_in`, `dop_interval1_burst_time_out`, `dop_interval1_burst_time_in`, `dop_interval2_time1`, `dop_interval2_time2`, `dop_interval2_speed_out`, `dop_interval2_speed_in`, `dop_interval2_prio`, `dop_interval2_burst_limit_out`, `dop_interval2_burst_limit_in`, `dop_interval2_burst_threshold_out`, `dop_interval2_burst_threshold_in`, `dop_interval2_burst_time_out`, `dop_interval2_burst_time_in`, `dop_interval3_time1`, `dop_interval3_time2`, `dop_interval3_speed_out`, `dop_interval3_speed_in`, `dop_interval3_prio`, `dop_interval3_burst_limit_out`, `dop_interval3_burst_limit_in`, `dop_interval3_burst_threshold_out`, `dop_interval3_burst_threshold_in`, `dop_interval3_burst_time_out`, `dop_interval3_burst_time_in`, `do_perevod_akciya`, `do_perevod_akciya_cena`, `acct_interval`, `do_pipe_shapers`, `do_credit_vremen`, `do_credit_procent_vremen`, `use_cards`, `use_shop`, `use_perevod`, `use_change_pass`, `use_change_data`, `credit_active_cena`, `credit_procent_active_cena`, `turbo_active_cena`, `turbo_speed_in`, `turbo_speed_out`, `turbo_time`, `speed_mik_treshold_in`, `speed_mik_treshold_out`, `speed_mik_burst_in`, `speed_mik_burst_out`, `speed_mik_limit_treshold_in`, `speed_mik_limit_treshold_out`, `speed_mik_limit_burst_in`, `speed_mik_limit_burst_out`, `zapret_uhoda_s_tarifa`, `kabinet_do_freeze`, `cena_freeze`, `cena_unfreeze`, `cena_sutok_freeze`, `freeze_do_return_abonolata`, `speed_mik_burst_time_in`, `speed_mik_burst_time_out`, `speed_mik_limit_burst_time_in`, `speed_mik_limit_burst_time_out`, `min_sutok_freeze`, `cena_podklucheniya`, `cena_akt_otkl`, `cena_akt_del`, `enable_vkl_user`, `dont_show_speed`, `use_drweb`, `freeze_do_ever`, `count_free_freeze`, `do_print_dogovor`, `world_shaper_do`, `world_speed_in`, `world_speed_out`, `world_speed_prio`, `world_speed_burst_in`, `world_speed_burst_out`, `world_speed_treshold_in`, `world_speed_treshold_out`, `world_speed_burst_time_in`, `world_speed_burst_time_out`, `do_credit_vozvrat_aktiv_cena`, `do_fixed_credit`, `do_fixed_credit_summa`, `do_credit_swing_date`, `do_credit_swing_date_days`, `numgroup`, `do_block_local`, `mikrotik_addr_list`, `do_addrlist`, `do_acct_interval`, `do_simple_shapers_mikrotik`, `do_session_time_out`, `use_mik_ip_pool`, `framed_ip_pool`, `do_idle_timeout_out`, `kabinet_do_freeze_balanse_plus`, `use_cards_auto`, `use_cards_auto_date`) VALUES
('0', 'Tarif 1', '', 1, 2, 1, 0, 0, 0.000000, 0, 1, 1, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0.000000, 0, 0, 0, 0.000000, 0.000000, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '0', '0', 0, 0, 0, 0, 0, 0, 0, 0, 0, '0', '0', 0, 0, 0, 0, 0, 0, 0, 0, 0, '0', '0', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.000000, 300, 0, 0, 0, 0, 0, 0, 0, 0, 0.00, 0.00, 0.00, 0, 0, 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0, 0, 7, 0.00, 0.00, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, 7, 0, 0, '', 0, 1, 0, 0, 0, '', 0, 0, 0, 0),
('0', 'Tarif 2', '', 2, 2, 1, 0, 0, 0.000000, 0, 1, 1, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0.000000, 0, 0, 0, 0.000000, 0.000000, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '0', '0', 0, 0, 0, 0, 0, 0, 0, 0, 0, '0', '0', 0, 0, 0, 0, 0, 0, 0, 0, 0, '0', '0', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.000000, 300, 0, 0, 0, 0, 0, 0, 0, 0, 0.00, 0.00, 0.00, 0, 0, 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0, 0, 7, 0.00, 0.00, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, 7, 0, 0, '', 0, 1, 0, 0, 0, '', 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Структура таблицы `packetsnas`
--

CREATE TABLE IF NOT EXISTS `packetsnas` (
  `paknasid` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `gid` smallint(5) unsigned NOT NULL,
  `nasid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`paknasid`),
  KEY `gid` (`gid`),
  KEY `nas-gid` (`gid`,`nasid`),
  KEY `nasid` (`nasid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `preferences`
--

CREATE TABLE IF NOT EXISTS `preferences` (
  `preferenceid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `preferencename` varchar(128) NOT NULL,
  `programid` int(14) unsigned NOT NULL,
  `stuffid` int(14) unsigned NOT NULL,
  `value` varchar(256) NOT NULL,
  PRIMARY KEY (`preferenceid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=62 AUTO_INCREMENT=165 ;

--
-- Дамп данных таблицы `preferences`
--

INSERT INTO `preferences` (`preferenceid`, `preferencename`, `programid`, `stuffid`, `value`) VALUES
(164, 'auto_launch;StaffsReference', 4, 1, ''),
(162, 'auto_launch;StaffsReference', 4, 1, ''),
(161, 'IdentificationWindow_autoupdateBox_delay', 4, 1, '1'),
(160, 'OnlineWindow_autoupdateBox_delay', 4, 1, '1'),
(159, 'SearchWindow_autoupdateBox_delay', 4, 1, '1'),
(158, 'PaymentsReportWindow_autoupdateBox_delay', 4, 1, '1'),
(157, 'ReferencesWindow_2x_autoupdateBox_delay', 4, 1, '1'),
(156, 'SubscribersReportWindow_autoupdateBox_delay', 4, 1, '1'),
(154, 'selected_index', 4, 1, '4'),
(155, 'ClearPreferencesPopUpWindow_autoupdateBox_delay', 4, 1, '1');

-- --------------------------------------------------------

--
-- Структура таблицы `prices`
--

CREATE TABLE IF NOT EXISTS `prices` (
  `gid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `week_day` tinyint(1) NOT NULL DEFAULT '0',
  `h0` double(8,6) NOT NULL DEFAULT '0.000000',
  `input0` double(8,6) NOT NULL DEFAULT '0.000000',
  `output0` double(8,6) NOT NULL DEFAULT '0.000000',
  `h1` double(8,6) NOT NULL DEFAULT '0.000000',
  `input1` double(8,6) NOT NULL DEFAULT '0.000000',
  `output1` double(8,6) NOT NULL DEFAULT '0.000000',
  `h2` double(8,6) NOT NULL DEFAULT '0.000000',
  `input2` double(8,6) NOT NULL DEFAULT '0.000000',
  `output2` double(8,6) NOT NULL DEFAULT '0.000000',
  `h3` double(8,6) NOT NULL DEFAULT '0.000000',
  `input3` double(8,6) NOT NULL DEFAULT '0.000000',
  `output3` double(8,6) NOT NULL DEFAULT '0.000000',
  `h4` double(8,6) NOT NULL DEFAULT '0.000000',
  `input4` double(8,6) NOT NULL DEFAULT '0.000000',
  `output4` double(8,6) NOT NULL DEFAULT '0.000000',
  `h5` double(8,6) NOT NULL DEFAULT '0.000000',
  `input5` double(8,6) NOT NULL DEFAULT '0.000000',
  `output5` double(8,6) NOT NULL DEFAULT '0.000000',
  `h6` double(8,6) NOT NULL DEFAULT '0.000000',
  `input6` double(8,6) NOT NULL DEFAULT '0.000000',
  `output6` double(8,6) NOT NULL DEFAULT '0.000000',
  `h7` double(8,6) NOT NULL DEFAULT '0.000000',
  `input7` double(8,6) NOT NULL DEFAULT '0.000000',
  `output7` double(8,6) NOT NULL DEFAULT '0.000000',
  `h8` double(8,6) NOT NULL DEFAULT '0.000000',
  `input8` double(8,6) NOT NULL DEFAULT '0.000000',
  `output8` double(8,6) NOT NULL DEFAULT '0.000000',
  `h9` double(8,6) NOT NULL DEFAULT '0.000000',
  `input9` double(8,6) NOT NULL DEFAULT '0.000000',
  `output9` double(8,6) NOT NULL DEFAULT '0.000000',
  `h10` double(8,6) NOT NULL DEFAULT '0.000000',
  `input10` double(8,6) NOT NULL DEFAULT '0.000000',
  `output10` double(8,6) NOT NULL DEFAULT '0.000000',
  `h11` double(8,6) NOT NULL DEFAULT '0.000000',
  `input11` double(8,6) NOT NULL DEFAULT '0.000000',
  `output11` double(8,6) NOT NULL DEFAULT '0.000000',
  `h12` double(8,6) NOT NULL DEFAULT '0.000000',
  `input12` double(8,6) NOT NULL DEFAULT '0.000000',
  `output12` double(8,6) NOT NULL DEFAULT '0.000000',
  `h13` double(8,6) NOT NULL DEFAULT '0.000000',
  `input13` double(8,6) NOT NULL DEFAULT '0.000000',
  `output13` double(8,6) NOT NULL DEFAULT '0.000000',
  `h14` double(8,6) NOT NULL DEFAULT '0.000000',
  `input14` double(8,6) NOT NULL DEFAULT '0.000000',
  `output14` double(8,6) NOT NULL DEFAULT '0.000000',
  `h15` double(8,6) NOT NULL DEFAULT '0.000000',
  `input15` double(8,6) NOT NULL DEFAULT '0.000000',
  `output15` double(8,6) NOT NULL DEFAULT '0.000000',
  `h16` double(8,6) NOT NULL DEFAULT '0.000000',
  `input16` double(8,6) NOT NULL DEFAULT '0.000000',
  `output16` double(8,6) NOT NULL DEFAULT '0.000000',
  `h17` double(8,6) NOT NULL DEFAULT '0.000000',
  `input17` double(8,6) NOT NULL DEFAULT '0.000000',
  `output17` double(8,6) NOT NULL DEFAULT '0.000000',
  `h18` double(8,6) NOT NULL DEFAULT '0.000000',
  `input18` double(8,6) NOT NULL DEFAULT '0.000000',
  `output18` double(8,6) NOT NULL DEFAULT '0.000000',
  `h19` double(8,6) NOT NULL DEFAULT '0.000000',
  `input19` double(8,6) NOT NULL DEFAULT '0.000000',
  `output19` double(8,6) NOT NULL DEFAULT '0.000000',
  `h20` double(8,6) NOT NULL DEFAULT '0.000000',
  `input20` double(8,6) NOT NULL DEFAULT '0.000000',
  `output20` double(8,6) NOT NULL DEFAULT '0.000000',
  `h21` double(8,6) NOT NULL DEFAULT '0.000000',
  `input21` double(8,6) NOT NULL DEFAULT '0.000000',
  `output21` double(8,6) NOT NULL DEFAULT '0.000000',
  `h22` double(8,6) NOT NULL DEFAULT '0.000000',
  `input22` double(8,6) NOT NULL DEFAULT '0.000000',
  `output22` double(8,6) NOT NULL DEFAULT '0.000000',
  `h23` double(8,6) NOT NULL DEFAULT '0.000000',
  `input23` double(8,6) NOT NULL DEFAULT '0.000000',
  `output23` double(8,6) NOT NULL DEFAULT '0.000000',
  `floor` double NOT NULL DEFAULT '0',
  `floor_payments` double(8,6) NOT NULL DEFAULT '0.000000',
  KEY `gid` (`gid`),
  KEY `week` (`week_day`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура таблицы `programs`
--

CREATE TABLE IF NOT EXISTS `programs` (
  `programid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `programname` varchar(45) NOT NULL,
  `version` varchar(4) NOT NULL,
  `build` int(6) NOT NULL,
  PRIMARY KEY (`programid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=33 AUTO_INCREMENT=5 ;

--
-- Дамп данных таблицы `programs`
--

INSERT INTO `programs` (`programid`, `programname`, `version`, `build`) VALUES
(1, 'MikBill Admin', '2.0', 71111),
(2, 'MikBill Stat', '2.01', 71111),
(3, 'MikBill Monitor', '1.01', 71111),
(4, 'MikBill Ticket', '1.0', 71111);

-- --------------------------------------------------------

--
-- Структура таблицы `radacct`
--

CREATE TABLE IF NOT EXISTS `radacct` (
  `radacctid` bigint(21) NOT NULL AUTO_INCREMENT,
  `acctsessionid` varchar(64) NOT NULL,
  `acctuniqueid` varchar(32) NOT NULL,
  `username` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `uid` bigint(16) unsigned DEFAULT NULL,
  `gid` smallint(5) unsigned DEFAULT NULL,
  `nasipaddress` varchar(15) NOT NULL,
  `nasportid` varchar(15) DEFAULT NULL,
  `acctstarttime` datetime DEFAULT NULL,
  `acctstoptime` datetime DEFAULT NULL,
  `acctsessiontime` int(12) DEFAULT NULL,
  `acctinputoctets` bigint(20) DEFAULT NULL,
  `acctoutputoctets` bigint(20) DEFAULT NULL,
  `calledstationid` varchar(50) NOT NULL,
  `callingstationid` varchar(50) NOT NULL,
  `acctterminatecause` varchar(32) NOT NULL,
  `framedipaddress` varchar(15) NOT NULL,
  `last_change` int(10) unsigned NOT NULL DEFAULT '0',
  `before_billing` double(20,6) NOT NULL,
  `billing_minus` double(20,6) NOT NULL,
  PRIMARY KEY (`radacctid`),
  KEY `acctsessionid` (`acctsessionid`),
  KEY `acctsessiontime` (`acctsessiontime`),
  KEY `acctstarttime` (`acctstarttime`),
  KEY `acctstoptime` (`acctstoptime`),
  KEY `acctuniqueid` (`acctuniqueid`),
  KEY `framedipaddress` (`framedipaddress`),
  KEY `framed-terminate` (`framedipaddress`,`acctterminatecause`),
  KEY `mrtggid` (`gid`,`acctterminatecause`),
  KEY `mrtguid` (`uid`,`acctterminatecause`),
  KEY `nasipaddress` (`nasipaddress`),
  KEY `Online_index` (`acctterminatecause`),
  KEY `ses-user-nas` (`acctsessionid`,`username`,`nasipaddress`),
  KEY `time_user` (`username`,`acctsessionid`,`acctsessiontime`,`acctstarttime`,`acctstoptime`),
  KEY `uid` (`uid`,`gid`),
  KEY `uniq-user-nas` (`acctuniqueid`,`username`,`nasipaddress`),
  KEY `user_uid` (`uid`),
  KEY `username` (`username`),
  KEY `user-start-time` (`username`,`acctstarttime`),
  FULLTEXT KEY `Acctterminatecause` (`acctterminatecause`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `radacctterminatecause`
--

CREATE TABLE IF NOT EXISTS `radacctterminatecause` (
  `acctterminatecauseid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acctterminatecause` varchar(32) NOT NULL,
  PRIMARY KEY (`acctterminatecauseid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=22 AUTO_INCREMENT=13 ;

--
-- Дамп данных таблицы `radacctterminatecause`
--

INSERT INTO `radacctterminatecause` (`acctterminatecauseid`, `acctterminatecause`) VALUES
(1, 'Online'),
(2, 'User-Request'),
(3, 'Admin-Reboot'),
(4, 'Admin-Reset'),
(5, 'BILL-Request'),
(6, 'User-Error'),
(7, 'Lost-Carrier'),
(8, 'Lost-Service'),
(9, 'NAS-Error'),
(10, 'NAS-Request'),
(11, 'Port-Error'),
(12, 'Service-Unavailable');

-- --------------------------------------------------------

--
-- Структура таблицы `raddactnew`
--

CREATE TABLE IF NOT EXISTS `raddactnew` (
  `radacctid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `acctsessionid` varchar(32) NOT NULL,
  `acctuniqueid` bigint(20) NOT NULL,
  `username` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `uid` int(10) unsigned DEFAULT NULL,
  `gid` int(10) unsigned DEFAULT NULL,
  `nasid` int(10) unsigned NOT NULL,
  `nasportid` int(10) unsigned NOT NULL,
  `acctstarttime` timestamp NULL DEFAULT NULL,
  `acctstoptime` timestamp NULL DEFAULT NULL,
  `acctsessiontime` int(10) unsigned NOT NULL DEFAULT '0',
  `acctinputoctets` bigint(20) unsigned NOT NULL DEFAULT '0',
  `acctoutputoctets` bigint(20) unsigned NOT NULL DEFAULT '0',
  `calledstationid` varchar(16) NOT NULL,
  `callingstationid` varchar(17) NOT NULL,
  `acctterminatecauseid` int(10) unsigned NOT NULL,
  `framedipaddress` int(10) unsigned NOT NULL,
  `last_change` int(10) unsigned NOT NULL DEFAULT '0',
  `before_billing` double(20,6) NOT NULL,
  `billing_minus` double(20,6) NOT NULL,
  PRIMARY KEY (`radacctid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `radgroupcheck`
--

CREATE TABLE IF NOT EXISTS `radgroupcheck` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `groupname` char(64) NOT NULL,
  `attribute` char(64) NOT NULL,
  `op` char(2) NOT NULL DEFAULT '==',
  `value` char(253) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `groupname` (`groupname`(32))
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=388 AUTO_INCREMENT=2 ;

--
-- Дамп данных таблицы `radgroupcheck`
--

INSERT INTO `radgroupcheck` (`id`, `groupname`, `attribute`, `op`, `value`) VALUES
(1, 'system', 'Simultaneous-Use', ':=', '1');

-- --------------------------------------------------------

--
-- Структура таблицы `radgroupreply`
--

CREATE TABLE IF NOT EXISTS `radgroupreply` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `groupname` char(64) NOT NULL,
  `attribute` char(64) NOT NULL,
  `op` char(2) NOT NULL DEFAULT ':=',
  `value` char(253) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `groupname` (`groupname`(32))
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=388 AUTO_INCREMENT=10 ;

--
-- Дамп данных таблицы `radgroupreply`
--

INSERT INTO `radgroupreply` (`id`, `groupname`, `attribute`, `op`, `value`) VALUES
(6, 'system', 'Port-Limit', ':=', '1'),
(5, 'system', 'Framed-IP-Netmask', ':=', '255.255.255.255'),
(4, 'system', 'Framed-Protocol', ':=', 'PPP'),
(9, 'system', 'Framed-MTU', ':=', '1500'),
(2, 'system', 'Service-Type', ':=', 'Framed-User'),
(1, 'system', 'Framed-Protocol', ':=', 'PPP'),
(7, 'system', 'Acct-Interim-Interval', ':=', '300'),
(8, 'system', 'Framed-Compression', ':=', 'Van-Jacobson-TCP-IP');

-- --------------------------------------------------------

--
-- Структура таблицы `radnas`
--

CREATE TABLE IF NOT EXISTS `radnas` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `nasname` char(32) NOT NULL,
  `shortname` char(32) DEFAULT NULL,
  `type` char(30) DEFAULT 'other',
  `ports` int(5) DEFAULT NULL,
  `secret` char(32) NOT NULL DEFAULT 'secret',
  `community` char(50) DEFAULT NULL,
  `description` char(200) DEFAULT 'RADIUS Client',
  `nastype` char(32) NOT NULL DEFAULT 'mikrotik',
  `shapertype` int(3) NOT NULL DEFAULT '0',
  `impruport` char(5) DEFAULT '3799',
  `monitoring_nas_do` tinyint(2) NOT NULL DEFAULT '1',
  `world_iface` char(32) CHARACTER SET koi8r COLLATE koi8r_bin DEFAULT NULL,
  `country_iface` char(32) CHARACTER SET koi8r COLLATE koi8r_bin DEFAULT NULL,
  `use_wolrd` tinyint(2) NOT NULL DEFAULT '0',
  `use_country` tinyint(2) NOT NULL DEFAULT '0',
  `naslogin` char(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `naspass` char(32) NOT NULL,
  `usessh` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `macaslogin` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `calleridauth` tinyint(2) NOT NULL DEFAULT '0',
  `usepass` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `swid` int(10) unsigned NOT NULL DEFAULT '0',
  `vlan_control_do` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `ipauth` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `nasname` (`nasname`),
  FULLTEXT KEY `nasip` (`nasname`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=568 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `radnas`
--

INSERT INTO `radnas` (`id`, `nasname`, `shortname`, `type`, `ports`, `secret`, `community`, `description`, `nastype`, `shapertype`, `impruport`, `monitoring_nas_do`, `world_iface`, `country_iface`, `use_wolrd`, `use_country`, `naslogin`, `naspass`, `usessh`, `macaslogin`, `calleridauth`, `usepass`, `swid`, `vlan_control_do`, `ipauth`) VALUES
(1, 'localhost', 'localhost', 'other', NULL, 'testing123', NULL, 'RADIUS Client', 'pppd', 0, '3799', 0, '', '', 0, 0, '', '', 1, 0, 0, 1, 0, 0, 0),
(2, '10.10.22.1', 'NAS 1', 'other', NULL, 'testing123', NULL, 'Mikrotik 1', 'mikrotik', 2, '3799', 0, 'WORLD', '', 0, 0, 'bill', 'testing123', 1, 0, 0, 1, 0, 0, 0);

-- --------------------------------------------------------

--
-- Структура таблицы `radnaslog`
--

CREATE TABLE IF NOT EXISTS `radnaslog` (
  `naslogid` bigint(15) unsigned NOT NULL AUTO_INCREMENT,
  `time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `nasipaddress` char(15) NOT NULL,
  `acctstatustype` varchar(32) NOT NULL,
  `nasIdentifier` varchar(64) NOT NULL,
  PRIMARY KEY (`naslogid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `radpostauth`
--
CREATE TABLE IF NOT EXISTS `radpostauth` (
`id` int(10) unsigned
,`username` varchar(32)
,`pass` varchar(32)
,`packettype` varchar(64)
,`replymessage` varchar(64)
,`nasipaddress` char(32)
,`nasportid` int(10) unsigned
,`nasident` char(32)
,`callingstationid` varchar(64)
,`authdate` timestamp
);
-- --------------------------------------------------------

--
-- Структура таблицы `radpostauthnew`
--

CREATE TABLE IF NOT EXISTS `radpostauthnew` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(10) unsigned NOT NULL,
  `username` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `pass` varchar(32) NOT NULL,
  `packettypeid` int(10) unsigned NOT NULL,
  `replymessageid` int(10) unsigned NOT NULL,
  `nasid` int(10) unsigned NOT NULL,
  `nasportid` int(10) unsigned NOT NULL,
  `callingstationid` varchar(64) NOT NULL,
  `authdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `radpostauthpackettype`
--

CREATE TABLE IF NOT EXISTS `radpostauthpackettype` (
  `packettypeid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `packettype` varchar(64) NOT NULL,
  PRIMARY KEY (`packettypeid`)
) ENGINE=InnoDB  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=8192 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `radpostauthpackettype`
--

INSERT INTO `radpostauthpackettype` (`packettypeid`, `packettype`) VALUES
(1, 'Accept'),
(2, 'Reject');

-- --------------------------------------------------------

--
-- Структура таблицы `radpostauthreplymessage`
--

CREATE TABLE IF NOT EXISTS `radpostauthreplymessage` (
  `replymessageid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `replymessage` varchar(64) NOT NULL,
  PRIMARY KEY (`replymessageid`)
) ENGINE=InnoDB  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=682 AUTO_INCREMENT=25 ;

--
-- Дамп данных таблицы `radpostauthreplymessage`
--

INSERT INTO `radpostauthreplymessage` (`replymessageid`, `replymessage`) VALUES
(1, 'Успех'),
(2, 'Несовпадение'),
(3, 'PAP Успешный вход'),
(4, 'PAP Неправильный пароль'),
(5, 'CHAP Успешный вход'),
(6, 'CHAP Неправильный пароль'),
(7, 'Инетрент у него отключен'),
(8, 'В пул без денег'),
(9, 'У абонента отключена локальная сеть'),
(10, 'Не найден в базе данных вызывающий IP/MAC'),
(11, 'Пользователь в группе отключенных'),
(12, 'Пользователь в группе удаленных'),
(13, 'IP/MAC не совпадает с привязкой'),
(14, 'Нет средств и закончилися пул без денег'),
(15, 'У абонента недостаточно средств'),
(16, 'IP уже выдан другому пользователю'),
(17, 'IP не выдан'),
(18, 'результат неопределен'),
(19, 'Учетка уже в Online'),
(20, 'Дубликат IP в Pool'),
(21, 'IP не найден в пуле'),
(22, 'Учетная запись заблокирована'),
(23, 'Закончились деньги'),
(24, '2й раз не пустим');

-- --------------------------------------------------------

--
-- Структура таблицы `sectors`
--

CREATE TABLE IF NOT EXISTS `sectors` (
  `sectorid` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `sector` char(64) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `iface` char(10) NOT NULL,
  `classless_route` blob,
  `static_routes` blob,
  `mask` char(15) DEFAULT '255.255.255.0',
  `subnet` char(15) DEFAULT '',
  `broadcast` char(15) DEFAULT '',
  `dns_serv` char(15) DEFAULT '',
  `wins_serv` char(15) DEFAULT '',
  `netbios_dd_serv` char(15) DEFAULT '',
  `routers` char(15) DEFAULT '',
  `dns_serv2` char(15) DEFAULT '',
  `time_serv` char(15) DEFAULT '',
  `dhcp_ranges` char(200) NOT NULL,
  `shared_network1` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `shared_network2` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `shared_network3` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `vlanid` int(4) unsigned NOT NULL DEFAULT '1',
  `del_ip1` varchar(15) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '',
  `del_ip2` varchar(15) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '',
  `del_ip3` varchar(15) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '',
  `del_ip4` varchar(15) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '',
  UNIQUE KEY `sectorid` (`sectorid`),
  KEY `vlanid` (`vlanid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=168 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `sectors`
--

INSERT INTO `sectors` (`sectorid`, `sector`, `iface`, `classless_route`, `static_routes`, `mask`, `subnet`, `broadcast`, `dns_serv`, `wins_serv`, `netbios_dd_serv`, `routers`, `dns_serv2`, `time_serv`, `dhcp_ranges`, `shared_network1`, `shared_network2`, `shared_network3`, `vlanid`, `del_ip1`, `del_ip2`, `del_ip3`, `del_ip4`) VALUES
(1, '192.168.3.0', '124', '', '', '255.255.255.0', '192.168.3.0', '192.168.3.255', '192.168.3.2', '192.168.3.1', '192.168.3.1', '10.10.0.1', '8.8.8.8', '192.168.3.2', '', 0, 0, 0, 124, '', '', '', ''),
(2, '192.168.124.0', '124', '', '', '255.255.255.0', '192.168.124.0', '192.168.124.255', '192.168.3.2', '192.168.3.1', '192.168.3.1', '192.168.124.1', '8.8.8.8', '192.168.3.2', '', 0, 0, 0, 124, '', '', '', '');

-- --------------------------------------------------------

--
-- Структура таблицы `sectorspool`
--

CREATE TABLE IF NOT EXISTS `sectorspool` (
  `ip2long` bigint(64) NOT NULL,
  `ip` char(15) COLLATE koi8r_bin NOT NULL,
  `sectorid` smallint(5) unsigned NOT NULL,
  KEY `sectorid` (`sectorid`),
  KEY `sector-ip` (`sectorid`,`ip`),
  FULLTEXT KEY `ip-text` (`ip`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COLLATE=koi8r_bin AVG_ROW_LENGTH=26;

--
-- Дамп данных таблицы `sectorspool`
--

INSERT INTO `sectorspool` (`ip2long`, `ip`, `sectorid`) VALUES
(3232236293, '192.168.3.5', 1),
(3232236294, '192.168.3.6', 1),
(3232236295, '192.168.3.7', 1),
(3232236296, '192.168.3.8', 1),
(3232236297, '192.168.3.9', 1),
(3232236298, '192.168.3.10', 1),
(3232236299, '192.168.3.11', 1),
(3232236300, '192.168.3.12', 1),
(3232236301, '192.168.3.13', 1),
(3232236302, '192.168.3.14', 1),
(3232236303, '192.168.3.15', 1),
(3232236304, '192.168.3.16', 1),
(3232236305, '192.168.3.17', 1),
(3232236306, '192.168.3.18', 1),
(3232236307, '192.168.3.19', 1),
(3232236308, '192.168.3.20', 1),
(3232236309, '192.168.3.21', 1),
(3232236310, '192.168.3.22', 1),
(3232236311, '192.168.3.23', 1),
(3232236312, '192.168.3.24', 1),
(3232236313, '192.168.3.25', 1),
(3232236314, '192.168.3.26', 1),
(3232236315, '192.168.3.27', 1),
(3232236316, '192.168.3.28', 1),
(3232236317, '192.168.3.29', 1),
(3232236318, '192.168.3.30', 1),
(3232236319, '192.168.3.31', 1),
(3232236320, '192.168.3.32', 1),
(3232236321, '192.168.3.33', 1),
(3232236322, '192.168.3.34', 1),
(3232236323, '192.168.3.35', 1),
(3232236324, '192.168.3.36', 1),
(3232236325, '192.168.3.37', 1),
(3232236326, '192.168.3.38', 1),
(3232236327, '192.168.3.39', 1),
(3232236328, '192.168.3.40', 1),
(3232236329, '192.168.3.41', 1),
(3232236330, '192.168.3.42', 1),
(3232236331, '192.168.3.43', 1),
(3232236332, '192.168.3.44', 1),
(3232236333, '192.168.3.45', 1),
(3232236334, '192.168.3.46', 1),
(3232236335, '192.168.3.47', 1),
(3232236336, '192.168.3.48', 1),
(3232236337, '192.168.3.49', 1),
(3232236338, '192.168.3.50', 1),
(3232236339, '192.168.3.51', 1),
(3232236340, '192.168.3.52', 1),
(3232236341, '192.168.3.53', 1),
(3232236342, '192.168.3.54', 1),
(3232236343, '192.168.3.55', 1),
(3232236344, '192.168.3.56', 1),
(3232236345, '192.168.3.57', 1),
(3232236346, '192.168.3.58', 1),
(3232236347, '192.168.3.59', 1),
(3232236348, '192.168.3.60', 1),
(3232236349, '192.168.3.61', 1),
(3232236350, '192.168.3.62', 1),
(3232236351, '192.168.3.63', 1),
(3232236352, '192.168.3.64', 1),
(3232236353, '192.168.3.65', 1),
(3232236354, '192.168.3.66', 1),
(3232236355, '192.168.3.67', 1),
(3232236356, '192.168.3.68', 1),
(3232236357, '192.168.3.69', 1),
(3232236358, '192.168.3.70', 1),
(3232236359, '192.168.3.71', 1),
(3232236360, '192.168.3.72', 1),
(3232236361, '192.168.3.73', 1),
(3232236362, '192.168.3.74', 1),
(3232236363, '192.168.3.75', 1),
(3232236364, '192.168.3.76', 1),
(3232236365, '192.168.3.77', 1),
(3232236366, '192.168.3.78', 1),
(3232236367, '192.168.3.79', 1),
(3232236368, '192.168.3.80', 1),
(3232236369, '192.168.3.81', 1),
(3232236370, '192.168.3.82', 1),
(3232236371, '192.168.3.83', 1),
(3232236372, '192.168.3.84', 1),
(3232236373, '192.168.3.85', 1),
(3232236374, '192.168.3.86', 1),
(3232236375, '192.168.3.87', 1),
(3232236376, '192.168.3.88', 1),
(3232236377, '192.168.3.89', 1),
(3232236378, '192.168.3.90', 1),
(3232236379, '192.168.3.91', 1),
(3232236380, '192.168.3.92', 1),
(3232236381, '192.168.3.93', 1),
(3232236382, '192.168.3.94', 1),
(3232236383, '192.168.3.95', 1),
(3232236384, '192.168.3.96', 1),
(3232236385, '192.168.3.97', 1),
(3232236386, '192.168.3.98', 1),
(3232236387, '192.168.3.99', 1),
(3232236388, '192.168.3.100', 1),
(3232236389, '192.168.3.101', 1),
(3232236390, '192.168.3.102', 1),
(3232236391, '192.168.3.103', 1),
(3232236392, '192.168.3.104', 1),
(3232236393, '192.168.3.105', 1),
(3232236394, '192.168.3.106', 1),
(3232236395, '192.168.3.107', 1),
(3232236396, '192.168.3.108', 1),
(3232236397, '192.168.3.109', 1),
(3232236398, '192.168.3.110', 1),
(3232236399, '192.168.3.111', 1),
(3232236400, '192.168.3.112', 1),
(3232236401, '192.168.3.113', 1),
(3232236402, '192.168.3.114', 1),
(3232236403, '192.168.3.115', 1),
(3232236404, '192.168.3.116', 1),
(3232236405, '192.168.3.117', 1),
(3232236406, '192.168.3.118', 1),
(3232236407, '192.168.3.119', 1),
(3232236408, '192.168.3.120', 1),
(3232236409, '192.168.3.121', 1),
(3232236410, '192.168.3.122', 1),
(3232236411, '192.168.3.123', 1),
(3232236412, '192.168.3.124', 1),
(3232236413, '192.168.3.125', 1),
(3232236414, '192.168.3.126', 1),
(3232236415, '192.168.3.127', 1),
(3232236416, '192.168.3.128', 1),
(3232236417, '192.168.3.129', 1),
(3232236418, '192.168.3.130', 1),
(3232236419, '192.168.3.131', 1),
(3232236420, '192.168.3.132', 1),
(3232236421, '192.168.3.133', 1),
(3232236422, '192.168.3.134', 1),
(3232236423, '192.168.3.135', 1),
(3232236424, '192.168.3.136', 1),
(3232236425, '192.168.3.137', 1),
(3232236426, '192.168.3.138', 1),
(3232236427, '192.168.3.139', 1),
(3232236428, '192.168.3.140', 1),
(3232236429, '192.168.3.141', 1),
(3232236430, '192.168.3.142', 1),
(3232236431, '192.168.3.143', 1),
(3232236432, '192.168.3.144', 1),
(3232236433, '192.168.3.145', 1),
(3232236434, '192.168.3.146', 1),
(3232236435, '192.168.3.147', 1),
(3232236436, '192.168.3.148', 1),
(3232236437, '192.168.3.149', 1),
(3232236438, '192.168.3.150', 1),
(3232236439, '192.168.3.151', 1),
(3232236440, '192.168.3.152', 1),
(3232236441, '192.168.3.153', 1),
(3232236442, '192.168.3.154', 1),
(3232236443, '192.168.3.155', 1),
(3232236444, '192.168.3.156', 1),
(3232236445, '192.168.3.157', 1),
(3232236446, '192.168.3.158', 1),
(3232236447, '192.168.3.159', 1),
(3232236448, '192.168.3.160', 1),
(3232236449, '192.168.3.161', 1),
(3232236450, '192.168.3.162', 1),
(3232236451, '192.168.3.163', 1),
(3232236452, '192.168.3.164', 1),
(3232236453, '192.168.3.165', 1),
(3232236454, '192.168.3.166', 1),
(3232236455, '192.168.3.167', 1),
(3232236456, '192.168.3.168', 1),
(3232236457, '192.168.3.169', 1),
(3232236458, '192.168.3.170', 1),
(3232236459, '192.168.3.171', 1),
(3232236460, '192.168.3.172', 1),
(3232236461, '192.168.3.173', 1),
(3232236462, '192.168.3.174', 1),
(3232236463, '192.168.3.175', 1),
(3232236464, '192.168.3.176', 1),
(3232236465, '192.168.3.177', 1),
(3232236466, '192.168.3.178', 1),
(3232236467, '192.168.3.179', 1),
(3232236468, '192.168.3.180', 1),
(3232236469, '192.168.3.181', 1),
(3232236470, '192.168.3.182', 1),
(3232236471, '192.168.3.183', 1),
(3232236472, '192.168.3.184', 1),
(3232236473, '192.168.3.185', 1),
(3232236474, '192.168.3.186', 1),
(3232236475, '192.168.3.187', 1),
(3232236476, '192.168.3.188', 1),
(3232236477, '192.168.3.189', 1),
(3232236478, '192.168.3.190', 1),
(3232236479, '192.168.3.191', 1),
(3232236480, '192.168.3.192', 1),
(3232236481, '192.168.3.193', 1),
(3232236482, '192.168.3.194', 1),
(3232236483, '192.168.3.195', 1),
(3232236484, '192.168.3.196', 1),
(3232236485, '192.168.3.197', 1),
(3232236486, '192.168.3.198', 1),
(3232236487, '192.168.3.199', 1),
(3232236488, '192.168.3.200', 1),
(3232236489, '192.168.3.201', 1),
(3232236490, '192.168.3.202', 1),
(3232236491, '192.168.3.203', 1),
(3232236492, '192.168.3.204', 1),
(3232236493, '192.168.3.205', 1),
(3232236494, '192.168.3.206', 1),
(3232236495, '192.168.3.207', 1),
(3232236496, '192.168.3.208', 1),
(3232236497, '192.168.3.209', 1),
(3232236498, '192.168.3.210', 1),
(3232236499, '192.168.3.211', 1),
(3232236500, '192.168.3.212', 1),
(3232236501, '192.168.3.213', 1),
(3232236502, '192.168.3.214', 1),
(3232236503, '192.168.3.215', 1),
(3232236504, '192.168.3.216', 1),
(3232236505, '192.168.3.217', 1),
(3232236506, '192.168.3.218', 1),
(3232236507, '192.168.3.219', 1),
(3232236508, '192.168.3.220', 1),
(3232236509, '192.168.3.221', 1),
(3232236510, '192.168.3.222', 1),
(3232236511, '192.168.3.223', 1),
(3232236512, '192.168.3.224', 1),
(3232236513, '192.168.3.225', 1),
(3232236514, '192.168.3.226', 1),
(3232236515, '192.168.3.227', 1),
(3232236516, '192.168.3.228', 1),
(3232236517, '192.168.3.229', 1),
(3232236518, '192.168.3.230', 1),
(3232236519, '192.168.3.231', 1),
(3232236520, '192.168.3.232', 1),
(3232236521, '192.168.3.233', 1),
(3232236522, '192.168.3.234', 1),
(3232236523, '192.168.3.235', 1),
(3232236524, '192.168.3.236', 1),
(3232236525, '192.168.3.237', 1),
(3232236526, '192.168.3.238', 1),
(3232236527, '192.168.3.239', 1),
(3232236528, '192.168.3.240', 1),
(3232236529, '192.168.3.241', 1),
(3232236530, '192.168.3.242', 1),
(3232236531, '192.168.3.243', 1),
(3232236532, '192.168.3.244', 1),
(3232236533, '192.168.3.245', 1),
(3232236534, '192.168.3.246', 1),
(3232236535, '192.168.3.247', 1),
(3232236536, '192.168.3.248', 1),
(3232236537, '192.168.3.249', 1),
(3232236538, '192.168.3.250', 1),
(3232236539, '192.168.3.251', 1),
(3232236540, '192.168.3.252', 1),
(3232236541, '192.168.3.253', 1),
(3232236542, '192.168.3.254', 1),
(3232267271, '192.168.124.7', 2),
(3232267272, '192.168.124.8', 2),
(3232267273, '192.168.124.9', 2),
(3232267274, '192.168.124.10', 2),
(3232267275, '192.168.124.11', 2),
(3232267276, '192.168.124.12', 2),
(3232267277, '192.168.124.13', 2),
(3232267278, '192.168.124.14', 2),
(3232267279, '192.168.124.15', 2),
(3232267280, '192.168.124.16', 2),
(3232267281, '192.168.124.17', 2),
(3232267282, '192.168.124.18', 2),
(3232267283, '192.168.124.19', 2),
(3232267284, '192.168.124.20', 2),
(3232267285, '192.168.124.21', 2),
(3232267286, '192.168.124.22', 2),
(3232267287, '192.168.124.23', 2),
(3232267288, '192.168.124.24', 2),
(3232267289, '192.168.124.25', 2),
(3232267290, '192.168.124.26', 2),
(3232267291, '192.168.124.27', 2),
(3232267292, '192.168.124.28', 2),
(3232267293, '192.168.124.29', 2),
(3232267294, '192.168.124.30', 2),
(3232267295, '192.168.124.31', 2),
(3232267296, '192.168.124.32', 2),
(3232267297, '192.168.124.33', 2),
(3232267298, '192.168.124.34', 2),
(3232267299, '192.168.124.35', 2),
(3232267300, '192.168.124.36', 2),
(3232267301, '192.168.124.37', 2),
(3232267302, '192.168.124.38', 2),
(3232267303, '192.168.124.39', 2),
(3232267304, '192.168.124.40', 2),
(3232267305, '192.168.124.41', 2),
(3232267306, '192.168.124.42', 2),
(3232267307, '192.168.124.43', 2),
(3232267308, '192.168.124.44', 2),
(3232267309, '192.168.124.45', 2),
(3232267310, '192.168.124.46', 2),
(3232267311, '192.168.124.47', 2),
(3232267312, '192.168.124.48', 2),
(3232267313, '192.168.124.49', 2),
(3232267314, '192.168.124.50', 2),
(3232267315, '192.168.124.51', 2),
(3232267316, '192.168.124.52', 2),
(3232267317, '192.168.124.53', 2),
(3232267318, '192.168.124.54', 2),
(3232267319, '192.168.124.55', 2),
(3232267320, '192.168.124.56', 2),
(3232267321, '192.168.124.57', 2),
(3232267322, '192.168.124.58', 2),
(3232267323, '192.168.124.59', 2),
(3232267324, '192.168.124.60', 2),
(3232267325, '192.168.124.61', 2),
(3232267326, '192.168.124.62', 2),
(3232267327, '192.168.124.63', 2),
(3232267328, '192.168.124.64', 2),
(3232267329, '192.168.124.65', 2),
(3232267330, '192.168.124.66', 2),
(3232267331, '192.168.124.67', 2),
(3232267332, '192.168.124.68', 2),
(3232267333, '192.168.124.69', 2),
(3232267334, '192.168.124.70', 2),
(3232267335, '192.168.124.71', 2),
(3232267336, '192.168.124.72', 2),
(3232267337, '192.168.124.73', 2),
(3232267338, '192.168.124.74', 2),
(3232267339, '192.168.124.75', 2),
(3232267340, '192.168.124.76', 2),
(3232267341, '192.168.124.77', 2),
(3232267342, '192.168.124.78', 2),
(3232267343, '192.168.124.79', 2),
(3232267344, '192.168.124.80', 2),
(3232267345, '192.168.124.81', 2),
(3232267346, '192.168.124.82', 2),
(3232267347, '192.168.124.83', 2),
(3232267348, '192.168.124.84', 2),
(3232267349, '192.168.124.85', 2),
(3232267350, '192.168.124.86', 2),
(3232267351, '192.168.124.87', 2),
(3232267352, '192.168.124.88', 2),
(3232267353, '192.168.124.89', 2),
(3232267354, '192.168.124.90', 2),
(3232267355, '192.168.124.91', 2),
(3232267356, '192.168.124.92', 2),
(3232267357, '192.168.124.93', 2),
(3232267358, '192.168.124.94', 2),
(3232267359, '192.168.124.95', 2),
(3232267360, '192.168.124.96', 2),
(3232267361, '192.168.124.97', 2),
(3232267362, '192.168.124.98', 2),
(3232267363, '192.168.124.99', 2),
(3232267364, '192.168.124.100', 2),
(3232267365, '192.168.124.101', 2),
(3232267366, '192.168.124.102', 2),
(3232267367, '192.168.124.103', 2),
(3232267368, '192.168.124.104', 2),
(3232267369, '192.168.124.105', 2),
(3232267370, '192.168.124.106', 2),
(3232267371, '192.168.124.107', 2),
(3232267372, '192.168.124.108', 2),
(3232267373, '192.168.124.109', 2),
(3232267374, '192.168.124.110', 2),
(3232267375, '192.168.124.111', 2),
(3232267376, '192.168.124.112', 2),
(3232267377, '192.168.124.113', 2),
(3232267378, '192.168.124.114', 2),
(3232267379, '192.168.124.115', 2),
(3232267380, '192.168.124.116', 2),
(3232267381, '192.168.124.117', 2),
(3232267382, '192.168.124.118', 2),
(3232267383, '192.168.124.119', 2),
(3232267384, '192.168.124.120', 2),
(3232267385, '192.168.124.121', 2),
(3232267386, '192.168.124.122', 2),
(3232267387, '192.168.124.123', 2),
(3232267388, '192.168.124.124', 2),
(3232267389, '192.168.124.125', 2),
(3232267390, '192.168.124.126', 2),
(3232267391, '192.168.124.127', 2),
(3232267392, '192.168.124.128', 2),
(3232267393, '192.168.124.129', 2),
(3232267394, '192.168.124.130', 2),
(3232267395, '192.168.124.131', 2),
(3232267396, '192.168.124.132', 2),
(3232267397, '192.168.124.133', 2),
(3232267398, '192.168.124.134', 2),
(3232267399, '192.168.124.135', 2),
(3232267400, '192.168.124.136', 2),
(3232267401, '192.168.124.137', 2),
(3232267402, '192.168.124.138', 2),
(3232267403, '192.168.124.139', 2),
(3232267404, '192.168.124.140', 2),
(3232267405, '192.168.124.141', 2),
(3232267406, '192.168.124.142', 2),
(3232267407, '192.168.124.143', 2),
(3232267408, '192.168.124.144', 2),
(3232267409, '192.168.124.145', 2),
(3232267410, '192.168.124.146', 2),
(3232267411, '192.168.124.147', 2),
(3232267412, '192.168.124.148', 2),
(3232267413, '192.168.124.149', 2),
(3232267414, '192.168.124.150', 2),
(3232267415, '192.168.124.151', 2),
(3232267416, '192.168.124.152', 2),
(3232267417, '192.168.124.153', 2),
(3232267418, '192.168.124.154', 2),
(3232267419, '192.168.124.155', 2),
(3232267420, '192.168.124.156', 2),
(3232267421, '192.168.124.157', 2),
(3232267422, '192.168.124.158', 2),
(3232267423, '192.168.124.159', 2),
(3232267424, '192.168.124.160', 2),
(3232267425, '192.168.124.161', 2),
(3232267426, '192.168.124.162', 2),
(3232267427, '192.168.124.163', 2),
(3232267428, '192.168.124.164', 2),
(3232267429, '192.168.124.165', 2),
(3232267430, '192.168.124.166', 2),
(3232267431, '192.168.124.167', 2),
(3232267432, '192.168.124.168', 2),
(3232267433, '192.168.124.169', 2),
(3232267434, '192.168.124.170', 2),
(3232267435, '192.168.124.171', 2),
(3232267436, '192.168.124.172', 2),
(3232267437, '192.168.124.173', 2),
(3232267438, '192.168.124.174', 2),
(3232267439, '192.168.124.175', 2),
(3232267440, '192.168.124.176', 2),
(3232267441, '192.168.124.177', 2),
(3232267442, '192.168.124.178', 2),
(3232267443, '192.168.124.179', 2),
(3232267444, '192.168.124.180', 2),
(3232267445, '192.168.124.181', 2),
(3232267446, '192.168.124.182', 2),
(3232267447, '192.168.124.183', 2),
(3232267448, '192.168.124.184', 2),
(3232267449, '192.168.124.185', 2),
(3232267450, '192.168.124.186', 2),
(3232267451, '192.168.124.187', 2),
(3232267452, '192.168.124.188', 2),
(3232267453, '192.168.124.189', 2),
(3232267454, '192.168.124.190', 2),
(3232267455, '192.168.124.191', 2),
(3232267456, '192.168.124.192', 2),
(3232267457, '192.168.124.193', 2),
(3232267458, '192.168.124.194', 2),
(3232267459, '192.168.124.195', 2),
(3232267460, '192.168.124.196', 2),
(3232267461, '192.168.124.197', 2),
(3232267462, '192.168.124.198', 2),
(3232267463, '192.168.124.199', 2),
(3232267464, '192.168.124.200', 2),
(3232267465, '192.168.124.201', 2),
(3232267466, '192.168.124.202', 2),
(3232267467, '192.168.124.203', 2),
(3232267468, '192.168.124.204', 2),
(3232267469, '192.168.124.205', 2),
(3232267470, '192.168.124.206', 2),
(3232267471, '192.168.124.207', 2),
(3232267472, '192.168.124.208', 2),
(3232267473, '192.168.124.209', 2),
(3232267474, '192.168.124.210', 2),
(3232267475, '192.168.124.211', 2),
(3232267476, '192.168.124.212', 2),
(3232267477, '192.168.124.213', 2),
(3232267478, '192.168.124.214', 2),
(3232267479, '192.168.124.215', 2),
(3232267480, '192.168.124.216', 2),
(3232267481, '192.168.124.217', 2),
(3232267482, '192.168.124.218', 2),
(3232267483, '192.168.124.219', 2),
(3232267484, '192.168.124.220', 2),
(3232267485, '192.168.124.221', 2),
(3232267486, '192.168.124.222', 2),
(3232267487, '192.168.124.223', 2),
(3232267488, '192.168.124.224', 2),
(3232267489, '192.168.124.225', 2),
(3232267490, '192.168.124.226', 2),
(3232267491, '192.168.124.227', 2),
(3232267492, '192.168.124.228', 2),
(3232267493, '192.168.124.229', 2),
(3232267494, '192.168.124.230', 2),
(3232267495, '192.168.124.231', 2),
(3232267496, '192.168.124.232', 2),
(3232267497, '192.168.124.233', 2),
(3232267498, '192.168.124.234', 2),
(3232267499, '192.168.124.235', 2),
(3232267500, '192.168.124.236', 2),
(3232267501, '192.168.124.237', 2),
(3232267502, '192.168.124.238', 2),
(3232267503, '192.168.124.239', 2),
(3232267504, '192.168.124.240', 2),
(3232267505, '192.168.124.241', 2),
(3232267506, '192.168.124.242', 2),
(3232267507, '192.168.124.243', 2),
(3232267508, '192.168.124.244', 2),
(3232267509, '192.168.124.245', 2),
(3232267510, '192.168.124.246', 2),
(3232267511, '192.168.124.247', 2),
(3232267512, '192.168.124.248', 2),
(3232267513, '192.168.124.249', 2),
(3232267514, '192.168.124.250', 2),
(3232267515, '192.168.124.251', 2),
(3232267516, '192.168.124.252', 2),
(3232267517, '192.168.124.253', 2),
(3232267518, '192.168.124.254', 2);

-- --------------------------------------------------------

--
-- Структура таблицы `secureauth`
--

CREATE TABLE IF NOT EXISTS `secureauth` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` bigint(16) unsigned NOT NULL,
  `CallingStationId` char(64) NOT NULL,
  `permit` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `prmit` (`permit`),
  KEY `uid` (`uid`),
  KEY `uid-caller` (`uid`,`CallingStationId`),
  FULLTEXT KEY `caller` (`CallingStationId`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `sessions`
--

CREATE TABLE IF NOT EXISTS `sessions` (
  `sessionid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `userID` int(14) unsigned NOT NULL,
  `auth` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `lastActivity` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ip` varchar(15) CHARACTER SET ucs2 COLLATE ucs2_bin NOT NULL,
  PRIMARY KEY (`sessionid`),
  UNIQUE KEY `sessionid` (`sessionid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `sticky_notes`
--

CREATE TABLE IF NOT EXISTS `sticky_notes` (
  `stickynoteid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `stickynotename` varchar(36) NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stuffid` int(14) unsigned NOT NULL,
  `ispublic` tinyint(1) unsigned NOT NULL,
  `x` int(14) unsigned NOT NULL DEFAULT '10',
  `y` int(14) unsigned NOT NULL DEFAULT '10',
  `visible` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `pinned` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `note` varchar(500) NOT NULL,
  PRIMARY KEY (`stickynoteid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `stuff`
--

CREATE TABLE IF NOT EXISTS `stuff` (
  `stuffid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `sLogin` varchar(36) NOT NULL,
  `sPwd` varchar(36) NOT NULL,
  PRIMARY KEY (`stuffid`),
  UNIQUE KEY `stuffid` (`stuffid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `stuff_aclid`
--

CREATE TABLE IF NOT EXISTS `stuff_aclid` (
  `aclid` tinyint(6) unsigned NOT NULL AUTO_INCREMENT,
  `acl` char(64) NOT NULL,
  PRIMARY KEY (`aclid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=66 AUTO_INCREMENT=14 ;

--
-- Дамп данных таблицы `stuff_aclid`
--

INSERT INTO `stuff_aclid` (`aclid`, `acl`) VALUES
(1, 'Администратор'),
(2, 'Монтажник'),
(9, 'Директор'),
(10, 'Управляющий'),
(11, 'Офис-менеджер'),
(12, 'Бухгалтер'),
(13, 'Бригадир монтажников');

-- --------------------------------------------------------

--
-- Структура таблицы `stuff_aclresource`
--

CREATE TABLE IF NOT EXISTS `stuff_aclresource` (
  `resourceid` tinyint(6) unsigned NOT NULL AUTO_INCREMENT,
  `resource` char(64) NOT NULL,
  PRIMARY KEY (`resourceid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=66 AUTO_INCREMENT=18 ;

--
-- Дамп данных таблицы `stuff_aclresource`
--

INSERT INTO `stuff_aclresource` (`resourceid`, `resource`) VALUES
(1, 'bugh'),
(2, 'stuff'),
(3, 'options'),
(4, 'cards'),
(5, 'vaucher'),
(6, 'logs'),
(7, 'modsendmail'),
(8, 'modules'),
(9, 'monitoring'),
(10, 'tarif'),
(11, 'users'),
(12, 'mapview'),
(13, 'mapedit'),
(14, 'ticketedit'),
(15, 'ticketview'),
(16, 'monitorview'),
(17, 'devel');

-- --------------------------------------------------------

--
-- Структура таблицы `stuff_aclrole`
--

CREATE TABLE IF NOT EXISTS `stuff_aclrole` (
  `id` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `aclid` tinyint(6) unsigned NOT NULL,
  `resourceid` tinyint(6) unsigned NOT NULL,
  `type` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `aclid` (`aclid`),
  KEY `resourceid` (`resourceid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=8 AUTO_INCREMENT=86 ;

--
-- Дамп данных таблицы `stuff_aclrole`
--

INSERT INTO `stuff_aclrole` (`id`, `aclid`, `resourceid`, `type`) VALUES
(1, 1, 1, 1),
(2, 1, 2, 1),
(3, 1, 3, 1),
(4, 1, 4, 1),
(5, 1, 5, 1),
(6, 1, 6, 1),
(8, 1, 7, 1),
(9, 1, 8, 1),
(10, 1, 9, 1),
(11, 1, 10, 1),
(12, 1, 11, 1),
(80, 1, 13, 1),
(81, 1, 14, 1),
(82, 1, 15, 1),
(83, 1, 16, 1),
(84, 1, 17, 0),
(85, 1, 12, 1);

-- --------------------------------------------------------

--
-- Структура таблицы `stuff_dolgnost`
--

CREATE TABLE IF NOT EXISTS `stuff_dolgnost` (
  `dolgnostid` tinyint(5) unsigned NOT NULL AUTO_INCREMENT,
  `dolgnost` char(128) NOT NULL,
  `stavka` double(20,3) unsigned NOT NULL,
  PRIMARY KEY (`dolgnostid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=138 AUTO_INCREMENT=7 ;

--
-- Дамп данных таблицы `stuff_dolgnost`
--

INSERT INTO `stuff_dolgnost` (`dolgnostid`, `dolgnost`, `stavka`) VALUES
(1, 'Монтажник', 1.000),
(2, 'Офис-менеджер', 7.000),
(3, 'Системный администратор', 12.500),
(4, 'Бригадир монтажников', 8.500),
(5, 'Руководитель', 15.000),
(6, 'Управляющий', 13.000);

-- --------------------------------------------------------

--
-- Структура таблицы `stuff_koef_stavki`
--

CREATE TABLE IF NOT EXISTS `stuff_koef_stavki` (
  `koefid` tinyint(6) unsigned NOT NULL AUTO_INCREMENT,
  `name` char(64) NOT NULL,
  `koef` double(20,2) NOT NULL,
  PRIMARY KEY (`koefid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=74 AUTO_INCREMENT=8 ;

--
-- Дамп данных таблицы `stuff_koef_stavki`
--

INSERT INTO `stuff_koef_stavki` (`koefid`, `name`, `koef`) VALUES
(1, 'Рабочий день', 1.00),
(2, 'Рабочий день (переработка)', 12.00),
(3, 'Выходной день', 3.00),
(4, 'Выходной день (переработка)', 1.00),
(5, 'Штраф', -1.00),
(6, 'Премия', 1.00),
(7, 'Больничный', 0.50);

-- --------------------------------------------------------

--
-- Структура таблицы `stuff_permissions`
--

CREATE TABLE IF NOT EXISTS `stuff_permissions` (
  `stuffid` tinyint(6) unsigned NOT NULL,
  `permissionid` int(14) unsigned NOT NULL,
  `value` tinyint(1) unsigned NOT NULL,
  PRIMARY KEY (`stuffid`,`permissionid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура таблицы `stuff_permissions_types`
--

CREATE TABLE IF NOT EXISTS `stuff_permissions_types` (
  `permissionid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `permissionname` varchar(64) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `aclid_1` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `aclid_2` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `aclid_9` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `aclid_10` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `aclid_11` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `aclid_12` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `aclid_13` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `necessary_aclids` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `description` varchar(128) NOT NULL,
  PRIMARY KEY (`permissionid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `stuff_personal`
--

CREATE TABLE IF NOT EXISTS `stuff_personal` (
  `stuffid` tinyint(6) unsigned NOT NULL AUTO_INCREMENT,
  `login` char(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `pass` char(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `aclid` tinyint(6) unsigned DEFAULT '1',
  `dolgnostid` tinyint(6) unsigned NOT NULL DEFAULT '1',
  `stavka` double(20,2) unsigned NOT NULL DEFAULT '0.00',
  `fio` char(128) DEFAULT NULL,
  `adress` char(128) DEFAULT NULL,
  `passportserie` char(16) DEFAULT NULL,
  `passportpropiska` char(128) DEFAULT NULL,
  `passportvoenkomat` char(128) DEFAULT NULL,
  `passportgdevidan` char(128) DEFAULT NULL,
  `inn` char(64) DEFAULT NULL,
  `ndogovora` tinyint(6) unsigned DEFAULT NULL,
  `semeynoepologenie` char(128) DEFAULT NULL,
  `phone_home` char(128) DEFAULT NULL,
  `phone_mob` char(128) DEFAULT NULL,
  `phone_mob2` char(128) DEFAULT NULL,
  `chasi` int(5) DEFAULT NULL,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_credit` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_payment` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_show_passwd` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_minus_payments` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_change_speed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_options` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_change_tarif` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `theme` char(16) DEFAULT NULL,
  `date_birth` char(16) DEFAULT NULL,
  `print_check` tinyint(1) NOT NULL DEFAULT '0',
  `doexportcvs` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `search_display_all` tinyint(1) NOT NULL DEFAULT '1',
  `search_default_or` tinyint(1) NOT NULL DEFAULT '0',
  `use_block_local_inet` tinyint(1) NOT NULL DEFAULT '0',
  `do_simple_change_tarif` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `do_full_change_tarif` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `use_beznal_plateg` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_edit_ip` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_window_doubleclick` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `access_ticket` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `access_map` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `map_create` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `map_superadmin` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_superadmin` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_add` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_update` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_delete` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_inwork` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_performed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_dialogue` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_close` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_open` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_add_note` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_update_note` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_delete_note` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_performers_change` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_categories_edit` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_print` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_see_opened` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_see_inwork` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_see_performed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_see_closed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `tickets_access_reports` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_simple_online` tinyint(2) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`stuffid`),
  KEY `dolgnostid` (`dolgnostid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=1390 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `stuff_personal`
--

INSERT INTO `stuff_personal` (`stuffid`, `login`, `pass`, `aclid`, `dolgnostid`, `stavka`, `fio`, `adress`, `passportserie`, `passportpropiska`, `passportvoenkomat`, `passportgdevidan`, `inn`, `ndogovora`, `semeynoepologenie`, `phone_home`, `phone_mob`, `phone_mob2`, `chasi`, `active`, `do_credit`, `do_payment`, `do_show_passwd`, `do_minus_payments`, `do_change_speed`, `do_options`, `do_change_tarif`, `theme`, `date_birth`, `print_check`, `doexportcvs`, `search_display_all`, `search_default_or`, `use_block_local_inet`, `do_simple_change_tarif`, `do_full_change_tarif`, `use_beznal_plateg`, `do_edit_ip`, `do_window_doubleclick`, `access_ticket`, `access_map`, `map_create`, `map_superadmin`, `tickets_superadmin`, `tickets_add`, `tickets_update`, `tickets_delete`, `tickets_inwork`, `tickets_performed`, `tickets_dialogue`, `tickets_close`, `tickets_open`, `tickets_add_note`, `tickets_update_note`, `tickets_delete_note`, `tickets_performers_change`, `tickets_categories_edit`, `tickets_print`, `tickets_see_opened`, `tickets_see_inwork`, `tickets_see_performed`, `tickets_see_closed`, `tickets_access_reports`, `do_simple_online`) VALUES
(1, 'admin', 'admin', 1, 3, 0.00, '', '', '', '', '', '', '', 0, '', '', '', '', 160, 1, 1, 1, 1, 1, 1, 1, 1, '', '', 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);


-- --------------------------------------------------------

--
-- Структура таблицы `stuff_vihoda`
--

CREATE TABLE IF NOT EXISTS `stuff_vihoda` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `stuffid` tinyint(6) unsigned NOT NULL,
  `chasi` double(11,2) NOT NULL,
  `comment` char(255) DEFAULT NULL,
  `month` date NOT NULL,
  `koefid` tinyint(6) unsigned NOT NULL,
  `who` char(64) NOT NULL,
  `date` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `stuffid` (`stuffid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `stuff_zarplata`
--

CREATE TABLE IF NOT EXISTS `stuff_zarplata` (
  `id` int(7) unsigned NOT NULL AUTO_INCREMENT,
  `stuffid` tinyint(6) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `who` varchar(128) NOT NULL,
  `comment` varchar(256) DEFAULT NULL,
  `month` date NOT NULL,
  `summa` double(20,2) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `switches`
--

CREATE TABLE IF NOT EXISTS `switches` (
  `swid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nameswitch` char(128) NOT NULL DEFAULT 'switch',
  `swtypeid` smallint(5) DEFAULT NULL,
  `login` char(64) DEFAULT NULL,
  `pass` char(64) DEFAULT NULL,
  `comunity` char(64) NOT NULL DEFAULT 'private',
  `snmpver` tinyint(4) DEFAULT '2',
  `port` int(11) DEFAULT '161',
  `ip` char(16) DEFAULT NULL,
  `telnet` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `address` char(128) DEFAULT NULL,
  `use_snmp` tinyint(2) NOT NULL DEFAULT '0',
  `managed` tinyint(2) NOT NULL DEFAULT '0',
  `app` char(16) NOT NULL,
  `houseid` int(14) unsigned NOT NULL DEFAULT '1',
  `housingid` int(14) unsigned NOT NULL,
  `houseblockid` int(14) unsigned NOT NULL,
  `porch` int(4) unsigned NOT NULL,
  `floor` int(4) unsigned NOT NULL,
  `productnum` char(128) NOT NULL,
  `serialnum` char(128) NOT NULL,
  `firmvarever` char(64) NOT NULL,
  `use_snmp_monitor` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `mac` char(17) CHARACTER SET keybcs2 COLLATE keybcs2_bin NOT NULL DEFAULT '',
  `use_ssh` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_web` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `ssh_port` int(10) unsigned NOT NULL DEFAULT '22',
  `telnet_port` int(10) unsigned NOT NULL DEFAULT '23',
  `web_port` int(10) unsigned NOT NULL DEFAULT '80',
  `external_telnet_url` varchar(64) NOT NULL DEFAULT '',
  `external_ssh_url` varchar(64) NOT NULL DEFAULT '',
  `external_web_url` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`swid`),
  KEY `ip` (`ip`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=80 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `switches`
--

INSERT INTO `switches` (`swid`, `nameswitch`, `swtypeid`, `login`, `pass`, `comunity`, `snmpver`, `port`, `ip`, `telnet`, `address`, `use_snmp`, `managed`, `app`, `houseid`, `housingid`, `houseblockid`, `porch`, `floor`, `productnum`, `serialnum`, `firmvarever`, `use_snmp_monitor`, `mac`, `use_ssh`, `use_web`, `ssh_port`, `telnet_port`, `web_port`, `external_telnet_url`, `external_ssh_url`, `external_web_url`) VALUES
(1, 'rost-cisco', 1, '', '', 'private', 2, 161, '', 1, '', 1, 1, '', 1, 0, 0, 0, 0, '', '', '', 0, '', 0, 0, 22, 23, 80, '', '', ''),
(2, 'test-summit', 2, 'admin', '', 'private', 2, 161, '192.168.3.2', 1, '', 1, 1, '', 1, 0, 0, 0, 0, '', '', '', 0, '', 0, 1, 22, 23, 80, '', '', '');

-- --------------------------------------------------------

--
-- Структура таблицы `switche_type`
--

CREATE TABLE IF NOT EXISTS `switche_type` (
  `swtypeid` smallint(5) NOT NULL AUTO_INCREMENT,
  `swtypename` char(128) NOT NULL,
  `numports` char(3) NOT NULL DEFAULT '24',
  `snmp_type` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `dont_use_uplink` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `do_check_switch_port` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_mac_autoreg_by_radius` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_ip_unnumbered` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`swtypeid`),
  KEY `swtypeid-ports` (`swtypeid`,`numports`),
  FULLTEXT KEY `swtypename` (`swtypename`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=139 AUTO_INCREMENT=3 ;

--
-- Дамп данных таблицы `switche_type`
--

INSERT INTO `switche_type` (`swtypeid`, `swtypename`, `numports`, `snmp_type`, `dont_use_uplink`, `do_check_switch_port`, `do_mac_autoreg_by_radius`, `do_ip_unnumbered`) VALUES
(1, 'Cisco', '24', 1, 1, 0, 0, 0),
(2, 'Summit-200', '26', 1, 1, 0, 0, 0);

-- --------------------------------------------------------

--
-- Структура таблицы `switch_ip_unnumbered`
--

CREATE TABLE IF NOT EXISTS `switch_ip_unnumbered` (
  `ipunnumberedid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `swid` int(14) unsigned NOT NULL,
  `port` int(3) unsigned NOT NULL,
  `vlan` int(10) unsigned NOT NULL,
  PRIMARY KEY (`ipunnumberedid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `switch_logs`
--

CREATE TABLE IF NOT EXISTS `switch_logs` (
  `swlogid` bigint(21) unsigned NOT NULL AUTO_INCREMENT,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `uid` int(10) unsigned NOT NULL DEFAULT '0',
  `swid` int(10) unsigned NOT NULL,
  `port` int(10) NOT NULL,
  `mac` char(17) NOT NULL,
  `vlan` int(5) NOT NULL DEFAULT '0',
  PRIMARY KEY (`swlogid`),
  KEY `mac-time` (`mac`,`time`),
  KEY `swid-mac-time` (`swid`,`mac`,`time`),
  KEY `swid-time` (`swid`,`time`),
  KEY `time` (`time`),
  FULLTEXT KEY `mac` (`mac`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `switch_port_dead`
--

CREATE TABLE IF NOT EXISTS `switch_port_dead` (
  `swdeadportid` int(22) unsigned NOT NULL AUTO_INCREMENT,
  `swid` int(10) unsigned NOT NULL,
  `deadport` int(2) unsigned NOT NULL,
  PRIMARY KEY (`swdeadportid`),
  KEY `swid` (`swid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `switch_port_grozi`
--

CREATE TABLE IF NOT EXISTS `switch_port_grozi` (
  `grozaid` int(22) unsigned NOT NULL AUTO_INCREMENT,
  `swid` int(10) unsigned NOT NULL,
  `grozaport` int(2) unsigned NOT NULL,
  PRIMARY KEY (`grozaid`),
  KEY `swid` (`swid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `switch_uplink`
--

CREATE TABLE IF NOT EXISTS `switch_uplink` (
  `uplinkid` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `swid` int(10) unsigned NOT NULL,
  `port` int(4) unsigned NOT NULL,
  `swiduplink` int(10) unsigned NOT NULL,
  `speed` char(20) NOT NULL DEFAULT '100',
  `type_uplink` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `use_uplink` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `portdst` int(4) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`uplinkid`),
  KEY `swid` (`swid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=43 AUTO_INCREMENT=2 ;

--
-- Дамп данных таблицы `switch_uplink`
--

INSERT INTO `switch_uplink` (`uplinkid`, `swid`, `port`, `swiduplink`, `speed`, `type_uplink`, `use_uplink`, `portdst`) VALUES
(1, 2, 26, 0, '1000', 1, 1, 0);

-- --------------------------------------------------------

--
-- Структура таблицы `switch_vlans`
--

CREATE TABLE IF NOT EXISTS `switch_vlans` (
  `swvlanid` int(22) unsigned NOT NULL AUTO_INCREMENT,
  `swid` int(10) unsigned NOT NULL,
  `sectorid` int(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`swvlanid`),
  KEY `sectorid` (`sectorid`),
  KEY `swid` (`swid`),
  KEY `swid-sectorid` (`swid`,`sectorid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=13 AUTO_INCREMENT=2 ;

--
-- Дамп данных таблицы `switch_vlans`
--

INSERT INTO `switch_vlans` (`swvlanid`, `swid`, `sectorid`) VALUES
(1, 2, 2);

-- --------------------------------------------------------

--
-- Структура таблицы `syslogs`
--

CREATE TABLE IF NOT EXISTS `syslogs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `host` char(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `facility` char(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `priority` char(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `level` char(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tag` char(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `datetime` datetime DEFAULT NULL,
  `program` char(15) COLLATE utf8_unicode_ci DEFAULT NULL,
  `msg` text COLLATE utf8_unicode_ci,
  `seq` bigint(20) unsigned NOT NULL DEFAULT '0',
  `counter` int(11) NOT NULL DEFAULT '1',
  `fo` datetime DEFAULT NULL,
  `lo` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `datetime` (`datetime`),
  KEY `facility` (`facility`),
  KEY `host` (`host`),
  KEY `priority` (`priority`),
  KEY `program` (`program`),
  KEY `sequence` (`seq`),
  FULLTEXT KEY `msg` (`msg`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `sysopts`
--

CREATE TABLE IF NOT EXISTS `sysopts` (
  `options_id` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `auto_local_ip` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `auto_vpn_ip` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `do_arping` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `sudo` varchar(50) NOT NULL DEFAULT '/usr/bin/sudo -u root ',
  `awk` varchar(16) NOT NULL DEFAULT '/bin/awk',
  `grep` varchar(16) NOT NULL DEFAULT '/bin/grep',
  `IPROUTE_TC` varchar(16) NOT NULL DEFAULT '/sbin/tc',
  `IPROUTE_IP` varchar(16) NOT NULL DEFAULT '/sbin/ip',
  `shaper_dev_in` varchar(8) NOT NULL DEFAULT 'imq0',
  `shaper_dev_out` varchar(8) NOT NULL DEFAULT 'imq1',
  `base_ip` varchar(16) NOT NULL DEFAULT '10.0',
  `DHCP_CONF` varchar(50) NOT NULL DEFAULT '/etc/dhcp/dhcpd.conf',
  `DHCP_PARAM_DOMAIN` varchar(50) NOT NULL DEFAULT 'newline.dn.ua',
  `DHCP_PARAM_DOMAIN_SERV` varchar(50) NOT NULL DEFAULT 'ns.newline.dn.ua',
  `DHCP_PARAM_DDNS_ZONE` varchar(50) NOT NULL DEFAULT 'private',
  `DNS_LOCAL_FILE_ZONE` varchar(50) NOT NULL DEFAULT '/etc/bind/master/ispnet.demo',
  `DNS_LOCAL_FILE_ARPA_ZONE` varchar(50) NOT NULL DEFAULT '/etc/bind/master/0.10.in-addr.arpa',
  `ETHERS_FILE` varchar(50) NOT NULL DEFAULT '/etc/ethers',
  `IP_SENTINEL_CONF` varchar(50) NOT NULL DEFAULT '/etc/ip-sentinel.cfg',
  `NAMED_RESTART` varchar(50) NOT NULL DEFAULT '/etc/init.d/named restart',
  `DHCPD_RESTART` varchar(50) NOT NULL DEFAULT '/etc/init.d/dhcpd restart',
  `ARP_DO_ETHERS` varchar(50) NOT NULL DEFAULT '/sbin/arp -f ',
  `IP_SENTINEL_RESTART` varchar(50) NOT NULL DEFAULT '/etc/rc.d/init.d/ip-sentinel restart',
  `MBYTE` int(8) unsigned NOT NULL DEFAULT '1048576',
  `SUDO_RADRELOAD` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `DO_LOG` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `LOG_FILE` varchar(80) DEFAULT '/var/log/mikbill.log',
  `NET_VPN` varchar(16) NOT NULL DEFAULT '192.168.',
  `NET_LAN` varchar(16) NOT NULL DEFAULT '10.10.',
  `NET_GW` varchar(16) NOT NULL DEFAULT '0.254',
  `COMPANY_NAME` varchar(100) NOT NULL DEFAULT 'ISP ispnet',
  `UE` varchar(50) NOT NULL DEFAULT 'Грн',
  `CREDIT_LIMIT` int(8) unsigned NOT NULL DEFAULT '6000',
  `DELIVERY` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `MAIL_DOMAIN` varchar(50) NOT NULL DEFAULT 'ispnet.demo',
  `MAIL_BASE` varchar(50) DEFAULT '/home/vmail',
  `USE_CARDS` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `CREATE_SYSTEM` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `GB` int(12) unsigned NOT NULL DEFAULT '1048576',
  `TRAF_LIST` varchar(50) NOT NULL DEFAULT './db/traf/',
  `USER_LIST` varchar(50) NOT NULL DEFAULT './db/usrlist',
  `SPEED_CHANEL_IN` int(20) unsigned NOT NULL DEFAULT '22120',
  `SPEED_CHANEL_OUT` int(20) unsigned NOT NULL DEFAULT '22120',
  `email` varchar(128) NOT NULL,
  `smtphost` varchar(128) NOT NULL,
  `smtplogin` varchar(128) NOT NULL,
  `smtppass` varchar(64) NOT NULL,
  `smtpport` varchar(4) NOT NULL DEFAULT '25',
  `smtpssl` tinyint(2) NOT NULL DEFAULT '0',
  `adv_mik_shaper` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `CLRLINE_CISCO` varchar(128) NOT NULL DEFAULT '/opt/freeradius/sbin/clrline',
  `CLRLINE_PORTSLAVE` varchar(128) NOT NULL DEFAULT '/usr/bin/finger',
  `CLRLINE_PPPD` varchar(128) NOT NULL DEFAULT '/usr/local/sbin/pppkill',
  `exec_radclient` varchar(128) NOT NULL DEFAULT '/usr/local/bin/radclient',
  `ECHO` varchar(128) NOT NULL DEFAULT '/bin/echo',
  `nonstop_key` varchar(64) NOT NULL DEFAULT '0',
  `nonstop_procent` double(5,3) NOT NULL DEFAULT '0.000',
  `use_dolg_ippool` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `dolgnik_ippololid` int(5) unsigned NOT NULL DEFAULT '0',
  `mrtg_exec_prog` varchar(128) NOT NULL DEFAULT '/usr/bin/php -q /var/www/mikbill/admin/index.php',
  `mrtg_path_data` varchar(128) NOT NULL DEFAULT '/var/www/mikbill/admin',
  `mrtg_users_conf` varchar(128) NOT NULL DEFAULT '/etc/mrtg/mrtg_mikbill_users.conf',
  `mrtg_tarifs_conf` varchar(128) NOT NULL DEFAULT '/etc/mrtg/mrtg_mikbill_tarif.conf',
  `tarif_perevod_vniz` double(4,2) NOT NULL DEFAULT '0.00',
  `tarif_perevod_vverh` double(4,2) NOT NULL DEFAULT '0.00',
  `real_ip_buy_cena` varchar(10) NOT NULL DEFAULT '0',
  `real_ip_disable_cena` varchar(10) NOT NULL DEFAULT '0',
  `turbo_buy_cena` varchar(10) NOT NULL DEFAULT '0',
  `turbo_speed` varchar(20) NOT NULL DEFAULT '0',
  `do_ping` tinyint(2) NOT NULL DEFAULT '1',
  `start_credit_date` varchar(2) NOT NULL DEFAULT '1',
  `stop_credit_date` varchar(2) NOT NULL DEFAULT '7',
  `start_credit_procent_date` varchar(2) NOT NULL DEFAULT '7',
  `stop_credit_procent_date` varchar(2) NOT NULL DEFAULT '15',
  `shaper_koef` varchar(4) NOT NULL DEFAULT '1024',
  `stop_all_credit` varchar(2) NOT NULL DEFAULT '15',
  `SUDO_DHCPDRELOAD` tinyint(2) NOT NULL DEFAULT '0',
  `DISABLE_DHCP` tinyint(2) NOT NULL DEFAULT '0',
  `DISABLE_DHCP_SYSLOG` tinyint(2) NOT NULL DEFAULT '0',
  `USE_languard` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `USE_admins_kick_users` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `USE_link_IP_MAC` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `USE_BLACK_LIST` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `dont_display_local_ip` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `dont_display_framed_ip` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `get_from_online_local_ip` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `get_from_online_framed_ip` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `osmp_key` varchar(64) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '79.142.16.0/20',
  `osmp_procent` double(4,3) unsigned NOT NULL DEFAULT '5.000',
  `default_lease_time` int(20) unsigned NOT NULL DEFAULT '21600',
  `max_lease_time` int(20) unsigned NOT NULL DEFAULT '864000',
  `do_osmp_terminal` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_24nonstop_terminal` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `do_liqpay_terminal` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `merchant_id` varchar(64) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `phone_pay` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `merc_sign` varchar(128) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `merc_sign_other` varchar(128) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `liqpay_curency` varchar(4) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `url_result` varchar(128) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `url_server` varchar(128) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `radiusd_path` varchar(128) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '/etc/init.d/radiusd restart',
  `mysqld_path` varchar(128) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '/etc/init.d/mysqld restart',
  `do_otkl_dolg` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `days_to_otkl` int(8) NOT NULL DEFAULT '60',
  `do_del_otkl` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `days_to_delete` int(8) NOT NULL DEFAULT '30',
  `copayco_test_mode` varchar(5) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT 'false',
  `copayco_shop_id` varchar(10) CHARACTER SET koi8r COLLATE koi8r_bin DEFAULT NULL,
  `copayco_sign_key` varchar(128) CHARACTER SET koi8r COLLATE koi8r_bin DEFAULT NULL,
  `do_copayco_terminal` tinyint(1) NOT NULL DEFAULT '0',
  `copayco_curency` varchar(5) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT 'UAH',
  `copayco_description` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT 'internet',
  `do_perevod_fixed` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `perevod_summa` double(10,2) NOT NULL DEFAULT '0.00',
  `do_ipoe_hosts_clean` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `ssh_path` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '/usr/bin/ssh',
  PRIMARY KEY (`options_id`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=916;

--
-- Дамп данных таблицы `sysopts`
--

INSERT INTO `sysopts` (`options_id`, `auto_local_ip`, `auto_vpn_ip`, `do_arping`, `sudo`, `awk`, `grep`, `IPROUTE_TC`, `IPROUTE_IP`, `shaper_dev_in`, `shaper_dev_out`, `base_ip`, `DHCP_CONF`, `DHCP_PARAM_DOMAIN`, `DHCP_PARAM_DOMAIN_SERV`, `DHCP_PARAM_DDNS_ZONE`, `DNS_LOCAL_FILE_ZONE`, `DNS_LOCAL_FILE_ARPA_ZONE`, `ETHERS_FILE`, `IP_SENTINEL_CONF`, `NAMED_RESTART`, `DHCPD_RESTART`, `ARP_DO_ETHERS`, `IP_SENTINEL_RESTART`, `MBYTE`, `SUDO_RADRELOAD`, `DO_LOG`, `LOG_FILE`, `NET_VPN`, `NET_LAN`, `NET_GW`, `COMPANY_NAME`, `UE`, `CREDIT_LIMIT`, `DELIVERY`, `MAIL_DOMAIN`, `MAIL_BASE`, `USE_CARDS`, `CREATE_SYSTEM`, `GB`, `TRAF_LIST`, `USER_LIST`, `SPEED_CHANEL_IN`, `SPEED_CHANEL_OUT`, `email`, `smtphost`, `smtplogin`, `smtppass`, `smtpport`, `smtpssl`, `adv_mik_shaper`, `CLRLINE_CISCO`, `CLRLINE_PORTSLAVE`, `CLRLINE_PPPD`, `exec_radclient`, `ECHO`, `nonstop_key`, `nonstop_procent`, `use_dolg_ippool`, `dolgnik_ippololid`, `mrtg_exec_prog`, `mrtg_path_data`, `mrtg_users_conf`, `mrtg_tarifs_conf`, `tarif_perevod_vniz`, `tarif_perevod_vverh`, `real_ip_buy_cena`, `real_ip_disable_cena`, `turbo_buy_cena`, `turbo_speed`, `do_ping`, `start_credit_date`, `stop_credit_date`, `start_credit_procent_date`, `stop_credit_procent_date`, `shaper_koef`, `stop_all_credit`, `SUDO_DHCPDRELOAD`, `DISABLE_DHCP`, `DISABLE_DHCP_SYSLOG`, `USE_languard`, `USE_admins_kick_users`, `USE_link_IP_MAC`, `USE_BLACK_LIST`, `dont_display_local_ip`, `dont_display_framed_ip`, `get_from_online_local_ip`, `get_from_online_framed_ip`, `osmp_key`, `osmp_procent`, `default_lease_time`, `max_lease_time`, `do_osmp_terminal`, `do_24nonstop_terminal`, `do_liqpay_terminal`, `merchant_id`, `phone_pay`, `merc_sign`, `merc_sign_other`, `liqpay_curency`, `url_result`, `url_server`, `radiusd_path`, `mysqld_path`, `do_otkl_dolg`, `days_to_otkl`, `do_del_otkl`, `days_to_delete`, `copayco_test_mode`, `copayco_shop_id`, `copayco_sign_key`, `do_copayco_terminal`, `copayco_curency`, `copayco_description`, `do_perevod_fixed`, `perevod_summa`, `do_ipoe_hosts_clean`, `ssh_path`) VALUES
(1, 1, 1, 0, '/usr/bin/sudo -u root', '/bin/awk', '/bin/grep', '/sbin/tc', '/sbin/ip', 'imq0', 'imq1', '10', '/etc/dhcpd.conf', 'domain.com', 'ns.domain.com', 'domain.com', '/etc/bind/master/domain.com.loc', '/etc/bind/master/0.10.inaddr.arpa', '/etc/ethers', '/etc/ip-sentinel.cfg', '/etc/init.d/named restart', '/etc/init.d/dhcpd restart', '/sbin/arp -f', '/etc/rc.d/init.d/ip-sentinel restart', 1048576, 1, 1, '/var/log/mikbill.log', '192.168.', '10.10.', '0.254', 'ISP Domain', 'Грн', 6000, 1, 'domain.com', '/home/vmail', 0, 0, 1048576, './db/traf/', './db/usrlist', 1200120, 1200120, 'admin@domain.com', 'localhost', 'user@domain.com', 'pass', '25', 1, 1, '/opt/freeradius/sbin/clrline', '/usr/bin/finger', '/usr/local/sbin/pppkill', '/usr/local/bin/radclient', '/bin/echo', '', 0.000, 0, 1, '/usr/bin/php -q /var/www/mikbill/admin/index.php', '/var/www/mikbill/admin', '/etc/mrtg/mrtg_mikbill_users.conf', '/etc/mrtg/mrtg_mikbill_tarif.conf', 0.00, 0.00, '0', '0', '0', '0', 0, '1', '7', '7', '15', '1024', '15', 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, '', 5.000, 21600, 864000, 0, 0, 0, '', '', '', '', '', '', '', '/etc/init.d/radiusd restart', '/etc/init.d/mysqld restart', 0, 60, 0, 30, 'false', NULL, NULL, 0, 'UAH', 'internet', 0, 0.00, 0, '/usr/bin/ssh');

-- --------------------------------------------------------

--
-- Структура таблицы `sysopts_voip`
--

CREATE TABLE IF NOT EXISTS `sysopts_voip` (
  `voipid` tinyint(2) unsigned NOT NULL AUTO_INCREMENT,
  `asterisk_spool_path` varchar(64) NOT NULL DEFAULT '/var/spool/asterisk/outgoing',
  `asterisk_channel` varchar(64) NOT NULL DEFAULT 'SIP/Promtelecom/',
  `asterisk_extension` varchar(32) NOT NULL DEFAULT 'anjeybill',
  `asterisk_context` varchar(32) NOT NULL DEFAULT 'anjeybill',
  `asterisk_callerid` varchar(32) NOT NULL DEFAULT 'bill',
  `asterisk_maxretries` varchar(3) NOT NULL DEFAULT '3',
  `asterisk_retrytime` varchar(3) NOT NULL DEFAULT '15',
  `asterisk_waittime` varchar(3) NOT NULL DEFAULT '45',
  `asterisk_priority` varchar(2) NOT NULL DEFAULT '1',
  `asterisk_nummin` varchar(2) NOT NULL DEFAULT '6',
  `asterisk_nummax` varchar(2) NOT NULL DEFAULT '7',
  `asterisk_numlines` varchar(2) NOT NULL DEFAULT '9',
  `asterisk_call_time` varchar(3) NOT NULL DEFAULT '180',
  PRIMARY KEY (`voipid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=92 AUTO_INCREMENT=2 ;

--
-- Дамп данных таблицы `sysopts_voip`
--

INSERT INTO `sysopts_voip` (`voipid`, `asterisk_spool_path`, `asterisk_channel`, `asterisk_extension`, `asterisk_context`, `asterisk_callerid`, `asterisk_maxretries`, `asterisk_retrytime`, `asterisk_waittime`, `asterisk_priority`, `asterisk_nummin`, `asterisk_nummax`, `asterisk_numlines`, `asterisk_call_time`) VALUES
(1, '/var/spool/asterisk/outgoing', 'SIP/trunkname/', 'mikbill', 'mikbill', 'bill', '3', '15', '45', '1', '6', '7', '9', '180');

-- --------------------------------------------------------

--
-- Структура таблицы `system_options`
--

CREATE TABLE IF NOT EXISTS `system_options` (
  `key` char(32) COLLATE koi8r_bin NOT NULL,
  `value` char(128) COLLATE koi8r_bin NOT NULL,
  UNIQUE KEY `key` (`key`),
  FULLTEXT KEY `key-fulltext` (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COLLATE=koi8r_bin AVG_ROW_LENGTH=161;

--
-- Дамп данных таблицы `system_options`
--

INSERT INTO `system_options` (`key`, `value`) VALUES
('options_id', '1'),
('auto_local_ip', '1'),
('auto_vpn_ip', '1'),
('do_arping', '1'),
('sudo', '/usr/bin/sudo -u root'),
('awk', '/bin/awk'),
('grep', '/bin/grep'),
('IPROUTE_TC', '/sbin/tc'),
('IPROUTE_IP', '/sbin/ip'),
('shaper_dev_in', 'imq0'),
('shaper_dev_out', 'imq1'),
('base_ip', '10'),
('DHCP_CONF', '/etc/dhcp/dhcpd.conf'),
('DHCP_PARAM_DOMAIN', 'celteh.com'),
('DHCP_PARAM_DOMAIN_SERV', 'ns.celteh.com'),
('DHCP_PARAM_DDNS_ZONE', 'celteh.com'),
('DNS_LOCAL_FILE_ZONE', '/etc/bind/master/newline.loc'),
('DNS_LOCAL_FILE_ARPA_ZONE', '/etc/bind/master/0.10.inaddr.arpa'),
('ETHERS_FILE', '/etc/ethers'),
('IP_SENTINEL_CONF', '/etc/ip-sentinel.cfg'),
('NAMED_RESTART', '/etc/init.d/named restart'),
('DHCPD_RESTART', '/etc/init.d/dhcpd restart'),
('ARP_DO_ETHERS', '/sbin/arp -f'),
('IP_SENTINEL_RESTART', '/etc/rc.d/init.d/ip-sentinel restart'),
('MBYTE', '1048576'),
('SUDO_RADRELOAD', '0'),
('DO_LOG', '1'),
('LOG_FILE', '/var/log/mikbill.log'),
('NET_VPN', '172.16.'),
('NET_LAN', '10.10.'),
('NET_GW', '0.254'),
('COMPANY_NAME', 'ISP Celteh'),
('UE', 'руб'),
('CREDIT_LIMIT', '6000'),
('DELIVERY', '1'),
('MAIL_DOMAIN', 'test.com'),
('MAIL_BASE', '/home/vmail'),
('USE_CARDS', '0'),
('CREATE_SYSTEM', '0'),
('GB', '1048576'),
('TRAF_LIST', './db/traf/'),
('USER_LIST', './db/usrlist'),
('SPEED_CHANEL_IN', '1200120'),
('SPEED_CHANEL_OUT', '1200120'),
('email', 'test@test.com'),
('smtphost', 'localhost'),
('smtplogin', 'test@test.com'),
('smtppass', 'test'),
('smtpport', '25'),
('smtpssl', '1'),
('adv_mik_shaper', '1'),
('CLRLINE_CISCO', '/opt/freeradius/sbin/clrline'),
('CLRLINE_PORTSLAVE', '/usr/bin/finger'),
('CLRLINE_PPPD', '/usr/local/sbin/pppkill'),
('exec_radclient', '/usr/local/bin/radclient'),
('ECHO', '/bin/echo'),
('nonstop_key', '0'),
('nonstop_procent', '0.000'),
('use_dolg_ippool', '1'),
('dolgnik_ippololid', '1'),
('mrtg_exec_prog', '/usr/bin/php -q /var/www/mikbill/admin/index.php'),
('mrtg_path_data', '/var/www/mikbill/admin'),
('mrtg_users_conf', '/etc/mrtg/mrtg_mikbill_users.conf'),
('mrtg_tarifs_conf', '/etc/mrtg/mrtg_mikbill_tarif.conf'),
('tarif_perevod_vniz', '10'),
('tarif_perevod_vverh', '0'),
('real_ip_buy_cena', '0'),
('real_ip_disable_cena', '0'),
('turbo_buy_cena', '0'),
('turbo_speed', '0'),
('do_ping', '1'),
('start_credit_date', '1'),
('stop_credit_date', '7'),
('start_credit_procent_date', '7'),
('stop_credit_procent_date', '15'),
('shaper_koef', '1024'),
('stop_all_credit', '15'),
('SUDO_DHCPDRELOAD', '0'),
('DISABLE_DHCP', '1'),
('DISABLE_DHCP_SYSLOG', '0'),
('USE_languard', '0'),
('USE_admins_kick_users', '0'),
('USE_link_IP_MAC', '0'),
('USE_BLACK_LIST', '0'),
('dont_display_local_ip', '0'),
('dont_display_framed_ip', '0'),
('get_from_online_local_ip', '0'),
('get_from_online_framed_ip', '0'),
('osmp_key', ''),
('osmp_procent', '5'),
('default_lease_time', '21600'),
('max_lease_time', '864000'),
('do_osmp_terminal', '0'),
('do_24nonstop_terminal', '0'),
('do_liqpay_terminal', '0'),
('merchant_id', ''),
('phone_pay', ''),
('merc_sign', ''),
('merc_sign_other', ''),
('liqpay_curency', ''),
('url_result', ''),
('url_server', ''),
('radiusd_path', '/etc/init.d/radiusd restart'),
('mysqld_path', '/etc/init.d/mysqld restart'),
('do_otkl_dolg', '1'),
('days_to_otkl', '60'),
('do_del_otkl', '1'),
('days_to_delete', '30'),
('copayco_test_mode', 'false'),
('copayco_shop_id', ''),
('copayco_sign_key', ''),
('do_copayco_terminal', '0'),
('copayco_curency', 'UAH'),
('copayco_description', 'internet'),
('do_perevod_fixed', '1'),
('perevod_summa', '0.5'),
('do_ipoe_hosts_clean', '0'),
('ssh_path', '/usr/bin/ssh'),
('privat24_procent', '0'),
('hs_idle_timeout', '30'),
('hs_speed_in', ''),
('privat24_merchantid', ''),
('wqiwiru_secret', ''),
('hs_session_timeout', '300'),
('mac_autoreg', '0'),
('elecsnet_procent', ''),
('privat24_ccy', ''),
('do_compay_terminal', '0'),
('guest_vlan_id_block', '124'),
('onpay_procent', ''),
('hs_speed_out', ''),
('do_vlan_opt82', '0'),
('compay_procent', ''),
('citypay_network2', ''),
('compay_secret', ''),
('elecsnet_network_1', ''),
('guest_vlan_id_not_current_sector', '124'),
('hs_do_addrlist', '0'),
('elecsnet_network_3', ''),
('onpay_secret', ''),
('do_easysoft_terminal', '0'),
('guest_vlan_id_freeze', '124'),
('privat24_server_url', ''),
('do_wqiwiru_terminal', '0'),
('guest_vlan_id_no_money', '124'),
('privat24_sign', ''),
('citypay_network', ''),
('onpay_ccy', ''),
('privat24_return_url', ''),
('wqiwiru_shop_id', ''),
('elecsnet_network_2', ''),
('hs_use_queue', '0'),
('guest_vlan_id_del', '124'),
('guest_vlan_do', '0'),
('do_citypay_terminal', '0'),
('do_elecsnet_terminal', '0'),
('hs_address_list', ''),
('onpay_url_success', ''),
('hs_acct_interim_interval', '300'),
('easysoft_procent', ''),
('guest_vlan_id_otkl', '124'),
('exec_snmpwalk', ''),
('easysoft_netork', ''),
('do_onpay_terminal', '0'),
('citypay_procent', ''),
('hs_prio', '1'),
('guest_vlan_id', '124'),
('do_privat24_terminal', '0'),
('onpay_login', ''),
('wqiwiru_procent', '');

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_acl_resources_list`
--

CREATE TABLE IF NOT EXISTS `tickets_acl_resources_list` (
  `aclresourceid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `aclresourcename` varchar(64) NOT NULL,
  PRIMARY KEY (`aclresourceid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_categories_list`
--

CREATE TABLE IF NOT EXISTS `tickets_categories_list` (
  `categoryid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `categoryname` varchar(45) NOT NULL,
  `description` varchar(64) NOT NULL,
  `color` int(10) unsigned NOT NULL DEFAULT '0',
  `req_uid` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `req_fio` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `req_phones` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `req_settlement` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `req_street` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `req_house` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `req_apartment` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `req_porch` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `req_floor` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `req_sector` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `link_to_uid` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`categoryid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=51 AUTO_INCREMENT=13 ;

--
-- Дамп данных таблицы `tickets_categories_list`
--

INSERT INTO `tickets_categories_list` (`categoryid`, `categoryname`, `description`, `color`, `req_uid`, `req_fio`, `req_phones`, `req_settlement`, `req_street`, `req_house`, `req_apartment`, `req_porch`, `req_floor`, `req_sector`, `link_to_uid`) VALUES
(1, 'other', 'predefined_category', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2, 'connection', 'predefined_category', 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1),
(3, 'maintenance', 'predefined_category', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(4, 'created_in_the_cabinet', 'predefined_category', 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(5, 'cable_is_not_connected', 'predefined_category', 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(6, 'ip_address_conflict', 'predefined_category', 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(7, 'internet_does_not_work', 'predefined_category', 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(8, 'pages_not_open', 'predefined_category', 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9, 'cable_replacement', 'predefined_category', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(10, 'does_not_work_the_whole_house', 'predefined_category', 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
(11, 'does_not_work_the_whole_sector', 'predefined_category', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
(12, 'configuring_the_router', 'predefined_category', 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_crews`
--

CREATE TABLE IF NOT EXISTS `tickets_crews` (
  `crewid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `crewname` varchar(45) NOT NULL,
  PRIMARY KEY (`crewid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_logs`
--

CREATE TABLE IF NOT EXISTS `tickets_logs` (
  `ticketlogid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `ticketid` int(14) unsigned NOT NULL,
  `logdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `record` varchar(512) NOT NULL,
  `stuffid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`ticketlogid`),
  UNIQUE KEY `ticketlogid` (`ticketlogid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_messages`
--

CREATE TABLE IF NOT EXISTS `tickets_messages` (
  `messageid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ticketid` int(14) unsigned NOT NULL,
  `stuffid` int(14) unsigned NOT NULL,
  `useruid` int(14) unsigned NOT NULL,
  `message` varchar(600) NOT NULL,
  `unread` tinyint(1) unsigned NOT NULL,
  PRIMARY KEY (`messageid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AUTO_INCREMENT=2 ;

--
-- Дамп данных таблицы `tickets_messages`
--

INSERT INTO `tickets_messages` (`messageid`, `date`, `ticketid`, `stuffid`, `useruid`, `message`, `unread`) VALUES
(1, '2013-07-19 15:26:13', 1, 0, 1, 'what&#63;', 1);

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_notes`
--

CREATE TABLE IF NOT EXISTS `tickets_notes` (
  `noteid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ticketid` int(14) unsigned NOT NULL,
  `stuffid` int(14) unsigned NOT NULL,
  `note` varchar(600) NOT NULL,
  PRIMARY KEY (`noteid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r AUTO_INCREMENT=2 ;

--
-- Дамп данных таблицы `tickets_notes`
--

INSERT INTO `tickets_notes` (`noteid`, `date`, `ticketid`, `stuffid`, `note`) VALUES
(1, '2013-07-19 15:26:13', 1, 0, 'what&#63;');

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_performers`
--

CREATE TABLE IF NOT EXISTS `tickets_performers` (
  `performerid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stuffid` int(14) unsigned NOT NULL,
  `employed_by_stuffid` int(14) unsigned NOT NULL,
  `ticketid` int(14) unsigned NOT NULL,
  PRIMARY KEY (`performerid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_priorities_types`
--

CREATE TABLE IF NOT EXISTS `tickets_priorities_types` (
  `prioritytypeid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `prioritytypename` varchar(45) NOT NULL,
  PRIMARY KEY (`prioritytypeid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_status_types`
--

CREATE TABLE IF NOT EXISTS `tickets_status_types` (
  `statustypeid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `statustypename` varchar(45) NOT NULL,
  PRIMARY KEY (`statustypeid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `tickets_tickets`
--

CREATE TABLE IF NOT EXISTS `tickets_tickets` (
  `ticketid` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `creationdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `performafter` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `performbefore` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `inworkdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `performingdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `inwork_by_stuffid` int(14) unsigned NOT NULL,
  `performed_by_stuffid` int(14) unsigned NOT NULL,
  `closingdate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `closed_by_stuffid` int(14) unsigned NOT NULL,
  `useruid` bigint(16) unsigned NOT NULL,
  `fio` char(128) NOT NULL,
  `sectorid` int(14) unsigned NOT NULL DEFAULT '0',
  `street` varchar(45) NOT NULL,
  `settlementname` varchar(36) NOT NULL,
  `neighborhoodname` varchar(36) NOT NULL,
  `house` varchar(20) NOT NULL,
  `porch` int(2) unsigned NOT NULL,
  `floor` int(3) unsigned NOT NULL,
  `apartment` varchar(10) NOT NULL,
  `housingname` varchar(36) NOT NULL,
  `houseblockname` varchar(36) NOT NULL,
  `phones` varchar(60) NOT NULL,
  `created_by_stuffid` int(14) unsigned NOT NULL,
  `created_by_useruid` int(14) unsigned NOT NULL,
  `categoryid` int(14) unsigned NOT NULL DEFAULT '1',
  `prioritytypeid` int(14) unsigned NOT NULL DEFAULT '1',
  `statustypeid` int(14) unsigned NOT NULL DEFAULT '1',
  `performed_without_on_site_visit` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `can_not_be_performed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `rating` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `emphasis` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `show_ticket_to_user` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `dialogue` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ticketid`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r ROW_FORMAT=FIXED AUTO_INCREMENT=2 ;

--
-- Дамп данных таблицы `tickets_tickets`
--

INSERT INTO `tickets_tickets` (`ticketid`, `creationdate`, `performafter`, `performbefore`, `inworkdate`, `performingdate`, `inwork_by_stuffid`, `performed_by_stuffid`, `closingdate`, `closed_by_stuffid`, `useruid`, `fio`, `sectorid`, `street`, `settlementname`, `neighborhoodname`, `house`, `porch`, `floor`, `apartment`, `housingname`, `houseblockname`, `phones`, `created_by_stuffid`, `created_by_useruid`, `categoryid`, `prioritytypeid`, `statustypeid`, `performed_without_on_site_visit`, `can_not_be_performed`, `rating`, `emphasis`, `show_ticket_to_user`, `dialogue`) VALUES
(1, '2013-07-19 15:26:13', '0000-00-00 00:00:00', '0000-00-00 00:00:00', '0000-00-00 00:00:00', '0000-00-00 00:00:00', 0, 0, '0000-00-00 00:00:00', 0, 1, '', 0, 'Lane 1', '', '', '1', 0, 0, '', '', '', '', 0, 1, 4, 2, 1, 0, 0, 0, 0, 1, 1);

-- --------------------------------------------------------

--
-- Структура таблицы `traf_data`
--

CREATE TABLE IF NOT EXISTS `traf_data` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `date` datetime NOT NULL,
  `uid` bigint(16) unsigned NOT NULL,
  `rx` bigint(20) unsigned NOT NULL,
  `tx` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `date` (`date`,`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `traf_data_day`
--

CREATE TABLE IF NOT EXISTS `traf_data_day` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uid` bigint(16) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `rx` bigint(20) unsigned NOT NULL,
  `tx` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`,`date`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `traf_data_hour`
--

CREATE TABLE IF NOT EXISTS `traf_data_hour` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uid` bigint(16) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `rx` bigint(20) unsigned NOT NULL,
  `tx` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`,`date`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `traf_tx_rx`
--

CREATE TABLE IF NOT EXISTS `traf_tx_rx` (
  `uid` bigint(16) unsigned NOT NULL,
  `rx` bigint(20) unsigned NOT NULL,
  `tx` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура таблицы `users`
--

CREATE TABLE IF NOT EXISTS `users` (
  `user` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `password` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '*',
  `crypt_method` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `uid` bigint(16) unsigned NOT NULL AUTO_INCREMENT,
  `gid` int(5) unsigned NOT NULL DEFAULT '1',
  `deposit` double(20,6) NOT NULL DEFAULT '0.000000',
  `credit` double(20,2) NOT NULL DEFAULT '0.00',
  `fio` char(128) NOT NULL,
  `phone` char(128) NOT NULL,
  `address` char(128) NOT NULL,
  `prim` char(254) NOT NULL,
  `add_date` date NOT NULL DEFAULT '0000-00-00',
  `blocked` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `activated` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `expired` date NOT NULL DEFAULT '0000-00-00',
  `total_time` int(10) NOT NULL DEFAULT '0',
  `total_traffic` bigint(15) NOT NULL DEFAULT '0',
  `total_money` double(20,6) NOT NULL DEFAULT '0.000000',
  `last_connection` date NOT NULL DEFAULT '0000-00-00',
  `framed_ip` char(16) NOT NULL,
  `framed_mask` char(16) NOT NULL DEFAULT '255.255.255.255',
  `callback_number` char(64) NOT NULL,
  `local_ip` char(16) NOT NULL DEFAULT '10.0.',
  `local_mac` char(22) DEFAULT NULL,
  `sectorid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `create_mail` smallint(2) unsigned NOT NULL DEFAULT '1',
  `user_installed` smallint(2) unsigned NOT NULL DEFAULT '1',
  `speed_rate` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_burst` int(10) unsigned NOT NULL DEFAULT '0',
  `gidd` smallint(5) unsigned NOT NULL DEFAULT '0',
  `link_to_ip_mac` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `email` char(64) DEFAULT NULL,
  `passportserie` char(16) DEFAULT NULL,
  `passportpropiska` char(128) DEFAULT NULL,
  `passportvoenkomat` char(128) DEFAULT NULL,
  `passportgdevidan` char(128) DEFAULT NULL,
  `inn` char(64) DEFAULT NULL,
  `real_ip` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `real_price` double(20,6) NOT NULL DEFAULT '0.000000',
  `real_ipfree` tinyint(3) NOT NULL DEFAULT '0',
  `dogovor` tinyint(2) NOT NULL DEFAULT '0',
  `credit_procent` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `rating` smallint(6) NOT NULL DEFAULT '0',
  `mob_tel` char(32) DEFAULT NULL,
  `sms_tel` char(32) DEFAULT NULL,
  `date_birth` date DEFAULT '0000-00-00',
  `date_birth_do` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `languarddisable` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `credit_unlimited` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `dontshowspeed` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `numdogovor` char(16) DEFAULT NULL,
  `app` char(4) NOT NULL,
  `switchport` int(2) unsigned DEFAULT '0',
  `houseid` int(14) unsigned NOT NULL DEFAULT '1',
  `housingid` int(14) unsigned NOT NULL,
  `houseblockid` int(14) unsigned NOT NULL,
  `porch` int(14) unsigned NOT NULL,
  `floor` int(14) unsigned NOT NULL,
  `swid` int(10) unsigned DEFAULT NULL,
  `use_router` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_model` char(16) NOT NULL,
  `router_login` char(16) NOT NULL,
  `router_pass` char(16) NOT NULL,
  `router_ssid` char(16) NOT NULL,
  `router_wep_pass` char(16) NOT NULL,
  `router_we_saled` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_use_dual` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_add_date` char(10) NOT NULL DEFAULT '00/00/0000',
  `router_serial` char(16) NOT NULL,
  `router_port` char(16) NOT NULL DEFAULT '8080',
  `credit_stop` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `date_abonka` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `mac_reg` tinyint(2) NOT NULL DEFAULT '0',
  `fixed_cost` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  UNIQUE KEY `uname` (`user`),
  KEY `gid` (`gid`),
  KEY `gidd` (`gidd`),
  KEY `mrtgusname` (`user`,`uid`),
  KEY `sectorid` (`sectorid`),
  KEY `swid` (`swid`),
  KEY `swid-port` (`swid`,`switchport`),
  KEY `swport` (`switchport`)
) ENGINE=InnoDB  DEFAULT CHARSET=koi8r AVG_ROW_LENGTH=3276 ROW_FORMAT=DYNAMIC AUTO_INCREMENT=8 ;

--
-- Дамп данных таблицы `users`
--

INSERT INTO `users` (`user`, `password`, `crypt_method`, `uid`, `gid`, `deposit`, `credit`, `fio`, `phone`, `address`, `prim`, `add_date`, `blocked`, `activated`, `expired`, `total_time`, `total_traffic`, `total_money`, `last_connection`, `framed_ip`, `framed_mask`, `callback_number`, `local_ip`, `local_mac`, `sectorid`, `create_mail`, `user_installed`, `speed_rate`, `speed_burst`, `gidd`, `link_to_ip_mac`, `email`, `passportserie`, `passportpropiska`, `passportvoenkomat`, `passportgdevidan`, `inn`, `real_ip`, `real_price`, `real_ipfree`, `dogovor`, `credit_procent`, `rating`, `mob_tel`, `sms_tel`, `date_birth`, `date_birth_do`, `languarddisable`, `credit_unlimited`, `dontshowspeed`, `numdogovor`, `app`, `switchport`, `houseid`, `housingid`, `houseblockid`, `porch`, `floor`, `swid`, `use_router`, `router_model`, `router_login`, `router_pass`, `router_ssid`, `router_wep_pass`, `router_we_saled`, `router_use_dual`, `router_add_date`, `router_serial`, `router_port`, `credit_stop`, `date_abonka`, `mac_reg`, `fixed_cost`) VALUES
('test', 'sest', 0, 7, 2, 0.000000, 0.00, '', '', '', '', '2013-07-19', 0, 1, '0000-00-00', 0, 0, 0.000000, '0000-00-00', '172.16.124.6', '255.255.255.255', '', '192.168.124.6', NULL, 2, 1, 1, 0, 0, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.000000, 0, 0, 0, 0, NULL, NULL, '0000-00-00', 0, 0, 0, 0, NULL, '', 0, 2, 0, 0, 0, 0, NULL, 0, '', '', '', '', '', 0, 0, '00/00/0000', '', '8080', 0, 1, 0, 0);

-- --------------------------------------------------------

--
-- Структура таблицы `usersblok`
--

CREATE TABLE IF NOT EXISTS `usersblok` (
  `blockid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `password` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '*',
  `crypt_method` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `uid` bigint(16) unsigned NOT NULL,
  `gid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `deposit` double(20,6) NOT NULL DEFAULT '0.000000',
  `credit` double(20,2) NOT NULL DEFAULT '0.00',
  `fio` varchar(128) NOT NULL,
  `phone` varchar(128) NOT NULL,
  `address` varchar(128) NOT NULL,
  `prim` varchar(254) NOT NULL,
  `add_date` date NOT NULL DEFAULT '0000-00-00',
  `blocked` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `activated` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `expired` date NOT NULL DEFAULT '0000-00-00',
  `total_time` int(10) NOT NULL DEFAULT '0',
  `total_traffic` bigint(15) NOT NULL DEFAULT '0',
  `total_money` double(20,6) NOT NULL DEFAULT '0.000000',
  `last_connection` date NOT NULL DEFAULT '0000-00-00',
  `framed_ip` varchar(16) NOT NULL,
  `framed_mask` varchar(16) NOT NULL DEFAULT '255.255.255.255',
  `callback_number` varchar(64) NOT NULL,
  `local_ip` varchar(16) NOT NULL DEFAULT '10.0.',
  `local_mac` varchar(22) DEFAULT NULL,
  `sectorid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `create_mail` smallint(2) unsigned NOT NULL DEFAULT '1',
  `user_installed` smallint(2) unsigned NOT NULL DEFAULT '1',
  `speed_rate` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_burst` int(10) unsigned NOT NULL DEFAULT '0',
  `gidd` smallint(5) unsigned NOT NULL DEFAULT '0',
  `link_to_ip_mac` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `email` varchar(64) DEFAULT NULL,
  `passportserie` varchar(16) DEFAULT NULL,
  `passportpropiska` varchar(128) DEFAULT NULL,
  `passportvoenkomat` varchar(128) DEFAULT NULL,
  `passportgdevidan` varchar(128) DEFAULT NULL,
  `inn` varchar(64) DEFAULT NULL,
  `real_ip` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `real_price` double(20,6) NOT NULL DEFAULT '0.000000',
  `real_ipfree` tinyint(3) NOT NULL DEFAULT '0',
  `dogovor` tinyint(2) NOT NULL DEFAULT '0',
  `credit_procent` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `rating` smallint(6) NOT NULL DEFAULT '0',
  `block_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mob_tel` varchar(32) DEFAULT NULL,
  `sms_tel` varchar(32) DEFAULT NULL,
  `date_birth` date DEFAULT '0000-00-00',
  `date_birth_do` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `languarddisable` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `credit_unlimited` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `dontshowspeed` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `numdogovor` varchar(16) DEFAULT NULL,
  `app` varchar(4) NOT NULL,
  `switchport` int(2) unsigned DEFAULT '0',
  `houseid` int(14) unsigned NOT NULL,
  `housingid` int(14) unsigned NOT NULL,
  `houseblockid` int(14) unsigned NOT NULL,
  `porch` int(14) unsigned NOT NULL DEFAULT '1',
  `floor` int(14) unsigned NOT NULL,
  `swid` int(10) unsigned DEFAULT '1',
  `use_router` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_model` varchar(16) NOT NULL,
  `router_login` varchar(16) NOT NULL,
  `router_pass` varchar(16) NOT NULL,
  `router_ssid` varchar(16) NOT NULL,
  `router_wep_pass` varchar(16) NOT NULL,
  `router_we_saled` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_use_dual` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_add_date` varchar(10) NOT NULL DEFAULT '00/00/0000',
  `router_serial` varchar(16) NOT NULL,
  `router_port` varchar(16) NOT NULL DEFAULT '8080',
  `credit_stop` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `date_abonka` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `mac_reg` tinyint(2) NOT NULL DEFAULT '0',
  `fixed_cost` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`blockid`),
  UNIQUE KEY `uname` (`user`),
  KEY `gid` (`gid`),
  KEY `gidd` (`gidd`),
  KEY `mrtgusname` (`user`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `usersdel`
--

CREATE TABLE IF NOT EXISTS `usersdel` (
  `delid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `password` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '*',
  `crypt_method` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `uid` bigint(16) unsigned NOT NULL,
  `gid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `deposit` double(20,6) NOT NULL DEFAULT '0.000000',
  `credit` double(20,2) NOT NULL DEFAULT '0.00',
  `fio` varchar(128) NOT NULL,
  `phone` varchar(128) NOT NULL,
  `address` varchar(128) NOT NULL,
  `prim` varchar(254) NOT NULL,
  `add_date` date NOT NULL DEFAULT '0000-00-00',
  `blocked` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `activated` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `expired` date NOT NULL DEFAULT '0000-00-00',
  `total_time` int(10) NOT NULL DEFAULT '0',
  `total_traffic` bigint(15) NOT NULL DEFAULT '0',
  `total_money` double(20,6) NOT NULL DEFAULT '0.000000',
  `last_connection` date NOT NULL DEFAULT '0000-00-00',
  `framed_ip` varchar(16) NOT NULL,
  `framed_mask` varchar(16) NOT NULL DEFAULT '255.255.255.255',
  `callback_number` varchar(64) NOT NULL,
  `local_ip` varchar(16) NOT NULL DEFAULT '10.0.',
  `local_mac` varchar(22) DEFAULT NULL,
  `sectorid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `create_mail` smallint(2) unsigned NOT NULL DEFAULT '1',
  `user_installed` smallint(2) unsigned NOT NULL DEFAULT '1',
  `speed_rate` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_burst` int(10) unsigned NOT NULL DEFAULT '0',
  `gidd` smallint(5) unsigned NOT NULL DEFAULT '0',
  `link_to_ip_mac` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `email` varchar(64) DEFAULT NULL,
  `passportserie` varchar(16) DEFAULT NULL,
  `passportpropiska` varchar(128) DEFAULT NULL,
  `passportvoenkomat` varchar(128) DEFAULT NULL,
  `passportgdevidan` varchar(128) DEFAULT NULL,
  `inn` varchar(64) DEFAULT NULL,
  `real_ip` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `real_price` double(20,6) NOT NULL DEFAULT '0.000000',
  `real_ipfree` tinyint(3) NOT NULL DEFAULT '0',
  `dogovor` tinyint(2) NOT NULL DEFAULT '0',
  `credit_procent` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `rating` smallint(6) NOT NULL DEFAULT '0',
  `block_date` datetime DEFAULT NULL,
  `del_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mob_tel` varchar(32) DEFAULT NULL,
  `sms_tel` varchar(32) DEFAULT NULL,
  `date_birth` date DEFAULT '0000-00-00',
  `date_birth_do` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `languarddisable` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `credit_unlimited` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `dontshowspeed` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `numdogovor` varchar(16) DEFAULT NULL,
  `app` varchar(4) NOT NULL,
  `switchport` int(2) unsigned DEFAULT '0',
  `houseid` int(14) unsigned NOT NULL,
  `housingid` int(14) unsigned NOT NULL,
  `houseblockid` int(14) unsigned NOT NULL,
  `porch` int(14) unsigned NOT NULL,
  `floor` int(14) unsigned NOT NULL,
  `swid` int(10) unsigned DEFAULT '0',
  `use_router` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_model` varchar(16) NOT NULL,
  `router_login` varchar(16) NOT NULL,
  `router_pass` varchar(16) NOT NULL,
  `router_ssid` varchar(16) NOT NULL,
  `router_wep_pass` varchar(16) NOT NULL,
  `router_we_saled` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_use_dual` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_add_date` varchar(10) NOT NULL DEFAULT '00/00/0000',
  `router_serial` varchar(16) NOT NULL,
  `router_port` varchar(16) NOT NULL DEFAULT '8080',
  `credit_stop` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `date_abonka` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `mac_reg` tinyint(2) NOT NULL DEFAULT '0',
  `fixed_cost` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`delid`),
  UNIQUE KEY `uname` (`user`),
  KEY `gid` (`gid`),
  KEY `gidd` (`gidd`),
  KEY `mrtgusname` (`user`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `usersfreeze`
--

CREATE TABLE IF NOT EXISTS `usersfreeze` (
  `freezeid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL,
  `password` varchar(32) CHARACTER SET koi8r COLLATE koi8r_bin NOT NULL DEFAULT '*',
  `crypt_method` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `uid` bigint(16) unsigned NOT NULL,
  `gid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `deposit` double(20,6) NOT NULL DEFAULT '0.000000',
  `credit` double(20,2) NOT NULL DEFAULT '0.00',
  `fio` varchar(128) NOT NULL,
  `phone` varchar(128) NOT NULL,
  `address` varchar(128) NOT NULL,
  `prim` varchar(254) NOT NULL,
  `add_date` date NOT NULL DEFAULT '0000-00-00',
  `blocked` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `activated` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `expired` date NOT NULL DEFAULT '0000-00-00',
  `total_time` int(10) NOT NULL DEFAULT '0',
  `total_traffic` bigint(15) NOT NULL DEFAULT '0',
  `total_money` double(20,6) NOT NULL DEFAULT '0.000000',
  `last_connection` date NOT NULL DEFAULT '0000-00-00',
  `framed_ip` varchar(16) NOT NULL,
  `framed_mask` varchar(16) NOT NULL DEFAULT '255.255.255.255',
  `callback_number` varchar(64) NOT NULL,
  `local_ip` varchar(16) NOT NULL DEFAULT '10.0.',
  `local_mac` varchar(22) DEFAULT NULL,
  `sectorid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `create_mail` smallint(2) unsigned NOT NULL DEFAULT '1',
  `user_installed` smallint(2) unsigned NOT NULL DEFAULT '1',
  `speed_rate` int(10) unsigned NOT NULL DEFAULT '0',
  `speed_burst` int(10) unsigned NOT NULL DEFAULT '0',
  `gidd` smallint(5) unsigned NOT NULL DEFAULT '0',
  `link_to_ip_mac` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `email` varchar(64) DEFAULT NULL,
  `passportserie` varchar(16) DEFAULT NULL,
  `passportpropiska` varchar(128) DEFAULT NULL,
  `passportvoenkomat` varchar(128) DEFAULT NULL,
  `passportgdevidan` varchar(128) DEFAULT NULL,
  `inn` varchar(64) DEFAULT NULL,
  `real_ip` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `real_price` double(20,6) NOT NULL DEFAULT '0.000000',
  `real_ipfree` tinyint(3) NOT NULL DEFAULT '0',
  `dogovor` tinyint(2) NOT NULL DEFAULT '0',
  `credit_procent` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `rating` smallint(6) NOT NULL DEFAULT '0',
  `mob_tel` varchar(32) DEFAULT NULL,
  `sms_tel` varchar(32) DEFAULT NULL,
  `date_birth` date DEFAULT '0000-00-00',
  `date_birth_do` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `languarddisable` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `credit_unlimited` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `dontshowspeed` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `numdogovor` varchar(16) DEFAULT NULL,
  `app` varchar(4) NOT NULL,
  `switchport` int(2) unsigned DEFAULT '0',
  `houseid` int(14) unsigned NOT NULL,
  `housingid` int(14) unsigned NOT NULL,
  `houseblockid` int(14) unsigned NOT NULL,
  `porch` int(14) unsigned NOT NULL,
  `floor` int(14) unsigned NOT NULL,
  `swid` int(10) unsigned DEFAULT '0',
  `use_router` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_model` varchar(16) NOT NULL,
  `router_login` varchar(16) NOT NULL,
  `router_pass` varchar(16) NOT NULL,
  `router_ssid` varchar(16) NOT NULL,
  `router_wep_pass` varchar(16) NOT NULL,
  `router_we_saled` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_use_dual` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `router_add_date` varchar(10) NOT NULL DEFAULT '00/00/0000',
  `router_serial` varchar(16) NOT NULL,
  `router_port` varchar(16) NOT NULL DEFAULT '8080',
  `unfreeze_date` date NOT NULL DEFAULT '0000-00-00',
  `freeze_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `credit_stop` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `date_abonka` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `mac_reg` tinyint(2) NOT NULL DEFAULT '0',
  `fixed_cost` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`freezeid`),
  UNIQUE KEY `uname` (`user`),
  KEY `gid` (`gid`),
  KEY `gidd` (`gidd`),
  KEY `mrtgusname` (`user`,`uid`)
) ENGINE=InnoDB  DEFAULT CHARSET=koi8r AUTO_INCREMENT=2 ;

-- --------------------------------------------------------

--
-- Структура таблицы `users_custom_fields`
--

CREATE TABLE IF NOT EXISTS `users_custom_fields` (
  `uid` bigint(16) unsigned NOT NULL,
  `key` varchar(32) COLLATE utf8_bin NOT NULL,
  `value` varchar(128) COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`uid`,`key`),
  UNIQUE KEY `full` (`uid`,`key`,`value`),
  KEY `search` (`key`,`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Custom users fields';

-- --------------------------------------------------------

--
-- Структура таблицы `white_list_srv`
--

CREATE TABLE IF NOT EXISTS `white_list_srv` (
  `srvid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serv` varchar(64) NOT NULL,
  `mikrotik` tinyint(1) NOT NULL DEFAULT '0',
  `ip` char(32) NOT NULL,
  `login` varchar(64) NOT NULL,
  `pass` varchar(64) NOT NULL,
  `disable` tinyint(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`srvid`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Структура таблицы `white_list_srv_ip`
--

CREATE TABLE IF NOT EXISTS `white_list_srv_ip` (
  `white_ip` char(32) NOT NULL DEFAULT '',
  `action` tinyint(2) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`white_ip`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r;

-- --------------------------------------------------------

--
-- Структура для представления `actions`
--
DROP TABLE IF EXISTS `actions`;

CREATE VIEW `actions` AS select `radacct`.`username` AS `user`,`radacct`.`gid` AS `gid`,`radacct`.`acctsessionid` AS `id`,`radacct`.`acctuniqueid` AS `unique_id`,`radacct`.`acctsessiontime` AS `time_on`,`radacct`.`acctstarttime` AS `start_time`,`radacct`.`acctstoptime` AS `stop_time`,`radacct`.`acctinputoctets` AS `in_bytes`,`radacct`.`acctoutputoctets` AS `out_bytes`,`radacct`.`framedipaddress` AS `ip`,`radacct`.`nasipaddress` AS `server`,`radacct`.`nasipaddress` AS `client_ip`,`radacct`.`calledstationid` AS `call_to`,`radacct`.`callingstationid` AS `call_from`,_utf8'' AS `connect_info`,`radacct`.`acctterminatecause` AS `terminate_cause`,`radacct`.`last_change` AS `last_change`,`radacct`.`before_billing` AS `before_billing`,`radacct`.`billing_minus` AS `billing_minus` from `radacct` where 1;

-- --------------------------------------------------------

--
-- Структура для представления `inetonline`
--
DROP TABLE IF EXISTS `inetonline`;

CREATE VIEW `inetonline` AS select `radacct`.`gid` AS `gid`,`radacct`.`uid` AS `uid`,`radacct`.`username` AS `user`,`radacct`.`nasportid` AS `port`,`radacct`.`nasipaddress` AS `server`,`radacct`.`framedipaddress` AS `ip`,`radacct`.`callingstationid` AS `call_from`,date_format(`radacct`.`acctstarttime`,_utf8'%d %b, %H:%i:%s') AS `fstart_time`,`radacct`.`acctsessiontime` AS `time_on`,`radacct`.`acctinputoctets` AS `in_bytes`,`radacct`.`acctoutputoctets` AS `out_bytes`,`radacct`.`billing_minus` AS `billing_minus` from `radacct` where (`radacct`.`acctterminatecause` = _koi8r'Online');

-- --------------------------------------------------------

--
-- Структура для представления `inetonlinenew`
--
DROP TABLE IF EXISTS `inetonlinenew`;

CREATE VIEW `inetonlinenew` AS select `radacct`.`radacctid` AS `radacctid`,`radacct`.`acctsessionid` AS `acctsessionid`,`radacct`.`acctuniqueid` AS `acctuniqueid`,`radacct`.`username` AS `username`,`radacct`.`uid` AS `uid`,`radacct`.`gid` AS `gid`,`radacct`.`nasipaddress` AS `nasipaddress`,`radacct`.`nasportid` AS `nasportid`,`radacct`.`acctstarttime` AS `acctstarttime`,`radacct`.`acctstoptime` AS `acctstoptime`,`radacct`.`acctsessiontime` AS `acctsessiontime`,`radacct`.`acctinputoctets` AS `acctinputoctets`,`radacct`.`acctoutputoctets` AS `acctoutputoctets`,`radacct`.`calledstationid` AS `calledstationid`,`radacct`.`callingstationid` AS `callingstationid`,`radacct`.`acctterminatecause` AS `acctterminatecause`,`radacct`.`framedipaddress` AS `framedipaddress`,`radacct`.`last_change` AS `last_change`,`radacct`.`before_billing` AS `before_billing`,`radacct`.`billing_minus` AS `billing_minus` from `radacct` where (`radacct`.`acctterminatecause` = _koi8r'Online');

-- --------------------------------------------------------

--
-- Структура для представления `inetonlinewithspeed`
--
DROP TABLE IF EXISTS `inetonlinewithspeed`;

CREATE VIEW `inetonlinewithspeed` AS select `radacct`.`radacctid` AS `radacctid`,`radacct`.`acctsessionid` AS `acctsessionid`,`radacct`.`acctuniqueid` AS `acctuniqueid`,`radacct`.`username` AS `username`,`radacct`.`uid` AS `uid`,`radacct`.`gid` AS `gid`,`radacct`.`nasipaddress` AS `nasipaddress`,`radacct`.`nasportid` AS `nasportid`,`radacct`.`acctstarttime` AS `acctstarttime`,`radacct`.`acctstoptime` AS `acctstoptime`,`radacct`.`acctsessiontime` AS `acctsessiontime`,`radacct`.`acctinputoctets` AS `acctinputoctets`,`radacct`.`acctoutputoctets` AS `acctoutputoctets`,`radacct`.`calledstationid` AS `calledstationid`,`radacct`.`callingstationid` AS `callingstationid`,`radacct`.`acctterminatecause` AS `acctterminatecause`,`radacct`.`framedipaddress` AS `framedipaddress`,`radacct`.`last_change` AS `last_change`,`radacct`.`before_billing` AS `before_billing`,`radacct`.`billing_minus` AS `billing_minus`,`users`.`speed_rate` AS `user_speed_in`,`users`.`speed_burst` AS `user_speed_out`,`packets`.`do_mik_rad_shapers` AS `use_radius_shaper`,`packets`.`speed_rate` AS `tarif_speed_in`,`packets`.`speed_burst` AS `tarif_speed_out`,`packets`.`shaper_prio` AS `tarif_shaper_prio` from ((`radacct` join `users`) join `packets`) where ((`radacct`.`acctterminatecause` = _koi8r'Online') and (`radacct`.`gid` = `users`.`gid`) and (`radacct`.`gid` = `packets`.`gid`) and (`radacct`.`uid` = `users`.`uid`) and (`users`.`gid` = `packets`.`gid`)) group by `radacct`.`uid`;

-- --------------------------------------------------------

--
-- Структура для представления `inetspeedlist`
--
DROP TABLE IF EXISTS `inetspeedlist`;

CREATE VIEW `inetspeedlist` AS select `users`.`user` AS `username`,`users`.`framed_ip` AS `framedipaddress`,`users`.`local_ip` AS `local_ip`,`users`.`speed_rate` AS `user_speed_in`,`users`.`speed_burst` AS `user_speed_out`,`packets`.`speed_rate` AS `tarif_speed_in`,`packets`.`speed_rate` AS `tarif_speed_out` from (`users` join `packets`) where (`users`.`gid` = `packets`.`gid`);

-- --------------------------------------------------------

--
-- Структура для представления `ip_pools_counts`
--
DROP TABLE IF EXISTS `ip_pools_counts`;

CREATE VIEW `ip_pools_counts` AS select `b`.`poolname` AS `poolname`,`a`.`poolid` AS `poolid`,count(distinct `a`.`poolip`) AS `ipfree`,count(distinct `c`.`poolip`) AS `ipuse` from ((`ip_pools_pool` `a` join `ip_pools` `b`) join `ip_pools_pool_use` `c`) where ((`a`.`poolid` = `b`.`poolid`) and (`b`.`poolid` = `c`.`poolid`)) group by `a`.`poolid`;

-- --------------------------------------------------------

--
-- Структура для представления `map_online`
--
DROP TABLE IF EXISTS `map_online`;

CREATE VIEW `map_online` AS select `radacct`.`radacctid` AS `radacctid`,`radacct`.`acctsessionid` AS `acctsessionid`,`radacct`.`acctuniqueid` AS `acctuniqueid`,`radacct`.`username` AS `username`,`radacct`.`uid` AS `uid`,`radacct`.`gid` AS `gid`,`radacct`.`nasipaddress` AS `nasipaddress`,`radacct`.`nasportid` AS `nasportid`,`radacct`.`acctstarttime` AS `acctstarttime`,`radacct`.`acctstoptime` AS `acctstoptime`,`radacct`.`acctsessiontime` AS `acctsessiontime`,`radacct`.`acctinputoctets` AS `acctinputoctets`,`radacct`.`acctoutputoctets` AS `acctoutputoctets`,`radacct`.`calledstationid` AS `calledstationid`,`radacct`.`callingstationid` AS `callingstationid`,`radacct`.`acctterminatecause` AS `acctterminatecause`,`radacct`.`framedipaddress` AS `framedipaddress`,`radacct`.`last_change` AS `last_change`,`radacct`.`before_billing` AS `before_billing`,`radacct`.`billing_minus` AS `billing_minus`,`users`.`app` AS `app`,`users`.`swid` AS `swid`,`users`.`switchport` AS `switchport`,`users`.`houseid` AS `houseid`,`users`.`speed_rate` AS `user_speed_in`,`users`.`speed_burst` AS `user_speed_out`,`packets`.`do_mik_rad_shapers` AS `use_radius_shaper`,`packets`.`speed_rate` AS `tarif_speed_in`,`packets`.`speed_burst` AS `tarif_speed_out`,`packets`.`shaper_prio` AS `tarif_shaper_prio` from ((`radacct` join `users`) join `packets`) where ((`radacct`.`acctterminatecause` = _koi8r'Online') and (`radacct`.`gid` = `users`.`gid`) and (`radacct`.`gid` = `packets`.`gid`) and (`radacct`.`uid` = `users`.`uid`) and (`users`.`gid` = `packets`.`gid`)) group by `radacct`.`uid`;

-- --------------------------------------------------------

--
-- Структура для представления `radpostauth`
--
DROP TABLE IF EXISTS `radpostauth`;

CREATE VIEW `radpostauth` AS select `radpostauthnew`.`id` AS `id`,`radpostauthnew`.`username` AS `username`,`radpostauthnew`.`pass` AS `pass`,`radpostauthpackettype`.`packettype` AS `packettype`,`radpostauthreplymessage`.`replymessage` AS `replymessage`,`radnas`.`nasname` AS `nasipaddress`,`radpostauthnew`.`nasportid` AS `nasportid`,`radnas`.`shortname` AS `nasident`,`radpostauthnew`.`callingstationid` AS `callingstationid`,`radpostauthnew`.`authdate` AS `authdate` from (((`radpostauthnew` join `radpostauthpackettype`) join `radpostauthreplymessage`) join `radnas`) where ((`radpostauthnew`.`packettypeid` = `radpostauthpackettype`.`packettypeid`) and (`radpostauthnew`.`replymessageid` = `radpostauthreplymessage`.`replymessageid`) and (`radnas`.`id` = `radpostauthnew`.`nasid`));

ALTER TABLE `lanes_houses` CHANGE `neighborhoodid` `neighborhoodid` INT( 10 ) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `lanes_neighborhoods` CHANGE `settlementid` `settlementid` INT( 14 ) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `lanes` CHANGE `settlementid` `settlementid` INT( 14 ) UNSIGNED NOT NULL DEFAULT '0';

UPDATE `lanes` SET `settlementid`=0 WHERE 1;
UPDATE `lanes_houses` SET `neighborhoodid`=0 WHERE 1;
UPDATE `lanes_neighborhoods` SET `settlementid`=0 WHERE 1;

UPDATE `bugh_plategi_type` SET `typename` = 'Оплата заморозки' WHERE `bugh_plategi_type`.`bughtypeid` =39;


--
-- Создать таблицу packets_rad_attr
--
CREATE TABLE packets_rad_attr (
  gid SMALLINT(5) UNSIGNED NOT NULL,
  `key` VARCHAR(32) NOT NULL,
  value VARCHAR(255) NOT NULL DEFAULT '',
  INDEX gid (gid),
  INDEX `gid-key` (gid, `key`),
  INDEX `key` (`key`)
)
ENGINE = MYISAM
CHARACTER SET koi8r
COLLATE koi8r_bin;

--
-- Создать таблицу switch_opt82_logs
--
CREATE TABLE switch_opt82_logs (
  logid INT(14) UNSIGNED NOT NULL AUTO_INCREMENT,
  timedate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  uid INT(10) UNSIGNED NOT NULL,
  user_mac CHAR(17) NOT NULL,
  vlan INT(6) UNSIGNED NOT NULL,
  user_port INT(4) UNSIGNED NOT NULL,
  swid INT(14) UNSIGNED NOT NULL,
  logtypeid SMALLINT(10) UNSIGNED NOT NULL,
  swid_mac CHAR(17) NOT NULL,
  switch_circuit_id VARCHAR(64) NOT NULL,
  switch_remote_id VARCHAR(64) NOT NULL,
  PRIMARY KEY (logid),
  KEY `uid` (`uid`),
  KEY `time` (`timedate`),
  KEY `mac` (`user_mac`),
  KEY `swid` (`swid`)
)
ENGINE = MYISAM
CHARACTER SET koi8r
COLLATE koi8r_general_ci;

--
-- Создать таблицу switch_opt82_logtype
--
CREATE TABLE switch_opt82_logtype (
  logtypeid TINYINT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  logtype CHAR(64) NOT NULL,
  access INT(1) UNSIGNED NOT NULL,
  PRIMARY KEY (logtypeid)
)
ENGINE = MYISAM
CHARACTER SET koi8r
COLLATE koi8r_general_ci;

--
-- Изменить таблицу switches
--
ALTER TABLE switches
  CHANGE COLUMN ip ip CHAR(16) NOT NULL,
  ADD COLUMN parent_swid INT(10) UNSIGNED NOT NULL DEFAULT 0 AFTER external_web_url;

DELIMITER $$

--
-- Создать процедуру do_switch_opt82_log
--
CREATE PROCEDURE do_switch_opt82_log(IN `uid` int, IN `user_mac` varchar(17), IN `vlan` int(5), IN `user_port` int(4), IN `swid` int, IN `logtypeid` smallint(10), IN `swid_mac` varchar(17), IN `switch_circuit_id` varchar(64), IN `switch_remote_id` varchar(64))
  DETERMINISTIC
  COMMENT 'Выполнить логирование события в ядре по DHCP Option 82'
BEGIN
  INSERT INTO `switch_opt82_logs`
    VALUES (NULL, CURRENT_TIMESTAMP, `uid`, `user_mac`, `vlan`, `user_port`, `swid`, `logtypeid`, `swid_mac`, `switch_circuit_id`, `switch_remote_id`);
END
$$

DELIMITER ;

UPDATE `switches` SET `ip` = '' WHERE `ip` IS NULL;

--
-- Изменить таблицу stuff_personal
--
ALTER TABLE stuff_personal
  ADD COLUMN usersgroupid INT(5) UNSIGNED NOT NULL DEFAULT 0 AFTER do_simple_online;

ALTER TABLE stuff_personal
  ADD INDEX usersgroupid (usersgroupid);

--
-- Создать таблицу stuff_usersgroups
--
CREATE TABLE stuff_usersgroups (
  usersgroupid INT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  usersgroupname VARCHAR(32) NOT NULL,
  UNIQUE INDEX usersgroupid (usersgroupid)
)
ENGINE = MYISAM
CHARACTER SET koi8r
COLLATE koi8r_general_ci;

--
-- Создать таблицу stuff_usersgroups_permissions
--
CREATE TABLE stuff_usersgroups_permissions (
  usersgroupid INT(5) UNSIGNED NOT NULL,
  `key` INT(1) UNSIGNED NOT NULL,
  value INT(16) UNSIGNED NOT NULL,
  INDEX `key` (`key`),
  INDEX usersgroupid (usersgroupid),
  INDEX value (value)
)
ENGINE = MYISAM
CHARACTER SET koi8r
COLLATE koi8r_general_ci;


INSERT INTO `switch_opt82_logtype` (`logtypeid`, `logtype`, `access`) VALUES
(1, 'В запросе отсутствует MAC абонента', 0),
(2, 'Нет DHCP-Relay-Circuit-Id или DHCP-Relay-Remote-Id, поиск по MAC', 1),
(3, 'Не обнаружено устройство по MAC', 0),
(4, 'Не обнаружена пара vlan, parent_swid', 0),
(5, 'unnumbered - пользователь найден', 1),
(6, 'autoreg port by MAC - пользователь найден', 1),
(7, 'port, swid, MAC - пользователь найден', 1),
(8, 'регистрация по MAC - пользователь найден', 1),
(9, 'unnumbered - пользователь не найден', 0),
(10, 'autoreg port by MAC - пользователь не найден', 0),
(11, 'port, swid, MAC - пользователь не найден', 0),
(12, 'регистрация по MAC - пользователь не найден', 0),
(13, 'Нет Remote-Id/-Circuit-Id: пользователь по MAC не найден', 0);



CREATE TABLE IF NOT EXISTS `changelog` (
  `change_number` bigint(20) NOT NULL,
    `delta_set` varchar(10) NOT NULL,
      `start_dt` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
        `complete_dt` timestamp NULL default NULL,
          `applied_by` varchar(100) NOT NULL,
            `description` varchar(500) NOT NULL,
              PRIMARY KEY  (`change_number`,`delta_set`)
              ) ENGINE=MyISAM DEFAULT CHARSET=koi8r; 



/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
