// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

struct Fundraising {
	uint256 id;
	string description;
	uint256 goal; // etherium aim
	uint256 current;
	address owner;
	uint256 closingTime;
	bool opened;
}

contract Crowdfunding {
	address contractOwner;

	Fundraising[] public fundraisings;
	
	mapping(uint256 => mapping(address => uint256)) public contributions; // fundraising id, user-address, funding

	event FundraisingOpenEvent(uint256 id, address owner, string description, uint256 goal, uint256 closingTime);
	event DonationAccepted(uint256 fundraisingId, uint256 value);

	modifier IsExpired (uint256 fund_id) {
		if (block.timestamp >= fundraisings[fund_id].closingTime) {
			fundraisings[fund_id].opened = false;
		}
		_;
	}

	constructor() payable {
		contractOwner = msg.sender;
	}

	receive() external payable {
	}

	fallback () external payable {}

	function openNewFundraising(
		uint256 _goal,
		string calldata _description,
		uint256 _closingTime
	) public {
		require(bytes(_description).length != 0);
		require(_goal != 0);

		Fundraising memory fund = Fundraising({
			id: fundraisings.length + 1,
			description: _description,
			goal: _goal,
			current: 0,
			owner: msg.sender,
			opened: true,
			closingTime: block.timestamp + _closingTime
		});

		fundraisings.push(fund);
		emit FundraisingOpenEvent(fund.id, fund.owner, fund.description, fund.goal, fund.closingTime);
	}

	function donate(uint256 _id) public payable IsExpired(_id){
		require(msg.value != 0, "Wei count must be not null!");
		if (fundraisings[_id].opened == false) {
			revert ("Fundraising expired!");
		}
		fundraisings[_id].current += msg.value;
		contributions[_id][msg.sender] += msg.value;

		emit DonationAccepted(_id, msg.value);
	}
}
