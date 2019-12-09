#!/bin/bash

### esta funcion toma 2 valores: 1- usuario que manda spam 2- ruta a chequear
### en base a esos dos valores, borra todos los mails de dicho usuario en esa ruta
#####VERSION 0.2

borrarmails()
{
	LISTAMAILS=`ls $2`

        while read -r MAILTEMP
        do
                SPAM=`grep $1 $2/$MAILTEMP | awk '{print $2}'`
                if [ $SPAM ]
                then
                        STRINGMAIL=`echo $MAILTEMP | sed 's/^..//'`
			 rm -f $2/df$STRINGMAIL $2/qf$STRINGMAIL
                fi
        done <<<"$LISTAMAILS"
}





bloquearcuenta()
{
	USUARIO=`grep "$1:" /etc/passwd | cut -d":" -f1`
	DOMINIO=`grep "$USUARIO:" /etc/passwd | cut -d":" -f5 | cut -d"@" -f2`
	MAILBLOQUEADO=`grep "$USUARIO:" /etc/passwd | cut -d":" -f5`
	FECHA=$(date +"%y-%m-%d %T")
	echo "suspendiendo cuenta..."
	echo "DejaDeSpamear1987" | passwd --stdin $USUARIO
}

chequearmailq()
{
	NOMBRETECNICO=$1
	LISTASPAMEROS=`grep -r X-AuthUser /var/spool/mqueue /var/spool/mqueue.in/ /var/spool/slow-mqueue/ /var/spool/clientmqueue/ | awk '{print $2}' | sort | uniq -c | sort -n | tail -n5 | nl -s ----`

	CANTSPAMEROS=`grep -r X-AuthUser /var/spool/mqueue /var/spool/mqueue.in/ /var/spool/slow-mqueue/ /var/spool/clientmqueue/ | awk '{print $2}' | sort | uniq -c | sort -n | tail -n5 | wc -l`

	case $CANTSPAMEROS in
        	1)
                	OPCIONNUMEROS="[1]"
	                ;;
        	2)
   	        	OPCIONNUMEROS="[1/2]"
   	             	;;
        	3)
                	OPCIONNUMEROS="[1/2/3]"
	                ;;
        	4)
	                OPCIONNUMEROS="[1/2/3/4]"
	                ;;
	        5)
	                OPCIONNUMEROS="[1/2/3/4/5]"
	                ;;
	        *)
	                echo "hubo un error tomando el listado de gente enviando mails, putealo a Oliver por favor."
	                exit 0
        esac

	echo "Este es el top de usuarios mandando mails en estos momentos "
	echo ""
	IFS=$(echo -en "\n")
	echo $LISTASPAMEROS
	echo ""
	echo "Defini el ID de usuario para trabajar"
	echo "Cualquier otra cosa que pongas cierra el programa"
	read -p $OPCIONNUMEROS ELEGIDO

	case $ELEGIDO in
	        [1-5])
        	        USUARIOELEGIDO=`echo $LISTASPAMEROS | grep $ELEGIDO--- | awk '{print $3}'`
			if [ $USUARIOELEGIDO ]
                        then
                                mostraropciones $USUARIOELEGIDO 2 $NOMBRETECNICO
                        else
                                echo "no encuentro el usuario $ELEGIDO en el passwd, lamentablemente vas a tener que trabajar"
                                exit 0
                        fi
			mostraropciones $USUARIOELEGIDO 2 $NOMBRETECNICO
                	#echo $USUARIOELEGIDO
			
	                #######
	                #bloquearcuenta $USUARIOELEGIDO
	                #echo "borrando sus mails..."
	                #borrarmails $USUARIOELEGIDO "/var/spool/mqueue/"
	                #borrarmails $USUARIOELEGIDO "/var/spool/mqueue.in/"
	                #borrarmails $USUARIOELEGIDO "/var/spool/slow-mqueue/"
	                #######
	                ;;
	        *)
	                echo "Levantando MailScanner y saliendo"
			/etc/init.d/MailScanner start
	                exit 0
	                ;;
	esac
}


loguear()
{
	USUARIOBLOQUEADO=$1
	TECNICO=$2
	FECHA=`date +"%m-%d-%y %H:%M"`
	echo "$FECHA --- $TECNICO bloqueo la cuenta $USUARIO" >> /var/log/controlspam.log
	chequearmailq $TECNICO
}


vermaildeejemplo()
{
	USUARIO=$1
	NOMBRETECNICO=$2
	ARCHIVO=`grep -r X-AuthUser /var/spool/mqueue /var/spool/mqueue.in/ /var/spool/slow-mqueue/ /var/spool/clientmqueue/ | grep $USUARIO | cut -d":" -f1 | grep "/df" |  head -n1`
	if [ $ARCHIVO ]
	then
		head -n100 $ARCHIVO
	else
		echo "no hay ningun cuerpo de mail para mostrar, esto puede pasar porque quedo basura de usar el spam_filter6"
	fi
	mostraropciones $USUARIO 1 $NOMBRETECNICO
}

mostraropciones()
{
	NOMBRETECNICO=$3
	USUARIO=$1
	MAILUSUARIO=`grep $USUARIO /etc/passwd | cut -d":" -f 5`
	echo "que queres hacer con $USUARIO o $MAILUSUARIO"
	echo "1- borrar todo y bloquearlo"
	if [ $2 == 1 ]
	then
		echo "2- ver la lista de mails"
	else
		echo "2- ver un mail de ejemplo"
	fi
	echo "3- levantar Mailscanner y salir"
	read -p "[1/2/3]" ELEGIDO
	case $ELEGIDO in
		1)
			echo "bloquenado la cuenta y notificando"
			bloquearcuenta $USUARIO
			echo "borrando sus mails"
			borrarmails $USUARIO "/var/spool/mqueue"
			borrarmails $USUARIO "/var/spool/mqueue.in/"
			borrarmails $USUARIO "/var/spool/slow-mqueue/"
			loguear $USUARIO $NOMBRETECNICO
			;;
		2)
			if [ $2 == 1 ]
			then
				chequearmailq $NOMBRETECNICO
			else
				vermaildeejemplo $USUARIO $NOMBRETECNICO
			fi
			;;
		3)
			/etc/init.d/MailScanner start
			exit 0
			;;
		*)
			echo "dale bruto ... es del 1 al 3"
			exit 0
			;;
	esac
			
	
}





##############################################################################
###################Aca empieza el flujo normal del script
##############################################################################

#bloquearcuenta info12241

echo "Bajando el MailScanner y sendmail"
/etc/init.d/MailScanner stop
sleep 4s
killall -9 sendmail
echo "----------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------"
echo "Bienvenido al control antispam, indicame quien sos para botonearte en los logs por favor"
read NOMBRETECNICO

chequearmailq $NOMBRETECNICO
