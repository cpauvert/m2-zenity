#!/usr/bin/env bash
# Flux de travaux NGS
# 12/05/2015
# Clément Lionnet & Charlie Pauvert

cat <<EOF

# Flux de travaux NGS - Projet Système M2.1 2015
# Clément LIONNET & Charlie PAUVERT

https://github.com/cpauvert/m2-zenity

EOF

if [ ! -x "/usr/bin/zenity" ];then
	echo "Malheur ! Zenity n'est pas installé !"
	echo "Le programme ne peut s'exécuter..."
	echo -e "--\napt-get install zenity ?"
	exit 1
fi


PHASE=("Aligneurs" "Appeleur de variants" "Visualisateur")
FIC_PHASE=(aligneurs.txt appeleurs.txt visualisateurs.txt)
MENU_FICHIER=( "Afficher" "Modifier/Supprimer une ligne" "Ajouter une ligne" )
TYPE_PARAM=( "Drapeau" "Fichier" "Valeur" )

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

ajoutLigne () {


	if [ -f ${FIC_PHASE[$1]} ];then 
		# si le fichier existe
		LOGICIEL=$(cut -d: -f 1 ${FIC_PHASE[$1]} |uniq |awk '{OFS="\n";print $0}END{print " "}' |zenity --list --text="Choissisez un logiciel dans la liste, ou ajouter le manuellement :" --column="${FIC_PHASE[$1]}" --editable  2>/dev/null)
		OUT_LOGICIEL=$?
		if [ "${OUT_LOGICIEL}" -eq 0 ];then
			echo "${LOGICIEL}" > nouvelle_ligne.tmp
		fi

		out=-1
		while [ "$out" -ne 1 ];do
			zenity --question --text="Continuez l'ajout de paramètre pour <tt>${LOGICIEL}</tt> ? "
			out=$?
			if [ "$out" -eq 0 ];then
				# Oui on ajoute des paramètres
				# print param puis value
				# append au fichiers correspondant

				NOUVEAU_PARAM=$(zenity --entry --text="Nouveau paramètre pour <tt>${LOGICIEL}</tt> - Phase ${PHASE[$1]}" )
				MENU_PARAM=( $( echo ${TYPE_PARAM[@]}|tr ' ' '\n'|zenity --list --title="Menu" --text="<b>Phase ${PHASE[$1]}</b>\n\nChoisir un type de paramètre pour <tt>${NOUVEAU_PARAM}</tt> :" --column="Type" --width=400 --height=270 --separator=" " 2>/dev/null ) )
				#NOUVEAU_VALEUR=$(zenity --entry --text="Valeur pour paramètre ${NOUVEAU_PARAM} ${PHASE[$1]}" )
#				NOUVEAU_VALEUR=$(zenity --question --text="Le paramètre ${NOUVEAU_PARAM} nécessite une valeur ?" --ok-label="Oui" --cancel-label="Non" )

				case "${MENU_PARAM}" in

					"Drapeau")
						#Flag
						NOUVEAU_VALEUR=""
						;;
					"Fichier")
						#Fichier
						NOUVEAU_VALEUR=$(zenity --file-selection --text="Fichier pour paramètre ${NOUVEAU_PARAM}" 2> /dev/null  )
						;;
					"Valeur")
						#Valeur

						NOUVEAU_VALEUR=$(zenity --entry --text="Valeur pour paramètre ${NOUVEAU_PARAM}" 2> /dev/null  )
						;;
					*)

						zenity --error --text="Item inconnu"
						ajoutLigne $1
						;;
				esac

				echo -e ":${NOUVEAU_PARAM}\t${NOUVEAU_VALEUR}" >> nouvelle_ligne.tmp
			fi
		done

		if [ "${OUT_LOGICIEL}" -eq 0 ];then
			cat nouvelle_ligne.tmp|tr -d '\n' >> ${FIC_PHASE[$1]}
			echo >> ${FIC_PHASE[$1]}
			rm nouvelle_ligne.tmp
		fi
	fi

}

choixBpipe () {
	if [ -f ${FIC_PHASE[$1]} ];then 
		# si le fichier existe
		LOGICIEL=$(cut -d: -f 1 ${FIC_PHASE[$1]} |uniq |zenity --list --text="Liste des logiciels" --column="${FIC_PHASE[$1]}" 2>/dev/null)
		RETOUR_CHOIX_BPIPE=$(awk -v a=${LOGICIEL} -F: '{OFS="\n";if($1==a){gsub(/:/," "); printf "%s\n%s\n","FALSE",$0}}' ${FIC_PHASE[$1]}  |zenity --list --text="Coucou" --column="Selection" --column="Commande" --checklist --width=650 --height=200 --print-column="2" 2> /dev/null)
	fi
}

inclureBpipe () {
#	zenity --question --text="Voulez vous donner un nom spécifique au fichier Bpipe ?"
#	if [ $? -eq 0 ];then
#		FileName=$(zenity --entry --text="Nom du fichier Bpipe" 2/dev/null )
#		BpipeFileName=${FileName}.txt
#	else
#		DATE=$(date +%Y_%m_%d_%H)
#		BpipeFileName="bpipe_"$DATE".txt"
#	fi

	DATE=$(date +%Y_%m_%d_%H_%M)
	BpipeFileName="bpipe_"$DATE".txt"


	if [ ! -f $BpipeFileName ];then
		# si le fichier bpipe n'existe pas : le créer
		cp template_bPipe.txt $BpipeFileName
	fi

	# s'il existe le modifier pour chaque phase
	COMMAND=$( echo $2|tr '\t' ' ' )

	if [ $1 -eq 0 ];then
		sed -i "s/COMMAND_LINE_ALIGN/${COMMAND}/" $BpipeFileName
	elif [ $1 -eq 1 ];then
		sed -i "s/COMMAND_LINE_APP/${COMMAND}/" $BpipeFileName
	else
		sed -i "s/COMMAND_LINE_VISUAL/${COMMAND}/" $BpipeFileName
	fi
}



modifFichier () {


	LIGNE_MODIF=$(awk '{OFS="\n";gsub(/:/," ");gsub(/\t/," "); printf "%s\n%d\n%s\n","FALSE",NR,$0}'  ${FIC_PHASE[$1]}|    zenity --list --text="Sélectionner une ligne à traiter (modifier/supprimer) dans le ficher ${FIC_PHASE[$1]}" --column="Selection" --column="N°" --column="Commande" --checklist --width=650 --height=200 --print-column="2" --ok-label="Traiter" 2> /dev/null)
	
	if [ $? -eq 0 ];then

	# OK fichier à traiter	
		zenity --question --title="Phase ${PHASE[$1]}" --text="Pour le fichier <tt>${FIC_PHASE[$1]}</tt> de la phase ${PHASE[$1]}, quelle action voulez vous effectuer ?" --ok-label="Modifier" --cancel-label="Supprimer la ligne ${LIGNE_MODIF}"

		if [ $? -eq 0 ];then
			echo $(sed -n "${LIGNE_MODIF}p" ${FIC_PHASE[$1]})
			zenity --entry --text="Ligne ${LIGNE_MODIF} à modifier" --entry-text="$( sed -n "${LIGNE_MODIF}p" ${FIC_PHASE[$1]} )" 

		elif [ $? -eq 1 ];then
			cp ${FIC_PHASE[$1]}{,.bak}
			sed -i "${LIGNE_MODIF}d" ${FIC_PHASE[$1]} 
		else
			echo "ERREUR"
			exit 1
		fi
	else
		echo "ERREUR"
		exit 1
	fi

}

menuPhase () {


	if [ -f ${FIC_PHASE[$1]} ];then 

		MENU=( $( echo ${MENU_FICHIER[@]// /_}|tr ' ' '\n'|awk '{OFS="\n";gsub("_"," ");print NR,$0}'|zenity --list --title="Menu ${PHASE[$1]}" --text="<b>Phase ${PHASE[$1]}</b>\n\nChoisir une action ci-dessous pour le fichier : <tt>${FIC_PHASE[$1]}</tt> :" --column="N°" --column="Action" --width=400 --height=270 --separator=" " 2>/dev/null ) )


		if [ ${#MENU[@]} -ne 0 ];then

			# Test du nombre d'items sélectionnés : si =/= de 1 recommencer
			if [ ${#MENU[@]} -eq 1 ];then

				case "$MENU" in 

					1 ) 
					# Affichage du fichier correspondant à la phase
					sed -e 's/:/ /g' -e 's/\t/ /g' ${FIC_PHASE[$1]}|    zenity --list --text="Contenu du ficher ${FIC_PHASE[$1]}" --column="Commande" --width=650 --height=200 2> /dev/null 
					menuPhase $1 
					;;

					2 )
					# Modification du fichier correspondant à la phase
					modifFichier $1
					;;

					3 )
					# Ajout d'une ligne au fichier correspondant à la phase
					ajoutLigne $1
					menuPhase $1 
					;;
	
					* )
					zenity --error --text="Item inconnu"
					menuPhase $1
					;;

				esac
			else
				zenity --error --text="Plusieurs items sélectionnés dans le menu. Je ne suis pas multi-tâches."
				menuPhase $1

			fi

		else
			QUITTER=$( zenity --question --text="Etes vous sûr de vouloir quitter ?" )
			if [ $? -eq 0 ];then
				exit 0

			elif [ $? -eq 1 ];then
				menuPhase $1
			else
				exit 1 
			fi
		fi
	fi
}


choixPhase () {

	INDICE_PHASE=( $( echo ${PHASE[@]// /_}|tr ' ' '\n'|awk '{OFS="\n";gsub("_"," ");print "TRUE",NR,$0}'|zenity --list --title="Menu" --text="Choisir une phase dans le menu suivant" --column=" " --column="°" --column=" " --width=400 --height=270 --separator=" " --checklist --multiple 2>/dev/null ) )
	echo ${INDICE_PHASE[@]}
	for i in ${INDICE_PHASE[@]}; do
		menuPhase $((i-1))
	done

}

menu () {

	ACCUEIL=$( echo -e "FALSE\nAfficher/Traiter les fichiers de commandes\nTRUE\nConstruction bpipe" |zenity --list --title="Menu - EUFTraSENG" --text="Bienvenue dans EUFTraSENG (<b>E</b>ncore <b>U</b>n <b>F</b>lux de <b>Tra</b>vaux <b>SÉ</b>quençage <b>N</b>ouvelles <b>G</b>énération)" --column=" " --column="Actions" --radiolist 2>/dev/null )

	if [ $? -eq 0 ];then
		# Si le code de sortie de la dernière commande ($?) vaut 0 : aka "succès"
		if [ "$ACCUEIL" = "Afficher/Traiter les fichiers de commandes" ];then
			choixPhase

		elif [ "$ACCUEIL" = "Construction bpipe" ];then 

			k=0
			while [ "$k" -lt "${#PHASE[@]}" ];do
				choixBpipe $k
				inclureBpipe $k "${RETOUR_CHOIX_BPIPE}"
				((k++))
			done

		else
			zenity --error --text="Action inappropriée pour le menu."
			exit 1
		fi

	fi
}


#### Fonction principale
menu 

