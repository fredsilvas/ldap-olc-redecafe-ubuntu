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

log="$(date +%Y-%m-%d_%H-%M)_instalacao-ldap-cafe.log"


## Variaveis

#DOMINIO="dti.local"
#DOMINIO_LDAP="dc=dti,dc=local"
#DC="dti"
#ORGANIZACAO="DTI"
#DESCRICAO="Diretoria de Tecnologia da Informação"
#CIDADE="Cidade"
#UF="Estado"

#SENHA_ADM="senha-adm"
#SENHA_SHIB="senha-shib"


DOMINIO=""
DOMINIO_LDAP=""
DC=""
ORGANIZACAO=""
DESCRICAO=""
CIDADE=""
UF=""

SENHA_ADM=""
SENHA_ADM_PASSAPORTE=""
SENHA_LEITOR_PASSAPORTE=""
SENHA_SHIB=""
SENHA_USER_TESTE=""
USER_TESTE=""
HELP=""
SAIR=""


# Realizando leitura dos parametros
while [ -n "$1" ]; do # while loop starts

	case "$1" in

    --DOMINIO|--dominio) DOMINIO=$2; shift;;
    --DOMINIO_LDAP|--dominio_ldap) DOMINIO_LDAP=$2; shift;;
    --DC|--dc) DC=$2; shift;;
    --ORGANIZACAO|--organizacao) ORGANIZACAO=$2; shift;;
    --DESCRICAO|--descricao) DESCRICAO=$2; shift;;
    --CIDADE|--cidade) CIDADE=$2; shift;;
    --UF|--uf) UF=$2; shift;;
    --SENHA_ADM|--senha_adm) SENHA_ADM=$2; shift;;
    --SENHA_ADM_PASSAPORTE|--senha_adm_passaporte) SENHA_ADM_PASSAPORTE=$2; shift;;
    --SENHA_LEITOR_PASSAPORTE|--senha_leitor_passaporte) SENHA_LEITOR_PASSAPORTE=$2; shift;;
    --SENHA_SHIB|--senha_shib) SENHA_SHIB=$2; shift;;
    --SENHA_USER_TESTE|--senha_user_teste) SENHA_USER_TESTE=$2; shift;;
    --USER_TESTE|--user_teste) USER_TESTE=$2; shift;;
  
    --HELP|--help)
      echo ""
      echo "Para executar este script é necessário que todos os parametros sejam informados corretamente."
      echo ""
      echo " sudo ./novo_ldap_server.sh --DOMINIO xpto.local --DOMINIO_LDAP cn=xpto,dc=local --DC xpto --ORGANIZACAO XPTO --DESCRICAO \"Empresa XPTO\" --CIDADE Curitiba --UF PR --SENHA_ADM \"senha_de_administrador\" --SENHA_ADM_PASSAPORTE \"senha_de_administrador_passaporte\" --SENHA_LEITOR_PASSAPORTE \"senha_de_leitura_passaporte\" --SENHA_SHIB \"senha_usuario_shibboleth\" --USER_TESTE nao"
      echo ""
      echo " --DOMINIO|--dominio                                 | <Obrigatorio> Dominio a ser condfigurado. Ex: xpto.local"
      echo " --DOMINIO_LDAP|--dominio_ldap                       | <Obrigatorio> Dominio no formato LDAP. Ex: cn=xpto,cn=local" 
      echo " --DC|--dc                                           | <Obrigatorio> Primeira parte do dominio. Ex: xpto"
      echo " --ORGANIZACAO|--organizacao                         | <Obrigatorio> Sigla da Organizacao. Ex: XPTO"
      echo " --DESCRICAO|--descricao                             | <Obrigatorio> Nome/Descricao da Organizacao: Ex: \"Empresa XPTO Ltda.\""
      echo " --CIDADE|--cidade                                   | <Obrigatorio> Cidade da Organizacao. Ex: Curitiba"
      echo " --UF|--uf                                           | <Obrigatorio> UF da Organizacao. Ex: PR"
      echo " --SENHA_ADM|--senha_adm                             | [Opcional] Senha do Administrador do LDAP. Ex: \"h#s9a8dnag62!@\""
      echo " --SENHA_ADM_PASSAPORTE|--senha_adm_passaporte       | [Opcional] Senha de Administrador do Passaporte LDAP. Ex: \"h#s9a8dnag62!@\""
      echo " --SENHA_LEITOR_PASSAPORTE|--senha_leitor_passaporte | [Opcional] Senha de Administrador do Passaporte LDAP. Ex: \"h#s9a8dnag62!@\""
      echo " --SENHA_SHIB|--senha_shib                           | [Opcional] Senha do Leitor Shibboleth do LDAP. Ex: \"dhh1234h**76\""
      echo " --SENHA_USER_TESTE|--senha_user_teste               | [Opcional] Senha do Usuário de Testes do LDAP. Ex: \"dhh1234h**76\""
      echo " --USER_TESTE|--user_teste                           | <Obrigatorio> Informa se será criado usuario de teste no do LDAP. Valores aceitos: sim|SIM / nao|NAO "
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
if [ -z "$DOMINIO" ]; then
  echo "O Parâmetro \"--DOMINIO | --dominio\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$DOMINIO_LDAP" ]; then
  echo "O Parâmetro \"--DOMINIO_LDAP | --dominio_ldap\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$DC" ]; then
  echo "O Parâmetro \"--DC | --dc\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$ORGANIZACAO" ]; then
  echo "O Parâmetro \"--ORGANIZACAO | --organizacao\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$DESCRICAO" ]; then
  echo "O Parâmetro \"--DESCRICAO | --descricao\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$CIDADE" ]; then
  echo "O Parâmetro \"--CIDADE | --cidade\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$UF" ]; then
  echo "O Parâmetro \"--UF | --uf\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ -z "$SENHA_ADM" ]; then
  echo "O Parâmetro \"--SENHA_ADM | --senha_adm\" não foi informado. Será gerada uma senha aleatória."
  echo ""
fi

if [ -z "$SENHA_ADM_PASSAPORTE" ]; then
  echo "O Parâmetro \"--SENHA_ADM_PASSAPORTE | --senha_adm_passaporte\" não foi informado. Será gerada uma senha aleatória."
  echo ""
fi

if [ -z "$SENHA_LEITOR_PASSAPORTE" ]; then
  echo "O Parâmetro \"--SENHA_LEITOR_PASSAPORTE | --senha_leitor_passaporte\" não foi informado. Será gerada uma senha aleatória."
  echo ""
fi

if [ -z "$SENHA_SHIB" ]; then
  echo "O Parâmetro \"--SENHA_SHIB | --senha_shib\" não foi informado. Será gerada uma senha aleatória."
  echo ""
fi

if [ -z "$SENHA_USER_TESTE" ]; then
  echo "O Parâmetro \"--SENHA_USER_TESTE | --senha_user_teste\" não foi informado. Será gerada uma senha aleatória."
  echo ""
fi

if [ -z "$USER_TESTE" ]; then
  echo "O Parâmetro \"--USER_TESTE | --user_teste\" não foi informado"
  echo ""
  SAIR="1"
fi

if [ "$USER_TESTE" != "sim" ] && [ "$USER_TESTE" != "SIM" ] &&  [ "$USER_TESTE" != "nao" ] && [ "$USER_TESTE" != "NAO" ]; then
  echo "O Parâmetro \"--USER_TESTE | --user_teste\" foi informado incorretamente. Apenas é aceito sim|SIM ou nao|NAO"
  echo ""
  SAIR="1"
fi


# Iniciando Script
if [ -z $SAIR ]; then
echo "Iniciando execução do script..."

(

export DEBIAN_FRONTEND='noninteractive'
echo -e "slapd slapd/root_password password $SENHA_ADM" |debconf-set-selections
echo -e "slapd slapd/root_password_again password $SENHA_ADM" |debconf-set-selections
echo -e "slapd slapd/internal/adminpw password $SENHA_ADM" |debconf-set-selections
echo -e "slapd slapd/internal/generated_adminpw password $SENHA_ADM" |debconf-set-selections
echo -e "slapd slapd/password2 password $SENHA_ADM" |debconf-set-selections
echo -e "slapd slapd/password1 password $SENHA_ADM" |debconf-set-selections
echo -e "slapd slapd/domain string $DOMINIO" |debconf-set-selections
echo -e "slapd shared/organization string $ORGANIZACAO" |debconf-set-selections
echo -e "slapd slapd/backend string MDB" |debconf-set-selections
echo -e "slapd slapd/purge_database boolean false" |debconf-set-selections
echo -e "slapd slapd/move_old_database boolean true" |debconf-set-selections
echo -e "slapd slapd/allow_ldap_v2 boolean false" |debconf-set-selections
echo -e "slapd slapd/no_configuration boolean false" |debconf-set-selections


# Grab slapd and ldap-utils (pre-seeded)
apt-get update && apt-get upgrade -y
apt-get install -y slapd ldap-utils slapd-smbk5pwd

# Must reconfigure slapd for it to work properly 
#sudo dpkg-reconfigure slapd

systemctl enable slapd.service
systemctl start slapd.service


# Descomentar e setar as variáveis caso deseje usar certificado já criado.
#VAR_USAR_CERT=1
#VAR_CERT_ROOT_CA=
#VAR_CERT_CRT=
#VAR_CERT_KEY=

# Caso deseje manter os arquivos LDIF gerados, comente esta linha
#VAR_EXCLUI_LDIFS=1

# Tipo de Backend. Valores possiveis: mdb, hdb
TIPO_BACKEND=mdb

# Verificacao se senhas foram informadas
if [ -z "$SENHA_ADM" ]; then
SENHA_ADM=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "SENHA_ADM gerada aleatoriamente: $SENHA_ADM"
echo ""
fi

if [ -z "$SENHA_ADM_PASSAPORTE" ]; then
SENHA_ADM_PASSAPORTE=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "SENHA_ADM_PASSAPORTE gerada aleatoriamente: $SENHA_ADM_PASSAPORTE"
echo ""
fi

if [ -z "$SENHA_LEITOR_PASSAPORTE" ]; then
SENHA_LEITOR_PASSAPORTE=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "SENHA_LEITOR_PASSAPORTE gerada aleatoriamente: $SENHA_LEITOR_PASSAPORTE"
echo ""
fi

if [ -z "$SENHA_SHIB" ]; then
SENHA_SHIB=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "SENHA_SHIB gerada aleatoriamente: $SENHA_SHIB"
echo ""
fi

if [ -z "$SENHA_USER_TESTE" ]; then
SENHA_USER_TESTE=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
echo "SENHA_USER_TESTE gerada aleatoriamente: $SENHA_USER_TESTE"
echo ""
fi

HASH_SENHA_ADM=$( slappasswd -h {SSHA} -u -s $SENHA_ADM )
HASH_SENHA_ADM_PASSAPORTE=$( slappasswd -h {SSHA} -u -s $SENHA_ADM_PASSAPORTE )
HASH_SENHA_LEITOR_PASSAPORTE=$( slappasswd -h {SSHA} -u -s $SENHA_LEITOR_PASSAPORTE )
HASH_SENHA_SHIB=$( slappasswd -h {SSHA} -u -s $SENHA_SHIB )
HASH_SENHA_USER_TESTE=$( slappasswd -h {SSHA} -u -s $SENHA_USER_TESTE )

## Configuração inicial do backend e definição da senha do usuário admin
printf "################### Configuração do Backend ###################\n\n"

cat > 01-size_backend_mdb.ldif <<_EOF_
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcDbMaxSize
olcDbMaxSize: 3221225472
_EOF_

ldapmodify -Y EXTERNAL -H ldapi:/// -f 01-size_backend_mdb.ldif


## Criação da estrutura de árvore e subarvore - people
printf "################### Criação da estrutura de árvore e subarvore - people ${DOMINIO_LDAP} ###################\n\n"

cat > 02-people.ldif <<_EOF_
dn: ou=people,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
ou: people
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 02-people.ldif


cat > 02.1-people_servidores.ldif <<_EOF_
dn: ou=servidores,ou=people,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
ou: servidores
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 02.1-people_servidores.ldif


cat > 02.2-people_alunos.ldif <<_EOF_
dn: ou=alunos,ou=people,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
ou: alunos
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 02.2-people_alunos.ldif


## Geração do certificado SSL
printf "################### Criação / Instalação do Certificado SSL ###################\n\n"

cat > 03-ssl.ldif <<_EOF_
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/sasl2/${DOMINIO}.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/sasl2/${DOMINIO}.key
_EOF_

if [ "${VAR_USAR_CERT}" == 1 ]; then ########################

cp "${CERT_ROOT_CA}" /etc/ldap/sasl2/${DOMINIO}.pem
cp "${CERT_CRT}" /etc/ldap/sasl2/${DOMINIO}.crt
cp "${CERT_KEY}" /etc/ldap/sasl2/${DOMINIO}.key

cat >> 03-ssl.ldif <<_EOF_
-
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/sasl2/${DOMINIO}.pem
_EOF_

else ########################################################

openssl req -new -x509 -nodes -out /etc/ldap/sasl2/${DOMINIO}.crt -keyout /etc/ldap/sasl2/${DOMINIO}.key -days 3650 -subj "/C=BR/ST=${UF}/L=${CIDADE}/O=${DESCRICAO}/CN=${DOMINIO}"

fi ##########################################################

chown -R openldap:openldap /etc/ldap/sasl2/${DOMINIO}*

ldapmodify -Y EXTERNAL -H ldapi:/// -f 03-ssl.ldif

cp /etc/default/slapd /etc/default/slapd.default
#sed -i 's#ldap:///"$#ldap:/// ldaps:///"#' /etc/sysconfig/slapd
sed -i 's#SLAPD_SERVICES="ldap:/// ldapi:///"#SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"#' /etc/default/slapd

systemctl restart slapd


## Importação dos Schemas para uso da Rede CAFe
printf "################### Importação dos Schemas ###################\n\n"

ldapadd -Y EXTERNAL -H ldapi:/// -f schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f schema/ppolicy.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f schema/eduperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f schema/breduperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f schema/schac-20061212-1.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f schema/samba.ldif


## Configuração dos Overlays
printf "################### Configuração dos Overlays Samba e MemberOf ###################\n\n"

cat > 04-overlays.ldif <<_EOF_
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulePath: /usr/lib/ldap
olcModuleLoad: smbk5pwd
olcModuleLoad: refint
olcModuleLoad: memberof
olcModuleLoad: ppolicy
_EOF_

ldapadd -Y EXTERNAL -H ldapi:/// -f 04-overlays.ldif



cat > 05-smbk5pwd_conf_mdb.ldif <<_EOF_
dn: olcOverlay=smbk5pwd,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSmbK5PwdConfig
objectClass: olcConfig
objectClass: top
olcOverlay: smbk5pwd
olcSmbK5PwdEnable: samba
_EOF_

ldapadd -Y EXTERNAL -H ldapi:/// -f 05-smbk5pwd_conf_mdb.ldif


cat > 06-memberof_conf_mdb.ldif <<_EOF_
dn: olcOverlay=memberof,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcMemberOf
objectClass: olcConfig
objectClass: top
olcOverlay: memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfNames
olcMemberOfMemberAD: member
olcMemberOfMemberOfAD: memberOf
_EOF_

ldapadd -Y EXTERNAL -H ldapi:/// -f 06-memberof_conf_mdb.ldif


cat > 07-refint_conf_mdb.ldif <<_EOF_
dn: olcOverlay=refint,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: olcConfig
objectClass: top
olcOverlay: refint
olcRefintAttribute: memberof member manager owner
_EOF_

ldapadd -Y EXTERNAL -H ldapi:/// -f 07-refint_conf_mdb.ldif


cat > 08-ppolicy_conf_ou.ldif <<_EOF_
dn: ou=pwpolicy,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
ou: pwpolicy
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 08-ppolicy_conf_ou.ldif


cat > 08.1-ppolicy_conf_mdb.ldif <<_EOF_
dn: olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcPPolicyConfig
olcOverlay: ppolicy
olcPPolicyDefault: cn=pwp-user-ativo,ou=pwpolicy,${DOMINIO_LDAP}
olcPPolicyHashCleartext: TRUE
_EOF_

ldapadd -Y EXTERNAL -H ldapi:/// -f 08.1-ppolicy_conf_mdb.ldif


cat > 08.2-ppolicy_user_ativo.ldif <<_EOF_
dn: cn=pwp-user-ativo,ou=pwpolicy,${DOMINIO_LDAP}
cn: pwp-user-ativo
objectClass: pwdPolicyChecker
objectClass: pwdPolicy
objectClass: organizationalRole
objectClass: top
pwdAllowUserChange: TRUE
pwdAttribute: userPassword
pwdExpireWarning: 600
pwdLockout: FALSE
pwdLockoutDuration: 0
pwdMaxAge: 0
pwdMinAge: 0
pwdMustChange: FALSE
pwdSafeModify: FALSE
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 08.2-ppolicy_user_ativo.ldif


cat > 08.3-ppolicy_user_inativo.ldif <<_EOF_
dn: cn=pwp-user-inativo,ou=pwpolicy,${DOMINIO_LDAP}
cn: pwp-user-inativo
objectClass: pwdPolicyChecker
objectClass: pwdPolicy
objectClass: organizationalRole
objectClass: top
pwdAllowUserChange: FALSE
pwdAttribute: userPassword
pwdLockout: TRUE
pwdAccountLockedTime: 20000101020000Z
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 08.3-ppolicy_user_inativo.ldif


## Criação de usuário de exemplo na rede
if [ $USER_TESTE == "sim" ] || [ $USER_TESTE == "SIM" ]; then
printf "################### Criação do usuário de exemplo ###################\n\n"


cat > 09-usuario_exemplo.ldif <<_EOF_
dn: uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
objectClass: person
objectClass: inetOrgPerson
objectClass: brPerson
objectClass: schacPersonalCharacteristics
objectClass: eduPerson
uid: teste.login
brcpf: 12345678900
brpassport: A23456
departmentNumber:12345
schacCountryOfCitizenship: Brazil
telephoneNumber: +55 12 34567890
mail: teste.login@teste.com.br
eduPersonPrincipalName: teste.login@teste.com.br
cn: Teste Login
givenName: Teste
sn: Login
userPassword: ${HASH_SENHA_USER_TESTE}
schacDateOfBirth:19891030
pwdPolicySubentry:cn=pwp-user-ativo,ou=pwpolicy,${DOMINIO_LDAP}
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 09-usuario_exemplo.ldif


## Configurações extras de usuário segundo o Samba
printf "################### Adição dos dados do Samba do usuário ###################\n\n"

cat > 09.1-usuario_exemplo_samba.ldif <<_EOF_
dn: uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
changetype: modify
add: objectClass
objectClass: sambaSamAccount
-
add: sambaSID
sambaSID: S-1-5-21-${RANDOM}-${RANDOM}-${RANDOM}-1102
_EOF_

ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 09.1-usuario_exemplo_samba.ldif

ldappasswd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -s ${SENHA_USER_TESTE} "uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}"


## Configurações extras de usuário segundo o brEduPerson
printf "################### Adição dos dados do brEduPerson do usuário ###################\n\n"

# cat > 09.2-usuario_exemplo_info_extras.ldif <<_EOF_
# dn: braff=1,uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
# objectclass: brEduPerson
# braff: 1
# brafftype: aluno-graduacao
# brEntranceDate: 20070205

# dn: braff=2,uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
# objectclass: brEduPerson
# braff: 2
# brafftype: professor
# brEntranceDate: 20070205
# brExitDate: 20080330

# dn: brvoipphone=1,uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
# objectclass: brEduVoIP
# brvoipphone: 1
# brEduVoIPalias: 2345
# brEduVoIPtype: pstn
# brEduVoIPadmin: uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
# brEduVoIPcallforward: +55 22 3418 9199
# brEduVoIPaddress: 200.157.0.333
# brEduVoIPexpiryDate:  20081030
# brEduVoIPbalance: 295340
# brEduVoIPcredit: 300000

# dn: brvoipphone=2,uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
# objectclass: brEduVoIP
# brvoipphone: 2
# brvoipalias: 2346
# brEduVoIPtype: celular
# brEduVoIPadmin: uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}

# dn: brbiosrc=left-middle,uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
# objectclass: brBiometricData
# brbiosrc: left-middle
# brBiometricData: ''
# brCaptureDate: 20001212
# _EOF_

cat > 09.2-usuario_exemplo_info_extras.ldif <<_EOF_
dn: uniqueIdentifier=122193,uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
objectclass: brEduPerson
objectclass: eduPerson
objectclass: extensibleObject
objectClass: top
braff: 3
brafftype: tecadm
eduPersonScopedAffiliation: curitiba
brEntranceDate: 20070201

dn: uniqueIdentifier=223451,uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
objectclass: brEduPerson
objectclass: eduPerson
objectclass: extensibleObject
objectClass: top
braff: 2
brafftype: docente
eduPersonScopedAffiliation: clargo
brEntranceDate: 20100401

_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 09.2-usuario_exemplo_info_extras.ldif

fi


## Criação de usuário admin Passaporte
printf "################### Criação do usuário admin-passaporte ###################\n\n"

cat > 10-admin_passaporte.ldif <<_EOF_
dn: cn=admin-passaporte,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin-passaporte
description: Usuário Passaporte para escrita na base LDAP
userPassword: ${HASH_SENHA_ADM_PASSAPORTE}
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 10-admin_passaporte.ldif


## Criação de usuário de leitura para o Shibboleth e Passaporte
printf "################### Criação dos usuários leitor-shib e leitor-passaporte ###################\n\n"

cat > 11-leitores.ldif <<_EOF_
dn: cn=leitor-shib,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: leitor-shib
description: Leitor da base para o shibboleth
userPassword: ${HASH_SENHA_SHIB}

dn: cn=leitor-passaporte,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: leitor-passaporte
description: Leitor da base para o Passaporte
userPassword: ${HASH_SENHA_LEITOR_PASSAPORTE}
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 11-leitores.ldif


## Criação do usuário teste (utilizado para criacao de grupos)
printf "################### Criação do usuário teste (utilizado para criacao de grupos) ###################\n\n"

cat > 12-user_teste.ldif <<_EOF_
dn: cn=user-teste,${DOMINIO_LDAP}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: user-teste
description: Usuario Teste
userPassword: 1234567890
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 12-user_teste.ldif


## Criação de grupos genéricos de permissões
printf "################### Configuração dos grupos admins, leitores e replicadores ###################\n\n"

cat > 13-grupos.ldif <<_EOF_
dn: ou=groups,${DOMINIO_LDAP}
objectClass: organizationalUnit
objectClass: top
ou: groups

dn: cn=admins,ou=groups,${DOMINIO_LDAP}
objectClass: groupofnames
objectClass: top
cn: admins
member: cn=admin,${DOMINIO_LDAP}

dn: cn=leitores,ou=groups,${DOMINIO_LDAP}
objectClass: groupofnames
objectClass: top
cn: leitores
member: cn=leitor-shib,${DOMINIO_LDAP}

dn: cn=leitores-campi,ou=groups,${DOMINIO_LDAP}
objectClass: groupofnames
objectClass: top
cn: leitores-campi
member: cn=user-teste,${DOMINIO_LDAP}

dn: cn=replicadores,ou=groups,${DOMINIO_LDAP}
objectClass: groupofnames
objectClass: top
cn: replicadores
member: cn=user-teste,${DOMINIO_LDAP}

dn: cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}
objectClass: groupofnames
objectClass: top
cn: replicadores-campi
member: cn=user-teste,${DOMINIO_LDAP}

dn: cn=dtic,ou=groups,${DOMINIO_LDAP}
objectClass: groupofnames
objectClass: top
cn: dtic
member: cn=user-teste,${DOMINIO_LDAP}
_EOF_

ldapadd -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 13-grupos.ldif


cat > 14-grupos_passaporte.ldif <<_EOF_
dn: cn=admins,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=admin-passaporte,${DOMINIO_LDAP}

dn: cn=leitores,ou=groups,${DOMINIO_LDAP}
changetype: modify
add: member
member: cn=leitor-passaporte,${DOMINIO_LDAP}
_EOF_

ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 14-grupos_passaporte.ldif


## Adicionar usuários nos grupos


#if [ $USER_TESTE == "sim" ] || [ $USER_TESTE == "SIM" ]; then
#printf "################### Adicionando usuário de exemplo no grupo admin ###################\n\n"

# cat > 16-usr_grupos.ldif <<_EOF_
# dn: cn=admins,ou=groups,${DOMINIO_LDAP}
# changetype: modify
# add: member
# member: uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}
# _EOF_

# ldapmodify -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -H ldap:// -f 16-usr_grupos.ldif

#fi


## Criação das ACLs para acesso ao LDAP
printf "################### Criação das ACLs para acesso ao LDAP ###################\n\n"

cat > 15-acls_mdb.ldif <<_EOF_
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to *
  by dn.base="cn=admin,${DOMINIO_LDAP}" manage
  by * break
-
add: olcAccess
olcAccess: {1}to *
  by group.base="cn=admins,ou=groups,${DOMINIO_LDAP}" write
  by group.base="cn=dtic,ou=groups,${DOMINIO_LDAP}" write
  by group.base="cn=leitores,ou=groups,${DOMINIO_LDAP}" read
  by group.base="cn=leitores-campi,ou=groups,${DOMINIO_LDAP}" read
  by group.base="cn=replicadores,ou=groups,${DOMINIO_LDAP}" read
  by group.base="cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}" read
  by * break
-
add: olcAccess
olcAccess: to attrs=userPassword,sambaNTPassword,sambaLMPassword,sambaPasswordHistory,sambaPwdLastSet,shadowLastChange
  by dn.base="cn=admin,${DOMINIO_LDAP}" write
  by dn.base="cn=admin-passaporte,${DOMINIO_LDAP}" write
  by group.base="cn=admins,ou=groups,${DOMINIO_LDAP}" write
  by group.base="cn=dtic,ou=groups,${DOMINIO_LDAP}" write
  by group.base="cn=leitores,ou=groups,${DOMINIO_LDAP}" read
  by group.base="cn=leitores-campi,ou=groups,${DOMINIO_LDAP}" read
  by group.base="cn=replicadores,ou=groups,${DOMINIO_LDAP}" read
  by group.base="cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}" read
  by self write
  by anonymous auth
  by * break
-
add: olcAccess
olcAccess: to dn.base=""
  by anonymous auth
  by * read
_EOF_

ldapmodify -Y EXTERNAL -H ldapi:/// -f 15-acls_mdb.ldif

# printf "17-acl_replicator_mdb.ldif"
# cat > 17-acl_replicator_mdb.ldif <<_EOF_
# dn: olcDatabase={1}mdb,cn=config
# changetype: modify
# add: olcAccess
# olcAccess: {0}to *
#   by group.base="cn=replicadores,ou=groups,${DOMINIO_LDAP}" read
#   by group.base="cn=replicadores-campi,ou=groups,${DOMINIO_LDAP}" read
#   by * break
# _EOF_

# ldapmodify -Y EXTERNAL -H ldapi:/// -f 17-acl_replicator_mdb.ldif


## Criação dos Limits para replicacao
printf "################### Criação dos Limits para replicacao ###################\n\n"

cat > 16-limits_replicator_mdb.ldif <<_EOF_
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcLimits
olcLimits: group/groupOfNames/member="cn=admins,ou=groups,${DOMINIO_LDAP}"
  time.soft=unlimited time.hard=unlimited
  size.soft=unlimited size.hard=unlimited
-
add: olcLimits
olcLimits: group/groupOfNames/member="cn=replicadores,ou=groups,${DOMINIO_LDAP}"
  time.soft=unlimited time.hard=unlimited
  size.soft=unlimited size.hard=unlimited
_EOF_

ldapmodify -Y EXTERNAL -H ldapi:/// -f 16-limits_replicator_mdb.ldif


## Configuração de nivel de log
printf "################### Configuração de nivel de log ###################\n\n"

cat > 17-config_ldap_log.ldif <<_EOF_
dn: cn=config
changeType: modify
replace: olcLogLevel
olcLogLevel: stats
_EOF_

ldapmodify -Y EXTERNAL -H ldapi:/// -f 17-config_ldap_log.ldif


## Consulta de Testes do LDAP
if [ $USER_TESTE == "sim" ] || [ $USER_TESTE == "SIM" ]; then
printf "################### Consulta de Teste (LDAPS, MemberOf, ACL por Grupo) ###################\n\n"


LDAPTLS_REQCERT=never ldapsearch -x -D "cn=admin,${DOMINIO_LDAP}" -w ${SENHA_ADM} -LLL -H ldaps:/// -b "uid=teste.login,ou=servidores,ou=people,${DOMINIO_LDAP}" dn memberof -s base

fi


) 2>&1 | tee -a "${log}"

[[ "${VAR_EXCLUI_LDIFS}" == 1 ]] && rm -rfv *.ldif


else

(
printf "Não foi possível executar o script.\n"
exit 1;
) 2>&1 | tee -a "${log}"

fi
