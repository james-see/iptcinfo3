#!/bin/sh
FILE=`ls -t dist/IPTCInfo-*.tar.gz| head -n 1`
wput $FILE ftp://gthomas:goody8@ftp.fw.hu/gthomas/python/
