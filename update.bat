@echo off
cd c:\COPIAS\
copy TMP\update.bat .
rmdir TMP /S /Q
git clone https://github.com/maininformatica/copias.ps1.git TMP/
cd TMP
copy copias.ps1 ..
copy copias_2.ps1 ..
cd ..

