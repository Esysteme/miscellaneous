NomFichier=`echo $1|awk -F/ '{print $NF}'`
DATE_JOUR=`date +%Y%m%d`
REPERTOIRE_COURANT=/var/www/html/DEV/PROC_TRANSFERT
FICHIER_TRANSFERTS=/var/www/html/DEV/PROC_TRANSFERT/DONNEES/Fichier_Transferts
REPERTOIRE_TRAVAIL=/var/www/html/DEV/PROC_TRANSFERT/TRAVAIL
REPERTOIRE_ADEL_NEW_RELEASE=/var/www/html/DEV/Adel
REPERTOIRE_ADEL=$REPERTOIRE_ADEL_NEW_RELEASE
REPERTOIRE_ADEL_REFERENCE=$REPERTOIRE_ADEL/RELEASES/REFERENCE/Adel
REPERTOIRE_ARCHIVES=/var/www/html/DEV/Adel/ARCHIVES
ROOT_DEMANDE=/var/www/html/DEV/Adel/DEMANDES_TRANSFERT_RECETTE
REPERTOIRE_DEMANDES=$ROOT_DEMANDE/ATTENTE
REPERTOIRE_DEMANDES_EN_COURS=$ROOT_DEMANDE/EN_COURS
REPERTOIRE_DEMANDES_TRAITEES=$ROOT_DEMANDE/TRAITEES
DEMANDE_SCRIPTS_BEFORE=$ROOT_DEMANDE/SCRIPTS_ATTACHES/BEFORE
DEMANDE_SCRIPTS_AFTER=$ROOT_DEMANDE/SCRIPTS_ATTACHES/AFTER
REPERTOIRE_TRANSFERT=/var/www/html/DEV/Adel/TRANSFERT_MPI
controlePropagationCorrection ()
{
P_SOURCE=$1
P_VERSION=$2
TAG="~ *$P_VERSION *~"
SOURCE_NEW_RELEASE=$REPERTOIRE_ADEL_NEW_RELEASE"/"$P_SOURCE
SOURCE_REFERENCE=$REPERTOIRE_ADEL_REFERENCE"/"$P_SOURCE
rm -f $REPERTOIRE_TRAVAIL/correctionsREF
rm -f $REPERTOIRE_TRAVAIL/correctionsNEW
touch $REPERTOIRE_TRAVAIL/correctionsREF
touch $REPERTOIRE_TRAVAIL/correctionsNEW
if [ -f  $SOURCE_REFERENCE ]
   then
   grep -i "$TAG" $SOURCE_REFERENCE >$REPERTOIRE_TRAVAIL/correctionsREF
   fi
if [ -f  $SOURCE_NEW_RELEASE ]
   then
    grep -i "$TAG" $SOURCE_NEW_RELEASE >$REPERTOIRE_TRAVAIL/correctionsNEW
    fi
NbLignesDifferentes=$(diff $REPERTOIRE_TRAVAIL/correctionsREF $REPERTOIRE_TRAVAIL/correctionsNEW | wc -l )
if [  $NbLignesDifferentes -gt 0 ]
   then
   echo "========================================================================" >>$REFUS_TRANSFERT
   echo "LIVRAISON EN RECETTE REFUSEE : DES CORRECTIONS SUR LA REFERENCE N'ONT PAS" >>$REFUS_TRANSFERT
   echo "                               ETE REPORTEES SUR LA NOUVELLE RELEASE" >>$REFUS_TRANSFERT
   echo " SOURCE : $P_SOURCE" >>$REFUS_TRANSFERT
   echo " VERSION : $P_VERSION" >>$REFUS_TRANSFERT
   echo "========================================================================" >>$REFUS_TRANSFERT
   
   
   tail -6 $REFUS_TRANSFERT
fi
}
#
#  A)Passer la MPI au statut EN COURS
#
mv $REPERTOIRE_DEMANDES/$NomFichier $REPERTOIRE_DEMANDES_EN_COURS/$NomFichier
#
#  CREER LE REPERTOIRE DE LIVRAISON
# ----------------------------------
export NOM_MPI=$NomFichier
export ROOT_LIVRAISON=$REPERTOIRE_TRANSFERT/$NOM_MPI
COMPTE_RENDU=$ROOT_LIVRAISON/COMPTE_RENDU/CompteRenduExecution.txt
REFUS_TRANSFERT=$ROOT_LIVRAISON/COMPTE_RENDU/livraisonRefusee.txt
REPERTOIRE_WEB_A_EFFACER=$ROOT_LIVRAISON/SERVEUR_WEB/ACTIONS/repertoiresEffacer.data
FICHIER_RELEASE=$ROOT_LIVRAISON/RELEASE/release.txt
rm -fr $REPERTOIRE_TRANSFERT/$NOM_MPI
if [ ! -d "$REPERTOIRE_TRANSFERT/$NOM_MPI" ]
   then
   cd $REPERTOIRE_TRANSFERT
   echo "Debut traitement " $NOM_MPI
   mkdir $ROOT_LIVRAISON
   mkdir $ROOT_LIVRAISON/SERVEUR_WEB
   mkdir $ROOT_LIVRAISON/SERVEUR_WEB/ACTIONS
   mkdir $ROOT_LIVRAISON/RELEASE
   mkdir $ROOT_LIVRAISON/COMPTE_RENDU
   mkdir $ROOT_LIVRAISON/WEB
   mkdir $ROOT_LIVRAISON/ORACLE
   mkdir $ROOT_LIVRAISON/BASE_DE_DONNEES
   mkdir $ROOT_LIVRAISON/BASE_DE_DONNEES/SCRIPTS_BEFORE
   mkdir $ROOT_LIVRAISON/BASE_DE_DONNEES/SCRIPTS_AFTER
   fi
rm -f $REPERTOIRE_WEB_A_EFFACER
echo "DEBUT TRAITEMENT MPI : " $NOM_MPI LE $DATE_JOUR
echo "DEBUT TRAITEMENT MPI : " $NOM_MPI LE $DATE_JOUR >$COMPTE_RENDU
echo "----------------------------------------------------------------"  >>$COMPTE_RENDU
# ------------------------------------------------------------------------------
# copier les scripts dans le rÃ©pertoire de livraison
# ------------------------------------------------------------------------------
echo ""  >>$COMPTE_RENDU
echo "copier les scripts dans le rÃ©pertoire de livraison" >>$COMPTE_RENDU
echo "----------------------------------------------------------------"  >>$COMPTE_RENDU
echo "copier les scripts dans le rÃ©pertoire de livraison : $DEMANDE_SCRIPTS_BEFORE "
echo $DEMANDE_SCRIPTS_BEFORE

export LIVRAISON_SCRIPTS_BEFORE=$ROOT_LIVRAISON/BASE_DE_DONNEES/SCRIPTS_BEFORE
for s in $(find $DEMANDE_SCRIPTS_BEFORE -name "$NOM_MPI_SCRIPT_BEFORE*" -type f)
do
 mv $s $LIVRAISON_SCRIPTS_BEFORE
done
export LIVRAISON_SCRIPTS_AFTER=$ROOT_LIVRAISON/BASE_DE_DONNEES/SCRIPTS_AFTER
for s in $(find $DEMANDE_SCRIPTS_AFTER -name "$NOM_MPI_SCRIPT_AFTER*" -type f)
do
 mv $s $LIVRAISON_SCRIPTS_AFTER
done
# ------------------------------------------------------------------------------
# copier les sources dans le rÃ©pertoire de livraison
# ------------------------------------------------------------------------------
export RELEASE="NOUVELLE"
export RELEASE_VERSION=""
while read Enr
do
TYPE_ENR=`echo $Enr| awk -F\; '{print $1}'`
# -------------------------------------------------
# RELEASE : s'agit-il de la reference ?
# -------------------------------------------------
if [ "$TYPE_ENR" = "RELEASE" ]
then
export RELEASE=$(echo $Enr| awk -F\; '{print $2}')
export RELEASE_VERSION=$(echo $Enr| awk -F\; '{print $3}')
echo $Enr >$FICHIER_RELEASE
if [ $RELEASE = "REFERENCE" -o  $RELEASE = "REFERENCE+NOUVELLE" ]
    then
    export REPERTOIRE_ADEL=$REPERTOIRE_ADEL_REFERENCE
    fi
fi
# -------------------------------------------------
# Copier les objets WEB dans le repertoire de livraison
# -------------------------------------------------
REP_WEB=$NOM_MPI/WEB
if [ "$TYPE_ENR" = "PHP" ]
then
declare -i NEW_VERSION
APPLICATION=`echo $Enr| awk -F\; '{print $2}'`
OBJETS=`echo $Enr| awk -F\; '{print $3}'`
OBJETS=$(echo "$OBJETS"  | perl -p -e '{ s/^\s+//;s/\s+$//;}')
if [ "$OBJETS" = '*' ]
    then
    echo $APPLICATION >>$REPERTOIRE_WEB_A_EFFACER

       fi
if [ ! -d "$REPERTOIRE_TRANSFERT/$REP_WEB/$APPLICATION" ]
   then
   cd $REPERTOIRE_TRANSFERT/$REP_WEB
    for r in $(perl -e '{
                       $parametre=$ARGV[0];
                       $rep="";
                        foreach( split( m!/!, $parametre ) ){
                           do {$rep .="/" } if ($rep ne "" );
                           $rep.=$_; print $rep,"\n";  }
                        }' $APPLICATION)
    do
     if [ ! -d $r ]
        then
        mkdir $r
        fi
    done
  fi

cd $REPERTOIRE_COURANT
NBOBJ=`ls -1 $REPERTOIRE_ADEL/$APPLICATION/$OBJETS 2>/dev/null | wc -l`
if [ $NBOBJ -ne 0 ]
then
for P in $REPERTOIRE_ADEL/$APPLICATION/$OBJETS
do
NOM_PROGRAMME=`echo $P|awk -F/ '{print $NF}'`
PGM=$REPERTOIRE_ADEL"/"$APPLICATION"/"$NOM_PROGRAMME
if [ ! -d "$PGM" ]
   then
# if [ $RELEASE = "REFERENCE" -o  $RELEASE = "REFERENCE+NOUVELLE" ]
# then
# # Si la reference a Ã©tÃ© debuggee : controler que la correction
# #     a Ã©tÃ© propagee sur la nouvelle release
#    controlePropagationCorrection $APPLICATION"/"$NOM_PROGRAMME $RELEASE_VERSION
#    if [ -f  $REFUS_TRANSFERT ]
#       then
#       exit 0
#       fi
# fi
cp $PGM $REPERTOIRE_TRANSFERT/$REP_WEB/$APPLICATION
fi
done
fi
fi

# ------------------------------------------------------------------------------
# Copier les OBJETS ORACLE dans le rÃ©pertoire de livraison
# ------------------------------------------------------------------------------
if [ "$TYPE_ENR" = "PLSQL" ]
then
declare -i NEW_VERSION
PACKAGE=`echo $Enr| awk -F\; '{print $3}'`
if [ ! -d "$REPERTOIRE_TRANSFERT/$NOM_MPI/ORACLE/PLSQL" ]
   then
   cd $REPERTOIRE_TRANSFERT/$NOM_MPI/ORACLE
   mkdir PLSQL
   fi
cd $REPERTOIRE_TRANSFERT/$NOM_MPI/ORACLE/PLSQL
echo "Export PACKAGE: " $PACKAGE >>$COMPTE_RENDU
sqlplus livraison/livraison@ADELDEV @$REPERTOIRE_COURANT/EXPORT_PACKAGE.sql $PACKAGE.sql $PACKAGE >>$COMPTE_RENDU
fi

done <$REPERTOIRE_DEMANDES_EN_COURS/$NomFichier
# ------------------------------------------------------------------------------
# C) Passer la MPI au statut TRAITEE
# --------------------------------
mv $REPERTOIRE_DEMANDES_EN_COURS/$NomFichier $REPERTOIRE_DEMANDES_TRAITEES/$NomFichier
echo "FIN CREATION DE LA MPI $NOM_MPI DANS L ESPACE LIVRAISON RECETTE: "  LE $DATE_JOUR
echo "FIN CREATION DE LA MPI $NOM_MPI DANS L ESPACE LIVRAISON RECETTE: "  LE $DATE_JOUR >>$COMPTE_RENDU
echo "----------------------------------------------------------------"

