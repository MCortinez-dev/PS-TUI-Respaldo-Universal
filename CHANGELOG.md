\# Changelog



Todos los cambios notables en este proyecto serán documentados en este archivo.



\## \[2.0.0] - 2026-07-19

\### Added

\- Soporte para copias de seguridad remotas mediante el motor \*\*Rsync\*\* sobre túneles SSH/Tailscale.

\- Detección interactiva de carpetas huérfanas en el destino antes de ejecutar el espejo remoto.

\- Codificación forzada a UTF-8 para corregir la lectura de caracteres especiales y tildes provenientes de servidores Linux.



\### Fixed

\- Error de bloqueo de consola provocado por el parámetro `BatchMode` en entornos sin llaves SSH preconfiguradas.

\- Error de sintaxis en el cierre de bloques lógicos del script que rompía la transición al Paso 4.



\### Changed

\- El comando generado ahora encapsula correctamente las rutas y exclusiones complejas con espacios entre comillas dobles.



\---



\## \[1.0.0] - 2025-05-15

\- Versión inicial del asistente interactivo con soporte local y SMB mediante Robocopy `/MIR`.

