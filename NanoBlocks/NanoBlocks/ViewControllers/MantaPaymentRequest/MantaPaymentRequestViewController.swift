//
//  MantaPaymentRequestViewController.swift
//  NanoBlocks
//
//  Created by Alessandro Viganò on 21/01/2019.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation
import UIKit
import mantaswift


class MantaPaymentRequestViewController: UIViewController {
    @IBOutlet weak var merchantName: UILabel!
    @IBOutlet weak var merchantAddress: UILabel!
    @IBOutlet weak var fiatAmount: UILabel!
    @IBOutlet weak var cryptoAmount: UILabel!
    @IBOutlet weak var destinationAddress: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bgView: UIVisualEffectView!
    
   
    weak var delegate: SendViewControllerDelegate?
    var mantaURL: String?
    
    private(set) var account: AccountInfo
    private var paymentRequest: PaymentRequestMessage?
    private var manta: MantaWallet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    init(account: AccountInfo) {
        self.account = account
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let url = mantaURL else {
            return
        }
        
        manta = MantaWallet (url)
        
        activityIndicator.startAnimating()
        
        manta?.getPaymentRequest(cryptoCurrency: "NANO").then { paymentRequestEnvelope in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            // TODO: Forcing try no good
            let paymentRequest = try! paymentRequestEnvelope.unpack()
            self.paymentRequest = paymentRequest
            self.destinationAddress.text = paymentRequest.destinations[0].destinationAddress
            self.merchantName.text = paymentRequest.merchant.name
            self.merchantAddress.text = paymentRequest.merchant.address
            self.fiatAmount.text = NSDecimalNumber(decimal: paymentRequest.amount).stringValue + " EUR"
            self.cryptoAmount.text = NSDecimalNumber(decimal: paymentRequest.destinations[0].amount).stringValue + "Nano"
        
        }
        
    }
    
    fileprivate func setupView() {
        //setupNavBar()
        destinationAddress.text = ""
        merchantAddress.text = ""
        merchantName.text = ""
        fiatAmount.text = ""
        cryptoAmount.text = ""
        
        bgView.roundCorners([.topRight, .topLeft], radius: 20.0)
        sendButton.layer.cornerRadius = 23.0
        sendButton.clipsToBounds = true
        let gradient = AppStyle.buttonGradient
        gradient.frame = sendButton?.bounds ?? .zero
        gradient.cornerRadius = 23.0
        sendButton?.layer.insertSublayer(gradient, at: 0)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        delegate?.closeTapped()
        dismiss(animated: true)
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        guard let pr = paymentRequest else {
            return
        }
        
        let recipientName = pr.merchant.name
        let recipientAddress = pr.destinations[0].destinationAddress
        let amount = NSDecimalNumber(decimal: pr.destinations[0].amount).stringValue
        
        let remaining = account.balance.decimalNumber.subtracting(amount.decimalNumber.rawValue)
        guard remaining.decimalValue >= 0.0 else {
            Banner.show(.localize("insufficient-funds"), style: .danger)
            return
        }
        
        let txInfo = TxInfo(recipientName: recipientName, recipientAddress: recipientAddress, amount: amount,
                            rawBalance: remaining.stringValue, accountInfo: account, manta: manta)
        
        delegate?.sendTapped(txInfo: txInfo)
    }
}
