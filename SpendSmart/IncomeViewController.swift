//
//  IncomeViewController.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 03/04/24.
//

import UIKit
import DGCharts
import CoreData

class IncomeViewController: UIViewController {
    
    var categorySums = [String: Double]()
    
    @IBOutlet weak var incomePieChartView: PieChartView!
    
    @IBOutlet weak var incomeTableView: UITableView!
    
    var incomeTransactions: [Transaction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Income"

        // Do any additional setup after loading the view.
        prepareIncomeChartData()
        // After fetching and grouping transactions
        setupPieChart(with: categorySums)
        
        incomeTableView.dataSource = self
        incomeTableView.rowHeight = UITableView.automaticDimension

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
    
    func prepareIncomeChartData() {
        
        DispatchQueue.main.async {
            self.incomeTableView.reloadData()
        }
        
        for transaction in incomeTransactions {
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

        incomePieChartView.data = data
        incomePieChartView.notifyDataSetChanged()
    }

}

extension IncomeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        let uniqueMonths = Set(incomeTransactions.map { dateFormatter.string(from: $0.date!) })
            return uniqueMonths.count
        }
        
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let keys = Array(Set(incomeTransactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
        let monthlyIncomeTransactions = incomeTransactions.filter { dateFormatter.string(from: $0.date!) == keys[section] }
        let totalIncome = Utils.calculateMultipleTransactionsTotal(transactionList: monthlyIncomeTransactions)
        
        return "\(keys[section]) - Total: \(totalIncome)"
    }

        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let uniqueMonths = Array(Set(incomeTransactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
            let transactionsForSection = incomeTransactions.filter { dateFormatter.string(from: $0.date!) == uniqueMonths[section] }
            return transactionsForSection.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "incomeCell", for: indexPath) as? IncomeTableViewCell else {
                return UITableViewCell()
            }
            
            let uniqueMonths = Array(Set(incomeTransactions.map { dateFormatter.string(from: $0.date!) })).sorted(by: sortMonthYear)
            let transactionsForSection = incomeTransactions.filter { dateFormatter.string(from: $0.date!) == uniqueMonths[indexPath.section] }
            
            cell.configure(with: transactionsForSection[indexPath.row])
            return cell
        }
    }
