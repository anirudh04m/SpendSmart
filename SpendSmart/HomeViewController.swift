//
//  HomeViewController.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 30/03/24.
//

import UIKit
import CoreData

class HomeViewController: UIViewController {
    
    @IBOutlet weak var incomeImage: UIImageView!
    @IBOutlet weak var expenseImage: UIImageView!
    @IBOutlet weak var expenseTotalLabel: UILabel!
    @IBOutlet weak var incomeTotalLabel: UILabel!
    @IBOutlet weak var transactionTableView: UITableView!
    @IBOutlet weak var expenseTotalView: UIView!
    @IBOutlet weak var incomeTotalView: UIView!
    @IBOutlet weak var balanceTotalLabel: UILabel!
    
    var transactions: [Transaction] = []
    var expenseTransactions: [Transaction] = []
    var incomeTransactions: [Transaction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Transactions"
        
        self.navigationItem.leftBarButtonItem = editButtonItem
        
        // Add tap gesture recognizers to total views
        let expenseTapGesture = UITapGestureRecognizer(target: self, action: #selector(expenseTotalViewTapped))
        expenseTotalView.addGestureRecognizer(expenseTapGesture)
        
        let incomeTapGesture = UITapGestureRecognizer(target: self, action: #selector(incomeTotalViewTapped))
        incomeTotalView.addGestureRecognizer(incomeTapGesture)
        
        // Do any additional setup after loading the view.
        transactionTableView.dataSource = self
        transactionTableView.rowHeight = UITableView.automaticDimension
        fetchTransactions()
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTransactions()
    }
    
    func fetchTransactions() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        do {
            transactions = try managedContext.fetch(fetchRequest)
            
            // Sort transactions by date
            transactions = transactions.sorted(by: { $0.date! > $1.date! })
            
            DispatchQueue.main.async {
                self.transactionTableView.reloadData()
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        updateExpenseAndIncomeTransactions()
    }
    
    func calculateMultipleTransactionsTotal(transactionList: [Transaction]) -> Double {
        var totalAmount: Double = 0.0
        for transaction in transactionList {
            totalAmount += transaction.amount
        }
        return totalAmount
    }
    
    // Expense total view tapped
    @objc func expenseTotalViewTapped() {
        // Navigate to expense view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let expenseVC = storyboard.instantiateViewController(withIdentifier: "ExpenseViewController") as? ExpenseViewController else {
            return
        }
        expenseVC.expenseTransactions = expenseTransactions
        navigationController?.pushViewController(expenseVC, animated: true)
    }
    
    // Income total view tapped
    @objc func incomeTotalViewTapped() {
        // Navigate to income view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let incomeVC = storyboard.instantiateViewController(withIdentifier: "IncomeViewController") as? IncomeViewController else {
            return
        }
        incomeVC.incomeTransactions = incomeTransactions
        navigationController?.pushViewController(incomeVC, animated: true)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // Toggle the editing mode of the table view
        transactionTableView.setEditing(editing, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Identify the transaction to be deleted
            let keys = Array(Set(transactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
            let sectionTransactions = transactions.filter { dateFormatter.string(from: $0.date!) == keys[indexPath.section] }
            let deletedTransaction = sectionTransactions[indexPath.row]

            // Remove the transaction from the data source
            if let index = transactions.firstIndex(of: deletedTransaction) {
                transactions.remove(at: index)
            }

            // Delete the transaction from Core Data
            deleteTransaction(deletedTransaction)
            
            // Update the table view
            if sectionTransactions.count == 1 {
                // If that was the only row in the section, delete the entire section
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
            } else {
                // Otherwise, just delete the row
                tableView.deleteRows(at: [indexPath], with: .fade)
            }

            // Update expense and income transactions arrays
            updateExpenseAndIncomeTransactions()
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteTransaction(_ transaction: Transaction) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        managedContext.delete(transaction)
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not delete transaction. \(error), \(error.userInfo)")
        }
    }
    
    private func updateExpenseAndIncomeTransactions() {
        // Update expense and income transactions
        expenseTransactions = transactions.filter { $0.type == TransactionType.expense.rawValue }
        incomeTransactions = transactions.filter { $0.type == TransactionType.income.rawValue }
        let expenseTotal = calculateMultipleTransactionsTotal(transactionList: expenseTransactions)
        let incomeTotal = calculateMultipleTransactionsTotal(transactionList: incomeTransactions)
        
        // Update total labels
        expenseTotalLabel.text = "-$\(expenseTotal.rounded(toPlaces: 2))"
        incomeTotalLabel.text = "+$\(incomeTotal.rounded(toPlaces: 2))"
        
        let balance = (incomeTotal - expenseTotal).rounded(toPlaces: 2)
        balanceTotalLabel.text = balance < 0 ? "-$\(abs(balance))" : "$\(balance)"
    }
    
    @IBAction func downloadToExcelButtonTapped(_ sender: UIBarButtonItem) {
        // Generate Excel data
        let excelData = generateExcelData()
        
        let timestamp = Int(Date().timeIntervalSince1970)
        // Save Excel data to a file
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = documentsPath.appending("/Transactions\(timestamp).csv")
        
        do {
            try excelData.write(toFile: filePath, atomically: true, encoding: .utf8)
            
            // Present share sheet
            let activityViewController = UIActivityViewController(activityItems: [URL(fileURLWithPath: filePath)], applicationActivities: nil)
            present(activityViewController, animated: true, completion: nil)
        } catch {
            print("Error saving Excel file: \(error)")
        }
    }
    
    private func generateExcelData() -> String {
        // Convert your transaction data to CSV format
        var csvString = "Date,Amount,Type,Category\n"
        
        for transaction in transactions {
            var formattedDate = ""
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            if let date = transaction.date {
                formattedDate = dateFormatter.string(from: date)
            } else {
                formattedDate = "Date not available"
            }
            csvString += "\(formattedDate),\(transaction.amount),\(transaction.type ?? ""),\(transaction.category ?? "")\n"
        }
        return csvString
    }
    
    private func sortMonthYear(_ a: String, _ b: String) -> Bool {
        
        if let dateA = dateFormatter.date(from: a), let dateB = dateFormatter.date(from: b) {
            return dateA > dateB
        }
        
        return false
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = transactionTableView.indexPathForSelectedRow,
           let destinationVC = segue.destination as? UpdateTransactionViewController {
            
            let keys = Array(Set(transactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
            let monthlyTransactions = transactions.filter { dateFormatter.string(from: $0.date!) == keys[indexPath.section] }
            let selectedTransaction = monthlyTransactions[indexPath.row]
            
            destinationVC.transaction = selectedTransaction
        }
    }

}

extension HomeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        let keys = Array(Set(transactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
        return keys.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let keys = Array(Set(transactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
        return keys[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let keys = Array(Set(transactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
        let monthlyTransactions = transactions.filter { dateFormatter.string(from: $0.date!) == keys[section] }
        return monthlyTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath) as? TransactionTableViewCell else {
            return UITableViewCell()
        }
        
        let keys = Array(Set(transactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
        let monthlyTransactions = transactions.filter { dateFormatter.string(from: $0.date!) == keys[indexPath.section] }
        
        cell.configure(with: monthlyTransactions[indexPath.row])
        return cell
    }

}

