//
//  Coin.swift
//  HDWalletKit
//
//  Created by Pavlo Boiko on 10/3/18.
//  Copyright © 2018 Essentia. All rights reserved.
//

import Foundation

public enum Coin {
    case bitcoin
    case ethereum
    case litecoin
    case litecoinTest
    case bitcoinCash
    case dash
    case dogecoin
    
    //https://github.com/satoshilabs/slips/blob/master/slip-0132.md
    public var privateKeyVersion: UInt32 {
        switch self {
        case .litecoin:
            return 0x019D9CFE
        case .litecoinTest:
            return 0x04358394
        case .bitcoinCash: fallthrough
        case .bitcoin:
            return 0x0488ADE4
        case .dash:
            return 0x02FE52CC
        case .dogecoin:
            return 0x0488E1F4
        default:
            fatalError("Not implemented")
        }
    }
    // P2PKH
    public var publicKeyHash: UInt8 {
        switch self {
        case .litecoin:
            return 0x30
        case .litecoinTest:
            return 0x6F
        case .bitcoinCash: fallthrough
        case .bitcoin:
            return 0x00
        case .dash:
            return 0x4C
        case .dogecoin:
            return 0x1E
        default:
            fatalError("Not implemented")
        }
    }
    
    // P2SH
    public var scriptHash: UInt8 {
        switch self {
        case .bitcoinCash: fallthrough
        case .litecoin:
            return 0x32
        case .bitcoin:
            return 0x05
        case .litecoinTest:
            return 0x3A
        case .dash:
            return 0x10
        case .dogecoin:
            return 0x16
        default:
            fatalError("Not implemented")
        }
    }
    
    //https://www.reddit.com/r/litecoin/comments/6vc8tc/how_do_i_convert_a_raw_private_key_to_wif_for/
    public var wifAddressPrefix: UInt8 {
        switch self {
        case .dogecoin:
            return 0x9E
        case .bitcoinCash: fallthrough
        case .bitcoin:
            return 0x80
        case .litecoin:
            return 0xB0
        case .litecoinTest:
            return 0xEF
        case .dash:
            return 0xCC
        default:
            fatalError("Not implemented")
        }
    }
    
    public var addressPrefix:String {
        switch self {
        case .ethereum:
            return "0x"
        default:
            return ""
        }
    }
    
    public var uncompressedPkSuffix: UInt8 {
        return 0x01
    }
    
    
    public var coinType: UInt32 {
        switch self {
        case .bitcoin:
            return 0
        case .litecoinTest:
            return 1
        case .litecoin:
            return 2
        case .dash:
            return 5
        case .dogecoin:
            return 3
        case .ethereum:
            return 60
        case .bitcoinCash:
            return 145
        }
    }
    
    public var scheme: String {
        switch self {
        case .bitcoin:
            return "bitcoin"
        case .litecoin:
            return "litecoin"
        case .litecoinTest:
            return "litecointest"
        case .bitcoinCash:
            return "bitcoincash"
        case .dogecoin:
            return "dogecoin"
        case .dash:
            return "dash"
        default: return ""
        }
    }
    
    public var dust: UInt64 {
        switch self {
        case .bitcoin: 564
        case .litecoin: 100000
        default: 0
        }
    }
}
