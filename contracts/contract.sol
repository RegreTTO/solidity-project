// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

struct Fundraising {
	uint256 id;
	string description;
	uint256 goal; // etherium aim
	uint256 current;
	address payable owner;
	address payable[] members;
	uint256 closingTime;
	bool filled_up;
	bool isOpened;
}

contract Crowdfunding {
	address contractOwner;

	Fundraising[] public fundraisings;

	mapping(uint256 => mapping(address => uint256)) public contributions; // fundraising id, user-address, funding
	mapping(uint256 => mapping(address => bool)) public members; // fundraising id, user-address, is member of the current fundraising

	event FundraisingOpenEvent(uint256 id, address owner, string description, uint256 goal, uint256 closingTime);
	event DonationAccepted(uint256 fundraisingId, uint256 value);
	event FundraisingCloseEvent(uint256 id, bool filledUp);
	event EthTransfered(address to, uint256 amount);
	event Refund(address to, uint256 amount);

	modifier IsExpired(uint256 fund_id) {
		if (block.timestamp >= fundraisings[fund_id].closingTime || !fundraisings[fund_id].isOpened) {
			revert("Fundraising is expired");
		}
		_;
	}

	constructor() payable {
		contractOwner = msg.sender;
	}

	receive() external payable {
		emit EthTransfered(address(this), msg.value);
	}

	fallback() external payable {
		emit EthTransfered(address(this), msg.value);
	}

	function openNewFundraising(
		uint256 _goal,
		string calldata _description,
		uint256 secondsDueClosing
	) public {
		require(bytes(_description).length != 0);
		require(_goal != 0);
		address payable[] memory tmp;
		Fundraising memory fund = Fundraising({
			id: fundraisings.length,
			description: _description,
			goal: _goal,
			current: 0,
			owner: payable(msg.sender),
			closingTime: block.timestamp + secondsDueClosing,
			filled_up: false,
			isOpened: true,
			members: tmp
		});

		fundraisings.push(fund);
		emit FundraisingOpenEvent(fund.id, fund.owner, fund.description, fund.goal, fund.closingTime);
	}

	/// @notice Returns eth to funders if not filled_up, else transfer eth to fund. owner
	function closeFundraising(uint256 _id) public {
		require(fundraisings[_id].isOpened, "Fundraising is already closed!");
		require(block.timestamp >= fundraisings[_id].closingTime, "Fundraising is not expired yet!");
		Fundraising storage fund = fundraisings[_id];
		fund.isOpened = false;

		// @dev check if fundraising is full
		if (fund.current >= fund.goal) {
			fund.owner.transfer(fund.current);
			emit EthTransfered(fund.owner, fund.current);
			fund.current = 0;
			fund.filled_up = true;
		} else {
			for (uint256 i = 0; i < fund.members.length; i++) {
				fund.members[i].transfer(contributions[_id][fund.members[i]]);
				emit Refund(fund.members[i], contributions[_id][fund.members[i]]);
			}
			fund.current = 0;
		}
	}

	function donate(uint256 _id) public payable IsExpired(_id) {
		require(msg.value != 0, "Wei count must be not null!");
		fundraisings[_id].current += msg.value;
		contributions[_id][msg.sender] += msg.value;
		if (!members[_id][msg.sender]) {
			members[_id][msg.sender] = true;
			fundraisings[_id].members.push(payable(msg.sender));
		}
		emit DonationAccepted(_id, msg.value);
	}
}
