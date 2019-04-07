#! /bin/ksh

LOGFILE=/usr/local/scripts/push.cfg.out
push.ksh cfgtable.push 2>&1 | tee $LOGFILE
