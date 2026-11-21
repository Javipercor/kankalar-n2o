# N₂O

También hay una [versión experimental para Windows](windows/README.md), con icono de bandeja y conexión al control de memoria de Intel Graphics Software. Su integración y requisitos son distintos de los de macOS.

App nativa de macOS con SwiftUI para ajustar `iogpu.wired_limit_mb`.

## Uso

Ejecuta `bash scripts/build.sh` y abre `build/N2O.app`. Puedes arrastrarla a Aplicaciones.

La app aparece con un **icono de botella** en la barra superior de macOS. Pulsa ese elemento para abrir el panel. El icono es monocromo y el panel se adapta al aspecto claro u oscuro del sistema. Permanece en la barra al cerrar el panel y no ocupa espacio en el Dock. Usa **Salir de N₂O** en el panel para cerrarla por completo.

1. Mueve el slider en pasos de 256 MB o pulsa **30.720 MB** para seleccionar el punto dulce.
2. Pulsa **Aplicar límite** y autoriza con el diálogo de administrador de macOS.
3. La app vuelve a consultar sysctl para verificar el cambio.

**Valor del sistema** selecciona 0; pulsa Aplicar para restaurarlo. La selección aplicada se recuerda entre aperturas, pero no se aplica automáticamente. El ajuste del kernel se pierde al reiniciar.

El slider deja al menos 4 GiB fuera del límite para macOS y otras apps. Esto limita la configuración: no garantiza memoria libre. Si el Mac tiene menos memoria, el preset se desactiva.

No almacena contraseñas ni instala servicios. El único comando con privilegios es `/usr/sbin/sysctl -w iogpu.wired_limit_mb=N`, con un entero validado. Si la clave no está disponible, la app muestra el error y desactiva Aplicar.

Requiere macOS 14+ para la interfaz y un sistema que exponga la clave de GPU. Compilar requiere Xcode o Command Line Tools. La compilación local usa firma ad hoc.

Referencia: [documentación de MLX sobre el límite wired](https://ml-explore.github.io/mlx/build/html/python/_autosummary/mlx.core.set_wired_limit.html).
