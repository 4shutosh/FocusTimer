//
//  FocusedTextField.swift
//  FloatingTimer
//
//  Created by Ashutosh on 17/04/25.
//

import SwiftUI
import AppKit

struct FocusedTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var shouldBecomeFirstResponder: Bool
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.isBordered = true
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.backgroundColor = .textBackgroundColor
        textField.lineBreakMode = .byTruncatingTail
        textField.cell?.truncatesLastVisibleLine = true
        textField.cell?.wraps = false
        
        // Set tooltip to show full text on hover
        textField.toolTip = text
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Update text value
        nsView.stringValue = text
        
        // Update tooltip to match current text
        nsView.toolTip = text
        
        // Make the text field become first responder if requested
        if shouldBecomeFirstResponder && ((nsView.window?.firstResponder?.isEqual(nsView)) == nil) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if nsView.window != nil {
                    nsView.window?.makeFirstResponder(nsView)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FocusedTextField
        
        init(_ parent: FocusedTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
                
                // Update tooltip when text changes
                textField.toolTip = textField.stringValue
            }
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            // Optional: handle end of editing if needed
        }
    }
} 
