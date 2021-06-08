#!/usr/bin/env bash

#   Copyright 2020 André Silva
#   Baseado no projeto de Eduardo Rolim - https://gitlab.com/ens.rolim/ldap-olc-redecafe
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

## Instalação do OpenLDAP
## https://www.openldap.org/doc/admin24/slapdconf2.html
## https://wiki.rnp.br/pages/viewpage.action?pageId=69968769
## http://www.zytrax.com/books/ldap/ch6/
## https://aput.net/~jheiss/samba/ldap.shtml
## http://labs.opinsys.com/blog/2010/05/05/smbkrb5pwd-password-syncing-for-openldap-mit-kerberos-and-samba/
## https://www.itzgeek.com/how-tos/linux/centos-how-tos/configure-openldap-with-ssl-on-centos-7-rhel-7.html
## https://www.itzgeek.com/how-tos/linux/configure-openldap-master-slave-replication.html
## https://www.itzgeek.com/how-tos/linux/centos-how-tos/step-step-openldap-server-configuration-centos-7-rhel-7.html
## https://ubuntu.com/server/docs/service-ldap-replication


if [[ $(id -u) -ne 0 ]] ; then echo "É necessário rodar como root/sudo." ; exit 1 ; fi

log="$(date +%Y-%m-%d_%H-%M)_ldap_campi_read_only_replica_user.log"


## Variaveis
DOMINIO_LDAP=""
SENHA_ADM=""
HELP=""
SAIR=""

SENHA_ADMIN_CAMPI=""
SENHA_REPLICATOR_CAMPI=""


# Caso deseje manter os arquivos LDIF gerados, comente esta linha
#VAR_EXCLUI_LDIFS=1


# Realizando leitura dos parametros
while [ -n "$1" ]; do # while loop starts

	case "$1" in

    --DOMINIO_LDAP|--dominio_ldap) DOMINIO_LDAP=$2; shift;;
    --SENHA_ADM|--senha_adm) SENHA_ADM=$2; shift;;

    --HELP|--help)
      echo ""
      echo "Para executar este script é necessário que todos os parametros sejam informados corretamente."
      echo ""
      echo " sudo ./ldap_campi_read_only_replica_user.sh --DOMINIO_LDAP cn=xpto,dc=local --SENHA_ADM \"senha_de_administrador\""
      echo ""
      echo " --DOMINIO_LDAP|--dominio_ldap              | <Obrigatorio> Dominio no formato LDAP. Ex: cn=xpto,cn=local"
      echo " --SENHA_ADM|--senha_adm                    | <Obrigatorio> Senha do Administrador do LDAP. Ex: \"h#s9a8dnag62!@\""
      echo ""
      echo "*** IMPORTANTE ***"
      echo "Quando um parametro necessitar de valores separados por espaco, escrever o mesmo entre aspas duplas. Exemplo \"Empresa XPTO Ltda\""
      exit 1;
      ;;

	  *) echo "Parametro $1 nao reconhecido. Digite --HELP|--help para lista de parametros"
       ;;

	esac

	shift

done

# Checando se todos os parametros foram informados
if [ -z "$DOMINIO_LDAP" ]; then
  echo "O Parâmetro \"--DOMINIO_LDAP | --dominio_ldap\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$SENHA_ADM" ]; then
  echo "O Parâmetro \"--SENHA_ADM | --senha_adm\" não foi informado."
  echo ""
  SAIR="1"
fi


# Iniciando Script
if [ -z $SAIR ]; then
echo "Iniciando execução do script..."


###############################################################################################
(

# Configurando OU dos campi
echo "Configurando OU dos campi"
cat > ou_campi.ldif <<_EOF_
dn: ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Unidade Organizacional - Campi
ou: campi
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ou_campi.ldif


# Inicio da escrita das senhas geradas em arquivo texto
echo "####################################################" > .credenciais-campi.txt
echo "# Credenciais de Acesso - Campi" >> .credenciais-campi.txt

# Configurando acesso para replicacao nos campi
###############################################################################################
# Campus Arapongas

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Arapongas" >> .credenciais-campi.txt
echo "# Usuario: admin-arapongas | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-arapongas | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Arapongas"
cat > ldif-campus-arapongas.ldif <<_EOF_
# Unidade Organizacional do Campus
dn: ou=arapongas,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Arapongas
ou: arapongas

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=arapongas,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Arapongas
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=arapongas,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Arapongas
ou: groups

##
# Usuarios
dn: cn=replicator-arapongas,ou=users,ou=arapongas,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-arapongas
description: Read Only Replication User - Campus Arapongas
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-arapongas,ou=users,ou=arapongas,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-arapongas
description: Admin User - Campus Arapongas
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-arapongas.ldif


# Adicionando Usuarios do Campus Arapongas nos respectivos Grupos
echo "Adicionando Usuarios do Campus Arapongas nos respectivos Grupos"
cat > group_member_campus_arapongas.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-arapongas,ou=users,ou=arapongas,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-arapongas,ou=users,ou=arapongas,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_arapongas.ldif


###############################################################################################
# Campus Assis Chateaubriand

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Assis Chateaubriand" >> .credenciais-campi.txt
echo "# Usuario: admin-assis | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-assis | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Assis Chateaubriand"
cat > ldif-campus-assis.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=assis,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Assis Chateaubriand
ou: assis

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=assis,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Assis Chateaubriand
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=assis,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Assis Chateaubriand
ou: groups

##
# Usuarios
dn: cn=replicator-assis,ou=users,ou=assis,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-assis
description: Read Only Replication User - Campus Assis Chateaubriand
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-assis,ou=users,ou=assis,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-assis
description: Admin User - Campus Assis Chateaubriand
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-assis.ldif


# Adicionando Usuarios do Campus Assis Chateaubriand nos respectivos Grupos
echo "Adicionando Usuarios do Campus Assis Chateaubriand nos respectivos Grupos"
cat > group_member_campus_assis.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-assis,ou=users,ou=assis,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-assis,ou=users,ou=assis,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_assis.ldif


###############################################################################################
# Campus Astorga

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Astorga" >> .credenciais-campi.txt
echo "# Usuario: admin-astorga | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-astorga | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Astorga"
cat > ldif-campus-astorga.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=astorga,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Astorga
ou: astorga

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=astorga,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Astorga
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=astorga,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Astorga
ou: groups

##
# Usuarios
dn: cn=replicator-astorga,ou=users,ou=astorga,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-astorga
description: Read Only Replication User - Campus Astorga
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-astorga,ou=users,ou=astorga,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-astorga
description: Admin User - Campus Astorga
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-astorga.ldif


# Adicionando Usuarios do Campus Astorga nos respectivos Grupos
echo "Adicionando Usuarios do Campus Astorga nos respectivos Grupos"
cat > group_member_campus_astorga.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-astorga,ou=users,ou=astorga,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-astorga,ou=users,ou=astorga,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_astorga.ldif


###############################################################################################
# Campus Barracao

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Barracao" >> .credenciais-campi.txt
echo "# Usuario: admin-barracao | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-barracao | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Barracao"
cat > ldif-campus-barracao.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=barracao,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Barracao
ou: barracao

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=barracao,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Barracao
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=barracao,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Barracao
ou: groups

##
# Usuarios
dn: cn=replicator-barracao,ou=users,ou=barracao,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-barracao
description: Read Only Replication User - Campus Barracao
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-barracao,ou=users,ou=barracao,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-barracao
description: Admin User - Campus Barracao
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-barracao.ldif


# Adicionando Usuarios do Campus Barracao nos respectivos Grupos
echo "Adicionando Usuarios do Campus Barracao nos respectivos Grupos"
cat > group_member_campus_barracao.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-barracao,ou=users,ou=barracao,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-barracao,ou=users,ou=barracao,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_barracao.ldif


###############################################################################################
# Campus Campo Largo

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Campo Largo" >> .credenciais-campi.txt
echo "# Usuario: admin-clargo | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-clargo | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Campo Largo"
cat > ldif-campus-clargo.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=clargo,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Campo Largo
ou: clargo

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=clargo,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Campo Largo
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=clargo,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Campo Largo
ou: groups

##
# Usuarios
dn: cn=replicator-clargo,ou=users,ou=clargo,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-clargo
description: Read Only Replication User - Campus Campo Largo
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-clargo,ou=users,ou=clargo,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-clargo
description: Admin User - Campus Campo Largo
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-clargo.ldif


# Adicionando Usuarios do Campus Campo Largo nos respectivos Grupos
echo "Adicionando Usuarios do Campus Campo Largo nos respectivos Grupos"
cat > group_member_campus_clargo.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-clargo,ou=users,ou=clargo,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-clargo,ou=users,ou=clargo,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_clargo.ldif


###############################################################################################
# Campus Capanema

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Capanema" >> .credenciais-campi.txt
echo "# Usuario: admin-capanema | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-capanema | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Capanema"
cat > ldif-campus-capanema.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=capanema,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Capanema
ou: capanema

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=capanema,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Capanema
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=capanema,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Capanema
ou: groups

##
# Usuarios
dn: cn=replicator-capanema,ou=users,ou=capanema,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-capanema
description: Read Only Replication User - Campus Capanema
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-capanema,ou=users,ou=capanema,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-capanema
description: Admin User - Campus Capanema
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-capanema.ldif


# Adicionando Usuarios do Campus Capanema nos respectivos Grupos
echo "Adicionando Usuarios do Campus Capanema nos respectivos Grupos"
cat > group_member_campus_capanema.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-capanema,ou=users,ou=capanema,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-capanema,ou=users,ou=capanema,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_capanema.ldif


###############################################################################################
# Campus Cascavel

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Cascavel" >> .credenciais-campi.txt
echo "# Usuario: admin-cascavel | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-cascavel | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Cascavel"
cat > ldif-campus-cascavel.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=cascavel,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Cascavel
ou: cascavel

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=cascavel,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Cascavel
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=cascavel,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Cascavel
ou: groups

##
# Usuarios
dn: cn=replicator-cascavel,ou=users,ou=cascavel,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-cascavel
description: Read Only Replication User - Campus Cascavel
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-cascavel,ou=users,ou=cascavel,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-cascavel
description: Admin User - Campus Cascavel
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-cascavel.ldif


# Adicionando Usuarios do Campus Cascavel nos respectivos Grupos
echo "Adicionando Usuarios do Campus Cascavel nos respectivos Grupos"
cat > group_member_campus_cascavel.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-cascavel,ou=users,ou=cascavel,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-cascavel,ou=users,ou=cascavel,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_cascavel.ldif


###############################################################################################
# Campus Colombo

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Colombo" >> .credenciais-campi.txt
echo "# Usuario: admin-colombo | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-colombo | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Colombo"
cat > ldif-campus-colombo.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=colombo,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Colombo
ou: colombo

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=colombo,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Colombo
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=colombo,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Colombo
ou: groups

##
# Usuarios
dn: cn=replicator-colombo,ou=users,ou=colombo,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-colombo
description: Read Only Replication User - Campus Colombo
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-colombo,ou=users,ou=colombo,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-colombo
description: Admin User - Campus Colombo
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-colombo.ldif


# Adicionando Usuarios do Campus Colombo nos respectivos Grupos
echo "Adicionando Usuarios do Campus Colombo nos respectivos Grupos"
cat > group_member_campus_colombo.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-colombo,ou=users,ou=colombo,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-colombo,ou=users,ou=colombo,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_colombo.ldif


###############################################################################################
# Campus Coronel Vivida

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Coronel Vivida" >> .credenciais-campi.txt
echo "# Usuario: admin-celvivida | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-celvivida | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Coronel Vivida"
cat > ldif-campus-celvivida.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=celvivida,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Coronel Vivida
ou: celvivida

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=celvivida,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Coronel Vivida
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=celvivida,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Coronel Vivida
ou: groups

##
# Usuarios
dn: cn=replicator-celvivida,ou=users,ou=celvivida,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-celvivida
description: Read Only Replication User - Campus Coronel Vivida
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-celvivida,ou=users,ou=celvivida,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-celvivida
description: Admin User - Campus Coronel Vivida
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-celvivida.ldif


# Adicionando Usuarios do Campus Coronel Vivida nos respectivos Grupos
echo "Adicionando Usuarios do Campus Coronel Vivida nos respectivos Grupos"
cat > group_member_campus_celvivida.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-celvivida,ou=users,ou=celvivida,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-celvivida,ou=users,ou=celvivida,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_celvivida.ldif


###############################################################################################
# Campus Curitiba

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Curitiba" >> .credenciais-campi.txt
echo "# Usuario: admin-curitiba | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-curitiba | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Curitiba"
cat > ldif-campus-curitiba.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=curitiba,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Curitiba
ou: curitiba

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=curitiba,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Curitiba
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=curitiba,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Curitiba
ou: groups

##
# Usuarios
dn: cn=replicator-curitiba,ou=users,ou=curitiba,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-curitiba
description: Read Only Replication User - Campus Curitiba
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-curitiba,ou=users,ou=curitiba,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-curitiba
description: Admin User - Campus Curitiba
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-curitiba.ldif


# Adicionando Usuarios do Campus Curitiba nos respectivos Grupos
echo "Adicionando Usuarios do Campus Curitiba nos respectivos Grupos"
cat > group_member_campus_curitiba.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-curitiba,ou=users,ou=curitiba,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-curitiba,ou=users,ou=curitiba,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_curitiba.ldif


###############################################################################################
# Campus Foz do Iguacu

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Foz do Iguacu" >> .credenciais-campi.txt
echo "# Usuario: admin-foz | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-foz | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Foz do Iguacu"
cat > ldif-campus-foz.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=foz,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Foz do Iguacu
ou: foz

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=foz,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Foz do Iguacu
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=foz,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Foz do Iguacu
ou: groups

##
# Usuarios
dn: cn=replicator-foz,ou=users,ou=foz,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-foz
description: Read Only Replication User - Campus Foz do Iguacu
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-foz,ou=users,ou=foz,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-foz
description: Admin User - Campus Foz do Iguacu
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-foz.ldif


# Adicionando Usuarios do Campus Foz do Iguacu nos respectivos Grupos
echo "Adicionando Usuarios do Campus Foz do Iguacu nos respectivos Grupos"
cat > group_member_campus_foz.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-foz,ou=users,ou=foz,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-foz,ou=users,ou=foz,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_foz.ldif


###############################################################################################
# Campus Goioere

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Goioere" >> .credenciais-campi.txt
echo "# Usuario: admin-goioere | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-goioere | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Goioere"
cat > ldif-campus-goioere.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=goioere,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Goioere
ou: goioere

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=goioere,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Goioere
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=goioere,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Goioere
ou: groups

##
# Usuarios
dn: cn=replicator-goioere,ou=users,ou=goioere,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-goioere
description: Read Only Replication User - Campus Goioere
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-goioere,ou=users,ou=goioere,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-goioere
description: Admin User - Campus Goioere
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-goioere.ldif


# Adicionando Usuarios do Campus Goioere nos respectivos Grupos
echo "Adicionando Usuarios do Campus Goioere nos respectivos Grupos"
cat > group_member_campus_goioere.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-goioere,ou=users,ou=goioere,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-goioere,ou=users,ou=goioere,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_goioere.ldif


###############################################################################################
# Campus Irati

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Irati" >> .credenciais-campi.txt
echo "# Usuario: admin-irati | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-irati | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Irati"
cat > ldif-campus-irati.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=irati,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Irati
ou: irati

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=irati,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Irati
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=irati,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Irati
ou: groups

##
# Usuarios
dn: cn=replicator-irati,ou=users,ou=irati,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-irati
description: Read Only Replication User - Campus Irati
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-irati,ou=users,ou=irati,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-irati
description: Admin User - Campus Irati
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-irati.ldif


# Adicionando Usuarios do Campus Irati nos respectivos Grupos
echo "Adicionando Usuarios do Campus Irati nos respectivos Grupos"
cat > group_member_campus_irati.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-irati,ou=users,ou=irati,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-irati,ou=users,ou=irati,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_irati.ldif


###############################################################################################
# Campus Ivaipora

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Ivaipora" >> .credenciais-campi.txt
echo "# Usuario: admin-ivaipora | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-ivaipora | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Ivaipora"
cat > ldif-campus-ivaipora.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=ivaipora,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Ivaipora
ou: ivaipora

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=ivaipora,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Ivaipora
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=ivaipora,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Ivaipora
ou: groups

##
# Usuarios
dn: cn=replicator-ivaipora,ou=users,ou=ivaipora,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-ivaipora
description: Read Only Replication User - Campus Ivaipora
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-ivaipora,ou=users,ou=ivaipora,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-ivaipora
description: Admin User - Campus Ivaipora
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-ivaipora.ldif


# Adicionando Usuarios do Campus Ivaipora nos respectivos Grupos
echo "Adicionando Usuarios do Campus Ivaipora nos respectivos Grupos"
cat > group_member_campus_ivaipora.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-ivaipora,ou=users,ou=ivaipora,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-ivaipora,ou=users,ou=ivaipora,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_ivaipora.ldif


###############################################################################################
# Campus Jacarezinho

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Jacarezinho" >> .credenciais-campi.txt
echo "# Usuario: admin-jacarezinho | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-jacarezinho | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Jacarezinho"
cat > ldif-campus-jacarezinho.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=jacarezinho,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Jacarezinho
ou: jacarezinho

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=jacarezinho,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Jacarezinho
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=jacarezinho,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Jacarezinho
ou: groups

##
# Usuarios
dn: cn=replicator-jacarezinho,ou=users,ou=jacarezinho,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-jacarezinho
description: Read Only Replication User - Campus Jacarezinho
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-jacarezinho,ou=users,ou=jacarezinho,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-jacarezinho
description: Admin User - Campus Jacarezinho
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-jacarezinho.ldif


# Adicionando Usuarios do Campus Jacarezinho nos respectivos Grupos
echo "Adicionando Usuarios do Campus Jacarezinho nos respectivos Grupos"
cat > group_member_campus_jacarezinho.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-jacarezinho,ou=users,ou=jacarezinho,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-jacarezinho,ou=users,ou=jacarezinho,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_jacarezinho.ldif


###############################################################################################
# Campus Jaguariaiva

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Jaguariaiva" >> .credenciais-campi.txt
echo "# Usuario: admin-jaguariaiva | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-jaguariaiva | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Jaguariaiva"
cat > ldif-campus-jaguariaiva.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=jaguariaiva,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Jaguariaiva
ou: jaguariaiva

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=jaguariaiva,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Jaguariaiva
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=jaguariaiva,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Jaguariaiva
ou: groups

##
# Usuarios
dn: cn=replicator-jaguariaiva,ou=users,ou=jaguariaiva,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-jaguariaiva
description: Read Only Replication User - Campus Jaguariaiva
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-jaguariaiva,ou=users,ou=jaguariaiva,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-jaguariaiva
description: Admin User - Campus Jaguariaiva
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-jaguariaiva.ldif


# Adicionando Usuarios do Campus Jaguariaiva nos respectivos Grupos
echo "Adicionando Usuarios do Campus Jaguariaiva nos respectivos Grupos"
cat > group_member_campus_jaguariaiva.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-jaguariaiva,ou=users,ou=jaguariaiva,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-jaguariaiva,ou=users,ou=jaguariaiva,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_jaguariaiva.ldif


###############################################################################################
# Campus Londrina

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Londrina" >> .credenciais-campi.txt
echo "# Usuario: admin-londrina | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-londrina | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Londrina"
cat > ldif-campus-londrina.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=londrina,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Londrina
ou: londrina

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=londrina,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Londrina
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=londrina,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Londrina
ou: groups

##
# Usuarios
dn: cn=replicator-londrina,ou=users,ou=londrina,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-londrina
description: Read Only Replication User - Campus Londrina
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-londrina,ou=users,ou=londrina,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-londrina
description: Admin User - Campus Londrina
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-londrina.ldif


# Adicionando Usuarios do Campus Londrina nos respectivos Grupos
echo "Adicionando Usuarios do Campus Londrina nos respectivos Grupos"
cat > group_member_campus_londrina.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-londrina,ou=users,ou=londrina,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-londrina,ou=users,ou=londrina,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_londrina.ldif


###############################################################################################
# Campus Palmas

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Palmas" >> .credenciais-campi.txt
echo "# Usuario: admin-palmas | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-palmas | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Palmas"
cat > ldif-campus-palmas.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=palmas,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Palmas
ou: palmas

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=palmas,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Palmas
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=palmas,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Palmas
ou: groups

##
# Usuarios
dn: cn=replicator-palmas,ou=users,ou=palmas,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-palmas
description: Read Only Replication User - Campus Palmas
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-palmas,ou=users,ou=palmas,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-palmas
description: Admin User - Campus Palmas
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-palmas.ldif


# Adicionando Usuarios do Campus Palmas nos respectivos Grupos
echo "Adicionando Usuarios do Campus Palmas nos respectivos Grupos"
cat > group_member_campus_palmas.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-palmas,ou=users,ou=palmas,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-palmas,ou=users,ou=palmas,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_palmas.ldif


###############################################################################################
# Campus Paranagua

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Paranagua" >> .credenciais-campi.txt
echo "# Usuario: admin-paranagua | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-paranagua | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Paranagua"
cat > ldif-campus-paranagua.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=paranagua,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Paranagua
ou: paranagua

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=paranagua,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Paranagua
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=paranagua,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Paranagua
ou: groups

##
# Usuarios
dn: cn=replicator-paranagua,ou=users,ou=paranagua,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-paranagua
description: Read Only Replication User - Campus Paranagua
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-paranagua,ou=users,ou=paranagua,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-paranagua
description: Admin User - Campus Paranagua
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-paranagua.ldif


# Adicionando Usuarios do Campus Paranagua nos respectivos Grupos
echo "Adicionando Usuarios do Campus Paranagua nos respectivos Grupos"
cat > group_member_campus_paranagua.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-paranagua,ou=users,ou=paranagua,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-paranagua,ou=users,ou=paranagua,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_paranagua.ldif


###############################################################################################
# Campus Paranavai

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Paranavai" >> .credenciais-campi.txt
echo "# Usuario: admin-paranavai | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-paranavai | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Paranavai"
cat > ldif-campus-paranavai.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=paranavai,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Paranavai
ou: paranavai

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=paranavai,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Paranavai
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=paranavai,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Paranavai
ou: groups

##
# Usuarios
dn: cn=replicator-paranavai,ou=users,ou=paranavai,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-paranavai
description: Read Only Replication User - Campus Paranavai
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-paranavai,ou=users,ou=paranavai,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-paranavai
description: Admin User - Campus Paranavai
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-paranavai.ldif


# Adicionando Usuarios do Campus Paranavai nos respectivos Grupos
echo "Adicionando Usuarios do Campus Paranavai nos respectivos Grupos"
cat > group_member_campus_paranavai.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-paranavai,ou=users,ou=paranavai,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-paranavai,ou=users,ou=paranavai,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_paranavai.ldif


###############################################################################################
# Campus Pinhais

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Pinhais" >> .credenciais-campi.txt
echo "# Usuario: admin-pinhais | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-pinhais | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Pinhais"
cat > ldif-campus-pinhais.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=pinhais,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Pinhais
ou: pinhais

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=pinhais,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Pinhais
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=pinhais,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Pinhais
ou: groups

##
# Usuarios
dn: cn=replicator-pinhais,ou=users,ou=pinhais,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-pinhais
description: Read Only Replication User - Campus Pinhais
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-pinhais,ou=users,ou=pinhais,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-pinhais
description: Admin User - Campus Pinhais
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-pinhais.ldif


# Adicionando Usuarios do Campus Pinhais nos respectivos Grupos
echo "Adicionando Usuarios do Campus Pinhais nos respectivos Grupos"
cat > group_member_campus_pinhais.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-pinhais,ou=users,ou=pinhais,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-pinhais,ou=users,ou=pinhais,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_pinhais.ldif


###############################################################################################
# Campus Pitanga

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Pitanga" >> .credenciais-campi.txt
echo "# Usuario: admin-pitanga | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-pitanga | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Pitanga"
cat > ldif-campus-pitanga.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=pitanga,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Pitanga
ou: pitanga

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=pitanga,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Pitanga
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=pitanga,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Pitanga
ou: groups

##
# Usuarios
dn: cn=replicator-pitanga,ou=users,ou=pitanga,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-pitanga
description: Read Only Replication User - Campus Pitanga
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-pitanga,ou=users,ou=pitanga,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-pitanga
description: Admin User - Campus Pitanga
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-pitanga.ldif


# Adicionando Usuarios do Campus Pitanga nos respectivos Grupos
echo "Adicionando Usuarios do Campus Pitanga nos respectivos Grupos"
cat > group_member_campus_pitanga.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-pitanga,ou=users,ou=pitanga,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-pitanga,ou=users,ou=pitanga,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_pitanga.ldif


###############################################################################################
# Campus Quedas do Iguacu

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Quedas do Iguacu" >> .credenciais-campi.txt
echo "# Usuario: admin-quedas | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-quedas | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Quedas do Iguacu"
cat > ldif-campus-quedas.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=quedas,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Quedas do Iguacu
ou: quedas

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=quedas,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Quedas do Iguacu
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=quedas,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Quedas do Iguacu
ou: groups

##
# Usuarios
dn: cn=replicator-quedas,ou=users,ou=quedas,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-quedas
description: Read Only Replication User - Campus Quedas do Iguacu
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-quedas,ou=users,ou=quedas,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-quedas
description: Admin User - Campus Quedas do Iguacu
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-quedas.ldif


# Adicionando Usuarios do Campus Quedas do Iguacu nos respectivos Grupos
echo "Adicionando Usuarios do Campus Quedas do Iguacu nos respectivos Grupos"
cat > group_member_campus_quedas.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-quedas,ou=users,ou=quedas,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-quedas,ou=users,ou=quedas,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_quedas.ldif


###############################################################################################
# Campus Telemaco Borba

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Telemaco Borba" >> .credenciais-campi.txt
echo "# Usuario: admin-telemaco | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-telemaco | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Telemaco Borba"
cat > ldif-campus-telemaco.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=telemaco,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Telemaco Borba
ou: telemaco

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=telemaco,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Telemaco Borba
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=telemaco,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Telemaco Borba
ou: groups

##
# Usuarios
dn: cn=replicator-telemaco,ou=users,ou=telemaco,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-telemaco
description: Read Only Replication User - Campus Telemaco Borba
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-telemaco,ou=users,ou=telemaco,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-telemaco
description: Admin User - Campus Telemaco Borba
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-telemaco.ldif


# Adicionando Usuarios do Campus Telemaco Borba nos respectivos Grupos
echo "Adicionando Usuarios do Campus Telemaco Borba nos respectivos Grupos"
cat > group_member_campus_telemaco.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-telemaco,ou=users,ou=telemaco,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-telemaco,ou=users,ou=telemaco,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_telemaco.ldif


###############################################################################################
# Campus Umuarama

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Umuarama" >> .credenciais-campi.txt
echo "# Usuario: admin-umuarama | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-umuarama | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Umuarama"
cat > ldif-campus-umuarama.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=umuarama,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Umuarama
ou: umuarama

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=umuarama,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Umuarama
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=umuarama,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Umuarama
ou: groups

##
# Usuarios
dn: cn=replicator-umuarama,ou=users,ou=umuarama,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-umuarama
description: Read Only Replication User - Campus Umuarama
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-umuarama,ou=users,ou=umuarama,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-umuarama
description: Admin User - Campus Umuarama
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-umuarama.ldif


# Adicionando Usuarios do Campus Umuarama nos respectivos Grupos
echo "Adicionando Usuarios do Campus Umuarama nos respectivos Grupos"
cat > group_member_campus_umuarama.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-umuarama,ou=users,ou=umuarama,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-umuarama,ou=users,ou=umuarama,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_umuarama.ldif


###############################################################################################
# Campus Uniao da Vitoria

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Uniao da Vitoria" >> .credenciais-campi.txt
echo "# Usuario: admin-uvitoria | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-uvitoria | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Campus Uniao da Vitoria"
cat > ldif-campus-uvitoria.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=uvitoria,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Campus Uniao da Vitoria
ou: uvitoria

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=uvitoria,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Campus Uniao da Vitoria
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=uvitoria,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Campus Uniao da Vitoria
ou: groups

##
# Usuarios
dn: cn=replicator-uvitoria,ou=users,ou=uvitoria,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-uvitoria
description: Read Only Replication User - Campus Uniao da Vitoria
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-uvitoria,ou=users,ou=uvitoria,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-uvitoria
description: Admin User - Campus Uniao da Vitoria
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-campus-uvitoria.ldif


# Adicionando Usuarios do Campus Uniao da Vitoria nos respectivos Grupos
echo "Adicionando Usuarios do Campus Uniao da Vitoria nos respectivos Grupos"
cat > group_member_campus_uvitoria.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-uvitoria,ou=users,ou=uvitoria,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-uvitoria,ou=users,ou=uvitoria,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_uvitoria.ldif


###############################################################################################
# EAD

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus EAD" >> .credenciais-campi.txt
echo "# Usuario: admin-ead | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-ead | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do EAD"
cat > ldif-ead.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=ead,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: EAD
ou: ead

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=ead,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - EAD
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=ead,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - EAD
ou: groups

##
# Usuarios
dn: cn=replicator-ead,ou=users,ou=ead,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-ead
description: Read Only Replication User - EAD
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-ead,ou=users,ou=ead,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-ead
description: Admin User - EAD
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-ead.ldif


# Adicionando Usuarios do Campus EAD nos respectivos Grupos
echo "Adicionando Usuarios do Campus EAD nos respectivos Grupos"
cat > group_member_campus_ead.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-ead,ou=users,ou=ead,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-ead,ou=users,ou=ead,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_campus_ead.ldif


###############################################################################################
# Reitoria

SENHA_ADMIN_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
SENHA_REPLICATOR_CAMPI=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "# Campus Reitoria" >> .credenciais-campi.txt
echo "# Usuario: admin-reitoria | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "# Usuario: replicator-reitoria | Senha: Gerar uma senha antes de utilizar esta conta." >> .credenciais-campi.txt
echo "" >> .credenciais-campi.txt

echo "Configurando acesso para replicacao do Reitoria"
cat > ldif-reitoria.ldif <<_EOF_
# Unidade Organizacional do Campus - Raiz
dn: ou=reitoria,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Reitoria
ou: reitoria

# Unidade Organizacional do Campus - Users
dn: ou=users,ou=reitoria,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Usuarios - Reitoria
ou: users

# Unidade Organizacional do Campus - Groups
dn: ou=groups,ou=reitoria,ou=campi,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
description: Grupos - Reitoria
ou: groups

##
# Usuarios
dn: cn=replicator-reitoria,ou=users,ou=reitoria,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator-reitoria
description: Rreitoria Only Replication User - Reitoria
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_REPLICATOR_CAMPI}`

dn: cn=admin-reitoria,ou=users,ou=reitoria,ou=campi,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-reitoria
description: Admin User - Reitoria
userPassword: `slappasswd -h {SSHA} -u -s ${SENHA_ADMIN_CAMPI}`
_EOF_
ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f ldif-reitoria.ldif


# Adicionando Usuarios da Reitoria nos respectivos Grupos
echo "Adicionando Usuarios da Reitoria nos respectivos Grupos"
cat > group_member_reitoria.ldif <<_EOF_
dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-reitoria,ou=users,ou=reitoria,ou=campi,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=replicator-reitoria,ou=users,ou=reitoria,ou=campi,${DOMINIO_LDAP}
_EOF_
ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f group_member_reitoria.ldif


# ###############################################################################################
# # Configurando ACL dos Usuarios dos Campi
# echo "Configurando ACL do Usuario Replicator - Provider -> Replica"
# cat > acl_campi.ldif <<_EOF_
# dn: olcDatabase={1}mdb,cn=config
# changetype: modify
# add: olcAccess
# olcAccess: to attrs=userPassword,shadowLastChange
#   by dn.base="ou=campi,${DOMINIO_LDAP}" read
#   by self write
#   by anonymous auth
#   by * none
# -
# add: olcAccess
# olcAccess: to dn.regex="^uid=([^,]+),ou=people,${DOMINIO_LDAP}\$"
#   by dn.base="ou=campi,${DOMINIO_LDAP}" read
#   by * none
# -
# add: olcAccess
# olcAccess: to dn.base=""
#   by * read
# -
# add: olcAccess
# olcAccess: to *
#   by dn.base="ou=campi,${DOMINIO_LDAP}" read
#   by * none
# _EOF_

# ldapmodify -Y EXTERNAL -H ldapi:/// -f acl_campi.ldif


###############################################################################################
echo "####################################################" >> .credenciais-campi.txt
printf "O arquivo credenciais-campi.txt foi escrito com sucesso!.\n"


) 2>&1 | tee -a "${log}"

[[ "${VAR_EXCLUI_LDIFS}" == 1 ]] && rm -rfv *.ldif


else

(
printf "Não foi possível executar o script.\n"
exit 1;
) 2>&1 | tee -a "${log}"

fi