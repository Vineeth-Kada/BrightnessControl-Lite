import Cocoa

class DisplayBrightnessView: NSView {
    var displayID: CGDirectDisplayID
    let slider: NSSlider
    let label: NSTextField
    
    init(frame frameRect: NSRect, displayID: CGDirectDisplayID, displayName: String) {
        self.displayID = displayID
        label = NSTextField(labelWithString: displayName)
        label.font = NSFont.systemFont(ofSize: 12)
        slider = NSSlider(value: getBrightness(displayID: displayID), minValue: 0, maxValue: 100, target: nil, action: nil)
        slider.isContinuous = true
        super.init(frame: frameRect)
        slider.target = self
        slider.action = #selector(sliderChanged(_:))
        label.frame = NSRect(x: 10, y: frameRect.height - 20, width: frameRect.width - 20, height: 16)
        slider.frame = NSRect(x: 10, y: 5, width: frameRect.width - 20, height: 20)
        addSubview(label)
        addSubview(slider)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func sliderChanged(_ sender: NSSlider) {
        let brightnessValue = UInt8(sender.doubleValue)
        print("Setting brightness for display \(displayID) to \(brightnessValue)")
        setBrightness(displayID: displayID, newBrightness: brightnessValue)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Brightness Control")
            image?.isTemplate = true // Use template image for dark mode
            button.image = image
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }
    
    // This method is called each time the menu is about to open.
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        
        // Re-enumerate displays and update the AVService cache.
        let nonAppleDisplayIDs = enumerateDisplays()
        
        // For each non‑Apple display, add a custom view with a slider.
        for displayID in nonAppleDisplayIDs {
            let displayName = getDisplayNameByID(displayID: displayID) + " (\(CGDisplaySerialNumber(displayID)))"
            let viewWidth: CGFloat = 250
            let viewHeight: CGFloat = 60
            let customView = DisplayBrightnessView(frame: NSRect(x: 0, y: 0, width: viewWidth, height: viewHeight),
                                                   displayID: displayID,
                                                   displayName: displayName)
            let item = NSMenuItem()
            item.view = customView
            menu.addItem(item)
        }
        
        // Add a separator and a Quit menu item.
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
