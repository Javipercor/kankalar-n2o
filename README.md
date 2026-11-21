<div align="center">

<img src="docs/assets/n2o-icon.png" width="144" alt="N₂O: botella de óxido nitroso en turquesa" />

# N₂O

### Tu memoria GPU. Un slider. El punto dulce.

Una pequeña utilidad que vive junto al reloj y acerca los ajustes de memoria de la GPU a un clic.

**SwiftUI en macOS · Bandeja del sistema en Windows · Sin servicios en segundo plano**

[Empezar en macOS](#macos) · [Probar en Windows](#windows-experimental) · [Compilar](#compilar-desde-el-código) · [Preguntas frecuentes](#preguntas-frecuentes)

</div>

---

## De la terminal a la barra superior

N₂O nació para poner este comando detrás de un slider:

```sh
sudo sysctl iogpu.wired_limit_mb=30720
```

Abres la botella de la barra superior, eliges el límite y lo aplicas. El preset de **30.720 MB** queda a mano para volver al ajuste que motivó la app.

El nombre pone el nitro; el sistema operativo pone las reglas. N₂O ajusta el límite de memoria de la GPU. El resultado depende del equipo, del modelo o aplicación que ejecutes y del resto de la memoria en uso.

## Lo que te llevas

- **Siempre a mano.** Icono de botella en la barra superior de macOS o en la bandeja de Windows.
- **Un control directo.** Slider y acceso al preset, sin escribir comandos cada vez.
- **Estado visible.** En Mac, lectura del valor actual y comprobación después de aplicar.
- **Aspecto nativo.** Panel de Mac adaptado al modo claro y oscuro, sin ocupar espacio en el Dock.
- **Dos implementaciones.** macOS cambia el ajuste del kernel; Windows conecta de forma experimental con el panel de Intel.

## macOS

### Abrir y ajustar

Si ya tienes `N2O.app`, arrástrala a **Aplicaciones** y ábrela. Verás una pequeña **botella monocroma** en la barra superior.

1. Pulsa la botella para abrir el panel.
2. Mueve el slider en pasos de **256 MB**, o selecciona **30.720 MB**.
3. Pulsa **Aplicar límite** y autoriza el cambio en el diálogo de macOS.
4. N₂O vuelve a leer el ajuste para comprobar el resultado.

**Valor del sistema** selecciona `0`. Pulsa **Aplicar límite** para restaurarlo.

### El punto dulce

El preset de **30.720 MB** corresponde al ajuste elegido para el Mac original de **36 GB de RAM**. Es un acceso rápido a esa configuración, no una recomendación universal.

El slider limita el máximo para dejar al menos **4 GiB fuera del límite configurado**. Eso no reserva memoria para otras apps ni garantiza RAM libre. Si el preset supera el máximo permitido en tu equipo, su botón queda desactivado.

### Qué ocurre al cerrar o reiniciar

- Cerrar el panel deja la app en la barra. **Salir de N₂O** la cierra por completo.
- La última selección aplicada se recuerda entre aperturas.
- Abrir la app no aplica el ajuste automáticamente.
- El cambio del kernel se pierde al reiniciar el Mac.

La interfaz requiere **macOS 14 o posterior**; el equipo también debe exponer `iogpu.wired_limit_mb`. Si no puede leer esa clave, N₂O muestra el error y desactiva la aplicación del cambio.

## Windows · Experimental

La versión de Windows está pensada para explorar el ajuste de memoria compartida de las GPU integradas Intel, por ejemplo en un portátil con **Core Ultra 7 258V, Arc 140V y 32 GB de RAM**.

> **Estado real:** compilación y empaquetado verificados desde macOS. La bandeja y la conexión con Intel aún necesitan validación en un equipo Windows compatible.

### Probarla

1. Descomprime `N2O-Windows-x64.zip` y ejecuta `N2O.exe`. Incluye .NET.
2. Abre **Intel Graphics Software** y entra en **Shared GPU Memory Override**.
3. En N₂O, pulsa **Conectar con Intel**.
4. Si detecta un único slider compatible, selecciona el porcentaje y pulsa **Enviar selección a Intel**.
5. Revisa y confirma el ajuste en Intel. **Reinicia Windows** para que tenga efecto.

El icono puede estar dentro del menú de iconos ocultos junto al reloj. Cerrar la ventana oculta el panel; clic derecho sobre el icono → **Salir** termina la app.

### Qué significa «experimental»

N₂O utiliza la accesibilidad de Windows para localizar el slider de Intel. Si el control no tiene un nombre reconocido, no es editable o resulta ambiguo, lo deja deshabilitado. Puedes realizar el ajuste directamente en Intel Graphics Software.

**Enviar selección a Intel verifica el valor del control de su interfaz; no verifica el límite activo del controlador.** El preset del Mac no se traslada a Windows. El botón **57 %** representa el valor predeterminado documentado por Intel, no un ajuste optimizado para todos los portátiles.

Consulta los [requisitos, límites y detalles de Windows](windows/README.md).

## Compilar desde el código

### Mac · Xcode o Command Line Tools

```sh
bash scripts/build.sh
open build/N2O.app
```

Resultado: `build/N2O.app`, con su icono y firma ad hoc local.

### Windows x64 · SDK .NET 10

Desde macOS o un entorno con Bash, Python 3 y .NET 10:

```sh
bash scripts/build-windows.sh
```

Resultados:

- `build/windows-x64/N2O.exe`: ejecutable con runtime incluido.
- `build/N2O-Windows-x64.zip`: paquete portable con instrucciones.

Para compilar directamente desde Windows con .NET:

```powershell
dotnet publish windows/N2O.Windows.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o build/windows-x64
```

El ejecutable Windows local no lleva firma Authenticode. Los artefactos de `build/` se generan localmente y no se incluyen en el repositorio.

## Por dentro

```text
Sources/N2O.swift            App macOS: panel, barra y acceso a sysctl
windows/Program.cs          App Windows: bandeja, hardware y conexión con Intel
windows/Assets/AppIcon.ico  Icono de Windows
scripts/make-icon.swift     Generador del icono de botella
scripts/build.sh            Compilación y empaquetado de macOS
scripts/build-windows.sh    Publicación de Windows y ZIP portable
```

En Mac, el único comando con privilegios es `/usr/sbin/sysctl -w iogpu.wired_limit_mb=N`, con un entero validado. macOS gestiona la autorización; N₂O no guarda contraseñas ni instala un servicio privilegiado.

En Windows, la app consulta el hardware y conecta con el control visible de Intel. No escribe claves de registro no documentadas ni instala un controlador propio.

## Preguntas frecuentes

**¿Esto convierte RAM en VRAM dedicada?**  
Ajusta un límite de uso de memoria. No añade memoria física ni cambia la arquitectura del equipo.

**¿Más memoria significa más velocidad?**  
No necesariamente. El objetivo es permitir un límite adecuado para tu carga; el rendimiento también depende de la GPU, del software y de la presión de memoria del sistema.

**¿Por qué Windows requiere Intel abierto?**  
Esta versión conecta con su interfaz. No implementa un equivalente de `sysctl` ni dispone de una integración directa verificada con el controlador.

**¿Se inicia al encender el equipo?**  
La app no configura el inicio automático ni aplica presets al arrancar.

**¿Cómo vuelvo atrás en Mac?**  
Selecciona **Valor del sistema** y pulsa **Aplicar límite**. También se restablece al reiniciar.

## Referencias

- [MLX: límite wired y ajuste del sistema en macOS](https://ml-explore.github.io/mlx/build/html/python/_autosummary/mlx.core.set_wired_limit.html).
- [Intel: Shared GPU Memory Override y requisitos](https://www.intel.com/content/www/us/en/support/articles/000101789/graphics.html).
- [Intel Graphics Control Library](https://github.com/intel/drivers.gpu.control-library).
- [Microsoft: RangeValuePattern.SetValue](https://learn.microsoft.com/en-us/dotnet/api/system.windows.automation.rangevaluepattern.setvalue).

---

<div align="center">

**N₂O — encuentra tu punto dulce.**

</div>
