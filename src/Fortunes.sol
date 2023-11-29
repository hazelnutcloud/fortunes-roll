// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract Fortunes is ERC721, Owned {
    /**
		# Methods that we need:

		## Deposits and withdrawals
		1. Deposit at any time
		2. Forfeit before game ends
		3. Redeem at end of game

		## User Game functions
		1. Add
		2. Multiply
		3. Seize

		## Admin Game functions
		1. Start game
		2. End game
		3. Set seziure parameters

		# Bookkeeping
		1. Fortunes - a mapping of tokenIds to their fortunes.
		2. Deposits - a mapping of tokenIds to their deposits.
		3. Bank - fortunes lost by players accumulate here.

		# Parameters
		1. Dice roll generation rate - how often to generate a new dice roll per deposit.
		2. Addition multiplier - how much to multiply the dice roll by when adding.
		3. Multiplication multiplier - how much to multiply the dice roll by when multiplying.
	 */

    struct SeizurePeriod {
        uint256 start;
        uint256 end;
        mapping(uint8 => uint256) rewards;
    }
    SeizurePeriod public seizure;

    mapping(uint256 => uint256) public fortunes;
    mapping(uint256 => uint256) public deposits;

    uint256 public gameStart;
    uint256 public gameEnd;
    uint256 public bank;

    constructor() ERC721("Fortunes", "FORTUNE") {}

    function deposit(uint256 tokenId) external payable {
        require(msg.value > 0, "Must deposit more than 0");
        deposits[msg.sender] += msg.value;
    }

    function forfeit(uint256 tokenId) external {
        require(deposits[msg.sender] > 0, "Must have a deposit");
        uint256 deposit = deposits[msg.sender];
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(deposit);
    }

    function redeem(uint256 tokenId) external {
        require(fortunes[msg.sender] > 0, "Must have a fortune");
        uint256 fortune = fortunes[msg.sender];
        fortunes[msg.sender] = 0;
        payable(msg.sender).transfer(fortune);
    }

    function add(uint256 tokenId) external {
        require(fortunes[msg.sender] > 0, "Must have a fortune");
        fortunes[msg.sender] += a + b;
    }

    function multiply(uint256 tokenId) external {
        require(fortunes[msg.sender] > 0, "Must have a fortune");
        fortunes[msg.sender] += a * b;
    }

    function seize(address user) external {
        require(fortunes[user] > 0, "Must have a fortune");
        uint256 fortune = fortunes[user];
        fortunes[user] = 0;
        bank += fortune;
    }

    function startGame() external {
        require(gameStart == 0, "Game already started");
        gameStart = block.timestamp;
        gameEnd = block.timestamp + 1 days;
    }

    function endGame() external {
        require(gameStart > 0, "Game not started");
        require(block.timestamp > gameEnd, "Game not ended");
        gameStart = 0;
        gameEnd = 0;
    }

    function startSeizure() external {
        require(gameStart > 0, "Game not started");
        require(block.timestamp > gameEnd, "Game not ended");
        require(seizureStart == 0, "Seizure already started");
        seizureStart = block.timestamp;
        seizureEnd = block.timestamp + 1 days;
    }

    function endSeizure() external {
        require(gameStart > 0, "Game not started");
        require(block.timestamp > gameEnd, "Game not ended");
        require(seizureStart > 0, "Seizure not started");
        require(block.timestamp > seizureEnd, "Seizure not ended");
        seizureStart = 0;
        seizureEnd = 0;
    }
}
