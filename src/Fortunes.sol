// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {VRFConsumerBaseV2} from "./chainlink/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "./chainlink/VRFCoordinatorV2Interface.sol";

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
		1. Start game - sets game parameters: dice roll generation rate, addition multiplier, multiplication multiplier, min fortune to roll seizure
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

    uint8 private constant DICE_SIDES = 12;
    uint256 private constant PRECISION = 1e6;

    struct FortuneSeeker {
        uint256 fortune;
        uint256 deposit;
        uint256 diceRollsRemaining;
        uint256 lastDiceRollTimestamp;
    }

    struct Seizure {
        uint256 start;
        uint256 end;
        uint256 fee;
        uint256[DICE_SIDES] rewards;
        mapping(address => uint256) rolls;
				uint256 vaultSnapshot;
    }

    struct RollingDice {
        uint256 requestId;
        address fortuneSeeker;
        uint256 multiplyStake;
        RollAction action;
    }

    enum RollAction {
        Add,
        Multiply,
        Seizure
    }

    // Chainlink VRF
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 private KEY_HASH;
    uint64 private SUBSCRIPTION_ID;

    uint256 public gameStart;
    uint256 public gameEnd;
    uint256 public vault;
    uint256 public totalFortune;
    uint256 public totalDepositors;
    uint256 public seizureIndex;
    uint256 public diceRollGenerationRate;
    uint256 public additionMultiplier;
    uint256 public multiplicationMultiplier;
    uint256 public minimumFortuneToRollSeize;

    mapping(uint256 => Seizure) public seizures;
    mapping(address => FortuneSeeker) public fortuneSeekers;
    mapping(uint256 => RollingDice) public rollingDie;

    constructor(
        address owner,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) Owned(owner) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        KEY_HASH = keyHash;
        SUBSCRIPTION_ID = subscriptionId;
    }

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
        uint256 fortune = fortuneSeeker.fortune;

        vault += fortune;
        totalDepositors -= 1;
        totalFortune -= fortune;

        delete fortuneSeekers[msg.sender];

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

    function calculateDiceRolls(
        FortuneSeeker storage fortuneSeeker
    ) internal view returns (uint256) {
        uint256 timeSinceLastDiceRoll = block.timestamp -
            fortuneSeeker.lastDiceRollTimestamp;
        uint256 diceRollsRemaining = fortuneSeeker.diceRollsRemaining +
            (timeSinceLastDiceRoll * diceRollGenerationRate);

        return diceRollsRemaining;
    }

    function rollAdd() external returns (uint256) {
        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        uint256 requestId = rollDice(fortuneSeeker);

        rollingDie[requestId] = RollingDice({
            requestId: requestId,
            fortuneSeeker: msg.sender,
            action: RollAction.Add,
            multiplyStake: 0
        });

        return requestId;
    }

    function rollMultiply(uint256 stake) external returns (uint256) {
        uint256 stakeModulus = stake % DICE_SIDES;
        require(stakeModulus > 0, "Must stake more than 0");

        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        uint256 requestId = rollDice(fortuneSeeker);

        rollingDie[requestId] = RollingDice({
            requestId: requestId,
            fortuneSeeker: msg.sender,
            action: RollAction.Multiply,
            multiplyStake: stakeModulus
        });

        return requestId;
    }

    function rollSeizure() external returns (uint256) {
        Seizure storage seizure = seizures[seizureIndex];
        require(
            block.timestamp >= seizure.start && block.timestamp <= seizure.end,
            "Must be during open seizure"
        );

        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        require(
            fortuneSeeker.fortune >= minimumFortuneToRollSeize,
            "Must have enough fortune to roll seizure"
        );

        uint256 fee = (fortuneSeeker.fortune * seizure.fee) / PRECISION;

        fortuneSeeker.fortune -= fee;
        totalFortune -= fee;
        vault += fee;

        uint256 requestId = rollDice(fortuneSeeker);

        rollingDie[requestId] = RollingDice({
            requestId: requestId,
            fortuneSeeker: msg.sender,
            action: RollAction.Seizure,
            multiplyStake: 0
        });

        return requestId;
    }

    function rollDice(
        FortuneSeeker storage fortuneSeeker
    ) internal returns (uint256) {
        require(fortuneSeeker.deposit > 0, "Must have a deposit");
        require(
            block.timestamp >= gameStart && block.timestamp <= gameEnd,
            "Must be during game"
        );

        uint256 diceRollsRemaining = calculateDiceRolls(fortuneSeeker);

        require(
            diceRollsRemaining >= 1 * PRECISION,
            "Must have dice rolls remaining"
        );

        fortuneSeeker.diceRollsRemaining = diceRollsRemaining - (1 * PRECISION);
        fortuneSeeker.lastDiceRollTimestamp = block.timestamp;

        uint256 requestId = COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            3,
            100_000,
            1
        );

        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        RollingDice storage rollingDice = rollingDie[requestId];
        FortuneSeeker storage fortuneSeeker = fortuneSeekers[
            rollingDice.fortuneSeeker
        ];

        uint256 diceRoll = randomWords[0] % DICE_SIDES;

        if (rollingDice.action == RollAction.Add) {
            finalizeAddRoll(diceRoll, fortuneSeeker);
        } else if (rollingDice.action == RollAction.Multiply) {
            finalizeMultiplyRoll(
                diceRoll,
                fortuneSeeker,
                rollingDice.multiplyStake
            );
        } else if (rollingDice.action == RollAction.Seizure) {
            finalizeSeizureRoll(diceRoll);
        }

        delete rollingDie[requestId];
    }

    function finalizeAddRoll(
        uint256 diceRoll,
        FortuneSeeker storage fortuneSeeker
    ) internal {
        uint256 fortuneRewards = (diceRoll * additionMultiplier) / PRECISION;
        fortuneSeeker.fortune += fortuneRewards;
        totalFortune += fortuneRewards;
    }

    function finalizeMultiplyRoll(
        uint256 diceRoll,
        FortuneSeeker storage fortuneSeeker,
        uint256 stake
    ) internal {
        bool isWin = diceRoll >= stake;

        uint256 fortuneRewards = (fortuneSeeker.fortune *
            stake *
            multiplicationMultiplier) /
            DICE_SIDES /
            PRECISION;

        if (isWin) {
            fortuneSeeker.fortune += fortuneRewards;
            totalFortune += fortuneRewards;
        } else {
            fortuneSeeker.fortune -= fortuneRewards;
            totalFortune -= fortuneRewards;
            vault += fortuneRewards;
        }
    }

    function finalizeSeizureRoll(uint256 diceRoll) internal {
        seizures[seizureIndex].rolls[msg.sender] = diceRoll;
    }

		function finalizeCurrentSeizure() external {
			Seizure storage seizure = seizures[seizureIndex];

			require(seizure.start > 0, "Must have started seizure");
			require(block.timestamp > seizure.end, "Must be after seizure end");

			uint totalRewards = 0;

			for (uint256 i = 0; i < DICE_SIDES; i++) {
				totalRewards += seizure.rewards[i] * vault / PRECISION;
			}

			seizure.vaultSnapshot = totalRewards;
			vault -= totalRewards;
			seizureIndex += 1;
		}
}
