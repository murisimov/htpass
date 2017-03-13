#!/bin/bash

# Clarify what OS is it
if [[ -e /etc/redhat-release ]]; then
    release="centos"
elif [[ -e /etc/debian_version ]]; then
    release="debian"
else
    echo; echo "Error: unknown OS!"; echo
    exit 1
fi

# Check arguments number
if [ ${#} -gt 3 ]; then
    echo; echo "Too many arguments!"; echo
    exit 1
elif [ ${#} -lt 1 ]; then
    echo; echo "Please specify webserver (nginx or apache)"; echo
    exit 1
fi

webserver="${1}"
homedir="/usr/gm/htpass"

# Return error in case of invalid webserver argument
if [ ${webserver} != 'nginx' -a ${webserver} != 'apache' ]; then
    echo; echo "Unknown webserver! Please specify either nginx or apache"; echo
    exit 1
# Specify correct conf file for furter substitution
elif [ ${webserver} == 'apache' ]; then
    if [ ${release} == 'centos' ]; then
        webserver="httpd"
    else
        webserver="apache2"
    fi
    conf="${homedir}/apache/htpass.conf"
else
    conf="${homedir}/nginx/htpass.conf"
fi

# Check if chosen webserver is installed
if ! [ -n "$(which ${webserver} 2>/dev/null|grep -E "(/\w+)+/${webserver}")" ]; then
    echo; echo "Please install ${webserver} and try again"; echo
    exit 1
fi

cd ${homedir}

# Add user htpass, so Apache can launch our virtualhost
if id -u htpass > /dev/null; then
    echo; echo "Htpass user exists"; echo
else
    if useradd htpass -m -b /home -s /bin/bash -U; then
        echo; echo "Htpass user created"; echo
    else
        echo; echo "Failed to create Htpass user"; echo
        exit 1
    fi
fi

# Provide valid configuration file
rm -f /etc/${webserver}/sites-{available,enabled}/htpass.conf
rm -rf ${homedir}/env/

if cp ${conf} /etc/${webserver}/sites-available/; then
    # Enable configuration file
    if ln -s /etc/${webserver}/sites-available/htpass.conf /etc/${webserver}/sites-enabled/; then
        echo; echo "Configuration files placed"; echo
    else
        echo; echo "Failed to place configuration files"; echo
        exit 1
    fi
fi

# Install virtualenv
if pip install virtualenv; then
    # Create vitrualenv for our app
    if virtualenv ${homedir}/env; then
        # Install dependencies under virtualenv
        if source ${homedir}/env/bin/activate; then
            if pip install Flask uwsgi && deactivate; then
                echo; echo "Virtual environment set"; echo
            else
                echo; echo "Failed to install pip dependencies"; echo
                exit 1
            fi
        else
            echo; echo "Failed to activate virtualenv"; echo
            exit 1
        fi
    else
        echo; echo "Failed to create virtualenv for Htpass"; echo
        exit 1
    fi
else
    echo; echo "Failed to install virtualenv"; echo
    exit 1
fi

# Provide init script in case of nginx
if [ ${webserver} == 'nginx' ]; then
    #stop htpass-init
    #rm -f /etc/init/htpass-init.conf
    /etc/init.d/htpass-init stop &> /dev/null
    rm -f /etc/init.d/htpass-init

    #if cp ${homedir}/nginx/htpass-init.conf /etc/init/htpass-init.conf; then
    if cp ${homedir}/htpass-init /etc/init.d/; then
        chmod +x /etc/init.d/htpass-init

        if [ -n "$(grep "nginx" /etc/passwd)" ]; then
            nginx_group="nginx"
        elif [ -n "$(grep "www-data" /etc/passwd)" ]; then
            nginx_group="www-data"
        else
            echo
            echo "No Nginx group found, are you sure you have Nginx installed?"
            exit 1
        fi

        if chown -R htpass:${nginx_group} ${homedir}/; then
            if /etc/init.d/htpass-init start; then
                echo; echo "Upstart script for uWSGI set and launched"; echo
            else
                echo; echo "Failed to set upstart script for uWSGI"; echo
                exit 1
            fi
        else
            echo; echo "Failed to give correct permissions on ${homedir} directory"; echo
            exit 1
        fi
    else
        echo; echo "Failed to copy init script to /etc/init/"; echo
        exit 1
    fi

    nginx -t &&\
    service nginx reload &&\
    echo && echo "Nginx reloaded, ready to serve" ||\
    echo "Failed to reload Nginx"
    echo
else
    apachectl configtest &&\
    service ${webserver} reload &&\
    echo && echo "Apache reloaded, ready to serve" ||\
    echo "Failed to reload Apache"
fi
