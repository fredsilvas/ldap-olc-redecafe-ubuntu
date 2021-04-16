# OpenLdap OLC / Ubuntu 20.04 / Rede CAFe / RNP

Baseado no [projeto](https://gitlab.com/ens.rolim/ldap-olc-redecafe) de Eduardo Rolim e adaptado para ubuntu.

Neste repositório, você encontrará os scripts necessários para fazer a instalação de serviço openLDAP no Ubuntu 20.04 de forma a permitir a homologação junto à Rede CAFe da RNP.

## Instalação

Este script executa as seguintes mudanças em uma instalação nova do CentOS:

* Instalação dos pacotes básicos para o OpenLdap;
* Liberação das portas `389` e `636` no firewall;
* Configuração do backend do LDAP;
* Criação de uma árvore nova;
* Criação ou instalação dos certificados SSL para o LDAPS;
* Importação dos schemas necessários para uso na Rede CAFe;
* Configuração dos módulos `Samba`, `MemberOf` e `Password Policy`;
* Criação de usuário exemplo conforme script `popula.sh` da RNP;
* Criação dos usuários `admin` e `leitor-shib` para acesso ao LDAP;
* Criação de grupos `admins` e `leitores`;
* Adição do usuário de exemplo no grupo `admins`
* Configuração das ACLs segundo o script `popula.sh` da RNP com a adição de regras por grupo;

## Informações extras

É importante ressaltar que na seção **Configuração Inicial** do arquivo é possível mudar várias informações para a construção da árvore, como domínio, nome da instituição, senha dos usuários iniciais e local dos certificados SSL, caso sejam usados certificados já existentes.

TODO
------

* ~~Adicionar ACLs por grupo;~~
* ~~Adicionar módulos para Samba e verificação de grupos;~~
* ~~Adicionar SSL;~~
* Reconstruir `cafe-homolog-ldap.sh` para homologação do LDAP OLC;

## Referências

1. http://www.rnp.br/servicos/servicos-avancados/cafe
1. https://wiki.rnp.br/pages/viewpage.action?pageId=69968769
1. https://www.openldap.org/doc/admin24/slapdconf2.html
1. http://www.zytrax.com/books/ldap/
1. https://aput.net/~jheiss/samba/ldap.shtml
1. http://labs.opinsys.com/blog/2010/05/05/smbkrb5pwd-password-syncing-for-openldap-mit-kerberos-and-samba/
1. https://www.itzgeek.com/how-tos/linux/centos-how-tos/configure-openldap-with-ssl-on-centos-7-rhel-7.html
