#!/usr/bin/env bash
# Flux de travaux NGS
# 12/05/2015
# Clément Lionnet & Charlie Pauvert

# Affichage de la version de zenity
echo `zenity --version`

# Test si zenity est installé sur l'ordinateur
if [ ! -x "/usr/bin/zenity" ];then
	echo "Malheur ! Zenity n'est pas installé !"
	echo "Le programme ne peut s'exécuter..."
	echo -e "--\napt-get install zenity ?"
	exit 1
fi

# Variable contenant les trois étapes du flux de travaux ngs
PHASE=("Aligneurs" "Appeleur de variants" "Visualisateur")

# Variable contenant les différents fichiers contenant les lignes de commandes de chaque étapes
FIC_PHASE=(aligneurs.txt appeleurs.txt visualisateurs.txt)

# Variable contenant les options concernant l'intéraction avec les fichiers
MENU_FICHIER=( "Afficher" "Modifier/Supprimer une ligne" "Ajouter une ligne" )

# Variable contenant les différents types de paramètres
# Drapeau : paramètres sans arguments
# Fichier : paramètres avec un nom de fichier en argument
# Valeur : paramètres avec une valeur en argument
TYPE_PARAM=( "Drapeau" "Fichier" "Valeur" )

#Déclaration des variables PARAM et LOGICIEL
declare -a PARAM
declare LOGICIEL

# Fonction ajoutLigne
# Elle permet d'ajouter une ligne de commande pour chacun des fichiers
# Elle prend en paramètre l'indice dans le tableau du fichier que l'on veut modifer
ajoutLigne () {
	# Test de l'existence du fichier
	if [ -f ${FIC_PHASE[$1]} ];then 
		# Si le fichier existe
		# Récupération du nom des logiciels
		LOGICIEL=$(cut -d: -f 1 ${FIC_PHASE[$1]} |uniq |awk '{OFS="\n";print $0}END{print " "}' |zenity --list --text="Choissisez un logiciel dans la liste, ou ajouter le manuellement :" --column="${FIC_PHASE[$1]}" --editable  2>/dev/null)
		# Récupération de code de retour de la commande précédente
		OUT_LOGICIEL=$?
		# Ajout du logiciel dans le fichier temporaire nouvelle_ligne.tmp
		if [ "${OUT_LOGICIEL}" -eq 0 ];then
			echo "${LOGICIEL}" > nouvelle_ligne.tmp
		fi

		# Ajout des paramétres du logiciel ajouté
		out=-1
		while [ "$out" -ne 1 ];do
			zenity --question --text="Continuez l'ajout de paramètre pour <tt>${LOGICIEL}</tt> ? "
			out=$?
			# Si la réponse est oui, on commence l'ajout du paramètre
			if [ "$out" -eq 0 ];then
				# Ajout du nouveau paramètre
				NOUVEAU_PARAM=$(zenity --entry --text="Nouveau paramètre pour <tt>${LOGICIEL}</tt> - Phase ${PHASE[$1]}" )
				# Choix du type de paramètre
				MENU_PARAM=( $( echo ${TYPE_PARAM[@]}|tr ' ' '\n'|zenity --list --title="Menu" --text="<b>Phase ${PHASE[$1]}</b>\n\nChoisir un type de paramètre pour <tt>${NOUVEAU_PARAM}</tt> :" --column="Type" --width=400 --height=270 --separator=" " 2>/dev/null ) )

				# Affichage de la boite de dialogue correspondant au type de paramètre sélectionné
				case "${MENU_PARAM}" in

					"Drapeau")
						# Drapeau
						NOUVEAU_VALEUR=""
						;;
					"Fichier")
						# Fichier
						NOUVEAU_VALEUR=$(zenity --file-selection --text="Fichier pour paramètre ${NOUVEAU_PARAM}" 2> /dev/null  )
						;;
					"Valeur")
						# Valeur
						NOUVEAU_VALEUR=$(zenity --entry --text="Valeur pour paramètre ${NOUVEAU_PARAM}" 2> /dev/null  )
						;;
					*)
						# Si aucun type de parmètres n'est choisi, un message d'erreur s'affiche
						zenity --error --text="Item inconnu"
						# Retour au début de la fonction ajoutLigne
						ajoutLigne $1
						;;
				esac
				
				# Ajout du paramètre et de son argument
				echo -e ":${NOUVEAU_PARAM}\t${NOUVEAU_VALEUR}" >> nouvelle_ligne.tmp
			fi
		done
		
		# Ecriture de la ligne de commande dans le fichier que l'on veut modifier
		if [ "${OUT_LOGICIEL}" -eq 0 ];then
			cat nouvelle_ligne.tmp|tr -d '\n' >> ${FIC_PHASE[$1]}
			echo >> ${FIC_PHASE[$1]}
			# Suppression du fichier temporaire nouvelle_ligne.tmp
			rm nouvelle_ligne.tmp
		fi
	fi

}

# Fonction choixBpipe
# Elle permet de choisir le logiciel que l'on va mettre dans le fichier bpipe
# Cette fonction est appelée pour chaque étapes du flux
# Elle prend en paramètre l'indice dans le tableau du fichier que l'on veux utiliser
choixBpipe () {
	# Test de l'existence du fichier
	if [ -f ${FIC_PHASE[$1]} ];then 
		# si le fichier existe
		# Choix du logiciel que l'on veut utiliser
		LOGICIEL=$(cut -d: -f 1 ${FIC_PHASE[$1]} |uniq |zenity --list --text="Liste des logiciels" --column="${FIC_PHASE[$1]}" 2>/dev/null)
		# choix des paramètres du logiciel
		RETOUR_CHOIX_BPIPE=$(awk -v a=${LOGICIEL} -F: '{OFS="\n";if($1==a){gsub(/:/," "); printf "%s\n%s\n","FALSE",$0}}' ${FIC_PHASE[$1]}  |zenity --list --text="Choisisser la ligne de commande que vous souhaitez utiliser" --column="Selection" --column="Commande" --checklist --width=650 --height=200 --print-column="2" 2> /dev/null)
	fi
}

# Fonction inclureBpipe
# Elle permet de 
# Cette fonction est appelée pour chaque étapes du flux
# Elle prend en paramètre l'indice dans le tableau de la phase à ajouter et la ligne de commande à ajouter au fichier bpipe
inclureBpipe () {
	# Récupération de la date pour créer le fichier bpipe
	DATE=$(date +%Y_%m_%d_%H_%M)
	# Nom du fichier bpipe
	BpipeFileName="bpipe_"$DATE".txt"

	# Test si le fichier existe
	if [ ! -f $BpipeFileName ];then
		# si le fichier bpipe n'existe pas : le créer
		cp template_bPipe.txt $BpipeFileName
	fi

	# s'il existe le modifier pour chaque phase
	COMMAND=$( echo $2|tr '\t' ' ' )

	# Test concernant la phase à modifier dans le fichier bpipe
	if [ $1 -eq 0 ];then
		# Ajout de la ligne de commande pour l'aligneur
		sed -i "s/COMMAND_LINE_ALIGN/${COMMAND}/" $BpipeFileName
	elif [ $1 -eq 1 ];then
		# Ajout de la ligne de commande pour l'appeleur de variant
		sed -i "s/COMMAND_LINE_APP/${COMMAND}/" $BpipeFileName
	else
		# Ajout de la ligne de commande pour le visualisateur 
		sed -i "s/COMMAND_LINE_VISUAL/${COMMAND}/" $BpipeFileName
	fi
}

# Fonction modifFichier
# Elle permet de modifier le contenu d'un fichier contenant les lignes de commande
# Elle prend en paramètre l'indice dans le tableau du fichier que l'on veux utiliser
modifFichier () {
	# Choix de la ligne à modifier ou à supprimer
	LIGNE_MODIF=$(awk '{OFS="\n";gsub(/:/," ");gsub(/\t/," "); printf "%s\n%d\n%s\n","FALSE",NR,$0}'  ${FIC_PHASE[$1]}|    zenity --list --text="Sélectionner une ligne à traiter (modifier/supprimer) dans le ficher ${FIC_PHASE[$1]}" --column="Selection" --column="N°" --column="Commande" --checklist --width=650 --height=200 --print-column="2" --ok-label="Traiter" 2> /dev/null)
	
	# Test si une ligne a été sélectionnée
	if [ $? -eq 0 ];then
	# OK fichier à traiter
		# Choix entre la modification et la suppression de la ligne sélectionnée
		zenity --question --title="Phase ${PHASE[$1]}" --text="Pour le fichier <tt>${FIC_PHASE[$1]}</tt> de la phase ${PHASE[$1]}, quelle action voulez vous effectuer ?" --ok-label="Modifier" --cancel-label="Supprimer la ligne ${LIGNE_MODIF}"
		
		# Lancement de la boite dialogue correspondante au choix		
		if [ $? -eq 0 ];then
			# Si le choix est la modification de la ligne
			echo $(sed -n "${LIGNE_MODIF}p" ${FIC_PHASE[$1]})
			# Modification de la ligne
			zenity --entry --text="Ligne ${LIGNE_MODIF} à modifier" --entry-text="$( sed -n "${LIGNE_MODIF}p" ${FIC_PHASE[$1]} )" 
		elif [ $? -eq 1 ];then
			# Si le choix est suppression de la ligne
			# Copie du fichier dans un fichier .bak pour revenir à l'état précédent en cas d'erreur
			cp ${FIC_PHASE[$1]}{,.bak}
			# Suppression de la ligne
			sed -i "${LIGNE_MODIF}d" ${FIC_PHASE[$1]} 
		else
			# Si aucun choix n'a été fait
			echo "ERREUR"
			exit 1
		fi
	else
		# Si aucun choix n'a été fait
		echo "ERREUR"
		exit 1
	fi

}

# Fonction menuPhase
# Elle permet de choisir l'action que l'on veux réaliser pour une phase donnée
# Cette fonction est appelée pour chaque étapes du flux
# Elle prend en paramètre l'indice dans le tableau du fichier que l'on veux utiliser
menuPhase () {
	# Test si le fichier existe
	if [ -f ${FIC_PHASE[$1]} ];then 
		# Choix de l'action que l'on souhaite faire sur le fichier
		MENU=( $( echo ${MENU_FICHIER[@]// /_}|tr ' ' '\n'|awk '{OFS="\n";gsub("_"," ");print NR,$0}'|zenity --list --title="Menu" --text="<b>Phase ${PHASE[$1]}</b>\n\nChoisir une action ci-dessous pour le fichier : <tt>${FIC_PHASE[$1]}</tt> :" --column="N°" --column="Action" --width=400 --height=270 --separator=" " 2>/dev/null ) )

		# Test si l'utilisateur a cliqué sur le bouton validé
		if [ ${#MENU[@]} -ne 0 ];then

			# Test du nombre d'items sélectionnés : si =/= de 1 recommencer
			if [ ${#MENU[@]} -eq 1 ];then
				case "$MENU" in 

					1 )
					# Affichage du contenu du fichier
					sed -e 's/:/ /g' -e 's/\t/ /g' ${FIC_PHASE[$1]}|    zenity --list --text="Contenu du ficher ${FIC_PHASE[$1]}" --column="Commande" --width=650 --height=200 2> /dev/null 
					menuPhase $1 
					;;

					2 )
					# Modification du fichier
					modifFichier $1
					;;

					3 )
					# Ajout d'une ligne
					ajoutLigne $1
					menuPhase $1 
					;;
	
					* )
					# si aucun choix n'à été fait
					zenity --error --text="Item inconnu"
					menuPhase $1
					;;

				esac
			else
				# Message d'erreur si plusieurs action ont été choisie
				zenity --error --text="Plusieurs items sélectionnés dans le menu. Je ne suis pas multi-tâches."
				menuPhase $1

			fi
		else
			# Si l'utilisateur a cliqué sur annuler
			# Demande a l'utilisateur si il veut bien quitter
			QUITTER=$( zenity --question --text="Etes vous sûr de vouloir quitter ?" )
			if [ $? -eq 0 ];then
				# Si oui, on sort
				exit 0
			elif [ $? -eq 1 ];then
				# Si non, on revient au menu
				menuPhase $1
			else
				# Sinon on sort
				exit 1 
			fi
		fi
	fi
}

# Fonction choixPhase
# Elle permet de choisir la ou les phase(s) que l'on souhaite modifier
# Elle ne prend pas de paramètre
choixPhase () {
	# Choix entre les trois phases
	INDICE_PHASE=( $( echo ${PHASE[@]// /_}|tr ' ' '\n'|awk '{OFS="\n";gsub("_"," ");print "TRUE",NR,$0}'|zenity --list --title="Menu" --text="Phase " --column=" " --column="°" --column=" " --width=400 --height=270 --separator=" " --checklist --multiple 2>/dev/null ) )
	# Affichage du menu pour chaque phases sélectionnées
	for i in ${INDICE_PHASE[@]}; do
		menuPhase $((i-1))
	done

}

# Fonction menu
# Elle permet de choisir entre le traitements des fichiers de commande et la construction d'un fichier bpipe
# C'est la fonction principale
menu () {
	# Choix entre les deux options
	ACCUEIL=$( echo -e "FALSE\nAfficher/Traiter les fichiers de commandes\nTRUE\nConstruction bpipe" |zenity --list --title="Menu - EUFTraSENG" --text="Bienvenue dans EUFTraSENG (<b>E</b>ncore <b>U</b>n <b>F</b>lux de <b>Tra</b>vaux <b>SÉ</b>quençage <b>N</b>ouvelles <b>G</b>énération)" --column=" " --column="Actions" --radiolist 2>/dev/null )
	# Test si l'utilisateur a cliqué sur validé
	if [ $? -eq 0 ];then
		if [ "$ACCUEIL" = "Afficher/Traiter les fichiers de commandes" ];then
			# Si l'utilisateur a choisi le traitement des fichiers de commande
			choixPhase
		elif [ "$ACCUEIL" = "Construction bpipe" ];then 
			# Si l'utilisateur a choisi la construction de fichier bpipe
			k=0
			# Pour chaque phases on va choisir un logiciel et un ligne de commande
			while [ "$k" -lt "${#PHASE[@]}" ];do
				# Choix du logiciel et de la ligne de commande
				choixBpipe $k
				# Ecriture dans le fichier bpipe
				inclureBpipe $k "${RETOUR_CHOIX_BPIPE}"
				((k++))
			done

		else
			# Si l'utilisateur n'a pas fait de choix
			zenity --error --text="Action inappropriée pour le menu."
			exit 1
		fi

	fi
}

# appel de la function menu
menu 
