// Wayfinder

import Foundation
import SwiftUI

struct Dismissable: ViewModifier {
    var text: String = "Dismiss"
    var action: (() -> Void)? = nil
    @Binding var isPresented: Bool
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button(text) {
                    action?()
                    isPresented = false
                }
                .padding()
                Spacer()
            }
            content
        }
    }
}

extension View {
    func dismissable(text: String = "Dismiss", action: (() -> Void)? = nil, isPresented: Binding<Bool> = .constant(true)) -> some View {
        modifier(Dismissable(text: text, action: action, isPresented: isPresented))
    }
}
