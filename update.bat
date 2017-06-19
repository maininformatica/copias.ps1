@echo off
cd c:\COPIAS\
rmdir TMP /S /Q
git clone https://github.com/maininformatica/copias.ps1.git TMP/
cd TMP
copy copias.ps1 ..
echo "Recuerda Editar el Fichero de Variables"
