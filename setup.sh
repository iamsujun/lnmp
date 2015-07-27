#!/bin/sh

#配置路径
softdir=/data/software
appdir=/data/app
tmpdir=/data/tmp
datadir=/data/data

#创建文件夹
mkdir -p /data/{app,tmp,log,bin,conf,data}

#system
groupadd www
useradd -g www www
yum install -y make gcc gcc-c++ lrzsz zip tree

#解压文件
ls $softdir/*.tar.gz | xargs -n1 tar --directory=$tmpdir/ -zxvf

#安装rsync
cd $tmpdir/rsync*
./configure --prefix=$appdir/rsync
make && make install

#安装nginx
yum install -y pcre-devel openssl-devel zlib-devel

cd $tmpdir/nginx*
./configure --prefix=$appdir/nginx --with-http_ssl_module
make && make install

#安装memcached
yum install -y libevent-devel
cd $tmpdir/memcached*
./configure --prefix=$appdir/memcached
make && make install

#安装redis
mv $tmpdir/redis* $appdir/redis
cd $appdir/redis
make

#安装mysql
groupadd mysql
useradd -r -g mysql mysql

mkdir -p $datadir/mysql/data
chown -R mysql:mysql $datadir/mysql
mv $tmpdir/mysql* $appdir/mysql
$appdir/mysql/bin/mysql_install_db --basedir=$appdir/mysql \
	--datadir=$datadir/mysql \
	--user=mysql
cp $appdir/mysql/support-files/mysql.server  /data/bin/mysqld
#sed -i "s#/usr/local/mysql#/data/app/mysql#g" /etc/init.d/mysqld

#安装PHP
yum install -y libxml2-devel curl-devel libpng-devel giflib-devel

cd $tmpdir/php*
./configure --prefix=$appdir/php \
	--with-curl \
	--with-openssl \
	--enable-fpm \
	--enable-mbstring \
	--with-gd \
	--enable-gd-native-ttf \
	--enable-opcache \
	--enable-zip \
	--with-mysql=$appdir/mysql
make && make install

cp ./sapi/fpm/init.d.php-fpm /data/bin/php-fpm
cp php.ini-development $appdir/php/lib/php.ini
cp $appdir/php/etc/php-fpm.conf{.default,}

#安装PHP的memcache扩展
