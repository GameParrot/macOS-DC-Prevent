//
//  AppDelegate.swift
//  DC Prevent
//
//  Created by Mike on 6/17/23.
//

import Cocoa
var globalClass = AppDelegate.self;
var globalText: NSTextView? = nil

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var eventTap: CFMachPort?
    public static var oms = 0.0;
    public static var omsr = 0.0;
    
    func startEventTap() {
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.rightMouseDown.rawValue)
        eventTap = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(eventMask), callback: eventTapCallback, userInfo: nil)
        
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            CFRunLoopRun()
        } else {
            print("Failed to create event tap.")
        }
    }
    
    func stopEventTap() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }
    
    @IBOutlet var window: NSWindow!
    @IBOutlet public var textView: NSTextView!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        globalText = textView
        textView.enclosingScrollView?.hasVerticalScroller = false;
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        
        if !accessEnabled {
            textView.textStorage?.append(NSAttributedString(string: "DC Prevent needs accessibility permission! Please give permission and then reopen DC Prevent.\n", attributes: attributes))
            print("Access Not Enabled")
        } else {
            print("Access Granted")
        }
        startEventTap();

    }
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    func applicationDidBecomeActive(_ notification: Notification) {
        NSApp.unhide(self)
        window.setIsVisible(true)
    }

}
let font = NSFont.systemFont(ofSize: 16)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.textColor,
]
func handleEvent(event: CGEvent) -> Unmanaged<CGEvent>? {
    let eventType = event.type
    
    // Check if it's a left mouse button down event
    if eventType == .leftMouseDown {
        if (Date().timeIntervalSince1970 - AppDelegate.oms < 0.050) {
            globalText?.textStorage?.append(NSAttributedString(string: "[o ] Supressed a DC\n", attributes: attributes))
            return nil
        } else {
            AppDelegate.oms = Date().timeIntervalSince1970;
            globalText?.textStorage?.append(NSAttributedString(string: "[o ] Mouse down\n", attributes: attributes))
        }
        globalText?.scrollToEndOfDocument(nil);
    }
    if eventType == .rightMouseDown {
        if (Date().timeIntervalSince1970 - AppDelegate.omsr < 0.050) {
            globalText?.textStorage?.append(NSAttributedString(string: "[ o] Supressed a DC\n", attributes: attributes))
            return nil
        } else {
            AppDelegate.omsr = Date().timeIntervalSince1970;
            globalText?.textStorage?.append(NSAttributedString(string: "[ o] Mouse down\n", attributes: attributes))
        }
        globalText?.scrollToEndOfDocument(nil);
    }
    
    // Pass through all other events
    return Unmanaged.passRetained(event)
}
func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    return handleEvent(event: event)
}
