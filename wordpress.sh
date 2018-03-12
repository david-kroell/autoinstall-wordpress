#!/bin/bash
#by Chrisitan Gubesch
#last updated 3/7/2018

function detect_distro {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ...
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        ...
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi

    return $OS $VER
}

function install_wordpress {
    cd "${1}"
    wget https://wordpress.org/latest.tar.gz
    tar xzf latest.tar.gz
    cp -R wordpress/* .
    chown -R www-data:www-data .
    PASSWDDB="$(openssl rand -base64 12)"
    echo -n "Enter database name: "
    read MAINDB
    echo -n "Please enter root user MySQL password:"
    read -s rootpasswd
    mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${MAINDB} DEFAULT CHARACTER SET utf8;"
    mysql -uroot -p${rootpasswd} -e "CREATE USER ${MAINDB}@localhost IDENTIFIED BY '${PASSWDDB}';"
    mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO '${MAINDB}'@'localhost';"
    mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"

    rm latest.tar.gz
    rm -rf wordpress

    ipADDRESS="$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')"

    echo -e "All your wordpress content is now saved at ${1} !\n"
    echo "Now go to your browser and open: ${ipADDRESS}"
    echo "Your database name is: ${MAINDB}"
    echo "Your database User-Name is: ${MAINDB}"
    echo "Your password is: ${PASSWDDB}"
}


echo "Welcome to wordpress installation!"
echo "Detecting operation system..."
DISTRO=detect_distro
read -p "Are you currently on "$DISTRO"? [Y/n]: " decision
if [ "${decision}" == "y" ] || [ "${decision}" == "Y" ] || [ "${decision}" == "" ] ; then
    echo ""
else
    echo -e "\nclosing script"
    exit 1
fi
    
read -p "Please enter your wished installation destination: " destination
echo ""

if [ -d ${destination} ] ; then
    install_wordpress "${destination}"
else
    echo "${destination} doesn't exist"
    echo -n "do you want to create this folder? (Y/n)"
    read election
    if [ "${election}" == "y" ] || [ "${election}" == "Y" ] || [ "${election}" == "" ] ; then
        mkdir -p "${destination}"
        install_wordpress "${destination}"
    else
        echo -e "\nclosing script"
    fi
    
fi
