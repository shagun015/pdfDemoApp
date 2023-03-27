import PDFKit
import UIKit

class ViewController: UIViewController, PDFViewDelegate {
    
    var pdfView: PDFView = PDFView()
    var totalPageCount = 0
    var document: PDFDocument = PDFDocument()
    var currentPage: Int = 0
    var documentURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        documentURL = Bundle.main.url(forResource: "sample", withExtension: "pdf")
        
        pdfView = PDFView(frame: view.bounds)
        view.addSubview(pdfView)
        
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "pdf") else {
            return
        }
        
        document = PDFDocument(url: url)!
        
        updateBackgroundColor()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.delegate = self
        pdfView.displayMode = .twoUpContinuous
        pdfView.usePageViewController(true)
        
        if let total = pdfView.document?.pageCount {
            totalPageCount = total
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(countPage), name: Notification.Name.PDFViewPageChanged, object: nil)
        countPage()
        
        let addPageButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPage))
        let addAnnote = UIBarButtonItem(title: "Note", style: .plain, target: self, action: #selector(addAnnotation))
        //let image = UIImage(systemName: "pencil.and.square")
        
        let addTextButton = UIBarButtonItem(title: "Text", style: .plain, target: self, action: #selector(addText))
        navigationItem.rightBarButtonItems = [addPageButton,addTextButton,addAnnote]
 
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pdfView.frame = view.bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Update the background color of the PDF view based on the device theme
        updateBackgroundColor()
    }
    
    private func updateBackgroundColor() {
        if traitCollection.userInterfaceStyle == .dark {
            pdfView.backgroundColor = UIColor.black
        } else {
            pdfView.backgroundColor = UIColor.white
        }
    }
    
    @objc func countPage() {
        var currentPageNumber = 0
        currentPageNumber = document.index(for: pdfView.currentPage!)
        
        currentPage = currentPageNumber
        print(currentPage)
        let totalPage = "\(currentPage)/\(totalPageCount)"
        title = "PDF Viewer \(totalPage)"
    }
    
    @objc func addPage() {
        if let documentURL = Bundle.main.url(forResource: "sample", withExtension: "pdf") {
            if let pdfDocument = PDFDocument(url: documentURL) {
                // Create a new page and add it to the PDF document
                let newPage = PDFPage()
                pdfDocument.insert(newPage, at: pdfDocument.pageCount)
                
                // Update the PDFView to display the updated document
                pdfView.document = pdfDocument
            }
        }
    }
    

    @objc func addText() {
        guard let currentPage = pdfView.currentPage else {
            return
        }
        
        let alertController = UIAlertController(title: "Add Text", message: "Enter the text to add to the PDF page", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Text"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] (_) in
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else {
                return
            }
            
            let pageBounds = currentPage.bounds(for: .cropBox)
            let fontSize: CGFloat = 16
            let font = UIFont.systemFont(ofSize: fontSize)
            let color = UIColor.red
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            let attributedString = NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ])
            
            let textRect = attributedString.boundingRect(with: pageBounds.size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            let textOrigin = CGPoint(x: pageBounds.minX + (pageBounds.width - textRect.width) / 2, y: pageBounds.minY + (pageBounds.height - textRect.height) / 2)
            let textFrame = CGRect(origin: textOrigin, size: textRect.size)
            
            currentPage.addAnnotation(PDFAnnotation(bounds: textFrame, forType: .text, withProperties: nil))
            let annotation = currentPage.annotations.last!
            annotation.font = font
            annotation.color = color
            //annotation.fontAttributes = [.paragraphStyle: paragraphStyle]
            annotation.contents = text
            
            self?.pdfView.document?.write(to: (self?.documentURL)!)
        }))
        
        present(alertController, animated: true, completion: nil)
    }


    @objc func addAnnotation() {
        guard let currentPage = pdfView.currentPage else {
            return
        }

        let newAnnotation = PDFAnnotation(bounds: CGRect(x: 225, y: 50, width: 100, height: 50), forType: .text, withProperties: nil)
        
        newAnnotation.color = .systemTeal
        newAnnotation.contents = "sample text annotation"
        currentPage.addAnnotation(newAnnotation)

        pdfView.setNeedsDisplay()
    }

    
}
