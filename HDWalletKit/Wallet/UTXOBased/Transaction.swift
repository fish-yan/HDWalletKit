//
//  BitcoinTransaction.swift
//  HDWalletKit
//
//  Created by Pavlo Boiko on 1/8/19.
//  Copyright © 2019 Essentia. All rights reserved.
//

import Foundation

/// tx describes a bitcoin transaction, in reply to getdata
public struct Transaction {
    public var segWit: Bool = false
    /// Transaction data format version (note, this is signed)
    public let version: UInt32
    /// If present, always 0001, and indicates the presence of witness data
    // public let flag: UInt16 // If present, always 0001, and indicates the presence of witness data
    /// Number of Transaction inputs (never zero)
    public var txInCount: VarInt {
        return VarInt(inputs.count)
    }
    /// A list of 1 or more transaction inputs or sources for coins
    public let inputs: [TransactionInput]
    /// Number of Transaction outputs
    public var txOutCount: VarInt {
        return VarInt(outputs.count)
    }
    /// A list of 1 or more transaction outputs or destinations for coins
    public let outputs: [TransactionOutput]
    /// A list of witnesses, one for each input; omitted if flag is omitted above
    // public let witnesses: [TransactionWitness] // A list of witnesses, one for each input; omitted if flag is omitted above
    /// The block number or timestamp at which this transaction is unlocked:
    public let lockTime: UInt32
    
    public var txHash: Data {
        return serialized().doubleSHA256
    }
    
    public var txID: String {
        return Data(txHash.reversed()).hex
    }
    
    public init(version: UInt32, inputs: [TransactionInput], outputs: [TransactionOutput], lockTime: UInt32, segWit: Bool = false) {
        self.version = version
        self.inputs = inputs
        self.outputs = outputs
        self.lockTime = lockTime
        self.segWit = segWit
    }
    
    public func serialized() -> Data {
        var data = Data()
        data += version
        if segWit {
            data += UInt8(0)       // marker 0x00
            data += UInt8(1)       // flag 0x01
        }
        data += txInCount.serialized()
        data += inputs.flatMap { $0.serialized() }
        data += txOutCount.serialized()
        data += outputs.flatMap {
            return $0.serialized()
        }
        print(data.hex)
        if segWit {
            data += inputs.flatMap { Transaction.serialize(dataList: $0.witnessData) }
        }
        print(data.hex)
        data += lockTime
        print(data.hex)
        return data
    }

    static func serialize(dataList: [Data]) -> Data {
        var data = Data()
        data += VarInt(dataList.count).serialized()
        for witness in dataList {
            data += VarInt(witness.count).serialized() + witness
        }
        return data
    }
    
    public func isCoinbase() -> Bool {
        return inputs.count == 1 && inputs[0].isCoinbase()
    }
    
    public static func deserialize(_ data: Data) -> Transaction {
        let byteStream = ByteStream(data)
        return deserialize(byteStream)
    }
    
    static func deserialize(_ byteStream: ByteStream) -> Transaction {
        let version = byteStream.read(UInt32.self)
        let txInCount = byteStream.read(VarInt.self)
        var inputs = [TransactionInput]()
        for _ in 0..<Int(txInCount.underlyingValue) {
            inputs.append(TransactionInput.deserialize(byteStream))
        }
        let txOutCount = byteStream.read(VarInt.self)
        var outputs = [TransactionOutput]()
        for _ in 0..<Int(txOutCount.underlyingValue) {
            outputs.append(TransactionOutput.deserialize(byteStream))
        }
        let lockTime = byteStream.read(UInt32.self)
        return Transaction(version: version, inputs: inputs, outputs: outputs, lockTime: lockTime)
    }
}
