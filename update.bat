@echo off
cd c:\COPIAS\
rmdir TMP /S
https://github.com/maininformatica/copias.ps1.git
cd TMP
copy copias.ps1 ..
echo "Recuerda Editar el Fichero de Variables"
