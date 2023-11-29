// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {VRFConsumerBaseV2} from "./chainlink/VRFConsumerBaseV2.sol";

contract Fortunes is VRFConsumerBaseV2, Owned, ReentrancyGuard {
    /**
		# Methods that we need:

		## Deposits and withdrawals
		1. Deposit at any time
		2. Forfeit before game ends
		3. Redeem at end of game

		## User Game functions
		1. Roll For Add
		2. Roll For Multiply
		3. Roll For Seizure

		## Chainlink VRF functions
		1. FulfillRandomness - generates a new dice roll for a user

		## Admin Game functions
		1. Start game - sets game parameters: dice roll generation rate, addition multiplier, multiplication multiplier
		2. End game
		3. Set open seizure

		# Bookkeeping
		1. Fortunes - a mapping of addresses to their fortunes.
		2. Deposits - a mapping of addresses to their deposits.
		3. Vault - fortunes lost by players accumulate here.

		# Parameters
		1. Dice roll generation rate - how often to generate a new dice roll per deposit.
		2. Addition multiplier - how much to multiply the dice roll by when adding.
		3. Multiplication multiplier - how much to multiply the dice roll by when multiplying.
	 */

    struct FortuneSeeker {
        uint256 fortune;
        uint256 deposit;
        uint256 diceRollsRemaining;
        uint256 lastDiceRollTimestamp;
    }

    struct Seizure {
        uint256 start;
        uint256 end;
        uint256[12] rewards;
    }

		enum RollAction {
			Add,
			Multiply,
			Seizure
		}

    uint256 private constant PRECISION = 1e6;

    uint256 public gameStart;
    uint256 public gameEnd;
    uint256 public vault;
    uint256 public totalFortune;
    uint256 public totalDepositors;

    uint256 public diceRollGenerationRate;
    uint256 public additionMultiplier;
    uint256 public multiplicationMultiplier;

    Seizure public openSeizure;

    mapping(address => FortuneSeeker) public fortuneSeekers;

    constructor(
        address owner,
        address vrfCoordinator
    ) VRFConsumerBaseV2(vrfCoordinator) Owned(owner) {}

    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than 0");

        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        if (fortuneSeeker.deposit == 0) {
            totalDepositors += 1;
        }

        fortuneSeeker.deposit += msg.value;
    }

    function forfeit() external nonReentrant {
        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        require(fortuneSeeker.deposit > 0, "Must have a deposit");
        require(
            block.timestamp >= gameStart && block.timestamp <= gameEnd,
            "Must be during game"
        );

        uint256 deposited = fortuneSeeker.deposit;

        delete fortuneSeekers[msg.sender];
        totalDepositors -= 1;
        vault += deposited;

        payable(msg.sender).transfer(deposited);
    }

    function redeem() external nonReentrant {
        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        require(fortuneSeeker.deposit > 0, "Must have a fortune");
        require(block.timestamp >= gameEnd, "Must be after game has ended");

        uint256 rewards = calculateRewards(fortuneSeeker);
        uint256 redemption = rewards + fortuneSeeker.deposit;

        totalDepositors -= 1;
        totalFortune -= fortuneSeeker.fortune;

        delete fortuneSeekers[msg.sender];

        payable(msg.sender).transfer(redemption);
    }

    function calculateRewards(
        FortuneSeeker storage fortuneSeeker
    ) internal view returns (uint256) {
        return (address(this).balance * fortuneSeeker.fortune) / totalFortune;
    }

    function rollDice(RollAction action) external nonReentrant {
        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        require(fortuneSeeker.deposit > 0, "Must have a deposit");
        require(
            block.timestamp >= gameStart && block.timestamp <= gameEnd,
            "Must be during game"
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {}
}
