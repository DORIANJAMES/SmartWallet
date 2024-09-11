// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Consumer {
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function deposit() public payable {

    }
}

contract SmartContractWallet {
    //constructor ile sahibi bellirliyoruz.
    address payable public owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;
    mapping(address => bool) public guardians;
    

    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVoteBool;
    uint guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3;


    constructor() {
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool _isGuardian) public {
        require(msg.sender == owner, "You are not the owner. You cannot set a guardian, aborting...!");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public {
        require(guardians[msg.sender],"You are not the guardian of this wallet, aborting...!");
        require(nextOwnerGuardianVoteBool[_newOwner][msg.sender] == false, "You alreadt voted, aborting...!");
        if(_newOwner != nextOwner) {
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if (guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance ( address _for, uint _amount) public {
        require(msg.sender == owner, "You are not the owner. You cannot set allowance, aborting...!");
        allowance[_for] = _amount;

        if(_amount > 0) {
            isAllowedToSend[_for] = true;
        } else {
            isAllowedToSend[_for] = false;
        }
    }


    function Transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory){

        //require(msg.sender == owner,"You are not allowd to transfer any amount, aborting...!");
        if(msg.sender != owner) {
            require(isAllowedToSend[msg.sender],"You are not allowed to send anything from this contract, aborting...!");
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting...!");

            allowance[msg.sender]-= _amount;
        }

        (bool success, bytes memory transferedData) =_to.call {value:_amount}(_payload);
        require(success,"Call function is not successful, aborting...!");
        return transferedData;
    }
    
    receive() external payable { }
}