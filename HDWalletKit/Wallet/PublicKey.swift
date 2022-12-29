//
//  PublicKey.swift
//  HDWalletKit
//
//  Created by Pavlo Boiko on 10/4/18.
//  Copyright © 2018 Essentia. All rights reserved.
//

import Foundation
import CryptoSwift
import secp256k1

public struct PublicKey {
    public let compressedPublicKey: Data
    public let uncompressedPublicKey: Data
    public let coin: Coin
    
    public init(privateKey: Data, coin: Coin) {
        self.compressedPublicKey = Crypto.generatePublicKey(data: privateKey, compressed: true)
        self.uncompressedPublicKey = Crypto.generatePublicKey(data: privateKey, compressed: false)
        self.coin = coin
    }
    
    public init(base58: Data, coin: Coin) {
        let publickKey = Base58.encode(base58)
        self.compressedPublicKey = Data(hex: publickKey)
        self.uncompressedPublicKey = Data(hex: publickKey)
        self.coin = coin
    }
    
    // NOTE: https://github.com/bitcoin/bips/blob/master/bip-0013.mediawiki
    public var address: String {
        switch coin {
        case .dogecoin: fallthrough
        case .bitcoin: fallthrough
        case .dash: fallthrough
        case .bitcoinCash: fallthrough
        case .litecoinTest: fallthrough
        case .litecoin:
            return generateBtcAddress()
        case .ethereum:
            return generateEthAddress()
        }
    }
    
    public var utxoAddress: Address {
        switch coin {
        case .bitcoin, .litecoin, .litecoinTest, .dash, .bitcoinCash, .dogecoin:
            return try! LegacyAddress(address, coin: coin)
        case .ethereum:
            fatalError("Coin does not support UTXO address")
        }
    }

    public var utxoSegWitAddress: Address {
        switch coin {
        case .bitcoin, .litecoin, .litecoinTest, .dash, .bitcoinCash, .dogecoin:
            return try! LegacyAddress(generateBtc49Address(), coin: coin)
        case .ethereum:
            fatalError("Coin does not support UTXO address")
        }
    }
    
    func generateBtcAddress() -> String {
        let prefix = Data([coin.publicKeyHash])
        let payload = RIPEMD160.hash(compressedPublicKey.sha256())
        let checksum = (prefix + payload).doubleSHA256.prefix(4)
        return Base58.encode(prefix + payload + checksum)
    }

    public func generateBtc49Address() -> String {
        let prefix = Data([coin.scriptHash])
        let payload = RIPEMD160.hash(compressedPublicKey.sha256())
        let payload1 = RIPEMD160.hash(PriOpCode.scriptWPKH(payload).sha256())
        let checksum = (prefix + payload1).doubleSHA256.prefix(4)
        return Base58.encode(prefix + payload1 + checksum)
    }
    
    func generateCashAddress() -> String {
        let prefix = Data([coin.publicKeyHash])
        let payload = RIPEMD160.hash(compressedPublicKey.sha256())
        return Bech32.encode(prefix + payload, prefix: coin.scheme)
    }
    
    func generateEthAddress() -> String {
        let formattedData = (Data(hex: coin.addressPrefix) + uncompressedPublicKey).dropFirst()
        let addressData = Crypto.sha3keccak256(data: formattedData).suffix(20)
        return coin.addressPrefix + EIP55.encode(addressData)
    }
    
    public func get() -> String {
        return compressedPublicKey.toHexString()
    }
    
    public var data: Data {
        return Data(hex: get())
    }
}

class PriOpCode {
    public static let p2pkhStart = Data([PriOpCode.dup, PriOpCode.hash160])
    public static let p2pkhFinish = Data([PriOpCode.equalVerify, PriOpCode.checkSig])

    public static let pushData1: UInt8 = 0x4c
    public static let pushData2: UInt8 = 0x4d
    public static let pushData4: UInt8 = 0x4e

    public static let dup: UInt8 = 0x76
    public static let hash160: UInt8 = 0xA9

    public static let equalVerify: UInt8 = 0x88
    public static let checkSig: UInt8 = 0xAC

    public static func push(_ value: Int) -> Data {
        guard value != 0 else {
            return Data([0])
        }
        guard value <= 16 else {
            return Data()
        }
        return Data([UInt8(value + 0x50)])
    }

    public static func push(_ data: Data) -> Data {
        let length = data.count
        var bytes = Data()

        switch length {
        case 0x00...0x4b: bytes = Data([UInt8(length)])
        case 0x4c...0xff: bytes = Data([PriOpCode.pushData1]) + UInt8(length).littleEndian
        case 0x0100...0xffff: bytes = Data([PriOpCode.pushData2]) + UInt16(length).littleEndian
        case 0x10000...0xffffffff: bytes = Data([PriOpCode.pushData4]) + UInt32(length).littleEndian
        default: return data
        }

        return bytes + data
    }

    public static func scriptWPKH(_ data: Data, versionByte: Int = 0) -> Data {
        return PriOpCode.push(versionByte) + PriOpCode.push(data)
    }
}
