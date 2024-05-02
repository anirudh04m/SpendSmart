//
//  IncomeTableViewCell.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 03/04/24.
//

import UIKit

class IncomeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var incomeCategoryLabel: UILabel!
    
    @IBOutlet weak var incomeDateLabel: UILabel!
    
    @IBOutlet weak var incomeAmountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with transaction: Transaction) {
        incomeCategoryLabel.text = transaction.category
        
        incomeAmountLabel.textColor = .systemGreen
        incomeAmountLabel.text = "+$\(transaction.amount)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        if let date = transaction.date {
            incomeDateLabel.text = dateFormatter.string(from: date)
        } else {
            incomeDateLabel.text = "Date not available"
        }
        
        incomeCategoryLabel.lineBreakMode = .byWordWrapping
        incomeAmountLabel.lineBreakMode = .byWordWrapping
        incomeDateLabel.lineBreakMode = .byWordWrapping
        
        incomeCategoryLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        incomeAmountLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        incomeDateLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

}
