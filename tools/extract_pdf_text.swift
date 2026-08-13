import Foundation
import PDFKit

guard CommandLine.arguments.count > 1 else {
  fatalError("Usage: swift tools/extract_pdf_text.swift path/to/file.pdf")
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let document = PDFDocument(url: url) else {
  fatalError("Could not open PDF at \(url.path)")
}

for index in 0..<document.pageCount {
  if let text = document.page(at: index)?.string {
    print(text)
  }
}
