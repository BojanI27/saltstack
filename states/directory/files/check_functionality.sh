#!/bin/bash
#
# CHECK SCRIPT FOR VA-DIRECTORY

exitstate=0
text=""

OUT=`sudo pdbedit -Lv | grep 'administratively locked out' | wc -l`
if [ $OUT -eq 0 ];then
   text=$text"No locked users"
else
    text=$text"Locked accounts: $OUT!"
   exitstate=1
fi

OUT=`wbinfo -u | wc -l`
if [ $OUT -eq 0 ];then
    text=$text', '"No users!"
   exitstate=2
else
    text=$text', '"Users: $OUT"
fi

OUT=`sudo samba-tool group list | wc -l`
if [ $OUT -eq 0 ];then
    text=$text', '"No groups!"
   exitstate=2
else
    text=$text', '"Groups: $OUT"
fi
#OUT=`cat /etc/passwd | wc -l`
#if [ $OUT -eq 0 ];then
#    text=$text', '"No local users!"
#   exitstate=2
#else
#   text=$text', '"Unix users: $OUT"
#fi


#OUT=`netstat -ntap |grep '1024' | wc -l`
#if [ $OUT -eq 0 ];then
#    text=$text', '"Replication port down!"
#   exitstate=2
#else
#    text=$text', '"Replication port OK"
#fi


sudo samba-tool dbcheck -d 0  > /dev/null
OUT=$?
if [ $OUT -eq 0 ];then
    text=$text #', '"Database OK"
else
    text=$text', '"Database corrupted!"
   exitstate=2
fi

sudo samba-tool drs kcc -d 0 > /dev/null
OUT=$?
if [ $OUT -eq 0 ];then
    text=$text', '"Consistency OK"
else
    text=$text', '"Consistency problem!"
   exitstate=2
fi

OUT=`sudo samba-tool drs showrepl | grep 'Last attempt @' | grep 'failed, result' | wc -l`
if [ $OUT -eq 0 ];then
    text=$text', '"Replication OK"
else
    text=$text', '$OUT "Replication problem(s)!"
   exitstate=2
fi

smbclient -L $(hostname) -N -d 0 > /dev/null
OUT=$?
if [ $OUT -eq 0 ];then
    text=$text', '"Shares OK"
else
    text=$text', '"Shares problem!"
   exitstate=2
fi

smbstatus -d 0 > /dev/null
OUT=$?
if [ $OUT -eq 0 ];then
    text=$text', '"Samba status OK"
else
    text=$text', '"Samba status problem!"
   exitstate=2
fi

DNS1=`nslookup $(hostname) | grep 'Address: ' | md5sum | awk -F " " '{print $1}'`
DNS2=`nslookup $(samba-tool domain info $(hostname) | grep 'DC name          :'| sed -e "s/DC name          : //") | grep 'Address: '| md5sum | awk -F " " '{print $1}'`

if [[ $DNS1 == $DNS2 ]]; then
    text=$text #', '"DNS record OK"
else
    text=$text', '"Wrong DNS record for this DC!"
   exitstate=2
fi

echo $text

exit $exitstate
