//
//  DocumentScannerView.swift
//  Rephrase
//
//  Created by Baldwin Kiel Malabanan on 2025-06-16.
//

import SwiftUI
import VisionKit
import Vision

struct DocumentScannerView: UIViewControllerRepresentable {
    var completion: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: (String) -> Void

        init(completion: @escaping (String) -> Void) {
            self.completion = completion
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)
            var scannedText = ""
            let requestHandler = VNImageRequestHandler(cgImage: scan.imageOfPage(at: 0).cgImage!, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                if let results = request.results as? [VNRecognizedTextObservation] {
                    scannedText = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                    self.completion(scannedText)
                }
            }
            try? requestHandler.perform([request])
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }
    }
}
