### SOGo Docker image ###
Docker image for SOGo based on the nightly build package of Alinto.

[SOGo](https://sogo.nu/) is free and open source groupware server for sharing calendars, address books, mail. 
SOGo supports use of standard protocols such as CalDAV, CardDAV and GroupDAV, as well as Microsoft ActiveSync.


## Features ##
* Comes with Apache in Memcached included
* MySQL
* Autoconfigure database incl. Emoji support
* Dynamic configuration based on the SOGo variable name


    
## docker-compose.yml example ##
  ```yml
version: '3.8'

services:
  sogo:
    image: grissir/sogo
    container_name: sogo
    links:
      - sogomariadb
    expose:
      - 80
    environment:
        - MYSQL_SERVER=sogomariadb
        - MYSQL_ROOT_PASSWORD=secret
        - MYSQL_USER=sogo
        - MYSQL_USER_PASSWORD=secret
        - MYSQL_DATABASE_NAME=sogo
        - MYSQL_PORT=3306
        - SOGO_SOGoIMAPServer="imaps://domain.tld"
        - SOGO_SOGoSMTPServer="smtp://domain.tld"
        - SOGO_SOGoMailDomain=ruppcup.de
        - SOGO_SOGoMailingMechanism=smtp
        - SOGO_SOGoSMTPAuthenticationType=PLAIN
        - SOGO_SOGoSieveServer="sieve://domain.tld"
        - SOGO_SOGoForceExternalLoginWithEmail=YES
        - SOGO_NGImap4ConnectionStringSeparator="."
        - SOGO_SOGoPasswordChangeEnabled=NO
        - SOGO_SOGoForwardEnabled=YES
        - SOGO_SOGoSieveScriptsEnabled=YES
        - SOGO_SOGoTimeZone=Europe/Paris
        - SOGO_SOGoAppointmentSendEMailNotifications=YES
        - SOGO_WorkersCount=4
        - SOGO_SOGoCalendarDefaultRoles=("PublicDAndTViewer","ConfidentialDAndTViewer","PrivateDAndTViewer")
        - SOGO_SOGoUserSources=({
              type = ldap;
              CNFieldName = cn;
              IDFieldName = uid;
              UIDFieldName = uid;
              baseDN = "ou=people,dc=org,dc=org";
              bindDN = "cn=admin,dc=org,dc=org";
              bindPassword = secret;
              canAuthenticate = YES;
              hostname = ldap://openldap:389;
              id = public;
              isAddressBook = YES;
              MailFieldNames = ("mail","mailAlias");
          })
        - SOGO_SOGoVacationEnabled=YES
        - SOGO_MySQL4Encoding=utf8mb4
        - APACHE_SERVER_NAME=sogo.domain.tld

  sogomariadb:
    image: mariadb:10.6
    container_name: sogomariadb
    environment:
        - MYSQL_ROOT_PASSWORD=secret
    ports:
        - 3306:3306
    volumes:
        - "./sogodata:/var/lib/mysql"
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

```
