#+-------------------------------------------------------------------+   
#|      SCRIPT DE WINDOWS UPDATE  - MAIN INFORMATICA GANDIA SL       | 
#|              V1.1 jtormo@main-informatica.com                     |
#|                                                                   |
#|                                                                   |
#|   ATENCION: El sistema debe permitir ejecucion de scripts         |
#|             Ejecuta como administrador POWER SHELL ISE            |
#|             Ejecuta el comando: Set-ExecutionPolicy Unrestricted  |
#|                                                                   |
#+-------------------------------------------------------------------+ 
 
 
# Aspectos a tener en cuenta
# Descargar el MÃ³dulo de Windows Update para POWERSHELL
# https://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc
# Instrucciones de InstalaciÃ³n: https://blogs.technet.microsoft.com/heyscriptingguy/2012/11/08/use-a-powershell-module-to-run-windows-update/
#
# BÃ¡sicamente se descomprime y
# Set-ExecutionPolicy Unrestricted
# cd .\PSWindowsUpdate\
# Import-Module .\PSWindowsUpdate.psd1
# Se Comprueba:
# gcm -Module pswindows*
# 
# CommandType     Name                                               Version    Source
# -----------     ----                                               -------    ------
# Function        Add-WUOfflineSync                                  1.5.1.11   PSWindowsUpdate
# Function        Add-WUServiceManager                               1.5.1.11   PSWindowsUpdate
# Function        Get-WUHistory                                      1.5.1.11   PSWindowsUpdate
# Function        Get-WUInstall                                      1.5.1.11   PSWindowsUpdate
# Function        Get-WUInstallerStatus                              1.5.1.11   PSWindowsUpdate
# Function        Get-WUList                                         1.5.1.11   PSWindowsUpdate
# Function        Get-WURebootStatus                                 1.5.1.11   PSWindowsUpdate
# Function        Get-WUServiceManager                               1.5.1.11   PSWindowsUpdate
# Function        Get-WUUninstall                                    1.5.1.11   PSWindowsUpdate
# Function        Hide-WUUpdate                                      1.5.1.11   PSWindowsUpdate
# Function        Invoke-WUInstall                                   1.5.1.11   PSWindowsUpdate
# Function        Remove-WUOfflineSync                               1.5.1.11   PSWindowsUpdate
# Function        Remove-WUServiceManager                            1.5.1.11   PSWindowsUpdate
# Function        Update-WUModule                                    1.5.1.11   PSWindowsUpdate
#
#
#



# Variables de Entorno
$servername="MAIN-HV01"							# Nombre HOST HyperV
$date = Get-Date -Format yyyyMMdd					# Fecha
$smtp = "188.93.78.29"							# Servidor SMTP para envio de correos
$from = "backups@main-informatica.com <backups@main-informatica.com>"	# Desde que cuenta 
$to = "dominios@main-informatica.com <jtormo@main-informatica.com>"	# A que cuenta
$subject = "$servername - Resultado de Actualizacion Windows"


# Tratamos de Asegurarnos que somos admin
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
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
   exit
   }
 

# Ejcutamos los comandos

Write-Host -NoNewLine "Iniciamos instalador de UPDATE"


"Resumen de Actualizaciones Windows para $servername en $date" | out-File "c:\update_log.txt"

"Listado de Pendientes a Instalar" | out-File -Append "c:\update_log.txt"
Get-WUlist  | out-File -Append "c:\update_log.txt"
"---------------------------------------------------------------" | out-File -Append "c:\update_log.txt"

"Resultado de la INstalaci󮢠| out-File -Append "c:\update_log.txt"
Get-WUInstall Software -IgnoreRebootRequired -WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$true | out-File -Append "c:\update_log.txt"
"---------------------------------------------------------------" | out-File -Append "c:\update_log.txt"
"Fin del Informe" | out-File -Append "c:\update_log.txt"

$TEXTTAMBODY="En EL Adjunto se puede ver el resultado del UPDATE"

# Enviamos El Correo

$body = "<font face=arial>Resultado de la INstalacion de Windows UPDATE para: <b>$servername</b> <br>
                    Fecha: <b>$date</b><br>
                    $TEXTTAMBODY<br><br>
                    " 


$attachment = "c:\update_log.txt" 
# Send an Email to User  
send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Attachments $attachment -Body $body -BodyAsHtml 
