#+-------------------------------------------------------------------+   
#|              SCRIPT DE COPIAS MAIN INFORMATICA GANDIA SL          | 
#|              V1.4 jtormo@main-informatica.com                     |
#|                                                                   |
#|   METODO DE COPIAS: VM-EXPORT Power Shell                         |
#|                                                                   |
#|   ATENCION: El sistema debe permitir ejecucion de scripts         |
#|             Ejecuta como administrador POWER SHELL ISE            |
#|             Ejecuta el comando: Set-ExecutionPolicy Unrestricted  |
#|                                                                   |
#+-------------------------------------------------------------------+ 
 
 
# Aspectos a tener en cuenta
# Este script de copia para sistemas Windows Hyper-V utiliza como directorios por defecto
# Discos: C:\Users\Public\Documents\Hyper-V\Virtual hard disks 
# Destino de copias Z:\BACKUPS
# Si los directorios y unidades son correctos NO hace falta tocar nada
# Este SCRIPT Mantendra un total de 3 copias. NO se permite VARIAS COPIAS por dia si NO se renombra el fichero del dia anterior 
# Borra la 4ª Rotacion mas antigua. Si no quieres que borre Comenta la linea donde se encuentre [Remove-Item -Recurse -Force]
 
 
 
# Variables de Entorno
$servername="HYPERV1"								# Nombre HOST HyperV
$maquinas = ('VM1','VM2')							# Nombre de Maquinas a Copias
$nummax = "2"									# Numero de copias NO rotativas, es decir, una vez existan 3 a la 4 borrarÃ¡ la mas antigua
$unidaddestino="C:"								# Unidad Donde estan las Imagenes a copiar
$unidadorigen="C:"								# Unidad destino donde guardar la copia
$dirdestino="$unidaddestino\SHELL\DESTINO"					# Directorio Completo donde alberga las copias
$source = "$unidadorigen\SHELL\ORIGEN\*"                                    	# Directorio Completo donde estan los discos a copiar
$date = Get-Date -Format yyyyMMdd 						# Fecha
$smtp = "188.93.78.29" 								# Servidor SMTP para envio de correos
$from = "backups@main-informatica.com <backups@main-informatica.com>"		# Desde que cuenta 
$to = "jtormo@main-informatica.com <jtormo@main-informatica.com>" 		# A que cuenta
$pref="SEMANAL"	 								# Prefijo de Copia (se puede usar para indicar la frecuencia de la copia)
$warnspace="120"                                                                # Nivel de Alarma en espacio Libre de Destino Medido en GB



### Funciones      
function tamanyo 
{ 
    param([string]$pth) 
    "{0:n2}" -f ((gci -path $pth -recurse | measure-object -property length -sum).sum /1gb ) 
}


$TAMORIGEN=tamanyo $source
$TAMDESTINO=tamanyo $dirdestino
$FREEDESTINOC=get-WmiObject win32_logicaldisk -Filter "DeviceID='$unidaddestino'" | Format-Table DeviceId,@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}} | findstr ':  '
$FREEDESTINO="{0:N2}" -f ($FREEDESTINOC.split(":", 3) -replace(" ","") | Select-Object -Last 1)
$TEXTTAM="El tamaño de la copia será de $TAMORIGEN GB y queda $FREEDESTINO GB libre con un uso de Copias ACTUAL de $TAMDESTINO GB en Destino"
$TEXTTAMBODY="El tama&ntilde;o de la copia ser&aacute; de <b>$TAMORIGEN</b> GB y queda <b>$FREEDESTINO</b> GB libre con un uso de Copias ACTUAL de <b>$TAMDESTINO</b> GB en Destino"

$datestart=Get-Date -Format "dd-MM-yyyy HH:mm"
echo $TEXTTAM
$numcopiasdef=[convert]::ToInt32($nummax, 10)+1


  
### Comprobaciones ##########################################################################################################
  

# Comprobamos que existe la unidad de DESTINO  
If (!(Test-Path "$unidaddestino"))
{
echo "No hay unidad Destino: $unidaddestino"
$subject = "Backup ERROR $servername $date"
$body = "No se ha podido realizar el backups porque La Unidad de Destino de Backups NO esta montada: $unidaddestino" 
send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
exit 0
}

# Comprobamos que existe la unidad de ORIGEN
If (!(Test-Path "$unidadorigen"))
{
echo "No hay unidad Origen: $unidadorigen"
$subject = "Backup ERROR $servername $date"
$body = "No se ha podido realizar el backups porque La Unidad de Origen de Backups NO existe: $unidadorigen" 
send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
exit 0
}
 
# Comprobamos que existe el Directorio de DESTINO
If (!(Test-Path $dirdestino))
{
echo "No esta el directorio Destino: $dirdestino"
$subject = "Backup ERROR $servername $date"
	$body = "No se ha podido realizar el backups porque el directorio de Destino de las copias NO existe: $dirdestino" 
	#Send an Email to User  
    send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
	exit 0
} 

# Comprobamos que existe el Directorio de ORIGEN
If (!(Test-Path $source))
{
echo "No esta el directorio Origen: $source"
$subject = "Backup ERROR $servername $date"
	$body = "No se ha podido realizar el backups porque el directorio de ORIGEN de las copias NO existe: $source" 
	#Send an Email to User  
    send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
	exit 0
} 

# Comprobamos si existe Copia con Mismo Nombre
If (Test-Path $dirdestino\BKP$pref$date)
{
echo "Ya existe una Copia con ese Noombre: $dirdestino\BKP$date"
$subject = "Backup ERROR $servername $date"
	$body = "No se ha podido realizar el backups porque ya existe una copia con ese nombre $dirdestino\BKP$date. Debe renombrarla o Eliminarla" 
	#Send an Email to User  
    send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
	exit 0
} 

# Comprobamos que tengamos espacio en DESTINO  
# If ( $FREEDESTINO -ge $TAMORIGEN)
# {
# echo "El Tamaño de la Copia ($TAMORIGEN GB) Excede el Libre en Destino ($FREEDESTINO GB). No puedo Hacer la copia"
# $subject = "Backup ERROR $servername $date"
# $body = "El Tamaño de la Copia ($TAMORIGEN GB) Excede el Libre en Destino ($FREEDESTINO GB). No puedo Hacer la copia" 
# send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
# exit 0
# }

  
##################################################################################################################################
  
# Backup Process started 
 
 $numcopias =  @( Get-ChildItem $dirdestino ).Count 
 
 function Haz-copia {
        	$destination = "$dirdestino\BKP$pref$date" 
		$path = test-Path $destination 
		cd $dirdestino\ 
		mkdir BKP$pref$date 
		## copy-Item  -Recurse $source -Destination $destination
		ForEach ($expmaq in $maquinas ) { 
                Export-VM -Name "$expmaq" -Path $destination
            	}
		$dateend=Get-Date -Format "dd-MM-yyyy HH:mm"


            If ( $warnspace -lt $FREEDESTINO) 
            {
             $subject = "Backup Correcto $servername $date"
            } else {
             $subject = "WARNING:: Backup Correcto $servername $date"
             $WARNINGTAMADJ="ATENCION: Se ha alcanzado tamaño de Aviso por Poco espacio en Unidad de Destino de Copias: $warnspace GB"
             $WARNINGTAMBODY = "ATENCION: Se ha alcanzado tama&ntilde;o de Aviso por Poco espacio en Unidad de Destino de Copias: $warnspace GB"
            }


            "Resumen COPIA de Sefuridad para $servername en $date" | out-File "$destination\backup_log.txt"
			"---------------------------------------------------------------" | out-File -Append "$destination\backup_log.txt"
            " Fecha de Inicio de Copia: $datestart" | out-File -Append "$destination\backup_log.txt"
            " Fecha de Fin de Copia:    $dateend" | out-File -Append "$destination\backup_log.txt"
            " $TEXTTAM" | out-File -Append "$destination\backup_log.txt"
            " El sistema guarda un Número Máximo de copias de: $numcopiasdef. Corresponden a $nummax NO Rotativas" | out-File -Append "$destination\backup_log.txt"
            " $WARNINGTAMADJ" | out-File -Append "$destination\backup_log.txt"
			"---------------------------------------------------------------" | out-File -Append "$destination\backup_log.txt"
			"Datos de Uso de la Unidad de Destino Backups" | out-File -Append "$destination\backup_log.txt"
			get-WmiObject win32_logicaldisk -Filter "DeviceID='$unidaddestino'" | out-File -Append "$destination\backup_log.txt"
			"---------------------------------------------------------------" | out-File -Append "$destination\backup_log.txt"
			"Datos de Uso de la Unidad de Destino Backups" | out-File -Append "$destination\backup_log.txt"
			get-WmiObject win32_logicaldisk -Filter "DeviceID='$unidadorigen'" | out-File -Append "$destination\backup_log.txt"
			"---------------------------------------------------------------" | out-File -Append "$destination\backup_log.txt"
			"Ficheros Copiados" | out-File -Append  "$destination\backup_log.txt"
			$backup_log = Dir -Recurse $destination | out-File -Append "$destination\backup_log.txt"
			"---------------------------------------------------------------" | out-File -Append "$destination\backup_log.txt"
			"Fin del Informe" | out-File -Append "$destination\backup_log.txt"
			$attachment = "$destination\backup_log.txt" 



            
			$body = "<font face=arial><h2>$WARNINGTAMBODY<br></h2> Resultado de la copia para: <b>$servername</b> <br>
                    Nombre del BACKUP: <b>BKP$pref$date</b><br>
                    La copia se inici&oacute;: <b>$datestart</b><br>
                    La copia Finaliz&oacute;:  <b>$dateend</b><br>
                    El sistema guarda un N&uacute;mero M&aacute;ximo de copias de: <b>$numcopiasdef</b>. Corresponden a <b>$nummax</b> NO Rotativas<br>
                    $TEXTTAMBODY<br><br>
                    Compruebe el Fichero Adjunto para mayor Detalle
                    
                    " 
			#Send an Email to User  
            send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Attachments $attachment -Body $body -BodyAsHtml 
            write-host "Backup Sucessfull"
            # Remove-PSDrive "Backup" -Force  
 }
 
 If ($numcopias -gt $nummax) {
 echo "NO HAGO COPIA: El numero de copias existentes es: $numcopias y el maximo permitido es $nummax "
 $dcopiavieja= @(Get-ChildItem -dir $dirdestino | ?{ $_.PSIsContainer } | Select-Object Name | Select-Object -First 1 | findstr BKP)
 $dcopiavieja = $dcopiavieja -replace(" ","")

 $copiavieja="$dcopiavieja\"
 echo "Eliminare la copia: $copiavieja"
 
 If ( $dcopiavieja = "" ) {
 echo "No puedo Borrar desde Raiz."
} else {
 echo "Eliminare la copia: $copiavieja"
 Remove-Item -Recurse -Force "$dirdestino\$copiavieja"   # Borrado Antiguo
} 

 Haz-copia
 
 } else {
    ## New-PSDrive -Name "Backup" -PSProvider Filesystem -Root $dirdestino
    $destination = "$dirdestino\BKP$pref$date" 
    ## $destination = "backup:\BKP$pref_$date" 
    $path = test-Path $destination 
 if ($path -eq $true) { 
    write-Host "Con Fecha $date ya hay una copia hecha. Debes Borrar o renombrar la existente" 
    ## Remove-PSDrive "Backup"   
	$subject = "Backup ERROR $servername $date"
	$body = "No se ha podido realizar el backups porque ya existe una copia de seguridad con este nombre: $destination" 
	#Send an Email to User  
    send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
            
  
 } elseif ($path -eq $false) { 
         echo "Empezando Copia $date"
		Haz-copia
			
 }
 }
