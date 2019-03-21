#!/bin/bash

dbases=(
#-----------------------+-------------------+-----------------------------+--------------------------------------+
#    Ssh alias(addr)    |Dump folder(bkpath)| Dump search pattern(dbname) | Test DB name(dbtest) Must be unique! |
#-----------------------+-------------------+-----------------------------+--------------------------------------+
#      'moscow'             '/backup'           'data_db_%d.%m.%Y'                   'moscow_data_prod_db'
#      'rybinsk'            '/backup/new'       '%Y%m%d_db_data'                     'rybinsk_data_prod_db'
#-----------------------+-------------------+-----------------------------+--------------------------------------+
); N=${#dbases[*]}; C=4

dmpdir=~/dumps                            # Dir to store dumps
dlderr=~/logs/dlderr                      # Download errors file
dbserr=~/logs/dbserr                      # DB test errors file
subjct="DDT"                              # Email options - subject
mailto="user@pisem.net"                   # Email options - address
mydate=$(date +'%d.%m.%Y')                # Date to search dumps
hasher=sha1sum                            # Hash algorithm
dbhost=192.168.0.1                        # DB server to test dump
dbport=5432                               # DB server port
dbuser=dbuser                             # User of test DB server
dbpass=password                           # DB user password
dbconf="-U $dbuser -h $dbhost -p $dbport" # DB connection parameters
dleror=(''
    ' ____  _____   ___   _  ____ \n'
    '|  _ \/ __\ \ / / \ | |/ ___|\n'
    '| |_) \___ \ V /|  \| | |    \n'
    '|  _ < ___) | | | |\  | |___ \n'
    '|_|_\_\____/|_| |_|_\_|\____|\n'
    '| ____| _ \  _ \/ _ \  _ \| |\n'
    '|  _|| |_) ||_) || | ||_) | |\n'
    '| |__|  _ <  _ < |_| | _ <|_|\n'
    '|_____|| \_\| \_\___/_| \_(_)\n')
dberor=(''
    ' ____  ____ _____        _   \n'
    '|  _ \| __ )_   _|_  ___| |_ \n'
    '| | | |  _ \ | / _ \/ __| __|\n'
    '| |_| | |_) || | __/\__ \ |_ \n'
    '|____/|____/_|_|___||___/\__|\n'
    '| ____| _ \  _ \/ _ \  _ \| |\n'
    '|  _|| |_) ||_) || | ||_) | |\n'
    '| |__|  _ <  _ < |_| | _ <|_|\n'
    '|_____|| \_\| \_\___/_| \_(_)\n')

[[ -f "$dlderr" ]] && rm "$dlderr"
[[ -f "$dbserr" ]] && rm "$dbserr"

function download {
    for ((j=0; j<10; j++)); do

        rsync -Pqz $addr:"$bkpath/$dump" "$dmpdir/$localdump" > /dev/null 2>> "$dlderr" \
            && { printf "\nDownload complete."; return; }
        sleep 5

    done; printf "${dleror[*]}"; cat "$dlderr"; continue
}

function check {
    for ((i=0; i<$N; i+=$C)); do printf '\n----------------------------------------------\n'

        read addr bkpath dbname dbtest <<< ${dbases[@]:$i:$C}
        # Restrict connections to test DB
        # Terminate connections to test DB if PostgreSQL ver. <= 9.1 change 'pid' to 'procpid'
        # Then drop test DB and create new test DB
        dbterm="
        ALTER DATABASE $dbtest ALLOW_CONNECTIONS false;
        SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$dbtest';"

        printf "Date\Time:\t$(date +'%d.%m.%Y %R')\n"
        printf "DBServer:\t$addr\n"

        dump=( $(ssh $addr ls -t $bkpath | grep $(date +${dbname}).*.gz) )) \
            || { printf "\nDump not found for the current date($mydate)!\n"; continue; }
        dump=${dump[0]}
        localdump=${dbtest}_$mydate.gz

        size=( $(ssh $addr du   -m "$bkpath/$dump") ); size=${size[0]}
        hash=( $(ssh $addr $hasher "$bkpath/$dump") ); hash=${hash[0]}

        printf "RemoteFile:\t$bkpath/$dump ($size MB)\n"
        printf "RemoteHash:\t$hash\n"

        download
        mysize=( $(du   -m "$dmpdir/$localdump") ); mysize=${mysize[0]}
        myhash=( $($hasher "$dmpdir/$localdump") ); myhash=${myhash[0]}

        [[ $hash = $myhash ]] \
            && { printf " Hash checked!)\n\n"; } \
            || { printf "${dleror[*]}\nLocalhash($myhash) not equal to remotehash($hash)!\n\n"; continue; }

        printf "LocalFile:\t$dmpdir/$localdump ($mysize MB)\n"
        printf "LocalHash:\t$myhash\n"

        # Drop test DB connections, drop DB and create DB
        psql     $dbconf -c        "$dbterm" > /dev/null 2>> "$dbserr"
        dropdb   $dbconf            $dbtest  > /dev/null 2>> "$dbserr"
        createdb $dbconf -O $dbuser $dbtest  > /dev/null 2>> "$dbserr"

        gunzip -c "$dmpdir/$localdump" | psql -v ON_ERROR_STOP=1 $dbconf $dbtest > /dev/null 2>> "$dbserr" \
            || { printf "${dberor[*]}"; cat "$dbserr"; continue; }

        printf "\nCheck complete!)\n"

    done
}

exec 5>&1
message=$(check|tee /dev/fd/5)
mutt -s "$subjct" "$mailto" <<< "$message"
