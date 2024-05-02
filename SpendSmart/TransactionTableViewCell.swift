//
//  TransactionTableViewCell.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 30/03/24.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {

    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var amountLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with transaction: Transaction) {
        categoryLabel.text = transaction.category
        
        if (transaction.type == TransactionType.income.rawValue) {
            amountLabel.textColor = .systemGreen
            amountLabel.text = "+$\(transaction.amount)"
        } else {
            amountLabel.textColor = .systemRed
            amountLabel.text = "-$\(transaction.amount)"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        if let date = transaction.date {
            dateLabel.text = dateFormatter.string(from: date)
        } else {
            dateLabel.text = "Date not available"
        }
        
        categoryLabel.lineBreakMode = .byWordWrapping
        amountLabel.lineBreakMode = .byWordWrapping
        dateLabel.lineBreakMode = .byWordWrapping
        
        categoryLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        amountLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        dateLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

}
