// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public owner;
    address[] public participants;
    uint public prize;
    bool public isActive;
    address public winner;

    modifier onlyOwner() {
        require(msg.sender == owner);

        _;
    }

    modifier shouldBeActive() {
        require(isActive);

        _;
    }

    constructor (uint _price) {
        owner = msg.sender;
        prize = _price;
        isActive = true;
    }

    function startLotter() public onlyOwner shouldBeActive {
        require(!isActive, "already actvie");

        isActive = true;
        delete participants;
        winner = address(0);
    }

    function buyTicker() public payable shouldBeActive {
        require(msg.value != prize, "bad price");


        participants.push(msg.sender);
    }

    function endLottery() public onlyOwner shouldBeActive {
        require(participants.length > 0, "no players");

        isActive = false;
        winner = _getWinner();

        payable(winner).transfer(address(this).balance);
    }

    function getParticipants() public view returns (address[] memory) {
        return participants;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }


    function _getWinner() private view returns(address) {
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants.length)));

        uint index = random % participants.length;

        return participants[index];
    }


}