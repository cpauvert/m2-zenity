#!/usr/bin/bash
# Flux de travaux NGS
# 12/05/2015
# Clément Lionnet & Charlie Pauvert

echo `zenity --version`

awk -F: '{print "Logiciel: ", $1}' aligneurs.txt
