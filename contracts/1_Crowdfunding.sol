// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Платформа для краудфандинга
// Реализуй контракт, где пользователи могут запускать кампании по сбору средств, а доноры отправлять ETH. 
// Добавь функцию возврата средств, если цель не достигнута, и таймер для завершения кампании.

contract CampaignFactory {
    address private _owner;
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner");

        _;
    }

    struct Campaign {
        uint id;
        
        string name;
        string description;
            
        address payable owner;
            
        uint currentBalance;
        uint goalBalance;

        uint startTime;
        uint endTime;
    }

    Campaign[] internal _campaigns;

    constructor() {
        _owner = msg.sender;
    }

    function createCampaign(string memory _name, string memory _description, uint _duration, uint _goalBalance) external {
        Campaign memory campaign = Campaign({
                id: _campaigns.length, 
                name: _name, 
                description: _description,
                owner: payable(msg.sender),
                currentBalance: 0,
                goalBalance: _goalBalance,
                startTime: block.timestamp,
                endTime: block.timestamp + _duration
        });

        _campaigns.push(campaign);
    }

    function getAllCampaigns() external view returns(Campaign[] memory) {
        return _campaigns;
    }
}

contract DepositorFactory is CampaignFactory {
    event DepositorAdded(uint campaignId, address depositor, uint amount);
    
    struct Depositor {
        address payable addr;
        uint balance;
    }

    mapping (uint => Depositor[]) internal _depositsToCampaign;

    function _increaseDepositor(uint _campaignId, address _depositor, uint amount) internal {
        for (uint i = 0; i < _depositsToCampaign[_campaignId].length; i++) {
            Depositor storage depositor = _depositsToCampaign[_campaignId][i];
            if (depositor.addr == _depositor) {
                depositor.balance += amount;
                emit DepositorAdded(_campaignId, _depositor, depositor.balance);
                return;
            }
        }
        
        _depositsToCampaign[_campaignId].push(Depositor({
            addr: payable(_depositor),
            balance: amount
        }));
        emit DepositorAdded(_campaignId, _depositor, amount);
    }

    function _returnToDepositors(Campaign memory _campaign) internal {
        for (uint i = 0; i < _depositsToCampaign[_campaign.id].length; i++) {
            Depositor memory depositor = _depositsToCampaign[_campaign.id][i];

            depositor.addr.transfer(depositor.balance);

            _campaigns[_campaign.id].currentBalance = 0;
        }
    }

    function getAllDepositsById(uint _id) public view returns (Depositor[] memory) {
        require(_id < _campaigns.length, "Campaign does not exist");
        
        return _depositsToCampaign[_id];
    }

    function getDepositsCountById(uint _id) public view returns (uint) {
       require(_id < _campaigns.length, "Campaign does not exist");
        return _depositsToCampaign[_id].length;
    }
}

contract Crowdfunding is DepositorFactory {
    uint8 private _commision = 5;

    function getCommision() public view returns(uint8) {
        return _commision;
    }

    function setCommision(uint8 _newCommision) external onlyOwner {
        _commision = _newCommision;
    }
    
    function depositToCampaign(uint _id) external payable {
        require(_id <= _campaigns.length, "bad id");
        require(msg.value > 0, "bad money");

        _campaigns[_id].currentBalance += msg.value;

        _increaseDepositor(_id, msg.sender, msg.value);
    }

    function withdrawFromCampaign(uint _id) external payable onlyOwner {
        require(_id <= _campaigns.length, "bad id");
        require(_campaigns[_id].endTime <= block.timestamp, "Campaign not finished");

        Campaign memory campaign = _campaigns[_id];

        if (campaign.currentBalance >= campaign.goalBalance) {
            uint commision = _calculateCommision(campaign.currentBalance);

            campaign.owner.transfer(campaign.currentBalance - commision);
            payable(address(this)).transfer(commision);
            
        } else {
            _returnToDepositors(campaign);
        }
    }

    function _calculateCommision(uint _campaignBalance) private view returns (uint) {
        return _campaignBalance * _commision / 100;
    }
}