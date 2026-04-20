import AppKit
import PointerDesignerCore

// Main entry point for the Cursor Designer app
let app = NSApplication.shared

// Set as menu bar app (no dock icon) - needed when running outside a bundle
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
