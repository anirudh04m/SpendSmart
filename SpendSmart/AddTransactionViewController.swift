//
//  AddTransactionViewController.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 30/03/24.
//

import UIKit
import CoreData
import Lottie
import Vision
import VisionKit
import PhotosUI

class AddTransactionViewController: UIViewController, PHPickerViewControllerDelegate {
    
    @IBOutlet weak var addTransactionAnimationView: UIView!
    @IBOutlet weak var addAmountTextField: UITextField!
    @IBOutlet weak var addCategoryButton: UIButton!
    @IBOutlet weak var addDateTextField: UIDatePicker!
    @IBOutlet weak var addTransactionTypeButton: UIButton!
    @IBOutlet weak var selectImageButton: UIButton!
    
    var selectedDate = Date()
    let transactionTypes: [String] = TransactionType.allCases.map { $0.rawValue }
    var selectedType: TransactionType? = .expense
    var selectedCategory: String?
    private var animationView: LottieAnimationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addDateTextField.maximumDate = Date()
        
        animationView = .init(name: "Budget")
        animationView!.frame = addTransactionAnimationView.bounds
        animationView!.contentMode = .scaleAspectFit
        animationView!.loopMode = .loop
        animationView!.animationSpeed = 0.5
        addTransactionAnimationView.addSubview(animationView!)
        animationView!.play()
        
        title = "Add a Transaction"
        
        setupTransactionTypeMenu()
        setupCategoryMenu()
        
        // Setup select image button to pick image from photo library
        selectImageButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // This allows other controls to receive touch events
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true) // This will resign the first responder status from all text fields
    }
    
    func setupTransactionTypeMenu() {
        let typeActionClosure = { (action: UIAction) in
            self.selectedType = TransactionType(rawValue: action.title)
            self.setupCategoryMenu()
        }
        
        let typeMenuChildren: [UIMenuElement] = transactionTypes.map { title in
            UIAction(title: title, handler: typeActionClosure)
        }
        
        addTransactionTypeButton.menu = UIMenu(children: typeMenuChildren)
        addTransactionTypeButton.showsMenuAsPrimaryAction = true
        addTransactionTypeButton.changesSelectionAsPrimaryAction = true
    }
    
    func setupCategoryMenu() {
        var categories: [String] = ["Select"]
        switch selectedType {
        case .income:
            categories += incomeCategories
        case .expense, .none:
            categories += expenseCategories
        }
        
        DispatchQueue.main.async {
            self.updateCategoryButtonMenu(with: categories)
        }
    }
    
    private func updateCategoryButtonMenu(with categories: [String]) {
        let categoryActionClosure = { (action: UIAction) in
            self.selectedCategory = action.title
            self.addCategoryButton.setTitle(action.title, for: .normal)
        }
        
        let categoryMenuChildren = categories.map { category in
            UIAction(title: category, handler: categoryActionClosure)
        }
        
        addCategoryButton.menu = UIMenu(children: categoryMenuChildren)
        addCategoryButton.showsMenuAsPrimaryAction = true
        addCategoryButton.changesSelectionAsPrimaryAction = true
        
        if addCategoryButton.title(for: .normal) == nil {
            addCategoryButton.setTitle("Select", for: .normal)
        }
    }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addTransactionButtonTapped(_ sender: UIBarButtonItem) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        guard let amountText = addAmountTextField.text,
              let amount = Double(amountText) else {
            let invalidAmountAlertController = Utils.fieldsValidationErrorAlert("amount")
            self.present(invalidAmountAlertController, animated: true)
            return
        }
        
        guard TransactionType.allCases.contains(selectedType!) else {
            print("Select a valid transaction type")
            return
        }
        
        if selectedCategory == nil || selectedCategory == "Select" {
            let invalidCategoryAlertController = Utils.fieldsValidationErrorAlert("category")
            self.present(invalidCategoryAlertController, animated: true)
            return
        }
        
        let newTransaction = Transaction(context: context)
        newTransaction.amount = amount.rounded(toPlaces: 2)
        newTransaction.type = selectedType?.rawValue
        newTransaction.category = selectedCategory
        newTransaction.date = selectedDate
        
        do {
            try context.save()
            let transactionAlertController = Utils.addSuccessAlert(selectedType!.rawValue) {
                self.navigationController?.popViewController(animated: true)
            }
            
            self.present(transactionAlertController, animated: true)
        } catch {
            print("Error saving transaction \(error)")
        }
    }
    
    @objc func selectImage() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self = self, let image = image as? UIImage else { return }
            
            self.performOCR(on: image)
        }
    }
    
    func performOCR(on image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var totalAmount: Double?
            var date: Date?
            var recognizedText = ""
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                recognizedText += "\(topCandidate.string)\n"
            }
                        
            totalAmount = self.extractTotalAmount(from: recognizedText)
            date = self.extractDate(from: recognizedText)
            
            DispatchQueue.main.async {
                if let amount = totalAmount {
                    self.addAmountTextField.text = String(amount.rounded(toPlaces: 2))
                }
                
                if let date = date {
                    self.addDateTextField.date = date
                    self.selectedDate = date
                }
            }
        }
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing OCR: \(error)")
        }
    }


    func extractTotalAmount(from text: String) -> Double? {
        let amountPattern = "\\$\\d+(\\.\\d{1,2})?"
        
        do {
            let regex = try NSRegularExpression(pattern: amountPattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            var amounts: [Double] = []
            
            for match in matches {
                if let range = Range(match.range, in: text), let amount = Double(text[range].replacingOccurrences(of: "$", with: "")) {
                    amounts.append(amount)
                }
            }
            
            if let maxAmount = amounts.max() {
                return maxAmount
            }
        } catch {
            print("Error extracting amount: \(error)")
        }
        
        return nil
    }


    func extractDate(from text: String) -> Date? {
        let datePattern = "\\d{1,2}/\\d{1,2}/\\d{4}"
        
        do {
            let regex = try NSRegularExpression(pattern: datePattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let dateString = String(text[range])
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MM/dd/yyyy"
                    return dateFormatter.date(from: dateString)
                }
            }
        } catch {
            print("Error extracting date: \(error)")
        }
        
        return nil
    }

}

