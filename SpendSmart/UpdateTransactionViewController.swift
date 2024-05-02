//
//  UpdateTransactionViewController.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 10/04/24.
//

import UIKit
import Lottie
import CoreData

class UpdateTransactionViewController: UIViewController {
    
    
    @IBOutlet weak var updateTransactionAmountField: UITextField!
    
    @IBOutlet weak var updateTransactionCategoryButton: UIButton!
    
    @IBOutlet weak var updateTransactionAnimationView: UIView!
    
    @IBOutlet weak var updateTransactionDatePicker: UIDatePicker!
    
    private var animationView: LottieAnimationView?
    
    var transaction: Transaction!
    
    var selectedDate: Date?
    
    var selectedCategory: String?
    
       let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

       override func viewDidLoad() {
           super.viewDidLoad()
           setupUI()
       }

       private func setupUI() {
           
           animationView = .init(name: "Edit")
           
           animationView!.frame = updateTransactionAnimationView.bounds
                   
           animationView!.contentMode = .scaleAspectFit
           
           animationView!.loopMode = .loop
                   
           animationView!.animationSpeed = 0.5
           
           updateTransactionAnimationView.addSubview(animationView!)
                   
           animationView!.play()
           
           selectedDate = transaction.date ?? Date()
           
           selectedCategory = transaction.category ?? "Select"
           
           title = "Update Transaction"
           
           updateTransactionDatePicker.maximumDate = Date()
           
           // Set initial values from the transaction
           updateTransactionAmountField.text = "\(transaction.amount)"
           updateTransactionDatePicker.date = transaction.date ?? Date()
           updateTransactionCategoryButton.setTitle(transaction.category ?? "Select", for: .normal)

           setupCategoryMenu()
           
           let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
           tapGesture.cancelsTouchesInView = false // This allows other controls to receive touch events
           view.addGestureRecognizer(tapGesture)
       }
    
    @objc func dismissKeyboard() {
        view.endEditing(true) // This will resign the first responder status from all text fields
    }

       private func setupCategoryMenu() {
           var categories: [String]
           switch TransactionType(rawValue: transaction.type ?? "") {
           case .income:
               categories = incomeCategories
           case .expense:
               categories = expenseCategories
           default:
               categories = ["Select"]
           }
           let menuItems: [UIMenuElement] = categories.map { category in
               UIAction(title: category, handler: { [unowned self] action in
                   updateTransactionCategoryButton.setTitle(action.title, for: .normal)
                   selectedCategory = action.title
               })
           }
           updateTransactionCategoryButton.menu = UIMenu(children: menuItems)
           updateTransactionCategoryButton.showsMenuAsPrimaryAction = true
       }

       @IBAction func saveChanges(_ sender: UIBarButtonItem) {
           guard let amountText = updateTransactionAmountField.text, let amount = Double(amountText) else {
               let invalidAmountAlertController = Utils.fieldsValidationErrorAlert("amount")
               self.present(invalidAmountAlertController, animated: true)
               return
           }
           transaction.amount = amount.rounded(toPlaces: 2)
           transaction.category = selectedCategory
           transaction.date = selectedDate

           do {
               try context.save()
               
               let transactionAlertController = Utils.updateSuccessAlert(transaction.type!) {
                   self.navigationController?.popViewController(animated: true)
               }
               self.present(transactionAlertController, animated: true)
               
           } catch {
               print("Error saving updated transaction: \(error)")
           }
       }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        
        selectedDate = sender.date
        
        dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
