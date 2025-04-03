// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multisig {
    address[] private admins;

    struct Transaction {
        address to;
        uint value;
        bool isExecuted;
        uint approvalCount;
        mapping (address => bool) approved;

        uint endTime;
    }

    Transaction[] private transactions;

    event TransactionPropose(uint transactionIndex, uint value, address to);
    event TransactionApproved(uint transactionIndex, address from);
    event TransactionRevert(uint transactionIndex);
    event TransactionExecuted(uint transactionIndex, uint timestamp, uint value);

    modifier onlyAdmins(address _addr) {
        require(_isAdmin(_addr), "not admin");

        _;
    }

    constructor() {
        admins.push(msg.sender);
    }

    function addAdmin(address _addr) external onlyAdmins(msg.sender) {
        require(!_isAdmin(_addr), "already exists");
        
        admins.push(_addr);
    }

    function proposeTransaction(address _to, uint _endTime) external payable onlyAdmins(msg.sender) {
        uint value = msg.value;
        
        require(value > 0, "bad value");
        
        Transaction storage transaction = transactions.push();
        transaction.to = _to;
        transaction.value = value;
        transaction.endTime = block.timestamp + _endTime;

        emit TransactionPropose(transactions.length, value, _to);
    }

    function approveTransaction(uint _txId) external onlyAdmins(msg.sender) {
        Transaction storage transaction = transactions[_txId];
        
        require(block.timestamp <= transaction.endTime, "transaction overtime");
        require(!transaction.isExecuted, "transaction executed");
        require(!transaction.approved[msg.sender], "already approved");
        
        transaction.approved[msg.sender] = true;
        transaction.approvalCount++;

        emit TransactionApproved(_txId, msg.sender);

        if (block.timestamp > transaction.endTime) revertTransaction(_txId);

        if (transaction.approvalCount >= admins.length) {
            executeTransaction(_txId);
        }
    }

    function executeTransaction(uint _txId) public onlyAdmins(msg.sender) {
        Transaction storage transaction = transactions[_txId];
        
        require(block.timestamp <= transaction.endTime, "transaction overtime");
        require(transaction.approvalCount >= admins.length, "not enough approvals");
        require(!transaction.isExecuted, "transaction executed");

        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "Transaction failed");


        transaction.isExecuted = true;
        emit TransactionExecuted(_txId, block.timestamp, transaction.value);
    }

    function revertTransaction(uint _txId) public onlyAdmins(msg.sender) {
        require(!transactions[_txId].isExecuted, "transaction executed");
        
        emit TransactionRevert(_txId);
        delete transactions[_txId];
    }

    function getTransaction(uint _txId) external view returns (address to, uint value, bool executed, uint approvalCount) {
        require(_txId < transactions.length, "bad id");
        
        Transaction storage transaction = transactions[_txId];
        return (transaction.to, transaction.value, transaction.isExecuted, transaction.approvalCount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getAdmins() external view returns (address[] memory) {
        return admins;
    }

    function _isAdmin(address addr) private view returns (bool) {
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == addr) return true;
        }

        return false;
    }

    receive() external payable {
    }
}