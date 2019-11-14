pragma solidity >=0.4.22 <0.6.0;
// Core concept - lock funds in Payment PaymentChannel
// When Wifi Available: Use makeVoluntaryPayment
// When Wifi unavailable: build signature validation to allow forced payment
// I.E. creator sends signed transaction to partner, who broadcasts it later. 
// signed payment can't be standard ETH transaction, must be some non-account based system.
// Likely best to have separate keys supplied in constructor

contract PaymentChannel {
    address creator;
    address partner;
    bool locked;
    mapping (address=>uint) balances;
    uint unlockHeight;
    event WithdrawalInitiated(address initiator, uint unlockHeight);
    
    modifier onlyPartners
    {
        require(
            msg.sender == creator || msg.sender == partner,
            "Sender not authorized."
        );
        _;
    }
    
    constructor(address _partner) public {
        creator = msg.sender;
        partner = _partner;
        locked = false;
        unlockHeight = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }
    
    function deposit() public payable onlyPartners {
        balances[msg.sender] += msg.value;
    }
    
    function lock() public onlyPartners {
        locked = true;
    }

    function initiateSoloWithdrawal() public onlyPartners {
        if (unlockHeight > block.number + 1500) {
            unlockHeight = block.number + 1500; // don't unlock for ~five days
            emit WithdrawalInitiated(msg.sender, unlockHeight);
        }
    }
    
    function withdraw() public onlyPartners {
        if (block.number >= unlockHeight) {
            locked = false;
        }
        if (!locked) {
            uint amount = balances[msg.sender];
            balances[msg.sender] = 0;
            msg.sender.transfer(amount);
        } else 
    }
    
    function makeVoluntaryPayment(uint amount) onlyPartners {
        require(
            balances[msg.sender] >= amount
            "Not enough funds to make payment"
        );
        balances[msg.sender] -= amount;
        if(msg.sender == creator) {
            balances[partner] += amount;
        } else {
            balances[creator] += amount;
        }
    }
}
