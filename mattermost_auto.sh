#=======================================================================================================================================================#
#																			#
#	####################################														#
#	# Script d'installation automatisé #														#
#	####################################														#
#																			#
#	#################################################												#
#	# 		Développé sur Fedora 38		#												#
#	#		Par NonneTrapuE			#												#
#	#################################################												#
#																			#
#	#########################################################################################							#
#	# /!\ Ce script est développé uniquement à but éducatif. Il ne permet pas de déployer	#							#
#	# Mattermost en production. Le déploiement du serveur postfix n'est pas compris dans 	#							#
#	# ce script. La sécurité n'est pas prise en compte également. /!\			#							#
#	#########################################################################################							#
#																			#
#																			#
#	# Une révision sera faite ultérieurement pour l\'adaptation sur d\'autres systèmes (Rocky,RHEL,Ubuntu,Debian) #					#
#																			#
#=======================================================================================================================================================#

#Variables

	#Variables
	#Chemin de log
		LOG_PATH=/tmp/auto_mattermost.log

#Installation de postgresql
	#Purge/création du fichier temporaire
rm -rf /tmp/auto_mattermost.log
touch $LOG_PATH

clear
echo -e "\n" >> $LOG_PATH
echo "======================================================" | tee $LOG_PATH
echo "Installation de PostgreSQL" | tee $LOG_PATH
echo "##########################" | tee $LOG_PATH

	#Timestamp
echo date | cut --delimiter=" " -f 2,3,4 >> $LOG_PATH

	
dnf install -y postgresql-server postgresql-contrib
POSTGRE_INSTALL_ERROR_EXIT_CODE=$?

if [ $POSTGRE_INSTALL_ERROR_MESSAGE = 0 ]; then
	echo "Installation de PostgreSQL: OK" | tee $LOG_PATH
else
	echo "Erreur d'installation." | tee $LOG_PATH
	echo $POSTGRE_INSTALL_ERROR_MESSAGE >> $LOG_PATH
	exit 1
fi

	#Vérification de l'utilisateur postgres

POSTGRES_USER=$(cat /etc/passwd | grep postgres | cut --delimiter=":" -f 1)

if [ $POSTGRES_USER -eq "postgres" ]; then
	echo "L'utilisateur $POSTGRES_USER est existant" 
else 
	echo "L'utilisateur $POSTGRES_USER n'existe pas."
fi

	#Connexion à l'utilisateur postgres/initialisation de la base de données

echo "Initialisation de PostgreSQL" | tee $LOG_PATH
postgresql-setup --initdb --unit postgresql
$POSTGRE_SETUP_EXIT_CODE=$? 

if [ $POSTGRE_SETUP_EXIT_CODE = 0 ]; then
	systemctl enable --now postgresql 2>> $LOG_PATH
else
	exit 2
fi

#Configuration de postgreSQL

 	#Création de la base de données, du propriétaire et des droits d'accès

echo -e "Opérations sur la base de données \n #######################"
read -p "Entrez le nom de la base de données: " DATABASE_NAME
read -p "Entrez l'utilisateur de la base de données: " DATABASE_USER
read -s -p "Entrez un mot de passe pour l'utilisateur: " DATABASE_USER_PASSWORD
sudo -u postgres -- psql --command="CREATE DATABASE $DATABASE_NAME WITH ENCODING 'UTF8' LC_COLLATE='fr_FR.UT-8' LC_CTYPE='fr_FR.UTF8' TEMPLATE=template0;"
sudo -u postgres -- psql --command="CREATE USER $DATABASE_USER WITH PASSWORD $DATABASE_USER_PASSWORD;"
sudo -u postgres -- psql --command="GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME to $DATABASE_USER;"
sudo -u postgres -- psql --command="ALTER DATABASE $DATABASE_NAME OWNER TO $DATABASE_USER;"
sudo -u postgres -- psql --command="GRANT USAGE, CREATE ON SCHEMA PUBLIC TO $DATABASE_USER;"


	#Changement du propriétaire du répertoire/var/lib/pgsql

PG_CONF_FILE=/var/lib/pgsql/data/pg_hba.conf
chown -vR $USERNAME /var/lib/pgsql | tee $LOG_PATH
mv -vf $PG_CONF_FILE $PG_CONF_FILE.bak | tee $LOG_PATH

	#Approvisionnement du fichier .conf
echo "Approvisionnement du fichier $PG_CONF_FILE"

echo "local   all             all                                     trust" > $PG_CONF_FILE
echo "host    all             all             127.0.0.1/32            ident" >> $PG_CONF_FILE
echo "host    all             all             ::1/128                 trust" >> $PG_CONF_FILE
echo "local   replication     all                                     peer" >> $PG_CONF_FILE
echo "host    replication     all             127.0.0.1/32            ident" >> $PG_CONF_FILE
echo "host    replication     all             ::1/128                 ident" >> $PG_CONF_FILE


	#Changement du propriétaire du répertoire /var/lib/pgsql

chown -vR postgres /var/lib/pgsql

	#Redémarrage du service postgresql
echo "Redémarrage du service postgreSQL"
systemctl restart postgresql.service 2>> $LOG_PATH

if [$? = 0]; then
	echo "Redémarrage du service : OK"
	exit 0
else
	echo "Redémarrage du service échoué"
	exit 3
fi
