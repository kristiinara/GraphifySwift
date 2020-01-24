//
//  AppDelegate.swift
//  Basic
//
//  Created by Kristiina Rahkema on 20/09/2019.
//

import Foundation

import Foundation
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static let application = NSApplication.shared
    let app: App
    var viewController: ClassDiagramViewController!
    
    static func run(app: App) { //TODO: figure out if this is the best way to do it?
        let delegate = AppDelegate(app: app)
        application.delegate = delegate
        application.run()
    }
    
    init(app: App) {
        self.app = app
    }
    
    let window = NSWindow(contentRect: NSScreen.main?.frame ?? NSMakeRect(200, 200, 800, 400), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false, screen: nil)
    
//    let window = NSWindow(contentRect: NSMakeRect(200, 200, 800, 400),
//                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
//                          backing: .buffered,
//                          defer: false,
//                          screen: nil)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        window.makeKeyAndOrderFront(nil)
        
        let rect = NSRect(origin: CGPoint(x: 0, y: 0), size: window.frame.size)
        
        let viewController = ClassDiagramViewController(app: self.app, frame: rect)
        window.contentView?.addSubview(viewController.view)
        if #available(OSX 10.11, *) {
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor).isActive = true
            viewController.view.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor).isActive = true
            viewController.view.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor).isActive = true
            viewController.view.topAnchor.constraint(equalTo: window.contentView!.topAnchor).isActive = true
        } else {
            // Fallback on earlier versions
        }
        //window.contentView = viewController.view
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        viewController.view.needsDisplay = true
        return frameSize
    }

}
