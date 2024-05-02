//
//  ExpenseViewController.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 03/04/24.
//

import UIKit
import CoreData
import DGCharts

class ExpenseViewController: UIViewController {
    
    var categorySums = [String: Double]()

    @IBOutlet weak var pieChartView: PieChartView!
    
    @IBOutlet weak var expenseTableView: UITableView!
    
    var expenseTransactions: [Transaction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Expenses"
        
        // Do any additional setup after loading the view.
        prepareExpenseChartData()
        // After fetching and grouping transactions
        setupPieChart(with: categorySums)
        
        expenseTableView.dataSource = self
        expenseTableView.rowHeight = UITableView.automaticDimension
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private func sortMonthYear(_ a: String, _ b: String) -> Bool {
        
        if let dateA = dateFormatter.date(from: a), let dateB = dateFormatter.date(from: b) {
            return dateA > dateB
        }
        
        return false
    }
    
    func prepareExpenseChartData() {
                
                DispatchQueue.main.async {
                    self.expenseTableView.reloadData()
                }
                        
                for transaction in expenseTransactions {
                    let category = transaction.category ?? "Other" // Handle nil category if necessary
                    let amount = transaction.amount
                                        
                    categorySums[category, default: 0] += amount
                }

    }
    
    func setupPieChart(with categorySums: [String: Double]) {
        var entries: [PieChartDataEntry] = []
        for (category, sum) in categorySums {
            let entry = PieChartDataEntry(value: sum, label: category)
            entries.append(entry)
        }

        let dataSet = PieChartDataSet(entries: entries, label: "Transaction Categories")
        // Customize the dataSet appearance
        dataSet.colors = ChartColorTemplates.joyful() // Or any other color template
        dataSet.xValuePosition = .outsideSlice

        let data = PieChartData(dataSet: dataSet)
        data.setValueTextColor(.black) // Set the text color
        data.setValueFont(.systemFont(ofSize: 10)) // Set the font size

        pieChartView.data = data
        pieChartView.notifyDataSetChanged()
    }

}

extension ExpenseViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        let keys = Array(Set(expenseTransactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
        return keys.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let keys = Array(Set(expenseTransactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
        let monthlyIncomeTransactions = expenseTransactions.filter { dateFormatter.string(from: $0.date!) == keys[section] }
        let totalExpense = Utils.calculateMultipleTransactionsTotal(transactionList: monthlyIncomeTransactions)
        
        return "\(keys[section]) - Total: \(totalExpense)"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let keys = Array(Set(expenseTransactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
        let monthlyExpenseTransactions = expenseTransactions.filter { dateFormatter.string(from: $0.date!) == keys[section] }
        return monthlyExpenseTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "expenseCell", for: indexPath) as? ExpenseTableViewCell else {
            return UITableViewCell()
        }
        
        let keys = Array(Set(expenseTransactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
        let monthlyExpenseTransactions = expenseTransactions.filter { dateFormatter.string(from: $0.date!) == keys[indexPath.section] }
        
        cell.configure(with: monthlyExpenseTransactions[indexPath.row])
        return cell
    }
    }
