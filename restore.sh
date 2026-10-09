#!/usr/bin/env bash

watchpath=$1
quarantinepath=$2
whitelist="./whitelist"
count=$(ls -A "$quarantinepath" | wc -l)
#taken from AI as a helpful method to count the number of malicious files

if [ "$count" -eq 0 ]; then
    echo "No malicious files to review."
    exit 0
fi

number=1
for name in $(ls -A "$quarantinepath"); 
do
	echo "($number):$name"
	number=$((number + 1))
done

echo "Choose a file:"
read -r choice1
echo "Your choice: $choice1"
	if [ "$choice1" -lt 1 ] || [ "$choice1" -gt "$count" ]; then
		echo "Your Index is out of boundaries"
		exit 1       #Error
	fi

name=$(ls -A "$quarantinepath" | sed -n "${choice1}p")
echo "your File is: $name do you want to restore it ??  (y/n)"
read -r choice2

	if [ "$choice2" = 'y' ]; then
		mv "$quarantinepath/$name" "$watchpath/$name"
		echo "The file has been restored and will be whitelisted"
		echo "$name" >> "$whitelist"
		exit 0
	elif [ "$choice2" = 'n' ]; then
		echo "The file has NOT been deleted"
		exit 0
	else
		echo "Wrong Choice!"
		exit 1
	fi

