# Token Report Crowdsale Contract Audit

<br />

## Summary

[Token Report](http://tokenreport.com/) intends to run a [crowdsale](http://tokenreport.com/ico.html) commencing in October 2017.

Token Report's white paper can be found [here](http://tokenreport.com/assets/white-paper.pdf).

Bok Consulting Pty Ltd was commissioned to perform an audit on the Ethereum smart contracts for Token Report's crowdsale.

The source code for the audit are:

* [Ledger](contracts/Ledger.sol) from [0x025db0ad4f49ae49102246bbb5120a619e9562c0](https://etherscan.io/address/0x025db0ad4f49ae49102246bbb5120a619e9562c0#code).

* [Controller](contracts/Controller.sol) from [0x179915bdc3846bc87730c26d6ec20996bfce5e20](https://etherscan.io/address/0x179915bdc3846bc87730c26d6ec20996bfce5e20#code).

* [Token](contracts/Token.sol) from [0xc931eac3b736f3a956b2973ddb4128c36c5c7add](https://etherscan.io/address/0xc931eac3b736f3a956b2973ddb4128c36c5c7add#code).

Note that the Ledger, Controller and Token contracts are included in each of the source file above.

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Notes](#notes)
* [Testing](#testing)
* [Code Review](#code-review)
  * [Check On Calls And Permissions](#check-on-calls-and-permissions)
    * [General Functions](#general-functions)
    * [Token Specific Functions](#token-specific-functions)
    * [Controller Specific Functions](#controller-specific-functions)
    * [Ledger Specific Functions](#ledger-specific-functions)
    * [Transfer And Other Functions That Can Be Called By Any Account](#transfer-and-other-functions-that-can-be-called-by-any-account)

<br />

<hr />

## Notes

* In *Token*, `transfer(...)`, `transferFrom(...)` and `approve(...)` have the `onlyPayloadSize(...)` check. This check was found to be
  ineffective and newly deployed token contracts generally do not include this check. See
  [Smart Contract Short Address Attack Mitigation Failure](https://blog.coinfabrik.com/smart-contract-short-address-attack-mitigation-failure/)
  for further information. The implementation in the *Token* contract has the check for the payload being greater than or equals to a specified
  number (`>=`) instead of being exactly equals to a specified number (`==`) and should not cause any technical issues if left in the code

<br />

<hr />

## Testing


<br />

<hr />

## Code Review

* [x] [code-review/Token.md](code-review/Token.md)
  * [x] contract SafeMath 
  * [x] contract Owned 
  * [x] contract Pausable is Owned 
  * [x] contract Finalizable is Owned 
  * [x] contract IToken 
  * [x] contract TokenReceivable is Owned 
  * [x] contract EventDefinitions 
  * [x] contract Token is Finalizable, TokenReceivable, SafeMath, EventDefinitions, Pausable 
  * [x] contract Controller is Owned, Finalizable 
  * [x] contract Ledger is Owned, SafeMath, Finalizable 

<br />

### Check On Calls And Permissions

This section looks across the permissions required to execute the non-constant functions in these set of contracts.

#### General Functions

All three main contracts *Token*, *Controller* and *Ledger* are derived from *Finalizable* which is derived from Owned. They all implement
`Finalizable.finalize()` that can only be called by the **owner**. They also implement `Owned.changeOwner(...)` that can only be called by
**owner**, and `Owned.acceptOwnership()` that can only be called by the new intended owner.

<br />

#### Token Specific Functions

* [x] *Token* additionally is derived from *TokenReceivable* that implements `TokenReceivable.claimTokens(...)` and this can only be called **owner**

* [x] `Token.setController(...)` can only be called by **owner**

* [x] `Token.controllerApprove(...)` can only be called by *Controller*. As *Controller* does not have any functions to call
  `Token.controllerApprove(...)`, this function is redundant

<br />

#### Controller Specific Functions

* [x] *Controller* has a `Controller.setToken(...)` and `Controller.setLedger(...)` that can only be called by **owner**

<br />

#### Ledger Specific Functions

* [x] `Ledger.multiMint(...)` can only be called by **owner**
  * [x] -> `Contoller.ledgerTransfer(...)` that can only be called by *Ledger*
    * [x] -> `Token.controllerTransfer(...)` that can only be called by *Controller*

* [x] *Ledger* has a `Ledger.setController(...)` and a `Ledger.stopMinting(...)` that can only be called by **owner**

<br />

#### Transfer And Other Functions That Can Be Called By Any Account

Following are the *Token* functions that can be executed by **any account**

* [x] `Token.transfer(...)`
  * [x] -> `Controller.transfer(...)` that can only be called by *Token*
    * [x] -> `Ledger.transfer(...)` that can only be called by Controller

* [x] `Token.transferFrom(...)`
  * [x] -> `Controller.transferFrom(...)` that can only be called by *Token*
    * [x] -> `Ledger.transferFrom(...)` that can only be called by Controller

* [x] Token.approve(...)
  * [x] -> `Controller.approve(...)` that can only be called by *Token*
    * [x] -> `Ledger.approve(...)` that can only be called by Controller

* [x] `Token.increaseApproval(...)`
  * [x] -> `Controller.increaseApproval(...)` that can only be called by *Token*
    * [x] -> `Ledger.increaseApproval(...)` that can only be called by Controller

* [x] `Token.decreaseApproval(...)`
  * [x] -> `Controller.decreaseApproval(...)` that can only be called by *Token*
    * [x] -> `Ledger.decreaseApproval(...)` that can only be called by Controller

* [x] `Token.burn(...)`
  * [x] -> `Controller.burn(...)` that can only be called by *Token*
    * [x] -> `Ledger.burn(...)` that can only be called by Controller


