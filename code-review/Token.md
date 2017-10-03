# Token

Source file [../contracts/Token.sol](../contracts/Token.sol).

<br />

<hr />

```javascript
// Copyright New Alchemy Limited, 2017. All rights reserved.

// BK Ok - Contract deployed with 0.4.16 anyway. Note that there are 48 warnings when compiling with 0.4.17 mainly relating to function visibility
pragma solidity >=0.4.10;

// from Zeppelin
// BK Ok
contract SafeMath {
    // BK Ok
    function safeMul(uint a, uint b) internal returns (uint) {
        // BK Ok
        uint c = a * b;
        // BK Ok
        require(a == 0 || c / a == b);
        // BK Ok
        return c;
    }

    // BK Ok
    function safeSub(uint a, uint b) internal returns (uint) {
        // BK Ok
        require(b <= a);
        // BK Ok
        return a - b;
    }

    // BK Ok
    function safeAdd(uint a, uint b) internal returns (uint) {
        // BK Ok
        uint c = a + b;
        // BK Ok
        require(c>=a && c>=b);
        // BK Ok
        return c;
    }
}

// BK Ok
contract Owned {
    // BK Ok
    address public owner;
    // BK Ok
    address newOwner;

    // BK Ok
    function Owned() {
        // BK Ok
        owner = msg.sender;
    }

    // BK Ok
    modifier onlyOwner() {
        // BK Ok
        require(msg.sender == owner);
        // BK Ok
        _;
    }

    // BK Ok - Only current owner can execute
    function changeOwner(address _newOwner) onlyOwner {
        // BK Ok
        newOwner = _newOwner;
    }

    // BK Ok - Only new owner can accept
    function acceptOwnership() {
        // BK Ok
        if (msg.sender == newOwner) {
            // BK Ok
            owner = newOwner;
        }
    }
}

// BK Ok
contract Pausable is Owned {
    // BK Ok
    bool public paused;

    // BK Ok - Only owner can execute
    function pause() onlyOwner {
        // BK Ok
        paused = true;
    }

    // BK Ok - Only owner can execute
    function unpause() onlyOwner {
        // BK Ok
        paused = false;
    }

    // BK Ok
    modifier notPaused() {
        // BK Ok
        require(!paused);
        // BK Ok
        _;
    }
}

// BK Ok
contract Finalizable is Owned {
    // BK Ok
    bool public finalized;

    // BK Ok - Only owner can execute
    function finalize() onlyOwner {
        // BK Ok
        finalized = true;
    }

    // BK Ok
    modifier notFinalized() {
        // BK Ok
        require(!finalized);
        // BK Ok
        _;
    }
}

// BK Ok
contract IToken {
    // BK Ok
    function transfer(address _to, uint _value) returns (bool);
    // BK Ok
    function balanceOf(address owner) returns(uint);
}

// In case someone accidentally sends token to one of these contracts,
// add a way to get them back out.
// BK Ok
contract TokenReceivable is Owned {
    // BK Ok - Only owner can execute
    function claimTokens(address _token, address _to) onlyOwner returns (bool) {
        // BK Ok
        IToken token = IToken(_token);
        // BK Ok
        return token.transfer(_to, token.balanceOf(this));
    }
}

// BK Ok
contract EventDefinitions {
    // BK Ok
    event Transfer(address indexed from, address indexed to, uint value);
    // BK Ok
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is Finalizable, TokenReceivable, SafeMath, EventDefinitions, Pausable {
    // BK Ok
    string constant public name = "Token Report";
    // BK Ok
    uint8 constant public decimals = 8;
    // BK Ok
    string constant public symbol = "DATA";
    // BK Ok
    Controller public controller;
    // BK Ok
    string public motd;
    // BK Ok - Event
    event Motd(string message);

    // functions below this line are onlyOwner

    // set "message of the day"
    // BK Ok - Only owner can execute
    function setMotd(string _m) onlyOwner {
        // BK Ok
        motd = _m;
        // BK Ok
        Motd(_m);
    }

    // BK Ok - Only owner can execute, when token contract not finalised
    function setController(address _c) onlyOwner notFinalized {
        // BK Ok
        controller = Controller(_c);
    }

    // functions below this line are public

    // BK Ok
    function balanceOf(address a) constant returns (uint) {
        // BK Ok
        return controller.balanceOf(a);
    }

    // BK Ok
    function totalSupply() constant returns (uint) {
        // BK Ok
        return controller.totalSupply();
    }

    // BK Ok
    function allowance(address _owner, address _spender) constant returns (uint) {
        // BK Ok
        return controller.allowance(_owner, _spender);
    }

    // BK Ok
    function transfer(address _to, uint _value) onlyPayloadSize(2) notPaused returns (bool success) {
        // BK Ok
        if (controller.transfer(msg.sender, _to, _value)) {
            // BK Ok - Log event
            Transfer(msg.sender, _to, _value);
            // BK Ok
            return true;
        }
        // BK Ok
        return false;
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3) notPaused returns (bool success) {
        if (controller.transferFrom(msg.sender, _from, _to, _value)) {
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value) onlyPayloadSize(2) notPaused returns (bool success) {
        // promote safe user behavior
        if (controller.approve(msg.sender, _spender, _value)) {
            Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }

    function increaseApproval (address _spender, uint _addedValue) onlyPayloadSize(2) notPaused returns (bool success) {
        if (controller.increaseApproval(msg.sender, _spender, _addedValue)) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
            return true;
        }
        return false;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) onlyPayloadSize(2) notPaused returns (bool success) {
        if (controller.decreaseApproval(msg.sender, _spender, _subtractedValue)) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
            return true;
        }
        return false;
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }

    function burn(uint _amount) notPaused {
        controller.burn(msg.sender, _amount);
        Transfer(msg.sender, 0x0, _amount);
    }

    // functions below this line are onlyController

    modifier onlyController() {
        assert(msg.sender == address(controller));
        _;
    }

    // In the future, when the controller supports multiple token
    // heads, allow the controller to reconstitute the transfer and
    // approval history.

    function controllerTransfer(address _from, address _to, uint _value) onlyController {
        Transfer(_from, _to, _value);
    }

    function controllerApprove(address _owner, address _spender, uint _value) onlyController {
        Approval(_owner, _spender, _value);
    }
}

contract Controller is Owned, Finalizable {
    // BK Ok
    Ledger public ledger;
    // BK Ok
    Token public token;

    // BK Ok - Constructor
    function Controller() {
    }

    // functions below this line are onlyOwner

    // BK Ok - Only owner can execute
    function setToken(address _token) onlyOwner {
        // BK Ok
        token = Token(_token);
    }

    // BK Ok - Only owner can execute
    function setLedger(address _ledger) onlyOwner {
        // BK Ok
        ledger = Ledger(_ledger);
    }

    // BK Ok
    modifier onlyToken() {
        // BK Ok
        require(msg.sender == address(token));
        // BK Ok
        _;
    }

    // BK Ok
    modifier onlyLedger() {
        // BK Ok
        require(msg.sender == address(ledger));
        // BK Ok
        _;
    }

    // public functions

    // BK Ok
    function totalSupply() constant returns (uint) {
        // BK Ok
        return ledger.totalSupply();
    }

    // BK Ok
    function balanceOf(address _a) constant returns (uint) {
        // BK Ok
        return ledger.balanceOf(_a);
    }

    // BK Ok
    function allowance(address _owner, address _spender) constant returns (uint) {
        // BK Ok
        return ledger.allowance(_owner, _spender);
    }

    // functions below this line are onlyLedger

    // let the ledger send transfer events (the most obvious case
    // is when we mint directly to the ledger and need the Transfer()
    // events to appear in the token)
    function ledgerTransfer(address from, address to, uint val) onlyLedger {
        token.controllerTransfer(from, to, val);
    }

    // functions below this line are onlyToken

    // BK Ok - Can only be called from the token contract
    function transfer(address _from, address _to, uint _value) onlyToken returns (bool success) {
        // BK Ok
        return ledger.transfer(_from, _to, _value);
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) onlyToken returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    function approve(address _owner, address _spender, uint _value) onlyToken returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) onlyToken returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) onlyToken returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

    function burn(address _owner, uint _amount) onlyToken {
        ledger.burn(_owner, _amount);
    }
}

contract Ledger is Owned, SafeMath, Finalizable {
    Controller public controller;
    // BK Ok
    mapping(address => uint) public balanceOf;
    // BK Ok
    mapping (address => mapping (address => uint)) public allowance;
    // BK Ok
    uint public totalSupply;
    uint public mintingNonce;
    bool public mintingStopped;

    // functions below this line are onlyOwner

    // BK Ok - Constructor
    function Ledger() {
    }

    // BK Ok - Only owner can execute this, when not finalised
    function setController(address _controller) onlyOwner notFinalized {
        // BK Ok
        controller = Controller(_controller);
    }

    function stopMinting() onlyOwner {
        mintingStopped = true;
    }

    function multiMint(uint nonce, uint256[] bits) onlyOwner {
        require(!mintingStopped);
        if (nonce != mintingNonce) return;
        mintingNonce += 1;
        uint256 lomask = (1 << 96) - 1;
        uint created = 0;
        for (uint i=0; i<bits.length; i++) {
            address a = address(bits[i]>>96);
            uint value = bits[i]&lomask;
            balanceOf[a] = balanceOf[a] + value;
            controller.ledgerTransfer(0, a, value);
            created += value;
        }
        totalSupply += created;
    }

    // functions below this line are onlyController

    // BK Ok
    modifier onlyController() {
        // BK Ok
        require(msg.sender == address(controller));
        // BK Ok
        _;
    }

    // BK Ok - Can only be called from the controller
    function transfer(address _from, address _to, uint _value) onlyController returns (bool success) {
        // BK Ok
        if (balanceOf[_from] < _value) return false;

        // BK Ok
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        // BK Ok
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        // BK Ok
        return true;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        var allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        allowance[_from][_spender] = safeSub(allowed, _value);
        return true;
    }

    function approve(address _owner, address _spender, uint _value) onlyController returns (bool success) {
        // require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = safeAdd(oldValue, _addedValue);
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = safeSub(oldValue, _subtractedValue);
        }
        return true;
    }

    function burn(address _owner, uint _amount) onlyController {
        balanceOf[_owner] = safeSub(balanceOf[_owner], _amount);
        totalSupply = safeSub(totalSupply, _amount);
    }
}
```