# Token Report Crowdsale Contract Audit

<br />

## Summary

[Token Report](http://tokenreport.com/) intends to run a [crowdsale](http://tokenreport.com/ico.html) commencing in October 2017.

Token Report's white paper can be found [here](http://tokenreport.com/assets/white-paper.pdf).

Bok Consulting Pty Ltd was commissioned to perform an audit on the Ethereum smart contracts for Token Report's token contracts.

No potential vulnerabilities have been identified in this token contract.

There are some differences in the token contract behaviour compared to the recently finalised ERC20 token standard, but none of these are significant.

<br />

## Token Contract

The token contract consist of *Token*, *Controller* and *Ledger* contracts working together. Funds collected during the crowdsale will be used to
calculate the token balances in this token contract, and the token balances will be minted in this token contract by an external program executing
the `Ledger.multiMint(...)` function. Once the minting is completed, the `Ledger.stopMinting()` function is execute to prevent any further token
minting.

The source code for this audit have been extracted from the verified source code on EtherScan:

* [Token](contracts/Token.sol) from [0xc931eac3b736f3a956b2973ddb4128c36c5c7add](https://etherscan.io/address/0xc931eac3b736f3a956b2973ddb4128c36c5c7add#code).

* [Controller](contracts/Controller.sol) from [0x179915bdc3846bc87730c26d6ec20996bfce5e20](https://etherscan.io/address/0x179915bdc3846bc87730c26d6ec20996bfce5e20#code).

* [Ledger](contracts/Ledger.sol) from [0x025db0ad4f49ae49102246bbb5120a619e9562c0](https://etherscan.io/address/0x025db0ad4f49ae49102246bbb5120a619e9562c0#code).

Note that source code is exactly the same in each of these three source code files, as expected.

Together, the contracts provide the general functionality required of an [ERC20 Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md)
token. There are some slight difference in behaviour compared to this recently (Sep 11 2017) finalised standard and these differences are listed
below:

* `Token.transfer(...)` returns false if there are insufficient tokens to transfer. In the recently finalised ERC20 token standard:

  > The function **SHOULD throw** if the _from account balance does not have enough tokens to spend.

  `Token.transfer(...)` returns false as required under the previous un-finalised version of the ERC20 token standard

* `Token.transferFrom(...)` returns false if there are insufficient tokens to transfer or insufficient tokens have been approved for transfer.
  In the recently finalised ERC20 token standard:

  > The function **SHOULD throw** unless the _from account has deliberately authorized the sender of the message via some mechanism

  `Token.transferFrom(...)` returns false as required under the previous un-finalised version of the ERC20 token standard

* `Token.approve(...)` requires that a non-0 approval limit be set to 0 before being modified to another non-0 approval limit. In the recently
  finalised ERC20 token standard:

  > ... clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value
  > for the same spender. **THOUGH The contract itself shouldn't enforce it**, to allow backwards compatilibilty with contracts deployed before

  `Token.approve(...)` implements the requirement to set a non-0 approval limit to 0 before modifying the limit to another non-0 approval limit
  that was a standard practice for ERC20 tokens before the recent ERC20 token standard was finalised 

* `Token.transfer(...)`, `Token.approve(...)` and `Token.transferFrom(...)` all implement the `onlyPayloadSize(...)` check that was recently
  relatively common in ERC20 token contracts, but has now been generally discontinued as it was found to be ineffective. See
  [Smart Contract Short Address Attack Mitigation Failure](https://blog.coinfabrik.com/smart-contract-short-address-attack-mitigation-failure/)
  for further information. The version used in the *Token* contract checks for a minimum payload size (using the `>=` operator) and should not
  cause any problems with multisig wallets as documented in the link.

None of the differences above are significant to the workings of an ERC20 token.

<br />

### Note

* Transfers in the *Token* contract can be paused and un-paused by the token contract owner, at any time

* The owner of the *Token*, *Controller* and *Ledger* contracts can use the `setToken(...)`, `setController(...)` and `setLedger(...)` functions
  to bypass the intended permissioning in this system of contracts and execute some of the functions with irregular operations. As an example,
  the owner of *Ledger* can call `setController({owner account})` and then execute `burn(...)` to burn the tokens of **any** account

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Potential Vulnerabilities](#potential-vulnerabilities)
* [Scope](#scope)
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

## Potential Vulnerabilities

No potential vulnerabilities have been identified in this token contract.

<br />

<hr />

## Scope

This audit is into the technical aspects of the token contract. The aim of this audit is to ensure that token balances and transfers
cannot easily be attacked or stolen by third parties. This audit does not guarantee that that the code is bugfree, but intends to
highlight any areas of weaknesses.

<br />

<hr />

## Testing

The following functions were tested using the script [test/01_test1.sh](test/01_test1.sh) with the summary results saved
in [test/test1results.txt](test/test1results.txt) and the detailed output saved in [test/test1output.txt](test/test1output.txt):

* [x] Deploy  *Token*, *Controller* and *Ledger* contracts
* [x] Stitch the *Token*, *Controller* and *Ledger* contracts together
* [x] Mint tokens
* [x] Switch off minting
* [x] Execute `transfer(...)`, `approve(...)` and `transferFrom(...)` of tokens
* [x] Execute invalid `transfer(...)`, `approve(...)` and `transferFrom(...)` of tokens
* [x] Execute `transfer(...)`, `approve(...)` and `transferFrom(...)` of 0 tokens

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

* [x] `Token.approve(...)`
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

Each of the *Token* functions listed above can be executed by **any account**, but will only apply to the token balances the particular account
has the permission to operate on.

<br />

<br />

(c) BokkyPooBah / Bok Consulting Pty Ltd for Token Report - Oct 18 2017. The MIT Licence.