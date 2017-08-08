# docker slapd

A Docker image for slapd, the OpenLDAP server


## Software specification

* Base image: Ubuntu Xenial

* Installed packages:
  - ca-certificates
  - ldap-utils
  - [ldapscripts](https://github.com/martymac/ldapscripts)
  - [ldapvi](http://www.lichteblau.com/ldapvi/)
  - [slapd](https://www.openldap.org/)
  - vim-nox


* Required Docker (any):
  - Docker Engine 1.10 and higher
  - Docker CE 17.03 and higher


* Optional software:
  - Docker Compose 1.14 and higher


## Quick start

Create a new container which will keep LDAP data volumes:

    $ docker create --name slapdata adegtyarev/slapd


Setup the environment:

* `LDAP_SUFFIX` used for `olcSuffix` attribute when creating a new
database
* `LDAP_ROOT_DN` used as a new database's `olcRootDN`
* `LDAP_ROOT_PW` used as a new database's `olcRootPW`

Within this document `.env` file will be used for that purpose and you may use
any other possible way to achieve the same:

    $ cat .env
    LDAP_SUFFIX=example
    LDAP_ROOT_DN=cn=admin,dc=example
    LDAP_ROOT_PW=<...>


Run an OpenLDAP server in a new container:

    $ docker run --name slapd --volumes-from slapdata --env-file .env -d slapd


The sever now should be up and ready:

    $ docker logs slapd
    5984b9fc @(#) $OpenLDAP: slapd  (Ubuntu) (May 30 2017 19:20:53) $
    5984b9fc slapd starting


## Create a new database

Given that you setup environment with desired values:

    $ docker exec slapd sh /init-db.sh

This will create a new database directory and add new `olcDatabase` entry to
the OpenLDAP server configuration stored as a special LDAP directory under
`cn=config` with a predefined schema and DIT.

You now may log into the OpenLDAP server using `$LDAP_ROOT_DN` and `LDAP_ROOT_PW`.


## Dynamic runtime configuration

Use `ldapvi` to edit OpenLDAP server configuration:

    $ docker exec -it slapd ldapvi -h ldapi:/// -Y EXTERNAL -b cn=config


## Using with Docker Compose

You may already using [Docker Compose](https://docs.docker.com/compose/) tool
for running multi-container environment including OpenLDAP server.  This
repository includes quick example of how to use Compose with this image.

    $ docker-compose up -d

To avoid naming conflict be sure to stop and remove containers which were run
manually before.


## Restore from backup

    $ source .env
    $ docker exec -i slapd ldapadd -H ldapi:/// -w $LDAP_ROOT_PW -D $LDAP_ROOT_DN < tree.ldif


## Add and remove users and groups

This docker image include software to manage POSIX entries in an OpenLDAP
directory, similar to `adduser` or `useradd` commands in Linux -
[ldapscripts](https://github.com/martymac/ldapscripts).

This tool must be configured prior to using it by supplying custom
configuration file.  Optionally, specify LDIF template files:

```yaml
slapd:
    image: adegtyarev/slapd
    ...
    volumes_from:
        - slapdata
    volumes:
        - ./data/ldapadduser.template:/etc/ldapscripts/ldapadduser.template
        - ./data/ldapaddgroup.template:/etc/ldapscripts/ldapaddgroup.template
        - ./data/ldapscripts.conf:/etc/ldapscripts/ldapscripts.conf
    ...
```

Please consult `ldapscript`'s documentation for details.  Once configured, it
can be used to add POSIX users:

    $ docker exec -it slapd ldapaddgroup newgroup

... and groups in the directory:

    $ docker exec -it slapd ldapadduser newuser newgroup


## Advanced usage

Setup ACLs and/or overlays by using LDIF snippet-files:

    $ source .env

    $ LDAPADD="docker exec -i slapd ldapadd -H ldapi:///"

    $ LDAP_INCLUDE_LDIFS="memberof refint"

    $ for i in $LDAP_INCLUDE_LDIFS; do $LDAPADD -Y EXTERNAL < $i.ldif; done


## Author

Alexey Degtyarev <alexey@renatasystems.org>
