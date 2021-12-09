// Wayfinder

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {

    @Binding var fileContent: String

    func makeCoordinator() ->DocumentPickerCoordinator {
        return DocumentPickerCoordinator(fileContent: $fileContent)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.text, .commaSeparatedText], asCopy: false)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Intentionally blank
    }
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {

    @Binding var fileContent: String

    init(fileContent: Binding<String>) {
        _fileContent = fileContent
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let fileURL = urls[0]
        do {
            print("Reading url: \(fileURL)")
            fileContent = try String(contentsOf: fileURL, encoding: .utf8)
            print(fileContent)
        } catch let error {
            print("\(error)")
        }
    }
    
    // NOTE can define `func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}` to handle cancelled event
}
