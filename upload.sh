#!/bin/sh
FILE=`ls -t dist/IPTCInfo-*.tar.gz| head -n 1`
scp $FILE gtmainbox:/var/www/html/python/
wput $FILE ftp://gthomas:goody8@ftp.fw.hu/gthomas/python/
