# ==============================================================================
# ASISTENTE INTERACTIVO DE RESPALDO UNIVERSAL - v2.0 (Branch Feature)
# Desarrollado por: MCortinez-dev (https://github.com/MCortinez-dev)
# ==============================================================================

$paso = 1
$salir = $false

$rutaRaiz = ""
$listaExcluidas = @()
$destinoFinal = ""
$esRsync = $false

function Mostrar-Footer {
    Write-Host "----------------------------------------------------------"
    Write-Host " Desarrollado por: MCortinez-dev | GitHub: https://github.com/MCortinez-dev" -ForegroundColor DarkGray
    Write-Host "==========================================================" -ForegroundColor Green
}

while (-not $salir) {
    switch ($paso) {
        
        # ----------------------------------------------------------------------
        # PASO 1: SELECCION DE ORIGEN
        # ----------------------------------------------------------------------
        1 {
            Clear-Host
            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host "   PASO 1: SELECCION DE ORIGEN                            " -ForegroundColor Green
            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host " [X] Salir" -ForegroundColor Red
            Write-Host "----------------------------------------------------------"
            Write-Host ""

            $discos = Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.DriveType -eq "Fixed" }
            $i = 1
            foreach ($disco in $discos) {
                $tamanoGB = [Math]::Round($disco.Size / 1GB, 1)
                $libreGB  = [Math]::Round($disco.SizeRemaining / 1GB, 1)
                Write-Host " $i = Unidad $($disco.DriveLetter): [Etiqueta: $($disco.FileSystemLabel)] | Total: $tamanoGB GB | Libre: $libreGB GB" -ForegroundColor Cyan
                $i++
            }
            Write-Host ""
            
            Mostrar-Footer
            $seleccion = Read-Host "Selecciona el numero de origen o 'X' para salir"
            
            if ($seleccion -eq "x") { $salir = $true }
            elseif ($seleccion -match "^\d+$" -and [int]$seleccion -ge 1 -and [int]$seleccion -lt $i) {
                $rutaRaiz = $discos[[int]$seleccion - 1].DriveLetter + ":\"
                $paso = 2
            } else {
                Write-Host "`nOpcion invalida. Reintenta." -ForegroundColor Red; Start-Sleep -Seconds 1
            }
        }

        # ----------------------------------------------------------------------
        # PASO 2: EXCLUSIONES DEL ORIGEN
        # ----------------------------------------------------------------------
        2 {
            $carpetas = Get-ChildItem -Path $rutaRaiz | Where-Object { $_.PSIsContainer }
            
            while ($true) {
                Clear-Host
                Write-Host "==========================================================" -ForegroundColor Green
                Write-Host "   PASO 2: SELECCION DE EXCLUSIONES (ORIGEN)              " -ForegroundColor Green
                Write-Host "==========================================================" -ForegroundColor Green
                Write-Host " [B] Volver al Paso Anterior  //  [X] Salir" -ForegroundColor Red
                Write-Host "----------------------------------------------------------"
                Write-Host "Origen seleccionado: $rutaRaiz" -ForegroundColor Gray
                Write-Host ""
                
                $j = 1
                foreach ($carpeta in $carpetas) {
                    Write-Host " $j = $($carpeta.Name)" -ForegroundColor Cyan
                    $j++
                }
                Write-Host ""
                if ($listaExcluidas.Count -gt 0) {
                    Write-Host "Exclusiones actuales: [ $($listaExcluidas -join ', ') ]" -ForegroundColor Yellow
                    Write-Host ""
                }

                Mostrar-Footer
                $selCarpeta = Read-Host "Numero de carpeta del ORIGEN a excluir (O Enter para continuar)"
                
                if ($selCarpeta -eq "b") { $paso = 1; break }
                if ($selCarpeta -eq "x") { $salir = $true; break }
                if ($selCarpeta -eq "") { $paso = 3; break }

                if ($selCarpeta -match "^\d+$" -and [int]$selCarpeta -ge 1 -and [int]$selCarpeta -lt $j) {
                    $carpetaExcluida = $carpetas[[int]$selCarpeta - 1].Name
                    if ($listaExcluidas -notcontains $carpetaExcluida) { $listaExcluidas += $carpetaExcluida }
                }
            }
        }

        # ----------------------------------------------------------------------
        # PASO 3: TIPO DE DESTINO Y ESCANEO DE HUERFANOS (Soporte SSH/Rsync)
        # ----------------------------------------------------------------------
        3 {
            Clear-Host
            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host "   PASO 3: CONFIGURAR DESTINO Y AGREGAR HUERFANOS        " -ForegroundColor Green
            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host " [B] Volver al Paso Anterior  //  [X] Salir" -ForegroundColor Red
            Write-Host "----------------------------------------------------------"
            Write-Host ""
            Write-Host " 1 = Unidad Local / Externa (Otro disco, USB)" -ForegroundColor Cyan
            Write-Host " 2 = Red Local SMB (Carpeta compartida)" -ForegroundColor Cyan
            Write-Host " 3 = Tunel VPN / Tailscale / SSH Remoto (Rsync)" -ForegroundColor Cyan
            Write-Host ""

            Mostrar-Footer
            $tipoDestino = Read-Host "Selecciona el tipo de destino (1-3)"

            if ($tipoDestino -eq "b") { $paso = 2; continue }
            if ($tipoDestino -eq "x") { $salir = $true; continue }

            $esRsync = $false
            switch ($tipoDestino) {
                "1" { 
                    $destinoFinal = Read-Host "`nIngresa la ruta de destino local (Ej: E:\)"
                    $accesible = Test-Path -Path $destinoFinal -ErrorAction SilentlyContinue
                }
                "2" { 
                    $destinoFinal = Read-Host "`nIngresa la ruta UNC de red (Ej: \\192.168.0.109\Particion)"
                    $accesible = Test-Path -Path $destinoFinal -ErrorAction SilentlyContinue
                }
                "3" { 
                    $destinoFinal = Read-Host "`nIngresa el destino SSH/Rsync (Ej: user@servidor:/media/Matias)"
                    $esRsync = $true
                    if ($destinoFinal -match "^([^@]+)@([^:]+):(.+)$") {
                        $sshUser = $Matches[1]
                        $sshHost = $Matches[2]
                        $sshPath = $Matches[3]
                        $accesible = $true 
                    } else {
                        $accesible = $false
                    }
                }
                Default { continue }
            }

            if ($accesible) {
                while ($true) {
                    Clear-Host
                    Write-Host "==========================================================" -ForegroundColor Green
                    Write-Host "   PASO 3.1: DETECCION DE CARPETAS EXCLUSIVAS DEL DESTINO" -ForegroundColor Green
                    Write-Host "==========================================================" -ForegroundColor Green
                    Write-Host "Analizando carpetas en el destino..." -ForegroundColor Gray
                    Write-Host "Las siguientes carpetas SOLO existen en el destino y se BORRARAN si no las excluis:" -ForegroundColor Red
                    Write-Host ""

                    $huefanas = @()

                    if ($esRsync) {
                        # Forzar a PowerShell a interpretar caracteres especiales de Linux en UTF-8
                        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
                        Write-Host "Conectando al servidor remoto para escanear directorios..." -ForegroundColor Yellow
                        $carpetasDestino = ssh -o StrictHostKeyChecking=no "$sshUser@$sshHost" "find '$sshPath' -maxdepth 1 -type d -printf '%f\n'" 2>$null
                        
                        if ($null -eq $carpetasDestino -or $carpetasDestino.Count -eq 0) {
                            Write-Host "`n[!] No se pudo obtener respuesta del servidor o el directorio remoto esta vacio/inexistente." -ForegroundColor Yellow
                            $null = Read-Host "Presiona Enter para continuar al Paso 4 sin exclusiones de destino"
                            $paso = 4
                            break
                        }

                        foreach ($folder in $carpetasDestino) {
                            if ($folder -eq "" -or $folder -eq "." -or $folder -match "^\.") { continue }
                            
                            $matchOrigen = Join-Path $rutaRaiz $folder
                            if (-not (Test-Path -Path $matchOrigen) -and ($listaExcluidas -notcontains $folder)) {
                                $huefanas += $folder
                            }
                        }
                    } else {
                        $carpetasDestino = Get-ChildItem -Path $destinoFinal -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }
                        foreach ($cd in $carpetasDestino) {
                            $nombreLower = $cd.Name.ToLower()
                            if ($nombreLower.StartsWith(".") -or $nombreLower.StartsWith("$") -or $nombreLower -eq "system volume information" -or $nombreLower -eq "desktop.ini") { continue }
                            $matchOrigen = Join-Path $rutaRaiz $cd.Name
                            if (-not (Test-Path -Path $matchOrigen) -and ($listaExcluidas -notcontains $cd.Name)) {
                                $huefanas += $cd.Name
                            }
                        }
                    }

                    if ($huefanas.Count -eq 0) {
                        Write-Host " [ No se encontraron mas carpetas exclusivas desprotegidas en el destino ]" -ForegroundColor Green
                        Write-Host ""
                    } else {
                        $k = 1
                        foreach ($h in $huefanas) {
                            Write-Host " $k = Excluir y proteger del espejo: $h" -ForegroundColor Yellow
                            $k++
                        }
                        Write-Host ""
                    }

                    if ($listaExcluidas.Count -gt 0) {
                        Write-Host "Lista total de exclusiones actual: [ $($listaExcluidas -join ', ') ]" -ForegroundColor Cyan
                        Write-Host ""
                    }

                    Mostrar-Footer
                    $selHuefana = Read-Host "Selecciona el numero para protegerla (O Enter para continuar al Paso 4)"

                    if ($selHuefana -eq "") { $paso = 4; break }
                    if ($selHuefana -eq "b") { break }
                    if ($selHuefana -eq "x") { $salir = $true; break }
                    
                    if ($selHuefana -match "^\d+$" -and [int]$selHuefana -ge 1 -and [int]$selHuefana -lt $k) {
                        $listaExcluidas += $huefanas[[int]$selHuefana - 1]
                    }
                }
            } else {
                Write-Host "`nERROR: El destino no es accesible o la ruta es invalida." -ForegroundColor Red
                $null = Read-Host "Presiona Enter para intentar de nuevo"
            }
        }

        # ----------------------------------------------------------------------
        # PASO 4: VISTA PREVIA Y EJECUCION
        # ----------------------------------------------------------------------
        4 {
            if ($esRsync) {
                $exclusionesRsync = ""
                foreach ($exc in $listaExcluidas) { $exclusionesRsync += " --exclude='$exc'" }
                $comandoFinal = 'rsync -avzP --delete{0} "{1}" "{2}"' -f $exclusionesRsync, $rutaRaiz, $destinoFinal
                $motor = "Rsync (via SSH/Tailscale con --delete)"
            } else {
                $exclusionesRobo = ""
                if ($listaExcluidas.Count -gt 0) { 
                    $listaQuoted = $listaExcluidas | ForEach-Object { "`"$_`"" }
                    $exclusionesRobo = " /XD " + ($listaQuoted -join " ")
                }
                $comandoFinal = "robocopy `"$rutaRaiz`" `"$destinoFinal`" /MIR /R:3 /W:5$exclusionesRobo"
                $motor = "Robocopy (Nativo de Windows con /MIR)"
            }

            Clear-Host
            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host "   PASO 4: VISTA PREVIA Y EJECUCION (v2.0)" -ForegroundColor Green
            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host " [B] Volver al Paso Anterior  //  [X] Salir" -ForegroundColor Red
            Write-Host "----------------------------------------------------------"
            Write-Host " Origen:    $rutaRaiz" -ForegroundColor Cyan
            Write-Host " Destino:   $destinoFinal" -ForegroundColor Cyan
            Write-Host " Motor:     $motor" -ForegroundColor Gray
            if ($listaExcluidas.Count -gt 0) {
                Write-Host " Excluidos: [ $($listaExcluidas -join ', ') ]" -ForegroundColor Yellow
            }
            Write-Host "----------------------------------------------------------"
            Write-Host "COMANDO CONFIGURADO:" -ForegroundColor Yellow
            Write-Host $comandoFinal -ForegroundColor Magenta
            Write-Host "----------------------------------------------------------"
            Write-Host " AVISO: Configurado en modo ESPEJO estricto." -ForegroundColor Red
            Write-Host " Las carpetas del destino que no fueron excluidas seran borradas." -ForegroundColor Red
            Write-Host "----------------------------------------------------------"
            Write-Host ""
            Write-Host " 1 = Ejecutar la copia de seguridad ahora mismo" -ForegroundColor Cyan
            Write-Host " 2 = Salir y copiar el comando manualmente" -ForegroundColor Cyan
            Write-Host ""
            
            Mostrar-Footer
            $ejecutar = Read-Host "Selecciona una opcion"

            if ($ejecutar -eq "b") { $paso = 3; continue }
            if ($ejecutar -eq "x" -or $ejecutar -eq "2") { $salir = $true; continue }

            if ($ejecutar -eq "1") {
                Write-Host "`n[!] Ejecutando proceso. Monitorea el progreso abajo...`n" -ForegroundColor Yellow
                Invoke-Expression $comandoFinal
                Write-Host "`n==========================================================" -ForegroundColor Green
                Write-Host "   PROCESO FINALIZADO CON EXITO" -ForegroundColor Green
                Write-Host "==========================================================" -ForegroundColor Green
                Mostrar-Footer
                $null = Read-Host "Presiona Enter para cerrar el asistente"
                $salir = $true
            }
        }
    }
}

Clear-Host
Write-Host "Asistente finalizado. Desarrollado por MCortinez-dev." -ForegroundColor Gray