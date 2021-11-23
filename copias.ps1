#+-------------------------------------------------------------------+   
#|              SCRIPT DE COPIAS MAIN INFORMATICA GANDIA SL          | 
#|              V1.6.2  copias@copias.connectate.com                 |
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
# Version 1.5 Requiere Registro de Variables.
# Version 1.5.6 nummax automatico y eliminacion carpeta si error
# Version 1.5.7 Cambio Modo calculo. Prima Manual y envia modo de calculo en resultado
# Version 1.5.8 Cambio Textos para Tamaño total de disco Copias y Resumen enviado
# Version 1.6.1 Permite AUTH y SSL
# Version 1.6.1 Permite AUTH y NO SSL
$versionnueva="1.6.2"


# Variables de Entorno
try {
    . ("c:\COPIAS\variables.ps1")

}
catch {
    Write-Host "No se ha encontrado el fichero de Variables o es invalido" 
    # Continuamos sin ser admin.
   $subject = "Backup ERROR -- Variables NO Encontradas"
   $body = "No se ha podido realizar el backups porque No puedo leer el Fichero de Variables" 
   $smtptmp="copias.connectate.com"
   send-MailMessage -SmtpServer $emailserver -Credential $cred -From copias@copias.connectate.com -To copias@copias.connectate.com -Subject $subject -Body $body -BodyAsHtml 
   exit 0 
}

## Montamos las credenciales del EMAIL
$secpasswd = ConvertTo-SecureString $emailpassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($emailusername, $secpasswd)

## Versiones
$versionactual=[IO.File]::ReadAllText("$ficheroversion")
if ($versionnueva -gt $versionactual) {
echo "Version de Sistema: $versionactual. Version Actualizada $versionnueva"
Remove-Item  -Path $ficheroversion -Force
New-Item $ficheroversion -type file -force -value "$versionnueva"
$subject = "Backup INFO $servername $date"
$body = "Se ha actualizado el Script de Copias de $servername desde la version: $versionactual a la $versionnueva<br>
  DETALLE: Se Envian los correos mediante AUTH y SSL" 
#Send an Email to User  
send-MailMessage -SmtpServer $emailserver -Credential $cred -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
} 


## OUTPUT
$outputfile="C:\output.txt"
Remove-Item  -Path $outputfile -Force  # Borrado Antiguo LOG
$ErrorActionPreference="SilentlyContinue"
$erroritem="Exception"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $outputfile -append


### Funciones

function tamanyo 
{ 
    param([string]$pth) 
    "{0:n2}" -f ((gci -path $pth -recurse | measure-object -property length -sum).sum /1gb ) 
}

# Tamaño origen Para Mail
$SIZEVHD=0
## ForEach ($expmaq in $maquinas ) { 
## @(Get-VM –VMName "$expmaq" | Select-Object VMId | Get-VHD).path
## echo "Mirando $VHD"
## ForEach ($MUCHOSVHD in $VHD ) { 
## $SIZEVHD=$SIZEVHD + @(Get-VHD â€“Path $MUCHOSVHD).filesize
## }
## }

$TAMORIGEN=@($SIZEVHD / 1gb ) | % {$_.ToString("#.##")}
$TAMDESTINO=tamanyo $dirdestino
$FREEDESTINOC=get-WmiObject win32_logicaldisk -Filter "DeviceID='$unidaddestino'" | Format-Table DeviceId,@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}} | findstr ':  '
$FREEDESTINO="{0:N2}" -f ($FREEDESTINOC.split(":", 3) -replace(" ","") | Select-Object -Last 1)
$TAMTOTALDISCOC=get-WmiObject win32_logicaldisk -Filter "DeviceID='$unidaddestino'" | Format-Table DeviceId,@{n="Size";e={[math]::Round($_.Size/1GB,2)}} | findstr ':  '
$TAMTOTALDISCO="{0:N2}" -f ($TAMTOTALDISCOC.split(":", 3) -replace(" ","") | Select-Object -Last 1)


## $TEXTTAM="El tamaÃ±o de la copia serÃ¡ de $TAMORIGEN GB y queda $FREEDESTINO GB libre con un uso de Copias ACTUAL de $TAMDESTINO GB en Destino"
$TEXTTAM="Disco Copias ( $unidaddestino ): Tamaño: <b>$TAMTOTALDISCO</b> GB. Libre: <b>$FREEDESTINO</b> GB"
## $TEXTTAMBODY="El tama&ntilde;o de la copia ser&aacute; de <b>$TAMORIGEN</b> GB y queda <b>$FREEDESTINO</b> GB libre con un uso de Copias ACTUAL de <b>$TAMDESTINO</b> GB en Destino"
$TEXTTAMBODY="Disco Copias ( $unidaddestino ): Tama&ntilde;o: <b>$TAMTOTALDISCO</b> GB. Libre: <b>$FREEDESTINO</b> GB"


$datestart=Get-Date -Format "dd-MM-yyyy HH:mm"
echo $TEXTTAM
If ($nummax  -eq '0') {
$nummax=8 ## AUTOMATICOSCRIPT
$anterior="El Sistema de copias esta en modo Automatico. Calculo: $nummax"
} else {
$anterior="El Sistema de copias esta en modo Manual. Total Programado: $nummax"
}
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
   ## send-MailMessage -SmtpServer $emailserver -Credential $cred -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
   exit 0
   }
 
### Comprobaciones ##########################################################################################################
  

# Comprobamos que existe la unidad de DESTINO  
If (!(Test-Path "$unidaddestino"))
{
echo "No hay unidad Destino: $unidaddestino"
$subject = "Backup ERROR $servername $date"
$body = "No se ha podido realizar el backups porque La Unidad de Destino de Backups NO esta montada: $unidaddestino" 
send-MailMessage -SmtpServer $emailserver -Credential $cred -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
exit 0
}

# Comprobamos que existe el Directorio de DESTINO
If (!(Test-Path $dirdestino))
{
echo "No esta el directorio Destino: $dirdestino"
$subject = "Backup ERROR $servername $date"
	$body = "No se ha podido realizar el backups porque el directorio de Destino de las copias NO existe: $dirdestino" 
	#Send an Email to User  
    send-MailMessage -SmtpServer $emailserver -Credential $cred -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
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
            " $anterior " | out-File -Append "$destination\backup_log.txt"
	    " El sistema guarda un Número Máximo de $numcopiasdef Copias." | out-File -Append "$destination\backup_log.txt"
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
		    Version de SCRIPT: <b>$versionnueva</b><br>
                    Nombre del BACKUP: <b>BKP$pref$date</b><br>
                    La copia se inici&oacute;: <b>$datestart</b><br>
                    La copia Finaliz&oacute;:  <b>$dateend</b><br>
                    <b>$anterior</b><br>
		    El sistema guarda un N&uacute;mero M&aacute;ximo de <b>$numcopiasdef</b> Copias.<br>
                    $TEXTTAMBODY<br><br>
		    Listado de VHD Copiados<br>
		    $BUSCAVHD
		    <br><br>
                    Compruebe el Fichero Adjunto para mayor Detalle
                    
                    " 
		
		 If (Select-String $outputfile -pattern $erroritem -quiet) {

            # do some stuff
            Stop-Transcript
            $subject = "Backup ERROR $servername $date"
            $body = "Ha habido alg&uacute;n Error NO controlado en el proceso del Script. <hr size=1> <br>Detalles del LOG Recuperado<br><br> $error[0].Exception" 
            send-MailMessage -SmtpServer $emailserver -Credential $cred -From $from -To $to -Subject $subject -Attachments $outputfile  -Body $body -BodyAsHtml 
            exit 0

            } else {
		
		#Send an Email to User  
            send-MailMessage -SmtpServer $emailserver -Credential $cred -From $from -To $to -Subject $subject -Attachments $attachment -Body $body -BodyAsHtml 
            write-host "Backup Sucessfull"
            # Remove-PSDrive "Backup" -Force  
	    
	    }
	    
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
    send-MailMessage -SmtpServer $emailserver -Credential $cred -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
   
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
 $body = "$anterior ------------> Ha habido alg&uacute;n Error NO controlado en el proceso del Script. <hr size=1> <br>Detalles del LOG Recuperado<br><br> $error[0].Exception" 
 #Send an Email to User  
 send-MailMessage -SmtpServer $emailserver -Credential $cred -From $from -To $to -Subject $subject -Body $body -BodyAsHtml 
 ### Throw ("Ooops! " + $error[0].Exception)
  Remove-Item -Recurse -Force "$dirdestino\BKP$pref$date"
}
