# TezosKit 

[![Build Status](https://travis-ci.org/keefertaylor/TezosKit.svg?branch=master)](https://travis-ci.org/keefertaylor/TezosKit)
[![codecov](https://codecov.io/gh/keefertaylor/TezosKit/branch/master/graph/badge.svg)](https://codecov.io/gh/keefertaylor/TezosKit)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/TezosKit.svg?style=flat)](http://cocoapods.org/pods/TezosKit)
[![License](https://img.shields.io/cocoapods/l/TezosKit.svg?style=flat)](http://cocoapods.org/pods/TezosKit)

TezosKit is a Swift library that is compatible with the [Tezos Blockchain](https://tezos.com). TezosKit implements communication with the blockchain via the JSON API.

Donations help me find time to work on TezosKit. If you find the library useful, please consider donating to support ongoing develoment.

|Currency| Address |
|---------|---|
| __Tezos__ | tz1SNXT8yZCwTss2YcoFi3qbXvTZiCojx833 |
| __Bitcoin__ | 1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo |
| __Bitcoin Cash__ | qqpr9are9gzs5r0q7hy3gdehj3w074pyqsrhpdmxg6 |


## Functionality

TezosKit provides first class support for the following RPCs:
* Getting account balances
* Getting data about the chain head
* Getting account delegates 
* Generating and restoring wallets 
* Sending transactions between accounts
* Sending multiple operations in a single request
* Setting / clearing delegates
* Registering as a delegate
* Originating accounts
* Examining upgrade votes
* Deploying / Examining / Calling smart contracts

The library is extensible allowing client code to easily create additional RPCs and signed operations, as required. 

TesosKit takes care of complex block chain interactions for you:
* Addresses are revealed automatically, if needed
* Sending multiple operations by passing them in an array

## Installation

### CocoaPods
TezosKit supports installation via CocoaPods. You can depened on TezosKit by adding the following to your Podfile:

```
pod "TezosKit"
```

### Carthage

If you use [Carthage](https://github.com/Carthage/Carthage) to manage your dependencies, simply add
TezosKit to your `Cartfile`:

 ```
github "keefertaylor/TezosKit"
```

 If you use Carthage to build your dependencies, make sure you have added `Base58Swift.framework`, `BigInt.framework`, `MnemonicKit.framework`,  and `PromiseKit.framework`, `Sodium.framework` and `TezosCrypto.framework`, to the "_Linked Frameworks and Libraries_" section of your target, and have included them in your Carthage framework copying build phase.

## Getting Started

TezosKit supports `Promise` style RPCs (in the `PromiseKit` variant), or block based callback's with `Result` types. All RPCs support both variants out of the box.

### Create a Network Client

```swift
let publicNodeURL = URL(string: "https://rpc.tezrpc.me")!
let tezosNodeClient = TezosNodeClient(remoteNodeURL: publicNodeURL)
```

### Retrieve Data About the Blockchain

```swift
tezosNodeClient.getHead() { result in
  switch result {
  case .success(let result):
    guard let metadata: = result["metadata"] as? [String : Any],
          let baker = metadata["baker"]  else {
      print("Unexpected format")
      return
    }
    print("Baker of the block at the head of the chain is \(baker)")
  case .failure(let error):
    print("Error getting result: \(error)")
  }
```

### Retrieve Data About a Contract

```swift
let address = "KT1BVAXZQUc4BGo3WTJ7UML6diVaEbe4bLZA" // http://tezos.community
tezosNodeClient.getBalance(address: address) { result in
  switch result {
  case .success(let balance):
    print("Balance of \(address) is \(balance.humanReadableRepresentation)")
  case .failure(let error):
    print("Error getting result: \(error)")
  }
}
```

### Create a Wallet

```swift
let wallet = Wallet()
print("New wallet mnemonic is: \(wallet.mnemonic)")
```

### Send a Transaction

```swift
let wallet = Wallet()
let sendAmount = Tez(1.0)!
let recipientAddress = ...
tezosNodeClient.send(
  amount: sendAmount,
  to recipientAddress: recipientAddress,
  from address: wallet.address,
  secretKey: wallet.secretKey
) { (txHash, txError) in 
  print("Transaction sent. See: https://tzscan.io/\(txHash!)")
}
```

### Send Multiple Transactions at Once

Here's an example of how you can send multiple transactions at once. You 
can easily send Jim and Bob some XTZ in one call:

```swift
let myWallet: Wallet = ...
let jimsAddress: String = tz1...
let bobsAddress: String = tz1...

let amountToSend = Tez("2")!

let sendToJimOperation = TransactionOperation(amount: amountToSend,
                                              source: myWallet,
                                              destination: jimsAddress)
let sendToBobOperation = TransactionOperation(amount: amountToSend,
                                              source: myWallet,
                                              destination: bobsAddress)

let operations = [ sendToJimOperation, sendToBobOperation ]
tezosNodeClient.forgeSignPreapplyAndInjectOperations(
  operations: operations,
  source: myWallet.address,
  keys: myWallet.keys
) { result in
  guard case let .success(txHash) = result else {
    return
  }
  print("Sent Jim and Bob some XTZ! See: https://tzscan.io/\(txHash!)")
}
```

### Set a Delegate

```swift
let wallet = ...
let originatedAccountAddress = <Some Account Managed By Wallet>
let delegateAddress = ...
tezosNodeClient.delegate(
  from: originatedAccountAddress,
  to: delegateAddress,
  keys: wallet.keys
) { result in
  guard case let .success(txHash) = result else {
    return
  }
  print("Delegate for \(originatedAccountAddress) set to \(delegateAddress).")
  print("See: https://tzscan.io/\(txHash!)")
}

```
### Fetch the code of a Smart Contract

```swift
  let contractAddress: String = ...
  tezosNodeClient.getAddressCode(address: contractAddress) { result in
     ...
  }
```  

### Deploy a Smart Contract 

```swift
  let wallet: Wallet = ...
  let code: ContractCode = ...
  tezosNodeClient.originateAccount(
    managerAddress: wallet.address, 
    keys: wallet.keys,
    contractCode: contractCode
  ) { result in
    guard case let .success(txHash) = result else {
      return
    }
    print("Originated a smart contract. See https://tzscan.io/\(txHash!)")
  }
```

### Call a Smart Contract

Assuming a smart contract takes a single string as an argument:

```swift
let txAmount: Tez = ...
let wallet: Wallet = ...
let contractAddr: String = ...
let parameters = ["string": "argument_to_smart_contract"]   
tezosNodeClient.send(
  amount: txAmount, 
  to: contractAddr, 
  from: wallet.address,  
  keys: wallet.keys, 
  parameters: parameters
) { result in
  guard case let .success(txHash) = result else {
    return
  }
  print("Called a smart contract. See https://tzscan.io/\(txHash!)")
}
```

### PromiseKit Variants

All RPCs can also be done with Promises. For instance, to retrieve a balance: 
```
nodeClient.getBalance(address: "KT1BVAXZQUc4BGo3WTJ7UML6diVaEbe4bLZA").done { result in
  let balance = Double(result.humanReadableRepresentation)!
  print("The balance of the contract is \(balance)")
} .catch { _ in
  print("Couldn't get balance.")
}
```

## Detailed Documentation

### Overview

The core components are: 
- *TezosNodeClient* - A gateway to a node that operates in the Tezos Blockchain.
- *RPC* - A superclass for all RPC objects. RPCs are responsible for making a request to an RPC endpoint and decoding the response.
- *ResponseAdapter* - Utilized to transform raw response data into a first class object.
- *Operation* - Representations of operations that can be committed to the blockchain.
- *OperationFees* - Represents the fee, gas limit and storage limit used when injecting an operation.
- *Wallet* - Represents an address on the blockchain and a set of keys to manage that address.
- *Crypto* - Cryptographic functions.

TODO: Describe interaction between these objects and how to exend RPCs and Operations. *In the meantime, check out the class comments on TezosNodeClient.swift*.

### Fees

The `OperationFees` object encapsulates the fee, gas limit and storage limit to inject an operation onto the blockchain. Every `Operation` object contains a default set of fees taken from [eztz](https://github.com/TezTech/eztz/blob/master/PROTO_003_FEES.md). Clients can pass custom `OperationFees` objects when creating Operations to define their own fees. 

## Contributing

Please open PRs or issues against the library. 

## License

MIT
