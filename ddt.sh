#!/bin/bash

dmpdir=~/dumps             # Dir to store dumps
dlderr=~/logs/dlderr       # Download errors file
dbserr=~/logs/dbserr       # DB test errors file
subjct="DDT"               # Email options - subject
mailto="user@pisem.net"    # Email options - address
mydate=$(date +'%d.%m.%Y') # Date to search dumps
dbhost=192.168.0.1         # DB server to test dump
dbport=5432                # DB server port
dbuser=dbuser              # User of test DB server
dbpass=password            # DB user password
hasher=sha1sum             # Hash algorithm
dbases=(
#---------------------+-------------------+--------------------+--------------------------------------+
#    Ssh alias(addr)  |Dump folder(bkpath)|  DB name(dbname)   | Test DB name(dbtest) Must be unique! |
#---------------------+-------------------+--------------------+--------------------------------------+
#Example:
#    'moscow'           '/backup'           'data_db'            'moscow_data_prod_db'
#    'rybinsk'          '/backup/new'       'data_db'            'rybinsk_data_prod_db'

); N=${#dbases[*]}; C=4

dl_error=(''
    ' ____  _____   ___   _  ____ \n'
    '|  _ \/ __\ \ / / \ | |/ ___|\n'
    '| |_) \___ \ V /|  \| | |    \n'
    '|  _ < ___) | | | |\  | |___ \n'
    '|_|_\_\____/|_| |_|_\_|\____|\n'
    '| ____| _ \  _ \/ _ |  _ \| |\n'
    '|  _|| |_) ||_) || || |_) | |\n'
    '| |__|  _ <  _ < |_||  _ <|_|\n'
    '|_____|| \_\| \_\___|_| \_(_)\n')

db_error=(''
    ' ____  ____ _____        _   \n'
    '|  _ \| __ )_   _|_  ___| |_ \n'
    '| | | |  _ \ | / _ \/ __| __|\n'
    '| |_| | |_) || | __/\__ \ |_ \n'
    '|____/|____/_|_|___||___/\__|\n'
    '| ____| _ \  _ \/ _ |  _ \| |\n'
    '|  _|| |_) ||_) || || |_) | |\n'
    '| |__|  _ <  _ < |_||  _ <|_|\n'
    '|_____|| \_\| \_\___|_| \_(_)\n')

[[ -f "$dlderr" ]] && rm "$dlderr"
[[ -f "$dbserr" ]] && rm "$dbserr"

function download {
	for ((j=0; j<10; j++)); do

		rsync -P -e ssh $addr:$bkpath/$dump $dmpdir/$localdump > /dev/null 2>> "$dlderr" \
            && { printf "\nDownload complete."; return; }
		sleep 5

	done; printf "${dl_error[*]}"; cat "$dlderr"; continue
}

function check {
	for ((i=0; i<$N; i+=$C)); do printf '\n----------------------------------------------\n'

		read addr bkpath dbname dbtest <<< ${dbases[@]:$i:$C}
		printf "Date\Time:\t$(date +'%d.%m.%Y %R')\n"
		printf "DBServer:\t$addr\n"
		printf "DBName:\t\t$dbname\n"

		dump=`ssh $addr ls $bkpath | grep ${dbname}_$mydate.*.gz` \
			|| { printf "\nDump not found for the current date($mydate)!\n"; continue; }
		localdump=${dbtest}_$mydate.gz

		size=(`ssh $addr du   -m $bkpath/$dump`); size=${size[0]}
		hash=(`ssh $addr $hasher $bkpath/$dump`); hash=${hash[0]}

		printf "RemoteFile:\t$bkpath/$dump ($size MB)\n"
		printf "RemoteHash:\t$hash\n"

		download
		mysize=(`du   -m $dmpdir/$localdump`); mysize=${mysize[0]}
		myhash=(`$hasher $dmpdir/$localdump`); myhash=${myhash[0]}

		[[ $hash = $myhash ]] \
			&& { printf " Hash checked!)\n\n"; } \
			|| { printf "${dl_error[*]}\nLocalhash($myhash) not equal to remotehash($hash)!\n\n"; continue; }

		printf "LocalFile:\t$dmpdir/$localdump ($mysize MB)\n"
		printf "LocalHash:\t$myhash\n"

        dbconn="-h $dbhost -p $dbport -U $dbuser"
		dropdb   $dbconn            $dbtest
		createdb $dbconn -O $dbuser $dbtest

		gunzip -c $dmpdir/$localdump | PGPASSWORD="$dbpass" psql -v ON_ERROR_STOP=1 $dbconn $dbtest > /dev/null \
            2>> "$dbserr" || { printf "${db_error[*]}"; cat "$dbserr"; continue; }

		printf "\nCheck complete!)\n"

	done
}

check | mutt -s "$subjct" "$mailto"

