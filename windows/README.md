# N₂O for Windows · Experimental

A system tray app for Windows 11 x64. The macOS implementation remains independent.

## Run

Extract `N2O-Windows-x64.zip` to a folder and run `N2O.exe`. The .NET runtime is included; no SDK installation is needed. The bottle icon appears next to your clock, possibly inside the hidden-icons menu. Closing the panel hides it; right-click the icon → Quit exits the app. It does not start automatically with Windows.

## Adjust the limit

1. Open Intel Graphics Software and find **Shared GPU Memory Override**. N₂O includes a link to launch Intel if it is registered under that name in Start.
2. Click **Connect to Intel**. N₂O only enables its slider when it finds a single visible, editable control with a recognized exact name, inside the IntelGraphicsSoftware process, with a compatible percentage range.
3. Select an allowed percentage. **57%** is Intel’s documented default, not an optimized recommendation for every machine. The GiB estimate is calculated from detected physical RAM.
4. Click **Send selection to Intel**. N₂O changes and reads back the UI control’s value, but **does not verify that the active driver limit has changed**.
5. Review and confirm the setting in Intel’s software. Restart Windows for it to take effect.

If Intel does not expose the control through UI Automation under a recognized name, the slider stays disabled. Adjust the setting directly in Intel instead. This integration is experimental and needs validation on real hardware, such as a Core Ultra 7 258V with Arc 140V and 32 GB of RAM. It has not been tested on that hardware from the development Mac.

## Requirements and limitations

Intel documents Core Ultra Series 2 or later, at least 10 GB of RAM, Intel Graphics Software 25.26.1602.2, and graphics driver 32.0.101.6974 or later. The maximum percentage depends on RAM and the driver. N₂O only uses the range exposed by the control: it does not replicate the Mac’s 30,720 MB preset or write undocumented registry keys.

Hardware detection shows CPU, RAM, and driver versions; it does not certify compatibility. Free memory, an application’s memory budget, and the GPU limit are different concepts. The displayed percentage is Intel’s panel selection, not a reading of the kernel limit.

N₂O’s interface is in English. A Spanish control-name alias is retained internally to recognize an externally localized Intel panel.

## Build

With the .NET 10 SDK, including from macOS:

```sh
dotnet build windows/N2O.Windows.csproj -c Release
dotnet publish windows/N2O.Windows.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o build/windows-x64
```

To also create the portable ZIP, run `bash scripts/build-windows.sh` from the repository root. This requires Bash and Python 3.

The local executable has no Authenticode signature. Building from macOS checks types and packaging; interaction with Intel and the tray interface require testing on Windows.

References: [Intel requirements](https://www.intel.com/content/www/us/en/support/articles/000101789/graphics.html), [public IGCL API](https://github.com/intel/drivers.gpu.control-library), [Microsoft RangeValuePattern](https://learn.microsoft.com/en-us/dotnet/api/system.windows.automation.rangevaluepattern.setvalue).
