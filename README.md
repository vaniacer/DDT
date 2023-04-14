# DDT

Downloads postgresql dumps from servers via rsync over ssh, tests them by restoring on a test DB server.<br>
Sends results to email via mutt(i'm using it cuz it add attachments).<br>

Servers addresses, dump folders, Dump search patterns and test DB names are stored in <b>dbases</b> array in form of a table:<br>
<pre>
dbases=(
#-----------------------+-------------------+-----------------------------+--------------------------------------+
#    Ssh alias(addr)    |Dump folder(bkpath)| Dump search pattern(dbname) | Test DB name(dbtest) Must be unique! |
#-----------------------+-------------------+-----------------------------+--------------------------------------+
      'moscow'             '/backup'           'data_db_%d.%m.%Y'                   'moscow_data_prod_db'
      'rybinsk'            '/backup/new'       '%Y%m%d_db_data'                     'rybinsk_data_prod_db'
      'yaroslavl'          '/dumps'            'data_db%Y'                          'yar_data_prod_db'
#-----------------------+-------------------+-----------------------------+--------------------------------------+
); N=${#dbases[*]}; C=4
</pre>

Have fun)!

[![Twitter Follow](https://img.shields.io/twitter/follow/Vaniacer?style=social)](https://twitter.com/Vaniacer)
[![paypal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/sshto?locale.x=en_US) <sup>Don't hold yourself, buy me a beer)</sup>

~~Twitter~~ DOGE: D7qJBRU3UpXES9EwtvE8YZSNAVgFEmz3py</br>
![dodge](https://user-images.githubusercontent.com/18072680/229992296-f415eadb-645b-4229-81c7-e269485c635d.png)
