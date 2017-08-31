# MAIN INFORMATICA
 
 # copias.ps1  (Archivo sin variables para update con git-clone)
 # copias-1.4  (Archivo Version 1.4 con variables incluidas)
 # 
 Pasos para Instalar:
 1- Instalar Git para Windows https://git-scm.com/download/win (opciones por defecto)
 2- Descargar en zip el proyecto y guardarlo en c:\COPIAS\
 3- Editar el fichero variables.ps1 y asignar campos requeridos como destino maquinas a copiar...
 4- Crear Tareas programadas:
 4.a - Tarea powershell.exe c:\COPIAS\copias.ps1 (Este es el script de copias como tal y lee el fichero variables)
 4.b - Tarea c:\COPIAS\update.bat (Esta tarea es opcional se puede poner semanal o mensualmente o ejecutar de forma manual. Lo que hace es buscar actualizaciones del repositorio y lo actualiza al ejecturar el script
 
 Hay un PDF en este repositorio con un manual de instalacion
