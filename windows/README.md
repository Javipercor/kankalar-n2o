# N₂O para Windows · versión experimental

App de bandeja para Windows 11 x64. Mantiene la versión macOS independiente.

## Ejecutar

Descomprime `N2O-Windows-x64.zip` en una carpeta y ejecuta `N2O.exe`. Incluye el runtime de .NET; no requiere instalar un SDK. El icono de botella aparece junto al reloj, posiblemente dentro del menú de iconos ocultos. Cerrar el panel lo oculta; clic derecho en el icono → Salir termina la app. No se inicia automáticamente con Windows.

## Ajustar el límite

1. Abre Intel Graphics Software y busca **Shared GPU Memory Override**. La app incluye un acceso para abrir Intel si está registrado con ese nombre en Inicio.
2. Pulsa **Conectar con Intel**. N₂O solo habilita el slider si encuentra un único control visible y editable con ese nombre exacto, dentro del proceso IntelGraphicsSoftware, y un rango porcentual compatible.
3. Selecciona un porcentaje permitido. **57 %** es la referencia predeterminada documentada por Intel, no una recomendación optimizada para todos los equipos. La estimación en GiB se calcula a partir de la RAM física detectada.
4. Pulsa **Enviar selección a Intel**. N₂O cambia y vuelve a leer el valor del control, pero **no confirma que haya cambiado el límite activo del controlador**.
5. Revisa y confirma el ajuste dentro del software de Intel. Reinicia Windows para que tenga efecto.

Si Intel no expone el control a UI Automation con el nombre reconocido, el slider permanece deshabilitado. Usa el ajuste directamente en Intel. Esta integración es experimental y necesita validación en un equipo real, por ejemplo un Core Ultra 7 258V con Arc 140V y 32 GB. No se ha probado en ese hardware desde el Mac de desarrollo.

## Requisitos y límites

Intel documenta Core Ultra Series 2 o posterior, al menos 10 GB de RAM, Intel Graphics Software 25.26.1602.2 y controlador 32.0.101.6974 o posteriores. El porcentaje máximo depende de la RAM y del controlador. N₂O utiliza únicamente el rango expuesto por el control: no replica el preset de 30.720 MB del Mac ni escribe claves de registro no documentadas.

La detección muestra CPU, RAM y versiones de controladores; no equivale a certificar compatibilidad. La memoria libre, el presupuesto de memoria de una aplicación y el límite de GPU son conceptos distintos. El porcentaje mostrado es la selección del panel de Intel, no una lectura del límite del kernel.

## Compilar

Con SDK .NET 10, incluso desde macOS:

```sh
dotnet build windows/N2O.Windows.csproj -c Release
dotnet publish windows/N2O.Windows.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o build/windows-x64
```

El ejecutable local no lleva firma Authenticode. La compilación desde macOS verifica tipos y empaquetado; la interacción con Intel y la interfaz de bandeja requieren pruebas en Windows.

Referencias: [requisitos de Intel](https://www.intel.com/content/www/us/en/support/articles/000101789/graphics.html), [API pública IGCL](https://github.com/intel/drivers.gpu.control-library), [RangeValuePattern de Microsoft](https://learn.microsoft.com/en-us/dotnet/api/system.windows.automation.rangevaluepattern.setvalue).
