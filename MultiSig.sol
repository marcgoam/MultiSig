// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultiSig {
    address[] public owners;
    uint256 public required;
    uint public transactionCount;
    uint transactionID;

    struct Transaction  {
        address destination;
        uint256 value;
        bool executed;
        bytes data;
    }

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;

    error MultiSig__NotOwner();

    modifier isOwner(address addr) {
        bool ok;
        for(uint i = 0; i < owners.length; ++i) {
            if(addr == owners[i]) {
                ok = true;
            }
        }
        if(!ok) {
            revert MultiSig__NotOwner();
        }
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "There are not owners!");
        require(_required > 0, "No confirmations!");
        require(_required < _owners.length, "More confirmations than addresses!");
        owners = _owners;
        required = _required;
    } 

    function addTransaction(address addr, uint256 value, bytes calldata data) internal returns(uint256) {
        transactionID = transactionCount;
        transactions[transactionID] = Transaction(addr,value,false, data);
        transactionCount++;
        return transactionID;
    }

    function confirmTransaction(uint id) public isOwner(msg.sender){
        confirmations[id][msg.sender] = true;
        if(isConfirmed(id)) {
            executeTransaction(id);
        }
        
    }

    function getConfirmationsCount(uint transactionId) public view returns(uint256) {
        uint count;
        for(uint i = 0; i < owners.length; ++i){
            if(confirmations[transactionId][owners[i]] == true) {
                count++;
            }
        }
        return count;

    }

    function submitTransaction(address addr, uint value, bytes calldata data) external {
        uint id = addTransaction(addr, value, data);
        confirmTransaction(id);
    }

    function isConfirmed(uint id) public view returns(bool){
        if(getConfirmationsCount(id) >= required) {
            return true;
        } else {
            return false;
        }
        
    }

    function executeTransaction(uint id) public {
        require(isConfirmed(id), "Transaction not confirmed!");
        Transaction storage _tx = transactions[id];
        (bool success,) = _tx.destination.call{value: _tx.value}(_tx.data);
        require(success);
        _tx.executed = true;
    }

    receive() external payable {
        
    }
}
