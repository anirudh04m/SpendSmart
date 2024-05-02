//
//  BudgetViewController.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 11/04/24.
//

import UIKit
import CoreData
import Lottie

class BudgetViewController: UIViewController {
    
    @IBOutlet weak var budgetAnimationView: UIView!
    
    @IBOutlet weak var budgetAmountTextField: UITextField!
    
    @IBOutlet weak var budgetInfoLabel: UILabel!
    
    @IBOutlet weak var addBudgetButton: UIButton!
    
    @IBOutlet weak var editBudgetButton: UIButton!
    
    private var animationView: LottieAnimationView?
    
    var isEditingBudget: Bool = false {
        didSet {
            updateUIForEditing()
        }
    }
    
    private var originalBudgetAmount: Double = 0.0
    
    var currentYear: Int {
        let date = Date()
        let calendar = Calendar.current
        return calendar.component(.year, from: date)
    }
    
    var currentMonth: Int {
        let date = Date()
        let calendar = Calendar.current
        return calendar.component(.month, from: date)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
    }
    
    func setupUI() {
        
        animationView = .init(name: "Savings")
        
        animationView!.frame = budgetAnimationView.bounds
        
        animationView!.contentMode = .scaleAspectFit
        
        animationView!.loopMode = .loop
        
        animationView!.animationSpeed = 0.5
        
        budgetAnimationView.addSubview(animationView!)
        
        animationView!.play()
        
        setBudgetLabel()
        
        isEditingBudget = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // This allows other controls to receive touch events
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true) // This will resign the first responder status from all text fields
    }
    
    private func setBudgetLabel() {
        let expenseAmount = fetchTotalExpenseForCurrentMonth()
        let budget = fetchBudgetForCurrentMonth()
        
        if let budget = budget {
            budgetAmountTextField.text = "\(budget.amount)"
            budgetAmountTextField.isEnabled = false
            addBudgetButton.isEnabled = false
            isEditingBudget = false
            originalBudgetAmount = budget.amount
            
            if expenseAmount > budget.amount {
                budgetInfoLabel.text = "Expenses exceed budget for \(currentMonth)/\(currentYear % 100) by \((expenseAmount - budget.amount).rounded(toPlaces: 2))."
                budgetInfoLabel.textColor = .systemRed
            } else {
                budgetInfoLabel.text = "Expenses are within budget for \(currentMonth)/\(currentYear % 100)."
                budgetInfoLabel.textColor = .systemGreen
            }
        } else {
            budgetInfoLabel.text = "Budget not set for this month."
        }
        
    }
    
    func updateUIForEditing() {
        budgetAmountTextField.isEnabled = isEditingBudget
        addBudgetButton.isEnabled = isEditingBudget
        editBudgetButton.setTitle(isEditingBudget ? "Cancel" : "Edit", for: .normal)
        
        if !isEditingBudget {
            // Revert to original budget amount
            budgetAmountTextField.text = "\(originalBudgetAmount)"
        }
    }
    
    func fetchTotalExpenseForCurrentMonth() -> Double {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        // Create a date range for the current month
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: currentDate)))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        // Filter transactions for the current month
        fetchRequest.predicate = NSPredicate(format: "type == %@ AND date >= %@ AND date <= %@", TransactionType.expense.rawValue, startOfMonth as NSDate, endOfMonth as NSDate)
        
        do {
            let transactions = try context.fetch(fetchRequest)
            let totalExpense = transactions.reduce(0) { $0 + ($1.amount) }
            return totalExpense
        } catch {
            print("Error fetching transactions: \(error)")
            return 0
        }
    }
    
    func fetchBudgetForCurrentMonth() -> Budget? {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Budget> = Budget.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "year == %d AND month == %d", currentYear, currentMonth)
        do {
            let budgets = try context.fetch(fetchRequest)
            return budgets.first
        } catch {
            print("Error fetching budget: \(error)")
            return nil
        }
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    @IBAction func addBudgetButtonTapped(_ sender: UIButton) {
        
        var didAdd: Bool = false;
        
        guard let amountText = budgetAmountTextField.text, let amount = Double(amountText) else {
            let invalidAmountAlertController = Utils.fieldsValidationErrorAlert("amount")
            self.present(invalidAmountAlertController, animated: true)
            return
        }
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        if let existingBudget = fetchBudgetForCurrentMonth() {
            existingBudget.amount = amount.rounded(toPlaces: 2)
        } else {
            let budget = Budget(context: context)
            budget.amount = amount.rounded(toPlaces: 2)
            budget.year = Int16(currentYear)
            budget.month = Int16(currentMonth)
            didAdd.toggle()
        }
        
        do {
            try context.save()
            setBudgetLabel()
            budgetAmountTextField.isEnabled = false
            addBudgetButton.isEnabled = false
            isEditingBudget = false
            if didAdd {
                let addBudgetAlertController = Utils.addSuccessAlert("Budget")
                self.present(addBudgetAlertController, animated: true)
            } else {
                let updateBudgetAlertController = Utils.updateSuccessAlert("Budget")
                self.present(updateBudgetAlertController, animated: true)
            }
        } catch {
            print("Error saving budget: \(error)")
        }
    }
    
    
    @IBAction func editBudgetButtonTapped(_ sender: UIButton) {
        isEditingBudget.toggle()
    }
    
}
