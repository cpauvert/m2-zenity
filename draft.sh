#!/usr/bin/env bash
# Flux de travaux NGS
# 12/05/2015
# Clément Lionnet & Charlie Pauvert

echo `zenity --version`

if [ ! -x "/usr/bin/zenity" ];then
	echo "Malheur ! Zenity n'est pas installé !"
	echo "Le programme ne peut s'exécuter..."
	echo -e "--\napt-get install zenity ?"
	exit 1
fi


PHASE=("Aligneurs" "Appeleur de variants" "Visualisateur")
FIC_PHASE=(aligneurs.txt appeleurs.txt visualisateurs.txt)


declare -a PARAM
declare LOGICIEL

choixLogicielParametre () {
	# Fonction pour une phase
	# Argument  :
	#+ indice phase

	# checker si l'utilisateur veut ajouter des paramètres tant que le retour de la dernière commande (aka zenity)
	#+ est différent de 0, correspond au Oui/Ok (cf man zenity).
	# Attention boucle infini pour le moment.
	# est ce bien $# ? 


	echo -e "#################\n ${PHASE[$1]}\n###############\n"

	if [ -f ${FIC_PHASE[$1]} ];then 
		# si le fichier existe
		LOGICIEL=$(cut -d: -f 1 ${FIC_PHASE[$1]} |uniq |zenity --list --text="Liste des logiciels" --column="${FIC_PHASE[$1]}" 2>/dev/null)

		echo $LOGICIEL
#		awk -F: '{print $1}' ${FIC_PHASE[$1]}
		#LIST_PARAM=( `grep "${LOGICIEL}" ${FIC_PHASE[$1]}|cut -d: -f2-|cut -f 1 ` )
		OUT_PARAM=( `grep "${LOGICIEL}" ${FIC_PHASE[$1]}|cut -d: -f2- |tr '\t' '\n'|zenity --list --text="Choisir un ou plusieurs paramètres pour ${LOGICIEL}" --column="Paramètre" --column="Valeur nécessaire ?" --multiple --print-column="1,2"  --separator="\t" 2>/dev/null ` )
		echo ${OUT_PARAM[@]}
		
		# boucle sur le tableau des paramètres récupérés
		INDEX=0
		NB_PARAM=$(( ${#OUT_PARAM[@]}/2 ))  
		echo $NB_PARAM
		while [ "$INDEX" -lt "${NB_PARAM}" ];do
			PARAM+=( $(echo ${OUT_PARAM[2*$INDEX]}) )
			if [ "${OUT_PARAM[ 2*$INDEX+1 ]}" = "TRUE" ];then

				zenity --question --text="Le paramètre \" ${OUT_PARAM[2*$INDEX]} \" nécessite-t-il un fichier ?"
				if [ $? -eq 0 ];then
					declare VAL_PARAM=$(zenity --file-selection --text="Fichier pour paramètre ${OUT_PARAM[2*$INDEX]}" 2> /dev/null  )

				elif [ $? -eq 1 ];then
					declare VAL_PARAM=$(zenity --entry --text="Valeur pour paramètre ${OUT_PARAM[2*$INDEX]}" 2/dev/null )
				else
					echo "ERREUR"
				fi
			else
				declare VAL_PARAM=""
			fi	
			echo ${VAL_PARAM}

			PARAM+=( $(echo ${VAL_PARAM}) )
			echo ${PARAM[@]}
			notify-send "Paramètre ${OUT_PARAM[2*$INDEX]}"
			((INDEX++))
		done
	fi
#	out=-1
#	while [ "$out" -ne 1 ];do
#       		zenity --question --text="Continuez l'ajout de paramètre pour xxxx ? "
#	 	out=$?
#		if [ "$out" -eq 0 ];then
#			# Oui on ajoute des paramètres
#			# print param puis value
#			# append au fichiers correspondant
#			NOUVEAU_PARAM=$(zenity --entry --text="Nouveau paramètre pour ${PHASE[$1]}" )
#			#NOUVEAU_VALEUR=$(zenity --entry --text="Valeur pour paramètre ${NOUVEAU_PARAM} ${PHASE[$1]}" )
#			NOUVEAU_VALEUR=$(zenity --question --text="Le paramètre ${NOUVEAU_PARAM} nécessite une valeur ?" --ok-label="Oui" --cancel-label="Non" )
#			echo "$NOUVEAU_PARAM"
#			echo "$NOUVEAU_VALEUR"
#		fi
#	done
}	


#inclureBpipe () {

	# prendre indice de la phase
	# copie du template
	# sed pour LOGICIEL
	# sed pour PARAM
#}

#i=0
#while [ "$i" -lt "${#PHASE[@]}" ];do
#	choixLogicielParametre $i
#	((i++))
#done

choixLogicielParametre 0

echo ${LOGICIEL} ${PARAM[@]}
#awk -F: '{print "Logiciel: ", $1}' aligneurs.txt
