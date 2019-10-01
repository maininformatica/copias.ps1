# Variables de Entorno
$dirlocal="C:\COPIAS\"
$ficheroversion="c:\COPIAS\version.txt"
$outputfile="C:\output.txt"
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
$emailusername="copias@copias.connectate.com"
$emailpassword="XXXXXXX"
$emailserver="connectate.com"
