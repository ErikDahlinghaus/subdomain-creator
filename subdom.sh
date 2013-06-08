
#!/bin/bash

apache_sites_available='/etc/apache2/sites-available/'
apache_www='/var/www/'
skeleton_file='skel'

domain='.dahlinghaus.net'


# No need to edit below this point...
if [ $# -eq 0 ]
  then
    echo -e "\nNo first argument..."
    echo -e "Usage: $0 [-r] subdomain\n"
    exit
fi

gainroot(){
	echo -e "\n\nThese operations require root access..."
	read -t 0.1 -N 255
	sleep 1
	ERROR=$( sudo echo -en 2>&1 )
	  if [ "$ERROR" != "" ]
	    then
	      echo -e "\t$ERROR"
	      exit
	  fi
}

create(){
	echo -e "\nCreating subdomin $subdir$domain"
	echo -en "\t"
	read -p "Is this correct? [y/n]" -n 1 -r
	if [[ $REPLY =~ ^[Nn]$ ]]
	  then
	    echo -e "\nAborting...\n"
	    exit
	fi

	gainroot

	echo -e '\nCreating vhosts file...'
	while read LINE
	do
		echo $LINE | sed -e "s/!!!name!!!/$subdir/" >> /tmp/$subdir$domain
	done < $apache_sites_available$skeleton_file$domain
	sudo mv /tmp/$subdir$domain $apache_sites_available$subdir$domain


	echo -e "Creating www subdirectory..."
	mkdir -p $wwwdir

	if [ -f $wwwdir"/index.html" ]
	  then
		echo "index.html already exists, not populating..."
	  else
		echo -e "Populating index.html..."
		echo "<html><body><br /><br /><br /><center><h1>$subdir$domain</h1></center></body></html>" >> $wwwdir"/index.html"
	fi

	echo -e "Enabling site $subdir$domain..."
	ERROR=$( sudo a2ensite $subdir$domain 2>&1 >/dev/null )
	if [ "$ERROR" != "" ]
	  then
		echo -e "\t$ERROR"
	fi

	echo -e "Reloading apache config..."
	ERROR=$( sudo service apache2 reload 2>&1 >/dev/null )
	if [ "$ERROR" != "" ]
	  then
		echo -e "\t$ERROR"
	fi
}

remove(){
	echo -e "\nRemoving subdomin $subdir$domain"
	echo -en "\t"
	read -p "Is this correct? [y/n]" -n 1 -r
	if [[ $REPLY =~ ^[Nn]$ ]]
	  then
	    echo -e "\nAborting...\n"
	    exit
  	fi

	gainroot
	
	echo -e '\nRemoving vhosts file...'
	ERROR=$( sudo rm $apache_sites_available$subdir$domain 2>&1 >/dev/null )
	if [ "$ERROR" != "" ]
		  then
		    echo -e "\t$ERROR"
		fi

	read -p "Remove www directory? [y/n]:" -n 1 -r
	if [[ $REPLY =~ ^[Yy]$ ]]
	  then
	    echo -e "\n\tRemoving www subdirectory..."
	    ERROR=$( rm -r $wwwdir 2>&1 >/dev/null )
	    if [ "$ERROR" != "" ]
		  then
		    echo -e "\t$ERROR"
		fi
	fi

	echo -e "Disabling site $subdir$domain..."
	ERROR=$( sudo a2dissite $subdir$domain 2>&1 >/dev/null )
	if [ "$ERROR" != "" ]
		  then
		    echo -e "\t$ERROR"
		fi

	echo -e "Reloading apache config..."
	ERROR=$( sudo service apache2 reload 2>&1 >/dev/null )
	if [ "$ERROR" != "" ]
		  then
		    echo -e "\t$ERROR"
		fi
}

if [ "$1" != "-r" ]
  then
    subdir=$1
    wwwdir=$apache_www$subdir$domain
    create
  else
    subdir=$2
    wwwdir=$apache_www$subdir$domain
    remove
fi




echo -e '\nDone.'
