#+-------------------------------------------------------------------+   
#|              SCRIPT DE COPIAS MAIN INFORMATICA GANDIA SL          | 
#|              V1.4.4 copias@copias.connectate.com                  |
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
# Destino de copias Z:\BACKUPS
# Si los directorios y unidades son correctos NO hace falta tocar nada
# Este SCRIPT Mantendra un total de 3 copias. NO se permite VARIAS COPIAS por dia si NO se renombra el fichero del dia anterior 
# Borra la 4ª Rotacion mas antigua. Si no quieres que borre Comenta la linea donde se encuentre [Remove-Item -Recurse -Force]
 
 # Cambios de 1.4 > 1.4.1
 # Comprobamos que ejecutamos el ROL de Administrador sino salimos con error Y MAIL
 # Cambios de 1.4.1 > 1.4.2
 # Para comprobar si hay espacio disposible se hace con la variable warnspace. Este establece un limite de Uso el cual a
 # 	partir de ahí el sistema NO COPIA
 # Cambios de 1.4.2 > 1.4.3
 # Control de Errores. Realiza controles de Errores Indeterminados y sale con un MailLog
 # Cambios de 1.4.3 > 1.4.4
 # Control de Errores. Reparácion controles de Errores Indeterminados IO.EXCEPTION
 # Muestra en el BODY del Correo los VHD o VHDX copiados en Destino)
 
 
 
 
# Variables de Entorno
$servername="HV-EJEMPLO"							# Nombre HOST HyperV
$maquinas = ('MACHINE1','MACHINE2')	# Nombre de Maquinas a Copias
$nummax = "3"									# Numero de copias NO rotativas, es decir, una vez existan 7 a la 8 borrarÃ¡ la mas antigua
$unidaddestino="F:"								# Unidad Donde estan las Imagenes a copiar
$dirdestino="$unidaddestino\"		            # Directorio Completo donde alberga las copias
$date = Get-Date -Format yyyyMMdd 				# Fecha
$smtp = "copias.connectate.com" 				# Servidor SMTP para envio de correos
$from = "copias@copias.connectate.com <copias@copias.connectate.com>"		    # Desde que cuenta 
$to = "copias@copias.connectate.com <copias@copias.connectate.com>" 		    # A que cuenta
$pref="DIARIA"	 								# Prefijo de Copia (se puede usar para indicar la frecuencia de la copia)
$warnspace="120"                                # Nivel de Alarma en espacio Libre de Destino Medido en GB



### Funciones      
function tamanyo 
{ 
    param([string]$pth) 
    "{0:n2}" -f ((gci -path $pth -recurse | measure-object -property length -sum).sum /1gb ) 
}

# Tamaño origen
$SIZEVHD=0
ForEach ($expmaq in $maquinas ) { 
$VHD=@(Get-VM –VMName "$expmaq" | Select-Object VMId | Get-VHD).path
echo "Mirando $VHD"
ForEach ($MUCHOSVHD in $VHD ) { 
$SIZEVHD=$SIZEVHD + @(Get-VHD –Path $MUCHOSVHD).filesize
}
}
$TAMORIGEN=@($SIZEVHD / 1gb ) | % {$_.ToString("#.##")}
$TAMDESTINO=tamanyo $dirdestino
$FREEDESTINOC=get-WmiObject win32_logicaldisk -Filter "DeviceID='$unidaddestino'" | Format-Table DeviceId,@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}} | findstr ':  '
$FREEDESTINO="{0:N2}" -f ($FREEDESTINOC.split(":", 3) -replace(" ","") | Select-Object -Last 1)
$TEXTTAM="El tamaño de la copia será de $TAMORIGEN GB y queda $FREEDESTINO GB libre con un uso de Copias ACTUAL de $TAMDESTINO GB en Destino"
$TEXTTAMBODY="El tama&ntilde;o de la copia ser&aacute; de <b>$TAMORIGEN</b> GB y queda <b>$FREEDESTINO</b> GB libre con un uso de Copias ACTUAL de <b>$TAMDESTINO</b> GB en Destino"

$datestart=Get-Date -Format "dd-MM-yyyy HH:mm"
echo $TEXTTAM
$numcopiasdef=[convert]::ToInt32($nummax, 10)+1

### Buscamos ser Administrador #########################################################################################################

$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
$userid=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name

if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # Somos ADMIN :-)
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # No somos admin. Elevamos si UAC nos permite sin POPUP
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   $newProcess.Verb = "runas";
   
   # Iniciamos la Ventana de ADMIN
   [System.Diagnostics.Process]::Start($newProcess);
   
   }

# Conrfirmamos que sea así

if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # Somos ADMIN :-)
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # Continuamos sin ser admin.
   $subject = "Backup ERROR $servername $date"
   $body = "No se ha podido realizar el backups porque No Veo el Rol de ADMINISTRADOR para $userid" 
   send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
   exit 0
   }
 
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

## Control Errores Indeterminados NO detectados bajo condicional
try
{  
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
			"Ficheros Copiados" | out-File -Append  "$destination\backup_log.txt"
			$backup_log = Dir -Recurse $destination | out-File -Append "$destination\backup_log.txt"
			"---------------------------------------------------------------" | out-File -Append "$destination\backup_log.txt"
			"Fin del Informe" | out-File -Append "$destination\backup_log.txt"
			$attachment = "$destination\backup_log.txt" 

  		$BUSCAVHD = (Dir -Recurse $destination).FullName | Select-String -Pattern "VHD" 
            	$BUSCAVHD = $BUSCAVHD -replace "$unidaddestino","<br>"

            
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

## Fin cotrol Errores
 }
 }
catch [Exception] {
 write-host $_.Exception.GetType().FullName; 
 write-host $_.Exception.Message; 
 $subject = "Backup ERROR $servername $date"
 $body = "Ha habido alg&uacute;n Error NO controlado en el proceso del Script. <hr size=1> <br>Detalles del LOG Recuperado<br><br> $error[0].Exception" 
 #Send an Email to User  
 send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
 ### Throw ("Ooops! " + $error[0].Exception)

}
