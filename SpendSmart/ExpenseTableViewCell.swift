//
//  ExpenseTableViewCell.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 03/04/24.
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {
    
    @IBOutlet weak var expenseCategoryLabel: UILabel!
    
    @IBOutlet weak var expenseDateLabel: UILabel!
    
    @IBOutlet weak var expenseAmountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configure(with transaction: Transaction) {
        expenseCategoryLabel.text = transaction.category
        
        expenseAmountLabel.textColor = .systemRed
        expenseAmountLabel.text = "-$\(transaction.amount)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        if let date = transaction.date {
            expenseDateLabel.text = dateFormatter.string(from: date)
        } else {
            expenseDateLabel.text = "Date not available"
        }
        
        expenseCategoryLabel.lineBreakMode = .byWordWrapping
        expenseAmountLabel.lineBreakMode = .byWordWrapping
        expenseDateLabel.lineBreakMode = .byWordWrapping
        
        expenseCategoryLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        expenseAmountLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        expenseDateLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
}
