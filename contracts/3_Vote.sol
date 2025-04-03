// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Poll {
        address owner;
        
        string description;
        string[] options;

        mapping (address => bool) hasVoted;
        mapping (uint => uint) votes;

        uint endTime;
        bool isActive;
    }

    mapping (uint => Poll) public polls;
    uint private pollsCount;

    modifier pollIsActive(uint _pollId) {
        require(polls[_pollId].isActive, "poll not active");

        _;
    }

    event PollCreated(uint pollId, string description, address creator);
    event Voted(uint pollId, uint option, address voter);
    event PollEnded(uint pollId, uint winningOption);


    function createPoll(string memory _description, string[] memory _options, uint duration) public {
        require(_options.length >= 2, "need more than 2 options");
        pollsCount++;

        Poll storage poll = polls[pollsCount];
        poll.description = _description;
        poll.isActive = true;
        poll.owner = msg.sender;
        poll.options = _options;
        poll.endTime = block.timestamp + duration;

        emit PollCreated(pollsCount, _description, msg.sender);
    }

    function vote(uint _pollId, uint _option) public pollIsActive(_pollId) {
        Poll storage poll = polls[_pollId];
        address sender = msg.sender;

        require(block.timestamp <= poll.endTime, "time expired");
        require(!poll.hasVoted[sender], "address already voted");
        require(_option <= poll.options.length, "bad option");

        poll.hasVoted[sender] = true;
        poll.votes[_option]++;

        emit Voted(_pollId, _option, sender);
    }

    function endVote(uint _pollId) public pollIsActive(_pollId) {
        Poll storage poll = polls[_pollId];

        require(msg.sender == poll.owner, "only owner");

        poll.isActive = false;

        uint winnerOption = _getWinningOption(_pollId);

        emit PollEnded(_pollId, winnerOption);
    }

    function _getWinningOption(uint _pollId) private view returns (uint) {
        Poll storage poll = polls[_pollId];
        
        uint maxVotes = 0;
        uint winningOption = 0;

        for (uint i = 0; i < poll.options.length; i++) {
            if (poll.votes[i] > maxVotes) {
                maxVotes = poll.votes[i];
                winningOption = i;
            }
        }
        return winningOption;
    }

    function getPollDetails(uint _pollId) public view returns (string memory, string[] memory, uint, bool) {
        Poll storage poll = polls[_pollId];
        return (poll.description, poll.options, poll.endTime, poll.isActive);
    }
}