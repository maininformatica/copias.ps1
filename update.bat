@echo off
cd c:\COPIAS\
copy TMP\copias1.bat .
rmdir TMP /S /Q
git clone https://github.com/maininformatica/copias.ps1.git TMP/
cd TMP
copy copias.ps1 ..
cd ..

