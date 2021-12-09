// Wayfinder

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {

    var forContentTypes: [UTType]
    var onDocumentsPicked: (_: [URL]) -> ()

    func makeCoordinator() ->DocumentPickerCoordinator {
        return DocumentPickerCoordinator(onDocumentsPicked: onDocumentsPicked)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: forContentTypes, asCopy: false)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Intentionally blank
    }
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {

    var onDocumentsPicked: (_: [URL]) -> ()

    init(onDocumentsPicked: @escaping (_: [URL]) -> ()) {
        self.onDocumentsPicked = onDocumentsPicked
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onDocumentsPicked(urls)
    }
    
    // NOTE can define `func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}` to handle cancelled event
}
