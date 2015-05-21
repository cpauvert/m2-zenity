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
MENU_FICHIER=( "Afficher" "Modifier/Supprimer une ligne" "Ajouter une ligne" "Construction fichier Bpipe" )
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

ajoutLigne () {


	if [ -f ${FIC_PHASE[$1]} ];then 
		# si le fichier existe
		LOGICIEL=$(cut -d: -f 1 ${FIC_PHASE[$1]} |uniq |awk '{OFS="\n";print NR,$0}END{print NR+1," "}' |zenity --list --text="Liste des logiciels" --column=" " --column="${FIC_PHASE[$1]}" --editable --print-column=2 2>/dev/null)
		OUT_LOGICIEL=$?
		if [ "${OUT_LOGICIEL}" -eq 0];then
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

		if [ "${OUT_LOGICIEL}" -eq 0];then
			cat nouvelle_ligne.tmp|tr -d '\n' >> ${FIC_PHASE[$1]}
			rm nouvelle_ligne.tmp
		fi
	fi

}

choixBpipe () {
	if [ -f ${FIC_PHASE[$1]} ];then 
		# si le fichier existe
		LOGICIEL=$(cut -d: -f 1 ${FIC_PHASE[$1]} |uniq |zenity --list --text="Liste des logiciels" --column="${FIC_PHASE[$1]}" 2>/dev/null)
		RETOUR_CHOIX_BPIPE=$(awk -v a=${LOGICIEL} -F: '{OFS="\n";if($1==a){gsub(/:/," "); printf "%s\n%s\n","FALSE",$0}}'  aligneurs.txt|zenity --list --text="Coucou" --column="Selection" --column="Commande" --checklist --width=650 --height=200 --print-column="2" 2> /dev/null)
	fi
}

inclureBpipe () {
	zenity --question --text="Voulez vous donner un nom spécifique au fichier Bpipe ?"
	if [ $? -eq 0 ];then
		FileName=$(zenity --entry --text="Nom du fichier Bpipe" 2/dev/null )
		BpipeFileName=${FileName}.txt
	else
		DATE=$(date +%Y_%m_%d_%H)
		BpipeFileName="bpipe_"$DATE".txt"
	fi
	
	COMMAND=$( echo $2|tr '\t' ' ' )
	cp template_bPipe.txt $BpipeFileName

	if [ $1 -eq 0 ];then
		sed -i "s/COMMAND_LINE_ALIGN/${COMMAND}/" $BpipeFileName
	elif [ $1 -eq 1 ];then
		sed -i "s/COMMAND_LINE_APP/${COMMAND}/" $BpipeFileName
	else
		sed -i "s/COMMAND_LINE_VISUAL/${COMMAND}/" $BpipeFileName
	fi
}

#i=0
#while [ "$i" -lt "${#PHASE[@]}" ];do
#	choixLogicielParametre $i
#	inclureBpipe $i
#	((i++))
#done

#choixLogicielParametre 0

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

	echo -e "#################\n ${PHASE[$1]}\n###############\n"

	if [ -f ${FIC_PHASE[$1]} ];then 

		MENU=( $( echo ${MENU_FICHIER[@]// /_}|tr ' ' '\n'|awk '{OFS="\n";v="TRUE";if(NR!=1){v="FALSE";}gsub("_"," ");print v, NR,$0}'|zenity --list --title="Menu" --text="<b>Phase ${PHASE[$1]}</b>\n\nChoisir une action ci-dessous pour le fichier : <tt>${FIC_PHASE[$1]}</tt> :" --column="Choix" --column="" --column="Action" --checklist --width=400 --height=270 --separator=" " 2>/dev/null ) )

#		zenity --question --title="Phase ${PHASE[$1]}" --text="Pour le fichier <tt>${FIC_PHASE[$1]}</tt> de la phase ${PHASE[$1]}, quelle action voulez vous effectuer ?" --ok-label="Go bpipe" --cancel-label="Modifier ${FIC_PHASE[$1]}"

		if [ ${#MENU[@]} -ne 0 ];then

			# Test du nombre d'items sélectionnés : si =/= de 1 recommencer
			if [ ${#MENU[@]} -eq 1 ];then

				case "$MENU" in 

					1 ) 
					sed -e 's/:/ /g' -e 's/\t/ /g' ${FIC_PHASE[$1]}|    zenity --list --text="Contenu du ficher ${FIC_PHASE[$1]}" --column="Commande" --width=650 --height=200 2> /dev/null 
					menuPhase $1 
					;;

					2 )
					modifFichier $1
					# insérer function modification
					;;

					3 )
					ajoutLigne $1
					LIGNE=$( zenity --entry --title="Nouvelle ligne pour fichier <tt>${FIC_PHASE[$1]}</tt>" --text="Entrez une nouvelle ligne. Format <tt>LOGICIEL:param1 valeur1:param2 :param3</tt>" )
					echo $LIGNE
					;;


					4 )
					choixBpipe $1
					inclureBpipe $1 "${RETOUR_CHOIX_BPIPE}"
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

menuPhase 0

#echo ${LOGICIEL} ${PARAM[@]}
#awk -F: '{print "Logiciel: ", $1}' aligneurs.txt
