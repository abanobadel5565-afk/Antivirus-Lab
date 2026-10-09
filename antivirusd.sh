#!/usr/bin/env bash

FLAGGED_EXTENSIONS="exe bat vbs scr ps1"
FLAGGED_KEYWORDS="virus trojan malware worm ransomware"


watchpath=$1
quarantinepath=$2
waitingTime=$3

scan() {
find "$watchpath" -type f | while IFS= read -r file
do
    filename="${file##*/}"
    extension="${filename##*.}"
    malicious="no"
    
for ext in $FLAGGED_EXTENSIONS; do
	if [ "$extension" = "$ext" ]; then 
		malicious="yes"
	fi
done

for key in $FLAGGED_KEYWORDS; do
	if grep -qiaF "$key" "$file"; then 
		malicious="yes"
	fi
done

    if [ "$malicious" = "yes" ]; then
    	echo "$file is malicious and it is DELETED"
    	cp "$file" "$quarantinepath/$filename"
    	rm "$file"
    fi    
done
}

while true
do
    sleep "$waitingTime"

    ls -l "$watchpath" > newDirectoryReport      

    if ! cmp -s newDirectoryReport currentDirectoryReport ; then
     echo "New files have been detected"
     scan
     ls -l "$watchpath" > currentDirectoryReport
    else 
    	echo "Nothing has been detected"
    fi
done

