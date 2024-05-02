//
//  ChatViewController.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 11/04/24.
//

import UIKit
import CoreData

class ChatViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var conversationTextField: UITextView!
    @IBOutlet weak var userInputField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!
    
    private var options: [String] = ["Expense", "Income", "Budget"]
    private var isChoosingOption: Bool = false
    private var selectedOption: String?
    private var currentState: ChatState = .initial
    private var currentOption: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        userInputField.delegate = self
        sendMessageButton.layer.cornerRadius = sendMessageButton.frame.width / 2
        sendMessageButton.clipsToBounds = true
        registerKeyboardNotifications()
        
        setupKeyboardDismissRecognizer()
        
        conversationTextField.isScrollEnabled = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let bottomSpace = view.bounds.height - (userInputField.frame.origin.y + userInputField.frame.height)
            let offset = keyboardSize.height - bottomSpace + 40 // Extra 10 points for some spacing
            view.transform = CGAffineTransform(translationX: 0, y: -offset)
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        view.transform = .identity
    }
    
    @IBAction func messageSendButtonTapped(_ sender: UIButton) {
        guard let userMessage = userInputField.text, !userMessage.isEmpty else { return }
        processMessage(userMessage)
        userInputField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let message = textField.text {
            processMessage(message)
        }
        textField.text = ""
        return true
    }
    
    func setupKeyboardDismissRecognizer() {
            let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(dismissKeyboard))
            tapRecognizer.cancelsTouchesInView = false
            tapRecognizer.delegate = self
            view.addGestureRecognizer(tapRecognizer)
        }

        @objc func dismissKeyboard(sender: UITapGestureRecognizer) {
            let location = sender.location(in: view)
            if sendMessageButton.frame.contains(location) {
                return
            }
            view.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if touch.view == sendMessageButton {
                return false
            }
            return true
        }
    
    private func processMessage(_ message: String) {
        addToConversation("You: \(message)", isUser: true)
        
        if currentState == .initial {
            if message.lowercased().contains("menu") {
                showOptions()
                currentState = .choosingOption
            } else {
                addToConversation("Bot: I'm not sure how to process that. Type 'menu' to see the options.", isUser: false)
            }
        } else if currentState == .choosingOption {
            handleOptionSelection(message)
        } else if currentState == .enteringExpenseDate || currentState == .enteringIncomeDate || currentState == .enteringBudgetDate {
            handleDateEntry(message)
        } else {
            addToConversation("Bot: I'm not sure how to process that.", isUser: false)
            currentState = .initial
        }
    }

    private func handleOptionSelection(_ message: String) {
        guard let choice = Int(message), choice > 0 && choice <= options.count else {
            addToConversation("Bot: Invalid option. Please choose a number from the list.", isUser: false)
            return
        }
        let selectedOption = options[choice - 1]
        currentOption = selectedOption
        showDataForSelectedOption()
    }

    private func showDataForSelectedOption() {
        guard let option = currentOption else { return }
        
        switch option {
        case "Expense":
            addToConversation("Bot: Please enter the month and year (MM/YYYY) for which you want to see expenses.", isUser: false)
            currentState = .enteringExpenseDate
        case "Income":
            addToConversation("Bot: Please enter the month and year (MM/YYYY) for which you want to see income.", isUser: false)
            currentState = .enteringIncomeDate
        case "Budget":
            addToConversation("Bot: Please enter the month and year (MM/YYYY) for which you want to see the budget.", isUser: false)
            currentState = .enteringBudgetDate
        default:
            addToConversation("Bot: I'm not sure how to process that.", isUser: false)
        }
    }

    private func handleDateEntry(_ message: String) {
        guard isValidDate(message) else {
            addToConversation("Bot: Invalid date format. Please enter the month and year in MM/YYYY format.", isUser: false)
            return
        }
        
        guard let option = currentOption else { return }
        
        let components = message.split(separator: "/")
        guard let month = Int(components[0]), let year = Int(components[1]) else { return }
        
        showData(forOption: option, month: month, year: year)
    }

    private func showData(forOption option: String, month: Int, year: Int) {
        switch option {
        case "Expense":
            let totalExpense = fetchTotalExpense(forMonth: month, year: year)
            addToConversation("Bot: Your total expense for \(month)/\(year) is $\(totalExpense.rounded(toPlaces: 2))", isUser: false)
        case "Income":
            let totalIncome = fetchTotalIncome(forMonth: month, year: year)
            addToConversation("Bot: Your total income for \(month)/\(year) is $\(totalIncome.rounded(toPlaces: 2))", isUser: false)
        case "Budget":
            let budgetAmount = fetchBudget(forMonth: month, year: year)
            addToConversation("Bot: Your budget for \(month)/\(year) is $\(budgetAmount.rounded(toPlaces: 2))", isUser: false)
        default:
            addToConversation("Bot: I'm not sure how to process that.", isUser: false)
        }
        showOptions()
    }

    private func showOptions() {
        var optionMessage = "Bot: Please choose an option by typing its number:\n"
        for (index, option) in options.enumerated() {
            optionMessage += "\(index + 1). \(option)\n"
        }
        addToConversation(optionMessage, isUser: false)
        currentState = .choosingOption
    }

    
    private func isValidDate(_ date: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/yyyy"
        return dateFormatter.date(from: date) != nil
    }

    
    private func addToConversation(_ message: String, isUser: Bool) {
        let fontSize: CGFloat = 18
        let font = UIFont(name: "Georgia", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        
        let attributedMessage = NSMutableAttributedString(string: "\n\(message)")
        
        let color: UIColor = isUser ? .systemBlue : .systemGreen
        attributedMessage.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: attributedMessage.length))
        
        attributedMessage.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedMessage.length))
        
        let lineBreak = NSAttributedString(string: "\n")
        attributedMessage.append(lineBreak)
        
        if let existingText = conversationTextField.attributedText {
            let mutableExistingText = NSMutableAttributedString(attributedString: existingText)
            mutableExistingText.append(attributedMessage)
            conversationTextField.attributedText = mutableExistingText
        } else {
            conversationTextField.attributedText = attributedMessage
        }
        
        scrollToBottom()
    }
    
    private func scrollToBottom() {
         let range = NSMakeRange(conversationTextField.text.count - 1, 1)
         conversationTextField.scrollRangeToVisible(range)
     }
    
    private func fetchTotalExpense(forMonth month: Int, year: Int) -> Double {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!
        
        fetchRequest.predicate = NSPredicate(format: "type == %@ AND date >= %@ AND date <= %@", TransactionType.expense.rawValue, startDate as NSDate, endDate as NSDate)
        
        do {
            let transactions = try context.fetch(fetchRequest)
            let totalExpense = transactions.reduce(0) { $0 + ($1.amount) }
            return totalExpense
        } catch {
            print("Error fetching expenses: \(error)")
            return 0.0
        }
    }

    private func fetchTotalIncome(forMonth month: Int, year: Int) -> Double {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!
        
        fetchRequest.predicate = NSPredicate(format: "type == %@ AND date >= %@ AND date <= %@", TransactionType.income.rawValue, startDate as NSDate, endDate as NSDate)
        
        do {
            let transactions = try context.fetch(fetchRequest)
            let totalIncome = transactions.reduce(0) { $0 + ($1.amount) }
            return totalIncome
        } catch {
            print("Error fetching income: \(error)")
            return 0.0
        }
    }

    private func fetchBudget(forMonth month: Int, year: Int) -> Double {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Budget> = Budget.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "year == %@ AND month == %@", "\(year)", "\(month)")
        
        do {
            let budgets = try context.fetch(fetchRequest)
            if let budget = budgets.first {
                return budget.amount
            } else {
                return 0.0
            }
        } catch {
            print("Error fetching budget: \(error)")
            return 0.0
        }
    }
}

extension ChatViewController {
    enum ChatState {
        case initial
        case choosingOption
        case enteringExpenseDate
        case enteringIncomeDate
        case enteringBudgetDate
    }
}
