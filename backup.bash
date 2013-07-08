#!/bin/bash


mkdir -p /home/www/backup/$1
cd /home/www/backup/$1

file=${1}_`date +"%Y-%m-%d"`.sql


mysqldump -u root -pPassword ${1} > ${file}

tar -cvzf "${file}.tar.gz" "${file}"

rm "${file}"


find /home/www/backup/$1/* -mtime +14 -exec rm {} \;
