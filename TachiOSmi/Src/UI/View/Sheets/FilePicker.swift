//
//  FilePicker.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 20/05/2024.
//

import SwiftUI

struct FilePicker: UIViewControllerRepresentable {

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    
    var parent: FilePicker
    let completion: (Data) -> Void

    init(
      parent: FilePicker,
      completion: @escaping (Data) -> Void
    ) {
      self.parent = parent
      self.completion = completion
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      guard let selectedFileURL = urls.first else {
        return
      }

      parent.fileURL = selectedFileURL

      do {
        let data = try Data(contentsOf: selectedFileURL)

        completion(data)
      } catch {
        print("Failed to read file content")
      }
    }
  }

  @Binding var fileURL: URL?
  let completion: (Data) -> Void

  func makeCoordinator() -> Coordinator {
    return Coordinator(parent: self, completion: completion)
  }

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])

    picker.delegate = context.coordinator

    return picker
  }

  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    
  }
}

private struct Preview_Content: View {

  @State var presenting = false
  @State var url: URL?

  var body: some View {
    VStack {
      Button {
        presenting.toggle()
      } label: {
        Text("Select file")
      }
    }
    .sheet(isPresented: $presenting) {
      ZStack {
        Color.white.ignoresSafeArea(edges: .bottom)

        FilePicker(fileURL: $url) { _ in }
          .presentationDetents([.medium, .large])
      }
    }
  }

}

#Preview {
  Preview_Content()
}
