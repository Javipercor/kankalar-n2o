using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Automation;
using System.Windows.Forms;
using UICondition = System.Windows.Automation.Condition;

namespace N2O;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        using var mutex = new Mutex(true, @"Local\N2O.Windows", out bool first);
        if (!first) return;
        ApplicationConfiguration.Initialize();
        Application.Run(new TrayApp());
    }
}

internal sealed class TrayApp : ApplicationContext
{
    readonly NotifyIcon tray;
    readonly MainForm panel = new();
    public TrayApp()
    {
        using var stream = typeof(Program).Assembly.GetManifestResourceStream("N2O.Windows.Assets.AppIcon.ico")
            ?? typeof(Program).Assembly.GetManifestResourceNames().Where(n => n.EndsWith("AppIcon.ico"))
                .Select(n => typeof(Program).Assembly.GetManifestResourceStream(n)).First()!;
        var icon = new Icon(stream);
        panel.Icon = icon;
        var menu = new ContextMenuStrip();
        menu.Items.Add("Abrir N₂O", null, (_, _) => Open());
        menu.Items.Add("Salir", null, (_, _) => ExitThread());
        tray = new NotifyIcon { Icon = icon, Text = "N₂O · Memoria GPU Intel", Visible = true, ContextMenuStrip = menu };
        tray.MouseClick += (_, e) => { if (e.Button == MouseButtons.Left) Open(); };
        Open();
    }
    void Open() { panel.Show(); panel.WindowState = FormWindowState.Normal; panel.Activate(); }
    protected override void ExitThreadCore() { tray.Visible = false; tray.Dispose(); panel.Dispose(); base.ExitThreadCore(); }
}

internal sealed class MainForm : Form
{
    readonly Label hardware = new() { AutoSize = true, MaximumSize = new Size(450, 0), Text = "Consultando hardware…" };
    readonly Label value = new() { AutoSize = true, Font = new Font("Segoe UI", 26, FontStyle.Bold), Text = "Sin conectar" };
    readonly Label status = new() { AutoSize = true, MaximumSize = new Size(450, 0), Text = "Abre Intel Graphics Software y entra en Shared GPU Memory Override. Después pulsa Conectar." };
    readonly TrackBar slider = new() { Minimum = 0, Maximum = 100, TickFrequency = 10, Width = 440, Enabled = false, AccessibleName = "Porcentaje de memoria compartida GPU" };
    readonly Button send = new() { Text = "Enviar selección a Intel", AutoSize = true, Enabled = false };
    readonly Button connect = new() { Text = "Conectar con Intel", AutoSize = true };
    readonly Button balanced = new() { Text = "57 % · Referencia Intel", AutoSize = true, Enabled = false };
    IntelControl? control;
    double ramGB;

    public MainForm()
    {
        Text = "N₂O · Memoria GPU Intel";
        ClientSize = new Size(510, 610);
        AutoScaleMode = AutoScaleMode.Dpi;
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        var layout = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoScroll = true, Padding = new Padding(26) };
        layout.Controls.Add(new Label { Text = "N₂O", Font = new Font("Segoe UI", 24, FontStyle.Bold), AutoSize = true });
        layout.Controls.Add(hardware);
        layout.Controls.Add(new Label { Text = "MEMORIA COMPARTIDA · CONEXIÓN EXPERIMENTAL", AutoSize = true, Margin = new Padding(0, 22, 0, 8) });
        layout.Controls.Add(value);
        layout.Controls.Add(slider);
        layout.Controls.Add(balanced);
        layout.Controls.Add(connect);
        layout.Controls.Add(send);
        layout.Controls.Add(status);
        var help = new LinkLabel { Text = "Abrir Intel Graphics Software", AutoSize = true, Margin = new Padding(0, 15, 0, 8) };
        help.LinkClicked += async (_, _) => await LaunchIntel();
        layout.Controls.Add(help);
        var docs = new LinkLabel { Text = "Requisitos y ayuda oficial de Intel", AutoSize = true };
        docs.LinkClicked += (_, _) => Process.Start(new ProcessStartInfo("https://www.intel.com/content/www/us/en/support/articles/000101789/graphics.html") { UseShellExecute = true });
        layout.Controls.Add(docs);
        layout.Controls.Add(new Label { Text = "Enviar cambia la selección del panel de Intel. Revisa y confirma allí el ajuste y reinicia Windows. N₂O no confirma que el límite del controlador haya cambiado.", AutoSize = true, MaximumSize = new Size(450, 0), Margin = new Padding(0, 16, 0, 8) });
        Controls.Add(layout);
        slider.ValueChanged += (_, _) => UpdateValue();
        balanced.Click += (_, _) => slider.Value = 57;
        connect.Click += async (_, _) => await Connect();
        send.Click += async (_, _) => await Send();
        Shown += async (_, _) => await Detect();
        FormClosing += (_, e) => { if (e.CloseReason == CloseReason.UserClosing) { e.Cancel = true; Hide(); } };
    }
    void UpdateValue() => value.Text = ramGB > 0 ? $"{slider.Value} % ≈ {ramGB * slider.Value / 100:0.0} GiB" : $"{slider.Value} %";
    void Disconnect() { control = null; slider.Enabled = send.Enabled = balanced.Enabled = false; }
    async Task Detect()
    {
        try
        {
            var json = await WindowsShell.PowerShell("$ErrorActionPreference='Stop'; [pscustomobject]@{CPU=(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name);RAM=(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory;GPU=@(Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion)} | ConvertTo-Json -Depth 4 -Compress");
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;
            ramGB = root.GetProperty("RAM").GetDouble() / 1073741824;
            hardware.Text = $"{root.GetProperty("CPU").GetString()} · {ramGB:0.#} GiB RAM\n" + string.Join("\n", root.GetProperty("GPU").EnumerateArray().Select(g => $"{g.GetProperty("Name").GetString()} · Driver {g.GetProperty("DriverVersion").GetString()}"));
        }
        catch (Exception e) { hardware.Text = "No se pudo consultar el hardware: " + e.Message; }
    }
    async Task Connect()
    {
        Disconnect(); connect.Enabled = false;
        try
        {
            control = await Task.Run(IntelControl.Find);
            slider.Minimum = (int)Math.Ceiling(control.Minimum);
            slider.Maximum = (int)Math.Floor(control.Maximum);
            slider.Value = Math.Clamp((int)Math.Round(control.Value), slider.Minimum, slider.Maximum);
            slider.Enabled = send.Enabled = true;
            balanced.Enabled = slider.Minimum <= 57 && slider.Maximum >= 57;
            UpdateValue();
            status.Text = $"Control de Intel detectado: {control.Minimum:0.#}–{control.Maximum:0.#} %. Valor mostrado por Intel, no lectura del límite activo del kernel.";
        }
        catch (Exception e) { Disconnect(); status.Text = e.Message; }
        finally { connect.Enabled = true; }
    }
    async Task Send()
    {
        if (control is null) return;
        var requested = slider.Value;
        var target = control;
        send.Enabled = connect.Enabled = slider.Enabled = false;
        try
        {
            await Task.Run(() => target.Set(requested));
            status.Text = "Selección verificada en el panel de Intel. Confirma allí el ajuste y reinicia Windows para que tenga efecto.";
        }
        catch (Exception e) { Disconnect(); status.Text = "No se pudo verificar la selección: " + e.Message + " Vuelve a conectar con Intel."; }
        finally { connect.Enabled = true; if (control is not null) send.Enabled = slider.Enabled = true; }
    }
    async Task LaunchIntel()
    {
        try
        {
            var id = (await WindowsShell.PowerShell("Get-StartApps | Where-Object {$_.Name -eq 'Intel Graphics Software' -or $_.Name -eq 'Intel® Graphics Software'} | Select-Object -First 1 -ExpandProperty AppID")).Trim();
            if (string.IsNullOrEmpty(id) || id.Contains('\n') || id.Contains('\r')) throw new InvalidOperationException("Abre Intel Graphics Software desde Inicio. Si no está instalado, utiliza el controlador y software oficiales de Intel o del fabricante del portátil.");
            var start = new ProcessStartInfo("explorer.exe");
            start.ArgumentList.Add("shell:AppsFolder\\" + id);
            Process.Start(start);
        }
        catch (Exception e) { status.Text = e.Message; }
    }
}

internal static class WindowsShell
{
    internal static async Task<string> PowerShell(string script)
    {
        var start = new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe")) { UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true };
        foreach (string arg in new[] { "-NoProfile", "-NonInteractive", "-Command", "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; " + script }) start.ArgumentList.Add(arg);
        using var process = Process.Start(start) ?? throw new IOException("No se pudo iniciar PowerShell.");
        var stdout = process.StandardOutput.ReadToEndAsync();
        var stderr = process.StandardError.ReadToEndAsync();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(20));
        try { await process.WaitForExitAsync(timeout.Token); }
        catch (OperationCanceledException) { process.Kill(true); throw new IOException("La consulta a Windows ha tardado demasiado."); }
        if (process.ExitCode != 0) throw new IOException((await stderr).Trim());
        return await stdout;
    }
}

// No registry guesses or undocumented driver writes. Connect only to a slider
// explicitly named by Intel's accessibility provider. Unknown layouts fail closed.
internal sealed class IntelControl
{
    readonly AutomationElement element;
    readonly RangeValuePattern pattern;
    readonly int processId;
    public double Minimum => pattern.Current.Minimum;
    public double Maximum => pattern.Current.Maximum;
    public double Value => pattern.Current.Value;
    IntelControl(AutomationElement e, RangeValuePattern p) { element = e; pattern = p; processId = e.Current.ProcessId; }
    static bool IsIntelProcess(int id)
    {
        try { using var p = Process.GetProcessById(id); return p.ProcessName.Equals("IntelGraphicsSoftware", StringComparison.OrdinalIgnoreCase); }
        catch { return false; }
    }
    public static IntelControl Find()
    {
        var windows = AutomationElement.RootElement.FindAll(TreeScope.Children, new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Window));
        IntelControl? result = null;
        foreach (AutomationElement window in windows)
        {
            if (!IsIntelProcess(window.Current.ProcessId)) continue;
            var candidates = window.FindAll(TreeScope.Descendants, new AndCondition(
                new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Slider),
                new OrCondition(new PropertyCondition(AutomationElement.NameProperty, "Shared GPU Memory Override"),
                                new PropertyCondition(AutomationElement.NameProperty, "Anulación de memoria compartida de GPU"))));
            foreach (AutomationElement candidate in candidates)
            {
                if (!candidate.Current.IsEnabled || candidate.Current.IsOffscreen || !candidate.TryGetCurrentPattern(RangeValuePattern.Pattern, out var raw)) continue;
                var pattern = (RangeValuePattern)raw;
                var state = pattern.Current;
                // A 0..1 normalized slider or unnamed slider cannot safely be interpreted as percent.
                if (state.IsReadOnly || state.Minimum < 0 || state.Maximum <= 1 || state.Maximum > 100 || state.Minimum >= state.Maximum || Math.Ceiling(state.Minimum) > Math.Floor(state.Maximum)) continue;
                if (result is not null) throw new InvalidOperationException("Hay varios controles posibles. No se modificará ninguno.");
                result = new IntelControl(candidate, pattern);
            }
        }
        return result ?? throw new InvalidOperationException("No se ha identificado un slider compatible. Abre Shared GPU Memory Override en Intel Graphics Software. Si tu versión no expone el control a Windows, ajusta el límite allí manualmente. No se ha realizado ningún cambio.");
    }
    public void Set(int value)
    {
        if (!IsIntelProcess(processId) || element.Current.ProcessId != processId || !element.Current.IsEnabled || element.Current.IsOffscreen) throw new InvalidOperationException("El panel de Intel ya no está disponible.");
        if (value < Minimum || value > Maximum || pattern.Current.IsReadOnly) throw new ArgumentOutOfRangeException(nameof(value));
        pattern.SetValue(value);
        if (Math.Abs(Value - value) > 0.01) throw new IOException("Intel no ha devuelto el valor solicitado.");
    }
}
