REPERTOIRE_DEMANDES_MODIF=/var/www/html/DEV/Adel/DEMANDES_MODIF/ATTENTE
REPERTOIRE_DEMANDES_TRANSFERT_RECETTE=/var/www/html/DEV/Adel/DEMANDES_TRANSFERT_RECETTE/ATTENTE
REPERTOIRE_DEMANDES_TRANSFERT_PROD=/var/www/html/DEV/Adel/DEMANDES_TRANSFERT_PROD/ATTENTE
REPERTOIRE_COURANT=/var/www/html/DEV/PROC_TRANSFERT
cd $REPERTOIRE_COURANT
while :
do
sleep 10
NBFIC=`ls -1 $REPERTOIRE_DEMANDES_TRANSFERT_RECETTE/*  2>/dev/null | wc -l`
if [ $NBFIC -ne 0 ]
then
for f in $REPERTOIRE_DEMANDES_TRANSFERT_RECETTE/*
do
.  $REPERTOIRE_COURANT/AjoutMPIespaceLivraison.sh $f
.  $REPERTOIRE_COURANT/PROC_TRANSFERT_RECETTE_SACCH10203.sh $f
done
fi
done

