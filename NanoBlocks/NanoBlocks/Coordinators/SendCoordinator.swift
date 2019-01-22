//
//  SendCoordinator.swift
//  RaiBlocksWallet
//
//  Created by Ben Kray on 1/21/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import UIKit
import StoreKit

protocol SendCoordinatorDelegate: class {
    func sendBlockGenerated(coordinator: Coordinator)
    func sendComplete(coordinator: Coordinator)
    func closeTapped(coordinator: Coordinator)
}

func getTopMostViewController() -> UIViewController? {
    var topMostViewController = UIApplication.shared.keyWindow?.rootViewController
    
    while let presentedViewController = topMostViewController?.presentedViewController {
        topMostViewController = presentedViewController
    }
    
    return topMostViewController
}

class SendCoordinator: RootViewCoordinator {
    var childCoordinators: [Coordinator] = []
    var rootViewController: UIViewController
    fileprivate var sendViewController: SendViewController
    fileprivate var mantaPaymentRequestVC: MantaPaymentRequestViewController?
    private(set) var account: AccountInfo
    weak var delegate: SendCoordinatorDelegate?
    
    init(root: UIViewController, account: AccountInfo) {
        self.rootViewController = root
        self.sendViewController = SendViewController(account: account)
        self.account = account
    }
    
    func start() {
        sendViewController.delegate = self
        sendViewController.modalPresentationStyle = .overFullScreen
        rootViewController.present(sendViewController, animated: true)
    }
}


extension SendCoordinator: SendViewControllerDelegate {
    
    
    func enterAddressTapped() {
        let enterAddressVC = EnterAddressViewController()
        enterAddressVC.onSelect = { [weak self] (entry) in
            self?.sendViewController.apply(entry: entry)
        }
        
        enterAddressVC.onMantaSelect = { [weak self] (url) in
            enterAddressVC.dismiss(animated: true) {
                self?.handleManta(url: url)
            }
        }
        
        enterAddressVC.modalTransitionStyle = .crossDissolve
        sendViewController.present(UINavigationController(rootViewController: enterAddressVC), animated: true)
        Lincoln.log("Are we dismissed?")
    }
    
    func enterAmountTapped() {
        let enterAmountVC = EnterAmountViewController(with: account)
        enterAmountVC.enteredAmount = { [weak self] (amount) in
            self?.sendViewController.apply(amount: amount)
        }
        enterAmountVC.modalTransitionStyle = .crossDissolve
        sendViewController.present(UINavigationController(rootViewController: enterAmountVC), animated: true)
    }
    
    func sendTapped(txInfo: TxInfo) {
        let confirmVC = ConfirmTxViewController(with: txInfo)
        confirmVC.modalTransitionStyle = .crossDissolve
        confirmVC.onSendComplete = { [weak self] in
            guard let me = self else {
                return
            }
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            }
            me.rootViewController.dismiss(animated: true)
            me.delegate?.sendComplete(coordinator:  me)
        }
        getTopMostViewController()?.present(UINavigationController(rootViewController: confirmVC), animated: true)
    }
    
    func handleManta(url: String) {
        mantaPaymentRequestVC = MantaPaymentRequestViewController(account: account, mantaURL: url)
        mantaPaymentRequestVC?.modalPresentationStyle = .overFullScreen
        mantaPaymentRequestVC?.delegate = self
        sendViewController.dismiss(animated: true) {
            guard let mantaPaymentRequestVC = self.mantaPaymentRequestVC else { return }
            self.rootViewController.present(mantaPaymentRequestVC, animated: true)
        }
        
    }
    
    func closeTapped() {
        delegate?.closeTapped(coordinator: self)
    }
    
    func scanTapped() {
        let qrVC = QRScanViewController()
        
        qrVC.onQRCodeScanned = { [weak self] (result) in
            self?.sendViewController.apply(scanResult: result)
            
            qrVC.dismiss(animated: true) {
                guard let url = result.mantaURL else {
                    return
                }
                self?.handleManta(url: url)
            }
        }
        sendViewController.present(UINavigationController(rootViewController: qrVC), animated: true)
    }
    
    func addressBookTapped() {
        let addressCoordinator = AddressBookCoordinator(root: sendViewController)
        addressCoordinator.delegate = self
        addressCoordinator.start()
        childCoordinators.append(addressCoordinator)
    }
}

extension SendCoordinator: AddressBookCoordinatorDelegate {
    func entrySelected(_ entry: AddressEntry, coordinator: Coordinator) {
        sendViewController.apply(entry: entry)
        removeChildCoordinator(coordinator)
    }
    
    func closeTapped(coordinator: AddressBookCoordinator) {
        removeChildCoordinator(coordinator)
    }
}
