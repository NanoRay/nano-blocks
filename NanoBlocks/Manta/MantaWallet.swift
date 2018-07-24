//
//  MantaWallet.swift
//  mantaprotocol
//
//  Created by Alessandro Viganò on 23/07/2018.
//  Copyright © 2018 Alessandro Viganò. All rights reserved.
//

import Foundation
import CocoaMQTT
import Promises

extension String {
    func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return self[range]
    }
}

extension String {
    func capturedGroups(withRegex pattern: String) -> [String] {
        var results = [String]()
        
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }
        
        let matches = regex.matches(in:self, options: [], range: NSRange(self.startIndex..., in:self))
        
        guard let match = matches.first else { return results }
        
        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }
        
        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.range(at:i)
            //let matchedString = (self as NSString).substring(with:capturedGroupIndex)
            if let matchedString = self.substring(with: capturedGroupIndex) {
                results.append(String(matchedString))
            }
        }
        
        return results
    }
}

public struct Destination: Codable {
    let amount: Float
    let cryptoCurrency: String
    let destinationAddress: String
    
    enum CodingKeys: String, CodingKey {
        case amount
        case cryptoCurrency = "crypto_currency"
        case destinationAddress = "destination_address"
    }
}

public struct PaymentRequestMessage: Codable {
    let amount: Float
    let fiatCurrency: String
    let destinations: [Destination]
    let merchant: String
    
    enum CodingKeys: String, CodingKey {
        case amount
        case fiatCurrency = "fiat_currency"
        case destinations
        case merchant
    }
}

struct PaymentMessage: Codable {
    let cryptoCurrency: String
    let transactionHash: String
    
    enum CodingKeys: String, CodingKey {
        case cryptoCurrency = "crypto_currency"
        case transactionHash = "transaction_hash"
    }
}

public extension Decodable {
    static func decode(data: Data) throws -> Self {
        let decoder = JSONDecoder()
        return try decoder.decode(Self.self, from: data)
    }
}

public extension Encodable {
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }
}

public class MantaWallet: CocoaMQTTDelegate {
    var mqtt: CocoaMQTT
    var sessionID: Int
    var paymentRequest: PaymentRequestMessage?
    let port: Int
    let host: String
    
    
    private var connectPromise: Promise<Void>?
    var getPaymentPromise: Promise<PaymentRequestMessage>?
    
    static func parseURL (_ url: String) -> [String] {
        let pattern = "^manta:\\/\\/((?:\\w|\\.)+)(?::(\\d+))?\\/(\\d+)$"
        return url.capturedGroups(withRegex: pattern)
    }
    
    public init? (_ url: String) {

        let results = MantaWallet.parseURL(url)
        
        if results.count < 2 { return nil}
        
        self.host = results[0]
        self.sessionID = Int(results[results.count-1])!
        self.port = results.count == 3 ? Int(results[1])! : 1883
        
        //mqtt = CocoaMQTT(clientID: "testClient", host:"www.google.com", port:8080)
        print ("NEW MANTA WALLET")
        mqtt = CocoaMQTT(clientID: "testClient", host: host, port: UInt16(port))
        mqtt.delegate = self
        mqtt.autoReconnect = true
        
    }
    
    deinit {
        print ("Destroyed manta wallet")
        mqtt.disconnect()
    }
    
    func connect () -> Promise <Void> {
        if mqtt.connState == .connected {return Promise(())}
        
        mqtt.connect()
        connectPromise = Promise<Void>.pending()
        return connectPromise!
        
    }
    
    func getPaymentRequest_() {
        mqtt.subscribe("/payment_requests/\(self.sessionID)")
    }
    
    public func getPaymentRequest() -> Promise <PaymentRequestMessage> {
        
        connect().then {
            self.getPaymentRequest_()
        }
        
        getPaymentPromise = Promise<PaymentRequestMessage>.pending()
        
        return getPaymentPromise!
        
    }
    
    func sendPayment_(cryptoCurrency:String, hashes:String) {
        let jsonEncoder = JSONEncoder()
        let paymentMessage = PaymentMessage (cryptoCurrency: cryptoCurrency, transactionHash: hashes)
        guard let jsonData = try? jsonEncoder.encode(paymentMessage) else { return }
        
        mqtt.publish("/payments/\(self.sessionID)", withString: String(data: jsonData, encoding: .utf8)!)
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        connectPromise?.fulfill(())
        print("connack")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        let tokens = message.topic.split(separator:"/")
        print(message.topic)
        print(message.string!)
        
        switch tokens[0] {
        case "payment_requests":
            print("Got Payment Request")
            
            let jsonDecoder = JSONDecoder()
            do {
                let paymentRequestMessage = try jsonDecoder.decode(PaymentRequestMessage.self, from: Data(bytes: message.payload))
                self.paymentRequest = paymentRequestMessage
                getPaymentPromise?.fulfill(paymentRequestMessage)
            }
            catch {
                print ("\(error)")
            }
            
        default:
            print ("Unknown case")
        }
        
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        
    }
    
    public func mqttDidPing(_ mqtt: CocoaMQTT) {
        
    }
    
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        
    }
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        //print(err)
        
    }
}


