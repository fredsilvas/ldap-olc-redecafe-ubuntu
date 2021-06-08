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

if [[ $(id -u) -ne 0 ]] ; then echo "É necessário rodar como root/sudo." ; exit 1 ; fi

log="$(date +%Y-%m-%d_%H-%M)_ldap_read_only_replica.log"


# ## Variaveis
# DOMINIO_LDAP=""
# SENHA_ROR_REPLICATOR=""
# SENHA_ADM=""
# HELP=""
# SAIR=""

# Caso deseje manter os arquivos LDIF gerados, comente esta linha
#VAR_EXCLUI_LDIFS=1


# # Realizando leitura dos parametros
# while [ -n "$1" ]; do # while loop starts

# 	case "$1" in

#     --DOMINIO_LDAP|--dominio_ldap) DOMINIO_LDAP=$2; shift;;
#     --SENHA_ROR_REPLICATOR|--senha_ror_replicator) SENHA_ROR_REPLICATOR=$2; shift;;
#     --SENHA_ADM|--senha_adm) SENHA_ADM=$2; shift;;

#     --HELP|--help)
#       echo ""
#       echo "Para executar este script é necessário que todos os parametros sejam informados corretamente."
#       echo ""
#       echo " sudo ./ldap_read_only_replica.sh --DOMINIO_LDAP cn=xpto,dc=local --SENHA_ROR_REPLICATOR \"senha_ror_replicator\" --SENHA_ADM \"senha_de_administrador\""
#       echo ""
#       echo " --DOMINIO_LDAP|--dominio_ldap                 | <Obrigatorio> Dominio no formato LDAP. Ex: cn=xpto,cn=local"
#       echo " --SENHA_ROR_REPLICATOR|--senha_ror_replicator | <Obrigatorio> Senha do usuario de Read Only Replica da base ldap. Ex: \"h#s9a8dnag62!@\""
#       echo " --SENHA_ADM|--senha_adm                       | <Obrigatorio> Senha do Administrador do LDAP. Ex: \"h#s9a8dnag62!@\""
#       echo ""
#       echo "*** IMPORTANTE ***"
#       echo "Quando um parametro necessitar de valores separados por espaco, escrever o mesmo entre aspas duplas. Exemplo \"Empresa XPTO Ltda\""
#       exit 1;
#       ;;

# 	  *) echo "Parametro $1 nao reconhecido. Digite --HELP|--help para lista de parametros"
#        ;;

# 	esac

# 	shift

# done

# # Checando se todos os parametros foram informados
# if [ -z "$DOMINIO_LDAP" ]; then
#   echo "O Parâmetro \"--DOMINIO_LDAP | --dominio_ldap\" não foi informado"
#   echo ""
#   SAIR="1"
# fi

# if [ -z "$SENHA_ROR_REPLICATOR" ]; then
#   echo "O Parâmetro \"--SENHA_ROR_REPLICATOR | --senha_ror_replicator\" não foi informado"
#   echo ""
#   SAIR="1"
# fi

# if [ -z "$SENHA_ADM" ]; then
#   echo "O Parâmetro \"--SENHA_ADM | --senha_adm\" não foi informado."
#   echo ""
#   SAIR="1"
# fi


# # Iniciando Script
# if [ -z $SAIR ]; then
# echo "Iniciando execução do script..."


###############################################################################################
(

# Configurando Replicacao LDAP Replica -> Campi
echo "# Configurando Replicacao LDAP Replica -> Campi"
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



###############################################################################################

) 2>&1 | tee -a "${log}"

[[ "${VAR_EXCLUI_LDIFS}" == 1 ]] && rm -rfv *.ldif


# else

# (
# printf "Não foi possível executar o script.\n"
# exit 1;
# ) 2>&1 | tee -a "${log}"

# fi