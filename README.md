# DDT

Downloads dumps from servers via rsync over ssh, tests them by restore on a test DB server.<br>
Sends results to email via mutt(i'm using it cuz it add attachments).<br>

Servers addresses, dump folders, DB names and test DB names are stored in <b>dbases</b> array in form of a table:<br>
<pre>
dbases=(
#---------------------+-------------------+--------------------+--------------------------------------+
#    Ssh alias(addr)  |Dump folder(bkpath)|  DB name(dbname)   | Test DB name(dbtest) Must be unique! |
#---------------------+-------------------+--------------------+--------------------------------------+
#Example:
#    'moscow'           '/backup'           'data_db'            'moscow_data_prod_db'
#    'rybinsk'          '/backup/new'       'data_db'            'rybinsk_data_prod_db'

); N=${#dbases[*]}; C=4
</pre>

Have fun)!
