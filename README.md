Htpass
---
_Provides web interface, where you can create login:pwdhash pairs for Nginx and Apache2 basic auth_


---
- __Prerequisites__
    - python 2.7
    - gcc
    - pip
    - nginx
    - Debian:
      - python-dev
      - apache2 with libapache2-mod-wsgi
    - CentOS:
      - python-devel
      - httpd with mod_wsgi

---
- __How to deploy this thing??__
    1. Create directory /usr/gm
    2. Clone this repo into it, so you get /usr/gm/htpass (accurately)
    3. Execute "deploy.sh (nginx|apache)" with root privileges
    4. Associate server's ip in /etc/hosts with "htpass" name
    5. ???????
    6. And we're done.

---
- __Additional details__
    - .htpassd with all collected credentials will be in /home/htpass directory
    - Identical usernames are not allowed
    - Username symbols are restricted to ascii letters, digits and underscores
    - Usernames are restricted to 3-12 character length
    - Passwords are restricted to 6-30 character length

---

╰(\*´︶\`\*)╯
