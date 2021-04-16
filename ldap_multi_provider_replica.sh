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

log="$(date +%Y-%m-%d_%H-%M)_ldap_multi_provider_replica.log"


## Variaveis
SERVER_ID=""
DOMINIO_LDAP=""
LDAP_PROVIDER_1=""
LDAP_PROVIDER_2=""
LDAP_PROVIDER_3=""
SENHA_REPLICA_CONF=""
SENHA_ADM=""
HELP=""
SAIR=""


# Caso deseje manter os arquivos LDIF gerados, comente esta linha
#VAR_EXCLUI_LDIFS=1


# Realizando leitura dos parametros
while [ -n "$1" ]; do # while loop starts

	case "$1" in

    --SERVER_ID|--server_id) SERVER_ID=$2; shift;;
    --DOMINIO_LDAP|--dominio_ldap) DOMINIO_LDAP=$2; shift;;
    --LDAP_PROVIDER_1|--ldap_provider_1) LDAP_PROVIDER_1=$2; shift;;
    --LDAP_PROVIDER_2|--ldap_provider_2) LDAP_PROVIDER_2=$2; shift;;
    --LDAP_PROVIDER_3|--ldap_provider_3) LDAP_PROVIDER_3=$2; shift;;
    --SENHA_REPLICA_CONF|--senha_replica_conf) SENHA_REPLICA_CONF=$2; shift;;
    --SENHA_ADM|--senha_adm) SENHA_ADM=$2; shift;;

    --HELP|--help)
      echo ""
      echo "Para executar este script é necessário que todos os parametros sejam informados corretamente."
      echo ""
      echo " sudo ./ldap_multi_provider_replica.sh --SERVER_ID 1 --DOMINIO_LDAP cn=xpto,dc=local --LDAP_PROVIDER_1 provider1.ldap.xpto.local --LDAP_PROVIDER_2 provider2.ldap.xpto.local --LDAP_PROVIDER_3 provider3.ldap.xpto.local --SENHA_REPLICA_CONF \"senha_replica_conf\" --SENHA_REPLICA_MDB \"senha_replica_mdb\" --SENHA_ADM \"senha_de_administrador\""
      echo ""
      echo " --SERVER_ID|--server_id                    | <Obrigatorio> ID único de 1 dígitos do Servidor. Ex: 1"
      echo " --DOMINIO_LDAP|--dominio_ldap              | <Obrigatorio> Dominio no formato LDAP. Ex: cn=xpto,cn=local" 
      echo " --LDAP_PROVIDER_1|--ldap_provider_1                | <Obrigatorio> IP ou fqdn do servidor Provider 1. Ex: \"172.16.1.1\" ou \"provider-1.dominio.com.br\""
      echo " --LDAP_PROVIDER_2|--ldap_provider_2                | <Obrigatorio> IP ou fqdn do servidor Provider 2. Ex: \"172.16.1.2\" ou \"provider-2.dominio.com.br\""
      echo " --LDAP_PROVIDER_3|--ldap_provider_3                | <Obrigatorio> IP ou fqdn do servidor Provider 3. Ex: \"172.16.1.3\" ou \"provider-3.dominio.com.br\""
      echo " --SENHA_REPLICA_CONF|--senha_replica_conf  | <Obrigatorio> Senha do usuario de Replica da base conf. Ex: \"h#s9a8dnag62!@\""
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
if [ -z "$SERVER_ID" ]; then
  echo "O Parâmetro \"--SERVER_ID | --server_id\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$DOMINIO_LDAP" ]; then
  echo "O Parâmetro \"--DOMINIO_LDAP | --dominio_ldap\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$LDAP_PROVIDER_1" ]; then
  echo "O Parâmetro \"--LDAP_PROVIDER_1 | --ldap_provider_1\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$LDAP_PROVIDER_2" ]; then
  echo "O Parâmetro \"--LDAP_PROVIDER_2 | --ldap_provider_2\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$LDAP_PROVIDER_3" ]; then
  echo "O Parâmetro \"--LDAP_PROVIDER_3 | --ldap_provider_3\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$SENHA_REPLICA_CONF" ]; then
  echo "O Parâmetro \"--SENHA_REPLICA_CONF | --senha_replica_conf\" não foi informado"
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

# Configurando Replicacao LDAP Multi-Provider
echo "Configurando Replicacao LDAP Multi-Provider"
# Habilitando Modulo SYNCPROV - Base conf
echo "Habilitando Modulo SYNCPROV - Base conf"
cat > syncprov_mod_conf.ldif <<_EOF_
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulePath: /usr/lib/ldap
olcModuleLoad: syncprov.la
_EOF_
ldapadd -Y EXTERNAL -H ldapi:/// -f syncprov_mod_conf.ldif


# Setando ID do server
echo "Setando ID do server"
cat > server_id.ldif <<_EOF_
dn: cn=config
changetype: modify
add: olcServerID
olcServerID: ${SERVER_ID}
_EOF_
ldapadd -Y EXTERNAL -H ldapi:/// -f server_id.ldif


# Configurando Senha para Replicacao Provider da base conf
echo "Configurando Senha para Replicacao Provider da base conf"
cat > passwd_conf_database.ldif <<_EOF_
dn: olcDatabase={0}config,cn=config
add: olcRootPW
olcRootPW: ${SENHA_REPLICA_CONF}
_EOF_
ldapmodify -Y EXTERNAL -H ldapi:/// -f passwd_conf_database.ldif


# Configurando Replicacao Provider da base conf
echo "Configurando Replicacao Provider da base conf"
cat > config_rep_conf.ldif <<_EOF_
### Update Server ID with LDAP URL ###

dn: cn=config
changetype: modify
replace: olcServerID
olcServerID: 1 ldap://${LDAP_PROVIDER_1}
olcServerID: 2 ldap://${LDAP_PROVIDER_2}
olcServerID: 3 ldap://${LDAP_PROVIDER_3}

### Enable Config Replication###
dn: olcOverlay=syncprov,olcDatabase={0}config,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov

### Adding config details for confDB replication ###
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=001
  provider=ldap://${LDAP_PROVIDER_1}
  binddn="cn=config"
  bindmethod=simple
  credentials=${SENHA_REPLICA_CONF}
  searchbase="cn=config"
  type=refreshAndPersist
  retry="5 5 60 10 300 5"
  timeout=1
olcSyncRepl: rid=002
  provider=ldap://${LDAP_PROVIDER_2}
  binddn="cn=config"
  bindmethod=simple
  credentials=${SENHA_REPLICA_CONF}
  searchbase="cn=config"
  type=refreshAndPersist
  retry="5 5 60 10 300 5"
  timeout=1
olcSyncRepl: rid=003
  provider=ldap://${LDAP_PROVIDER_3}
  binddn="cn=config"
  bindmethod=simple
  credentials=${SENHA_REPLICA_CONF}
  searchbase="cn=config"
  type=refreshAndPersist
  retry="5 5 60 10 300 5"
  timeout=1
-
add: olcMirrorMode
olcMirrorMode: TRUE
_EOF_
ldapmodify -Y EXTERNAL -H ldapi:/// -f config_rep_conf.ldif


# Habilitando modulo SYNCPROV - Base mdb
echo "Habilitando modulo SYNCPROV - Base mdb"
cat > syncprov_mod_mdb.ldif <<_EOF_
dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpCheckpoint: 100 10
olcSpSessionLog: 100000
_EOF_
ldapmodify -Y EXTERNAL -H ldapi:/// -f syncprov_mod_mdb.ldif


# Configurando Replicacao Provider da base mbd
echo "Configurando Replicacao Provider da base mdb"
cat > config_rep_mdb.ldif <<_EOF_
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: ${DOMINIO_LDAP}
-
add: olcSyncRepl
olcSyncRepl: rid=004
  provider=ldap://${LDAP_PROVIDER_1}
  binddn="cn=admin,${DOMINIO_LDAP}"
  bindmethod=simple
  credentials=${SENHA_ADM}
  searchbase="${DOMINIO_LDAP}"
  scope=sub
  schemachecking=on
  type=refreshAndPersist
  interval=00:00:00:05
  retry="5 5 60 10 300 5"
  timeout=1
olcSyncRepl: rid=005
  provider=ldap://${LDAP_PROVIDER_2}
  binddn="cn=admin,${DOMINIO_LDAP}"
  bindmethod=simple
  credentials=${SENHA_ADM}
  searchbase="${DOMINIO_LDAP}"
  scope=sub
  schemachecking=on
  type=refreshAndPersist
  interval=00:00:00:05
  retry="5 5 60 10 300 5"
  timeout=1
olcSyncRepl: rid=006
  provider=ldap://${LDAP_PROVIDER_3}
  binddn="cn=admin,${DOMINIO_LDAP}"
  bindmethod=simple
  credentials=${SENHA_ADM}
  searchbase="${DOMINIO_LDAP}"
  scope=sub
  schemachecking=on
  type=refreshAndPersist
  interval=00:00:00:05
  retry="5 5 60 10 300 5"
  timeout=1
-
add: olcDbIndex
olcDbIndex: entryUUID  eq
-
add: olcDbIndex
olcDbIndex: entryCSN  eq
-
add: olcMirrorMode
olcMirrorMode: TRUE
_EOF_
ldapmodify -Y EXTERNAL  -H ldapi:/// -f config_rep_mdb.ldif


# # Configurando Monitor da Replicacao Provider
# echo "Configurando Monitor da Replicacao Provider"
# cat > monitor.ldif <<_EOF_
# dn: olcDatabase={1}monitor,cn=config
# changetype: modify
# replace: olcAccess
# olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=admin,${DOMINIO_LDAP}" read by * none
# _EOF_
# ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif


###############################################################################################

) 2>&1 | tee -a "${log}"

[[ "${VAR_EXCLUI_LDIFS}" == 1 ]] && rm -rfv *.ldif


else

(
printf "Não foi possível executar o script.\n"
exit 1;
) 2>&1 | tee -a "${log}"

fi