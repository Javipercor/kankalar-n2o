import SwiftUI
import AppKit

enum WiredLimit {
    static let preset = 30_720
    static let key = "iogpu.wired_limit_mb"
    static let memoryMB = Int(ProcessInfo.processInfo.physicalMemory / 1_048_576)
    // Leave at least 4 GiB for macOS and other applications.
    static let maximum = max(0, ((memoryMB - 4_096) / 256) * 256)

    static func validate(_ value: Int) throws {
        guard value >= 0, value <= maximum else {
            throw Failure(message: "Choose a value between 0 and \(maximum) MB.")
        }
    }

    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func run(_ executable: String, _ arguments: [String]) throws -> String {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard process.terminationStatus == 0 else {
            if text.contains("-128") { throw Failure(message: "Change canceled. The setting was not applied.") }
            throw Failure(message: text.isEmpty ? "Could not run the command." : text)
        }
        return text
    }

    static func read() throws -> Int {
        let output = try run("/usr/sbin/sysctl", ["-n", key])
        guard let value = Int(output), value >= 0 else {
            throw Failure(message: "macOS returned an unexpected value: \(output)")
        }
        return value
    }

    static func apply(_ value: Int) throws -> Int {
        try validate(value)
        // Only a validated integer enters the fixed command. macOS owns the password dialog.
        let script = "do shell script \"/usr/sbin/sysctl -w \(key)=\(value)\" with administrator privileges"
        _ = try run("/usr/bin/osascript", ["-e", script])
        let actual = try read()
        guard actual == value else {
            throw Failure(message: "Could not verify the change. Current value: \(actual) MB.")
        }
        return actual
    }
}

@MainActor
final class LimitModel: ObservableObject {
    @Published var selection: Double
    @Published var current: Int?
    @Published var busy = false
    @Published var message: String?
    @Published var isError = false
    @Published var available = false

    init() {
        let saved = UserDefaults.standard.object(forKey: "selectedLimit") as? Int
        selection = Double(min(max(saved ?? WiredLimit.preset, 0), WiredLimit.maximum))
    }

    var value: Int { Int(selection.rounded()) }

    func refresh() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            current = try await Task.detached { try WiredLimit.read() }.value
            available = true
            message = nil
        } catch {
            available = false
            isError = true
            message = "Could not read the GPU setting on this Mac. \(error.localizedDescription)"
        }
    }

    func apply() async {
        guard !busy, available else { return }
        let requested = value
        busy = true
        message = nil
        defer { busy = false }
        do {
            current = try await Task.detached { try WiredLimit.apply(requested) }.value
            UserDefaults.standard.set(requested, forKey: "selectedLimit")
            isError = false
            message = requested == 0 ? "System default restored." : "Applied and verified: \(requested.formatted(.number.locale(Locale(identifier: "en_US")))) MB."
        } catch {
            isError = true
            message = error.localizedDescription
            // Refresh reality after cancellation, failure, or an external change.
            current = try? await Task.detached { try WiredLimit.read() }.value
        }
    }
}

struct ContentView: View {
    @ObservedObject var model: LimitModel
    @Environment(\.colorScheme) private var colorScheme
    private var accent: Color {
        colorScheme == .dark
            ? Color(red: 0.39, green: 0.89, blue: 0.76)
            : Color(red: 0.08, green: 0.43, blue: 0.35)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack(spacing: 12) {
                Image(systemName: "memorychip.fill")
                    .font(.system(size: 25)).foregroundStyle(accent)
                    .frame(width: 50, height: 50)
                    .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text("N₂O").font(.system(size: 25, weight: .bold, design: .rounded))
                    Text("GPU memory, your way").foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(WiredLimit.memoryMB / 1024) GB RAM")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .padding(8).background(Color.primary.opacity(0.06), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Label("WIRED LIMIT", systemImage: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    Spacer()
                    if model.value == WiredLimit.preset {
                        Text("SWEET SPOT").font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent).padding(.horizontal, 9).padding(.vertical, 5)
                            .background(accent.opacity(0.12), in: Capsule())
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(model.value == 0 ? "Auto" : model.value.formatted(.number.locale(Locale(identifier: "en_US"))))
                        .font(.system(size: 48, weight: .medium, design: .rounded))
                        .monospacedDigit().contentTransition(.numericText())
                    if model.value != 0 { Text("MB").font(.title3).foregroundStyle(.secondary) }
                    Spacer()
                }
                Slider(value: $model.selection, in: 0...Double(max(256, WiredLimit.maximum)), step: 256)
                    .tint(accent).disabled(model.busy || WiredLimit.maximum == 0)
                    .accessibilityLabel("GPU memory limit in MB")
                    .accessibilityValue("\(model.value) MB")
                HStack {
                    Text("Automatic")
                    Spacer()
                    Text("\(WiredLimit.maximum.formatted(.number.locale(Locale(identifier: "en_US")))) MB")
                }.font(.system(size: 11)).foregroundStyle(.secondary)

                HStack {
                    Button { model.selection = Double(WiredLimit.preset) } label: {
                        Label("30,720 MB", systemImage: "sparkle")
                    }.disabled(WiredLimit.maximum < WiredLimit.preset)
                    Button("System default") { model.selection = 0 }
                    Spacer()
                }.buttonStyle(.bordered).disabled(model.busy)
            }
            .padding(22)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.primary.opacity(0.08)))

            HStack {
                Circle().fill(model.available ? accent : .gray).frame(width: 6, height: 6)
                Text(currentLabel).font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
                Button { Task { await model.refresh() } } label: {
                    Image(systemName: "arrow.clockwise")
                }.buttonStyle(.plain).help("Refresh current value").disabled(model.busy)
            }

            if let message = model.message {
                Text(message).font(.system(size: 12))
                    .foregroundStyle(model.isError ? Color.orange : accent)
                    .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
            }

            Button { Task { await model.apply() } } label: {
                HStack(spacing: 8) {
                    if model.busy { ProgressView().controlSize(.small) }
                    else { Image(systemName: "lock.shield") }
                    Text(model.busy ? "Working…" : "Apply limit")
                }.font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 9)
                    .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                    .background(accent, in: RoundedRectangle(cornerRadius: 9))
                    .opacity(model.busy || !model.available || model.current == model.value ? 0.45 : 1)
            }
            .buttonStyle(.plain)
            .disabled(model.busy || !model.available || model.current == model.value)
            .keyboardShortcut(.return, modifiers: .command)

            Text("macOS will ask for authorization. The setting lasts until restart. At least 4 GiB stays outside the configured limit.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("N₂O · GPU Memory").font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button("Quit N₂O") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.secondary)
                    .disabled(model.busy)
            }
        }
        .padding(28).frame(width: 480)
        .foregroundStyle(.primary)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.locale, Locale(identifier: "en_US"))
        .task { await model.refresh() }
    }

    private var currentLabel: String {
        guard let value = model.current else { return "Current value: not checked" }
        return value == 0 ? "Current: system default (0)" : "Current: \(value.formatted(.number.locale(Locale(identifier: "en_US")))) MB"
    }
}

enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            let body = NSBezierPath(roundedRect: NSRect(x: 4.5, y: 1, width: 9, height: 12), xRadius: 3, yRadius: 3)
            body.lineWidth = 1.5
            body.stroke()
            let detail = NSBezierPath()
            detail.lineWidth = 1.5
            detail.lineCapStyle = .round
            // Valve, neck and the bottle's label band.
            detail.move(to: NSPoint(x: 9, y: 13))
            detail.line(to: NSPoint(x: 9, y: 16.5))
            detail.move(to: NSPoint(x: 6, y: 16.5))
            detail.line(to: NSPoint(x: 12, y: 16.5))
            detail.move(to: NSPoint(x: 5, y: 6))
            detail.line(to: NSPoint(x: 13, y: 6))
            detail.move(to: NSPoint(x: 5, y: 8.5))
            detail.line(to: NSPoint(x: 13, y: 8.5))
            detail.stroke()
            return true
        }
        // macOS supplies the correct color, including the selected/highlighted state.
        image.isTemplate = true
        image.accessibilityDescription = "N₂O"
        return image
    }()
}

@main
struct N2OApp: App {
    @StateObject private var model = LimitModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(model: model)
        } label: {
            Image(nsImage: MenuBarIcon.image)
                .renderingMode(.template)
                .help("N₂O · GPU memory limit")
                .accessibilityLabel("N₂O, GPU memory control")
        }
        .menuBarExtraStyle(.window)
    }
}
