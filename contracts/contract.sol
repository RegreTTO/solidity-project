// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

struct Fundraising {
	uint256 id;
	string description;
	uint256 goal; // etherium aim
	uint256 current;
	address owner;
	uint256 closing_time;
	bool opened;
}

contract Crowdfunding {
	address contract_owner;
	Fundraising[] public fundraisings;
	mapping(uint256 => mapping(address => uint256)) public contributions;

	event fundraisingOpenEvent(uint256 id, address owner, string description, uint256 goal);

	constructor() {
		contract_owner = msg.sender;
	}

	function openNewFundraising(uint256 _goal, string calldata _description, uint256 _closing_time) public {
		require(bytes(_description).length != 0);
        require(_goal != 0);

		Fundraising memory fund = Fundraising({
			id: fundraisings.length + 1,
			description: _description,
			goal: _goal,
			current: 0,
			owner: msg.sender,
			opened: true,
			closing_time: _closing_time
		});
		
		fundraisings.push(fund);
        emit fundraisingOpenEvent(fund.id, fund.owner, fund.description, fund.goal);
	}

}
