#!/bin/ksh

CRONENTRY='5 0 * * 6 /usr/local/scripts/altDiskBkup.ksh >/dev/null 2>&1'

if [ -n `crontab -l |grep altDiskBkup.ksh` ]
then
  echo "altDiskBkup.ksh already in the crontab..."
  echo "Check and cleanup image_1 ..."
  if [ -n `lspv | grep image_1` ]
  then
    echo "Cleanup old image_1 image..."
    /usr/sbin/alt_disk_install -X
    varyoffvg image_1
    exportvg image_1
  else
    echo "No image_1 image..."
  fi
  exit 0
else
  echo "altDiskBkup.ksh is NOT in the crontab..."
  crontab -l > /tmp/tempCron
  echo "5 0 * * 6 /usr/local/scripts/altDiskBkup.ksh >/dev/null 2>&1" >> /tmp/tempCron
  crontab /tmp/tempCron
  cat /tmp/tempCron
  exit 0
fi
