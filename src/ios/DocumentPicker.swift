
enum DocumentTypes: String {
    case pdf
    case image
    case all
    case audio
    case video

    var uti: String {
        switch self {
            case .pdf: return "com.adobe.pdf"
            case .image: return "public.image"
            case .video: return "public.movie"
            case .audio: return "public.audio"
            case .all: return "public.data"
        }
    }
}

@objc(DocumentPicker)
class DocumentPicker : CDVPlugin {
    var commandCallback: String?

    @objc(getFile:)
    func getFile(command: CDVInvokedUrlCommand) {

        DispatchQueue.global(qos: .background).async {
            var arguments: [DocumentTypes] = []

            command.arguments.forEach {
                if let key =  $0 as? String, let type = DocumentTypes(rawValue: key) {
                    arguments.append(type)
                } else if let array = $0 as? [String] {
                    arguments = array.compactMap { DocumentTypes(rawValue: $0) }
                }
            }

            if arguments.isEmpty {
                self.sendError("Didn't receive any argument.")
            } else {
                self.commandCallback = command.callbackId
                self.callPicker(withTypes: arguments)
            }
        }
    }

    func callPicker(withTypes documentTypes: [DocumentTypes]) {

        let utis = documentTypes.map { $0.uti }

        let picker = UIDocumentPickerViewController(documentTypes: utis, in: .import)
        picker.delegate = self

        DispatchQueue.main.async {
            self.viewController.present(picker, animated: true, completion: nil)
        }
    }

    func documentWasSelected(document: URL) {
        self.sendResult(.init(status: CDVCommandStatus_OK, messageAs: document.absoluteString))
        self.commandCallback = nil
    }

    func sendError(_ message: String) {
        sendResult(.init(status: CDVCommandStatus_ERROR, messageAs: message))
    }

}

private extension DocumentPicker {
    func sendResult(_ result: CDVPluginResult) {

        self.commandDelegate.send(
            result,
            callbackId: commandCallback
        )
    }
}

extension DocumentPicker: UIDocumentPickerDelegate {

    @available(iOS 11.0, *)
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            documentWasSelected(document: url)
        }
    }


    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL){
        documentWasSelected(document: url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        sendError("User canceled.")
    }
}
