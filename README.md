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

* [ ] [code-review/Token.md](code-review/Token.md)
  * [x] contract SafeMath 
  * [x] contract Owned 
  * [x] contract Pausable is Owned 
  * [x] contract Finalizable is Owned 
  * [x] contract IToken 
  * [x] contract TokenReceivable is Owned 
  * [x] contract EventDefinitions 
  * [ ] contract Token is Finalizable, TokenReceivable, SafeMath, EventDefinitions, Pausable 
  * [ ] contract Controller is Owned, Finalizable 
  * [ ] contract Ledger is Owned, SafeMath, Finalizable 

