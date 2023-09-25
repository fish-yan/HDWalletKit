//
//  UTXOWallet.swift
//  HDWalletKit
//
//  Created by Pavlo Boiko on 2/19/19.
//  Copyright © 2019 Essentia. All rights reserved.
//

import Foundation

final public class UTXOWallet {
    public let privateKey: PrivateKey
    public var txID: String = ""
    public var fee: UInt64 = 0

    private static let dustThreshhold: UInt64 = 100000
    
    public let utxoSelector: UtxoSelectorInterface
    private let utxoTransactionBuilder: UtxoTransactionBuilderInterface
    private let utoxTransactionSigner: UtxoTransactionSignerInterface
    
    public convenience init(privateKey: PrivateKey) {
        switch privateKey.coin {
        case .bitcoin, .litecoin, .litecoinTest, .dash, .bitcoinCash:
            self.init(privateKey: privateKey,
                      utxoSelector: UtxoSelector(dustThreshhold: UTXOWallet.dustThreshhold),
                      utxoTransactionBuilder: UtxoTransactionBuilder(),
                      utoxTransactionSigner: UtxoTransactionSigner())
        default:
            fatalError("Coin not supported yet")
        }
    }
    
    public init(privateKey: PrivateKey,
                utxoSelector: UtxoSelectorInterface,
                utxoTransactionBuilder: UtxoTransactionBuilderInterface,
                utoxTransactionSigner: UtxoTransactionSignerInterface) {
        self.privateKey = privateKey
        self.utxoSelector = utxoSelector
        self.utxoTransactionBuilder = utxoTransactionBuilder
        self.utoxTransactionSigner = utoxTransactionSigner
    }
    
    public func createTransaction(to toAddress: Address, amount: UInt64, utxos: [UnspentTransaction], feeRate: UInt64 = 1) throws -> String {
        let (utxosToSpend, fee) = try self.utxoSelector.select(from: utxos, targetValue: amount, segWit: false)
        let totalAmount: UInt64 = utxosToSpend.sum()
        let change: UInt64 = totalAmount - amount - fee
        var destinations: [(Address, UInt64)] = [(toAddress, amount)]
        if change >= UTXOWallet.dustThreshhold { // 找零太小就不找零
            destinations.append((privateKey.publicKey.utxoAddress, change))
        }
        let unsignedTx = try self.utxoTransactionBuilder.build(destinations: destinations, utxos: utxosToSpend)
        let signedTx = try self.utoxTransactionSigner.sign(unsignedTx, with: self.privateKey)
        self.txID = signedTx.txID
        self.fee = fee * feeRate
        return signedTx.serialized().hex
    }

    public func createSegWitTransaction(to toAddress: Address, amount: UInt64, utxos: [UnspentTransaction], feeRate: UInt64 = 1) throws -> String {
        let (utxosToSpend, fee) = try self.utxoSelector.select(from: utxos, targetValue: amount, segWit: true)
        let totalAmount: UInt64 = utxosToSpend.sum()
        let change: UInt64 = totalAmount - amount - fee
        var destinations: [(Address, UInt64)] = [(toAddress, amount)]
        if change >= UTXOWallet.dustThreshhold { // 找零太小就不找零
            destinations.append((privateKey.publicKey.utxoSegWitAddress, change))
        }
        let unsignedTx = try self.utxoTransactionBuilder.buildSegWit(destinations: destinations, utxos: utxosToSpend)
        let signedTx = try self.utoxTransactionSigner.signSegWit(unsignedTx, with: self.privateKey)
        self.txID = signedTx.txID
        self.fee = fee * feeRate
        return signedTx.serialized().hex
    }
}
