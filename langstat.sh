###################################################################
# langstat.sh                                                     #
#------------                                                     #
#                                                                 #
# Explication du fonctionnement du script:                        #
# On lance le script en faisant                                   #
# ./langstat.sh                                                   #
#                                                                 #
# On peut lui passer un des 2 parametres proposés suivants:       #
#                                                                 #
# --help = affiche l'aide d'utilisation de la                     #
#          commande                                               #
#                                                                 #
# -f ou --file suivi du chemin et du nom du fichier dictionnaire  #
# (exemple: ./langstat.sh -f ~/dictionnaires/dicoFR.txt)          #
#                                                                 #
# ---------------                                                 #
#                                                                 #
# le parametre -f ou --file peut être cumulé avec 2 autres        #
# parametres:                                                     #
#                                                                 #
# -c ou --charcount                                               #
# = on ne se base plus sur le fait qu'un lettre apparaisse au     #
#   moins une fois dans le mot pour le compter, mais on se base   #
#   cette fois sur le nombre de fois où le caractère apparait     #
#   dans le dictionnaire                                          #
#                                                                 #
# -p ou --percentages                                             #
# = affiche en plus le pourcentage d'apparition de chaque lettre  #
#   (nombre de mots où apparait la lettre / nombre total de mots) #
#   Bien entendu, ce parametre peut être cumulé avec le précédent #
#   c'est à dire qu'on peut faire                                 #
#   ./langstat.sh ~/dicos/dicoFR.txt -c -p                        #
#   ou meme                                                       #
#   ./langstat.sh ~/dicos/dicoFR.txt -p -c                        #
#   ce qui prendra en compte le fait qu'on compte le nombre       #
#   d'apparition des lettres et cela sera donc intégré dans le    #
#   pourcentage qui correspondra au nombre d'occurence de la      #
#   lettre divisé par le nombre total de lettres                  #
#                                                                 #
###################################################################

#!/bin/bash

##############################
# Declaration des variables: #
##############################

#booleen, 1 si le parametre -c a été entré, 0 sinon
switch_c='0'

#booleen, 1 si le parametre -p a été entré, 0 sinon
switch_p='0'

#boolen, 1 si l'utilisateur a entré autre chose que ./langstat.sh -f fichier (|-c|-p|-c -p|-p -c), 0 sinon
switch_error='0'

# Message d'erreur en cas de mauvaise syntaxe de la commande
syntax_error_msg="
MAUVAISE SYNTAXE. Syntaxe correcte:
\n------------------------------\n
./langstat.sh -f CHEMIN_FICHIER_DICTIONNAIRE/FICHIER_DICTIONNAIRE.EXT
\n------------------------------\n
Pour afficher l'aide de la commande, faire:
\n--------------------\n
./langstat.sh --help
\n--------------------"

#Message d'aide à afficher avec le parametre --help
help_msg="
##################################################################\n
# langstat.sh                                                      \n
#-----------                                                      \n
#                                                                 \n
# Explication du fonctionnement du script:                        \n
# On lance le script en faisant                                   \n
# ./langstat.sh                                                   \n
#                                                                 \n
# On peut lui passer un des 2 parametres proposés suivants:       \n
#                                                                 \n
# --help = affiche l'aide d'utilisation de la                     \n
#          commande                                               \n
#                                                                 \n
# -f ou --file suivi du chemin et du nom du fichier dictionnaire  \n
# (exemple: ./langstat.sh -f ~/dictionnaires/dicoFR.txt)          \n
#                                                                 \n
### ---------------                                                 \n
###                                                                 \n
### le parametre -f ou --file peut être cumulé avec 2 autres        \n
### parametres:                                                     \n
###                                                                 \n
### -c ou --charcount                                               \n
### = on ne se base plus sur le fait qu'un lettre apparaisse au     \n
###   moins une fois dans le mot pour le compter, mais on se base   \n
###   cette fois sur le nombre de fois où le caractère apparait     \n
###   dans le dictionnaire                                          \n
###                                                                 \n
### -p ou --percentages                                             \n
### = affiche en plus le pourcentage d'apparition de chaque lettre  \n
###   (nombre de mots où apparait la lettre / nombre total de mots) \n
###   Bien entendu, ce parametre peut être cumulé avec le précédent \n
###   c'est à dire qu'on peut faire                                 \n
###   ./langstat.sh ~/dicos/dicoFR.txt -c -p                        \n
###   ce qui prendra en compte le fait qu'une lettre apparaisse     \n
###   plusieurs fois dans un mot et sera donc intégré dans le       \n
###   pourcentage                                                   \n
###                                                                 \n
####################################################################\n
"

#Message d'erreur, fichier dictionnaire non existant
file_not_exist_error_msg="Le fichier entré n'existe pas"

#############################
# Declaration des fonctions #
#############################

# fonction qui affiche l'aide
show_help()
{
	echo -e $help_msg
}

#fonction qui affiche une erreur en cas de mauvaise syntaxe de la commande, dans la sortie erreur
show_syntax_error()
{
	echo -e $syntax_error_msg >&2
}

#fonction qui affiche une erreur en cas de fichier dictionnaire entré non existant. 
#cette fonction prend en parametre le nom du fichier en question
show_file_exist_error()
{
	echo -e "ERREUR FICHIER: $1\n$file_not_exist_error_msg" >&2
}


#fonction qui va parser le fichier dico et compter le nombre de mots pour chaque lettre et retourner le resultat
#faire toute la partie centrale du taff quoi...
# cette fonction prend en parametre le fichier dictionnaire a paser, soit $2 dans la partie main
parse_file()
{
	#message de presentation
	echo -e "Parsing du fichier $1: \n---------"	
	
	#REMARQUE: 
	#je fais le choix de faire 4 boucles distinctes en fonction des parametres passés pour des raisons d'optimisation 
	#j'aurais pu faire utiliser des structures conditionnelles genre "si on a fait -p, alors rajouter le pourcentage"
	#mais cela aurait impliqué un test à chaque tour de boucle, je préfère que ce test ne soit fait qu'une seule fois.
	###############################

	#si on est en mode par défaut,
	if [ $switch_c = '0' ] && [ $switch_p = '0' ]
	then
		#on recupere le nombre total de mots dans le dictionnaire
		total_words=`cat $1 | wc -w`

		#on affiche ce total en préambule pour pouvoir mettre les resultats en perspective
		echo "Nombre total de mots dans le dictionnaire: $total_words mots"

		for letter in {A..Z}
		do 
			#ca retourne le nombre de mots où ya au moins une fois la lettre
			echo -e `grep $letter $1 | wc -l`"\t-\t$letter" 
		done

	#si on est en mode charcount sans -p	
	elif [ $switch_c = '1' ] && [ $switch_p = '0' ]
	then

		#on recupere le nombre total de lettres dans le dictionnaire
		total_letters=`cat $1 | wc -c`

		#on affiche ce total en préambule pour pouvoir mettre les resultats en perspective
		echo "Nombre total de lettres  dans le dictionnaire: $total_letters lettres"

		for letter in {A..Z}
		do 
			#ca retourne le nombre de ligne de grep -o letter fichier, or letter -o retourne la lettre a chaque fois qu'il la trouve, 
			#donc en comptant le nombre de lignes de grep -o, on a le nombre de lettres.
			echo -e `grep -o $letter $1 | wc -l`"\t-\t$letter" 
		done

	#si on est en mode percent sans -c
	elif [ $switch_c = '0' ] && [ $switch_p = '1' ]
	then	
		#on recupere le nombre total de mots dans le dictionnaire
		total_words=`cat $1 | wc -w`

		#on affiche ce total en préambule pour pouvoir mettre les resultats en perspective
		echo "Nombre total de mots dans le dictionnaire: $total_words mots"

		#nombre d'occurences de mot
		nb_occur=""
		#pourcentage d'occurence de mot
		percent=""

		for letter in {A..Z}
		do 
			#on recupere le nombre de mots où ya au moins une fois la lettre
			nb_occur=`grep $letter $1 | wc -l`

			#on recupere la valeur du pourcentage arrondi à 10^-2
			#pour cela on ajoute 0.005 au resultat de la division et on tronque la nombre avec grep -E 
			percent=`echo "((($nb_occur/$total_words)*100)+0.005)" | bc -l | grep -Eo '^[0-9]*\.[0-9]{2}'`

			#affichage du resultat
			echo -e "$nb_occur\t-($percent%)-\t$letter"
			
		done
	
	
	#si on est en mode -c et -p
	elif [ $switch_c = '1' ] && [ $switch_p = '1' ]
	then
		#on recupere le nombre total de lettres dans le dictionnaire
		total_letters=`cat $1 | wc -c`

		#on affiche ce total en préambule pour pouvoir mettre les resultats en perspective
		echo "Nombre total de lettres  dans le dictionnaire: $total_letters lettres"

		#nombre d'occurences de lettre
		nb_occur=""
		#pourcentage d'occurence de lettre
		percent=""

		for letter in {A..Z}
		do 
		
			# On recupere le nombre de fois ou la lettre apparait:
			nb_occur=`grep -o $letter $1 | wc -l`

			#on recupere la valeur du pourcentage
			#pour cela on ajoute 0.005 au resultat de la division et on tronque la nombre avec grep -E 
			percent=`echo "((($nb_occur/$total_letters)*100)+0.005)" | bc -l | grep -Eo '^[0-9]*\.[0-9]{2}'`

			#affichage du resultat
			echo -e "$nb_occur\t-($percent%)-\t$letter"
			
		done

	#si on est dans la situation du tiers exclu
	else
		switch_error='1'
		echo "Il y a un problème, switch_c ou switch_p ne prend pas une valeur valable."
	
	fi 
}


######
#MAIN#
########################################
#Recuperation du premier parametre,    #
#qui est obligatoire                   #
########################################

#si l'utilisateur n'a pas passé au moins un parametre, syntaxe minimale correcte de la commande, ou s'il a passé plus de 4 parametres,
#syntaxe maximale correcte de la commande
if [ -z $1 ] || [ $# -gt 4 ]
then
	# affichage du message d'erreur de syntaxe de la commande, dans la sortie erreur
	show_syntax_error	

#si le nombre de parametres passé est compris entre 1 et 4
else
	# on verifie ce qu'est le premier parametre, si c'est --help on affiche l'aide, 
        # si c'est -f, on récupère l'emplacement du fichier dictionnaire qui doit être dans $2,
        # sinon on retourne le message d'erreur de la commande
	#############

	# si le premier parametre passé est --help
	if [ $1 = '--help' ]
        then
        	show_help

	# si le premier parametre passé est -f ou --file
	elif [ $1 = '-f' ] || [ $1 = '--file' ]
	then
		# on vérifie que $2 est défini, sinon, on affiche la syntax error
		if [ -z $2  ]
		then 
			show_syntax_error

		#$2 est défini, on vérifie que ce $2 est bien un fichier existant
		elif [ ! -e $2 ]
		then 
			show_file_exist_error $2

		# on a bien $1='-f' ou '--file' et un nom de fichier passé en parametre qui est valide. On verifie les autres parametres
		else
			#s'il y a un 3e parametre passé
			if [ ! -z $3 ]
			then
				# on regarde quel est ce parametre: si c'est -c, c'est ok
				if [ $3 = '-c' ] || [ $3 = '--charcount' ]
				then
					switch_c='1'
					
					# s'il y a egalement un 4e parametre passé, 
					if [ ! -z $4 ]
					then
						# si c'est -p, c'est ok
						if [ $4 = '-p' ] || [ $4 = '--percentages' ]
						then
							switch_p='1'

						#sinon c'est syntax error
						else
							show_syntax_error
							switch_error='1'
						fi
					fi

				#si c'est pas -c mais que c'est -p, c'est ok
				elif [ $3 = '-p' ] || [ $3 = '--percentages' ]
				then
					switch_p='1'

                                         # s'il y a egalement un 4e parametre passé, 
                                         if [ ! -z $4 ]
                                         then
                                         	# si c'est -c, c'est ok
                                                 if [ $4 = '-c' ] || [ $4 = '--charcount' ]
                                                 then
                                                        switch_c='1'
                                 
                                                 #sinon c'est syntax error
                                                 else    
                                                         show_syntax_error
                                                         switch_error='1'
                                                 fi
					fi
                                 

				# si le 3e parametre n'est ni -c ni -p, syntax error
				else
					show_syntax_error
					switch_error='1'
				fi
				
			fi
		

			#s'il n'y a pas d'erreur dans la syntaxe des parametres, cad qu'on a aucune autre configuration que -p -c; -c -p, -c; -p,  
			if [ $switch_error = '0' ]
			then
				parse_file $2
			fi

		fi

	# si le premier paramètre n'est aucun des 2 proposés, c'est une syntax error
	else 
		show_syntax_error
	fi	
fi


