//
//  TxInfo.swift
//  RaiBlocksWallet
//
//  Created by Ben Kray on 1/31/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Foundation
import mantaswift

struct TxInfo {
    var recipientName: String
    var recipientAddress: String
    var amount: String
    var balance: String
    var accountInfo: AccountInfo
    var manta: MantaWallet?
}
