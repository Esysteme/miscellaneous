NomFichier=`echo $1|awk -F/ '{print $NF}'`
export NOM_MPI=$NomFichier

export DATE_JOUR=`date +%Y%m%d`
export REPERTOIRE_COURANT=/var/www/html/DEV/PROC_TRANSFERT
export REPERTOIRE_ADEL=/var/www/html/DEV/Adel
export REPERTOIRE_ADEL_RECETTE=/data/www/REC/Adel
export REPERTOIRE_ADEL_RECETTE_REFERENCE=$REPERTOIRE_ADEL_RECETTE/RELEASES/REFERENCE/Adel
export REPERTOIRE_ADEL_RECETTE_NEW_RELEASE=$REPERTOIRE_ADEL_RECETTE
export REPERTOIRE_TRANSFERT=/var/www/html/DEV/Adel/TRANSFERT_MPI
export ROOT_LIVRAISON=$REPERTOIRE_TRANSFERT/$NOM_MPI
export LIVRAISON_COMPTE_RENDU=$ROOT_LIVRAISON/COMPTE_RENDU
export COMPTE_RENDU=$LIVRAISON_COMPTE_RENDU/CompteRenduExecutionSACCH10203.txt
export LIVRAISON_WEB=$ROOT_LIVRAISON/WEB
export LIVRAISON_PACKAGE=$ROOT_LIVRAISON/ORACLE/PLSQL
export LIVRAISON_SCRIPTS_BEFORE=$ROOT_LIVRAISON/BASE_DE_DONNEES/SCRIPTS_BEFORE
export LIVRAISON_SCRIPTS_AFTER=$ROOT_LIVRAISON/BASE_DE_DONNEES/SCRIPTS_AFTER
export FILE_RELEASE=$ROOT_LIVRAISON/RELEASE/release.txt
export REFUS_TRANSFERT=$LIVRAISON_COMPTE_RENDU/livraisonRefusee.txt
export REPERTOIRE_WEB_A_EFFACER=$ROOT_LIVRAISON/SERVEUR_WEB/ACTIONS/repertoiresEffacer.data
export BASE=ADELREC
export USER=LIVRAISON
export PASSW=LIVRAISON
export SERVEUR_RECETTE='sag@10.239.4.207'
export CONNEXION_RECETTE=${SERVEUR_RECETTE}:
message ()
{
texte=$1
echo $texte
echo "" >>$COMPTE_RENDU
echo $texte >>$COMPTE_RENDU
}
ExecuterScript()
{
SCRIPT=$1
TYPE_SCRIPT=$2
message "$TYPE_SCRIPT :  $SCRIPT "
sqlplus $USER/$PASSW@$BASE @$SCRIPT "$LIVRAISON_COMPTE_RENDU" >>$COMPTE_RENDU
CR=$?
if [ $CR -ne 0 ]; then message "ERREUR!! $TYPE_SCRIPT $SCRIPT / Code Retour : $? "; fi
if [ $CR -eq 0 ]; then message "Le $TYPE_SCRIPT $SCRIPT a ete execute "; fi
}

echo "DEBUT TRAITEMENT MPI : " $NOM_MPI LE $DATE_JOUR >$COMPTE_RENDU


echo "----------------------------------------------------------------"
# --------------------------------------------------------------------
# VÃ©rifier que la livraison n'est pas refusee
# -------------------------------------------------------------------
echo  "REFUS_TRANSFERT=" $REFUS_TRANSFERT
 if [ -f  $REFUS_TRANSFERT ]
    then
    message "La livraison est REFUSEE !!!!!!!!!!!!!!!!!!!!!! "
    message "================================================"
    message "Merci de consulter $REFUS_TRANSFERT pour en connaitre les raisons"
    cat $REFUS_TRANSFERT
    exit 0
    fi
# -----------------------------------------------------
# RELEASE : s'agit-il de la nouvelle release ou celle de rÃ©fÃ©rence ?
# -----------------------------------------------------
message "La livraison concerne la release de rÃ©fÃ©rence ? "
message "================================================"
export RELEASE="NOUVELLE"
if [ -f $FILE_RELEASE ]
then
   RELEASE=$(head -1 $FILE_RELEASE | awk -F\; '{print $2}')
   if [ $RELEASE = "REFERENCE" -o $RELEASE = "REFERENCE+NOUVELLE" ]
    then
    export REPERTOIRE_ADEL_RECETTE=$REPERTOIRE_ADEL_RECETTE_REFERENCE
    fi
fi
message "Repertoire de livraison:  $REPERTOIRE_ADEL_RECETTE"
if [ $RELEASE = "REFERENCE+NOUVELLE" ]
    then
     message "PLUS le repertoire:  $REPERTOIRE_ADEL_RECETTE_NEW_RELEASE"
    fi
# ----------------------------------------------------
# Executer les SCRIPTS Ã  EXECUTER AVANT LA LIVRAISON
# -----------------------------------------------------
message "SCRIPTS A EXECUTER AVANT LA LIVRAISON"
message "====================================="
if [ -d $LIVRAISON_SCRIPTS_BEFORE ]
then
    for s in $(find $LIVRAISON_SCRIPTS_BEFORE -type f | sort)
    do
        message "DEBUT EXECUTION SCRIPT : $s"
        message "-------------------------------------"
        ExecuterScript $s "SCRIPT_ORACLE"
        
        
    done
fi
# -----------------------------------------------------
# LIVRAISON DANS ENVIR PHP WEB
# -----------------------------------------------------
export REP_WEB=$NOM_MPI/WEB
message "LIVRAISON DES OBJETS WEB"
message "========================"
if [ -d "$LIVRAISON_WEB" ]
then
NBOBJ=`ls -1 $LIVRAISON_WEB 2>/dev/null | wc -l`
if [ $NBOBJ -ne 0 ]
then
if [ -f $REPERTOIRE_WEB_A_EFFACER ]
   then
    for repToClean in $(cat $REPERTOIRE_WEB_A_EFFACER)
        do
        ssh $SERVEUR_RECETTE "find $REPERTOIRE_ADEL_RECETTE_NEW_RELEASE/$repToClean -maxdepth 1 -type f  -exec rm {} \;"
        done
   fi
for Rep in $LIVRAISON_WEB/*
do
APPLICATION=`echo $Rep|awk -F/ '{print $NF}'`
REPERTOIRE=$LIVRAISON_WEB"/"$APPLICATION
if [ -d $REPERTOIRE ]
   then
   NBFIC=`ls -1 $REPERTOIRE/* 2>/dev/null | wc -l`
   if [ $NBFIC -ne 0 ]
      then
      for P in $REPERTOIRE/*
      do
          NOM_PROGRAMME=`echo $P|awk -F/ '{print $NF}'`
                if [ -d $REPERTOIRE/$NOM_PROGRAMME ]
                 then
             scp -Br $REPERTOIRE/$NOM_PROGRAMME/* ${CONNEXION_RECETTE}$REPERTOIRE_ADEL_RECETTE/$APPLICATION/$NOM_PROGRAMME >>$COMPTE_RENDU
             if [ $RELEASE = "REFERENCE+NOUVELLE" ]
                then
                 scp -Br $REPERTOIRE/$NOM_PROGRAMME/* ${CONNEXION_RECETTE}$REPERTOIRE_ADEL_RECETTE_NEW_RELEASE/$APPLICATION/$NOM_PROGRAMME >>$COMPTE_RENDU
                fi

                 fi

                if [ -f $REPERTOIRE/$NOM_PROGRAMME ]
                    then
              scp -B $REPERTOIRE/$NOM_PROGRAMME ${CONNEXION_RECETTE}$REPERTOIRE_ADEL_RECETTE/$APPLICATION/$NOM_PROGRAMME >>$COMPTE_RENDU
              if [ $RELEASE = "REFERENCE+NOUVELLE" ]
                then
                 scp -B $REPERTOIRE/$NOM_PROGRAMME ${CONNEXION_RECETTE}$REPERTOIRE_ADEL_RECETTE_NEW_RELEASE/$APPLICATION/$NOM_PROGRAMME >>$COMPTE_RENDU
                fi
                fi
                export myMessage="Mise_en_Recette_de_l_objet_WEB=>$NOM_PROGRAMME"
                if [ $RELEASE = "REFERENCE" -o $RELEASE = "REFERENCE+NOUVELLE" ]
              then
              export myMessage="Mise_en_RECETTE_DANS_L_ESPACE_REFERENCE_de_l_objet_WEB=>$NOM_PROGRAMME"
              fi
           message $myMessage
           if [  $RELEASE = "REFERENCE+NOUVELLE" ]
               then
               export myMessage="Mise_en_Recette_de_l_objet_WEB=>$NOM_PROGRAMME"
               message $myMessage
               fi
      done
      fi
   fi
done
fi
fi
# ------------------------------------------------------------
# LIVRAISON DES PACKAGES
# ------------------------------------------------------------
message "LIVRAISON DES PACKAGES"
message "========================"
if [ -d "$LIVRAISON_PACKAGE" ]
then
    for PACKAGE in $LIVRAISON_PACKAGE/*
    do
        NOM_PACKAGE=$(echo $PACKAGE | awk -F/ '{print $NF}')
        message "Mise en recette du package :  $NOM_PACKAGE"
        ExecuterScript $PACKAGE "Chargement_PACKAGE"
    done
fi
# ----------------------------------------------------
# Executer les SCRIPTS Ã  EXECUTER AVANT LA LIVRAISON
# -----------------------------------------------------
message "SCRIPTS A EXECUTER APRES LA LIVRAISON"
message "====================================="
if [ -d $LIVRAISON_SCRIPTS_AFTER ]
then
    for s in $(find $LIVRAISON_SCRIPTS_AFTER -type f | sort)
        do
            message "DEBUT EXECUTION SCRIPT : $s"
            message "-------------------------------------"
            ExecuterScript $s "SCRIPT_ORACLE"
        done
fi
# --------------------------------
# FIN
# --------------------------------
echo "FIN TRAITEMENT MPI SACCH10203 : " $NOM_MPI LE $DATE_JOUR
echo "FIN TRAITEMENT MPI SACCH10203 : " $NOM_MPI LE $DATE_JOUR >>$COMPTE_RENDU
echo "----------------------------------------------------------------"
