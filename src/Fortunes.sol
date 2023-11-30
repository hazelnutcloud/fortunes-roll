// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {VRFConsumerBaseV2} from "./chainlink/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "./chainlink/VRFCoordinatorV2Interface.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IStakedAvax} from "./benqi/IStakedAvax.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

contract Fortunes is VRFConsumerBaseV2, Owned, ReentrancyGuard {
    /**

		8888888888               888                              d8b             8888888b.          888 888		   _______
		888                      888                              88P             888   Y88b         888 888		  /\ o o o\
		888                      888                              8P              888    888         888 888		 /o \ o o o\_______
		8888888  .d88b.  888d888 888888 888  888 88888b.   .d88b. "  .d8888b      888   d88P .d88b.  888 888		<    >------>   o /|
		888     d88""88b 888P"   888    888  888 888 "88b d8P  Y8b   88K          8888888P" d88""88b 888 888		 \ o/  o   /_____/o|
		888     888  888 888     888    888  888 888  888 88888888   "Y8888b.     888 T88b  888  888 888 888		  \/______/     |oo|
		888     Y88..88P 888     Y88b.  Y88b 888 888  888 Y8b.            X88     888  T88b Y88..88P 888 888		        |   o   |o/
		888      "Y88P"  888      "Y888  "Y88888 888  888  "Y8888     88888P'     888   T88b "Y88P"  888 888		        |_______|/

		Fortune's Roll is a game of chance where players deposit funds and roll a dice to increase their fortune.
		At the end of the game, players can redeem their fortunes for a share of the total yield generated by deposits throughout the game.

		# Contract Structure:

		## Events
		1. FortuneGained - emitted when a player gains fortune. 🧪
		2. FortuneLost - emitted when a player loses fortune. 🧪
		3. Deposit - emitted when a player deposits funds. 🧪
		4a. Withdraw - emitted when a player withdraws funds. 🧪
		4b. Forfeit - emitted when a player forfeits their funds. 🧪
		4c. Redeem - emitted when a player redeems their funds. 🧪
		5. DiceRolled - emitted when a player rolls the dice. 🧪
		6. DiceLanded - emitted when the dice lands. 🧪
		7. GrabbeningClosed - emitted when a grabbening is closed. 🧪

		## Methods

		### Deposits and withdrawals
		1. Deposit at any time 🧪
		2. Withdraw before game starts 🧪
		3. Forfeit while game is running 🧪
		4. Redeem after end of game 🧪

		### User Game functions
		1. Roll For Add 🧪
		2. Roll For Multiply 🧪
		3. Roll For Grabbening 🧪
		4. Close current Grabbening - Closes the current open grabbening to continue to the next one 🧪

		### Chainlink VRF functions
		1. FulfillRandomness - generates a new dice roll for a user 🧪

		### Admin Game functions
		1. Set grabbening 🧪
		2. Reclaim LINK tokens 🧪
		3. Claim protocol share 🧪

		### View/Helper functions
		1. Calculate Dice Rolls 🧪
		2. Calculate Rewards 🧪
		3. Calculate Grabbening Rewards 🧪
		4. Get Total Fortune For 🧪

		## Mapping & Variables

		### Bookkeeping
		1. Fortunes - a mapping of addresses to their fortunes. ✅
		2. Deposits - a mapping of addresses to their deposits. ✅
		3. Vault - fortunes lost by players accumulate here. ✅
		4. Total Fortune - total fortune of all players. ✅
		5. Total Deposited - total deposits of all players. ✅
		6. Grabbening Index - the index of the current open grabbening. ✅
		7. Rolling Dice - a mapping of request ids to rolling dice. ✅
		8. Total Protocol Rewards - total protocol rewards. ✅

		### Parameters
		1. Dice roll generation rate - how often to generate a new dice roll. ✅
		2. Addition multiplier - how much to multiply the dice roll by when adding. ✅
		3. Multiplication multiplier - how much to multiply the dice roll by when multiplying. ✅
		4. Minimum fortune to roll grabbening - how much fortune a player must have to roll for grabbening. ✅
		5. Game start - when the game starts. ✅
		6. Game end - when the game ends. ✅
	 */

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    event FortuneGained(
        address indexed fortuneSeeker,
        uint256 fortuneGained,
        uint256 timestamp
    );
    event FortuneLost(
        address indexed fortuneSeeker,
        uint256 fortuneLost,
        uint256 timestamp
    );
    event Deposit(
        address indexed fortuneSeeker,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(
        address indexed fortuneSeeker,
        uint256 shareAmount,
        bytes32 kind,
        uint256 timestamp
    );
    event DiceRolled(
        address indexed fortuneSeeker,
        RollAction action,
        uint256 multiplyStake,
        uint256 grabbeningIndex,
        uint256 requestId,
        uint256 timestamp
    );
    event DiceLanded(
        address indexed fortuneSeeker,
        RollAction action,
        uint256 multiplyStake,
        uint256 grabbeningIndex,
        uint256 requestId,
        uint256 diceRoll,
        uint256 timestamp
    );
    event GrabbeningClosed(
        uint256 grabbeningIndex,
        uint256 potBalance,
        uint256 totalRewards,
        uint256 timestamp
    );

    /* -------------------------------------------------------------------------- */
    /*                            Mappings & Variables                            */
    /* -------------------------------------------------------------------------- */

    uint8 private constant DICE_SIDES = 12;
    uint256 private constant PRECISION = 1e6;
    uint256 public constant PROTOCOL_SHARE = 50000; // 5% of generated yield goes to protocol

    bytes32 public constant WITHDRAW = keccak256(abi.encodePacked("withdraw"));
    bytes32 public constant FORFEIT = keccak256(abi.encodePacked("forfeit"));
    bytes32 public constant REDEEM = keccak256(abi.encodePacked("redeem"));

    struct FortuneSeeker {
        uint256 fortune;
        uint256 deposit;
        uint256 diceRollsRemaining;
        uint256 lastDiceRollTimestamp;
    }

    struct Grabbening {
        uint256 start;
        uint256 end;
        uint256 fee;
        uint256[DICE_SIDES] rewardShares; // denominated in PRECISION e.g 50% = 0.5 * PRECISION. Total should never exceed 1 * PRECISION
        uint256[DICE_SIDES] grabberTallies; // number of seekers who rolled each side
        uint256 rewardSharesTotal;
        mapping(address => uint256) rolls;
        uint256 rewardsSnapshot;
    }

    struct RollingDice {
        uint256 requestId;
        address fortuneSeeker;
        uint256 multiplyStake;
        uint256 grabbeningIndex;
        RollAction action;
    }

    enum RollAction {
        Add,
        Multiply,
        Grab
    }

    // Chainlink VRF
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 private KEY_HASH;
    uint64 private SUBSCRIPTION_ID;

    // sAVAX
    IStakedAvax public STAKED_AVAX;

    // LINK
    ERC20 public LINK_TOKEN;

    uint256 public gameStart;
    uint256 public gameEnd;
    uint256 public potBalance;
    uint256 public totalFortune;
    uint256 public totalDeposited;
    uint256 public grabbeningIndex;
    uint256 public totalProtocolRewards;
		uint256 public outstandingRolls;

    uint256 public diceRollGenerationRate;
    uint256 public additionMultiplier;
    uint256 public multiplicationMultiplier;
    uint256 public minimumFortuneToRollGrab;

    mapping(uint256 => Grabbening) public grabbenings;
    mapping(address => FortuneSeeker) public fortuneSeekers;
    mapping(uint256 => RollingDice) public rollingDie;

    /* -------------------------------------------------------------------------- */
    /*                                 Constructor                                */
    /* -------------------------------------------------------------------------- */

    constructor(
        address _owner,
        address _vrfCoordinator,
        address payable _stakedAvax,
        address _linkToken,
        uint256 _gameStart,
        uint256 _gameEnd,
        uint256 _diceRollGenerationRate,
        uint256 _additionMultiplier,
        uint256 _multiplicationMultiplier,
        uint256 _minimumFortuneToRollGrab,
        bytes32 keyHash,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) Owned(_owner) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        KEY_HASH = keyHash;
        SUBSCRIPTION_ID = subscriptionId;

        STAKED_AVAX = IStakedAvax(_stakedAvax);

        LINK_TOKEN = ERC20(_linkToken);

        gameStart = _gameStart;
        gameEnd = _gameEnd;
        diceRollGenerationRate = _diceRollGenerationRate;
        additionMultiplier = _additionMultiplier;
        multiplicationMultiplier = _multiplicationMultiplier;
        minimumFortuneToRollGrab = _minimumFortuneToRollGrab;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */

    function deposit(uint256 shareAmount) public {
        require(shareAmount > 0, "Must deposit more than 0");

        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

				uint256 underlyingAmount = STAKED_AVAX.getPooledAvaxByShares(shareAmount);

        fortuneSeeker.deposit += underlyingAmount;
        totalDeposited += underlyingAmount;

        STAKED_AVAX.transferFrom(msg.sender, address(this), shareAmount);

        emit Deposit(msg.sender, underlyingAmount, block.timestamp);
    }

    function withdraw() public nonReentrant {
        require(block.timestamp < gameStart, "Must be before game start");

        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        require(fortuneSeeker.deposit > 0, "Must have a deposit");

        totalDeposited -= fortuneSeeker.deposit;
        fortuneSeeker.deposit = 0;

        uint256 amount = STAKED_AVAX.getSharesByPooledAvax(
            fortuneSeeker.deposit
        );

        require(
            amount < STAKED_AVAX.balanceOf(address(this)),
            "Not enough shares to withdraw"
        );

        STAKED_AVAX.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, WITHDRAW, block.timestamp);
    }

    function forfeit() external nonReentrant {
        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        require(fortuneSeeker.deposit > 0, "Must have a deposit");
        require(
            block.timestamp >= gameStart && block.timestamp <= gameEnd,
            "Must be during game"
        );

        uint256 deposited = fortuneSeeker.deposit;
        uint256 fortune = getTotalFortuneFor(msg.sender, fortuneSeeker);

        potBalance += fortune;
        totalFortune -= fortune;
        totalDeposited -= deposited;

        delete fortuneSeekers[msg.sender];

        uint256 amount = STAKED_AVAX.getSharesByPooledAvax(deposited);

        require(
            amount < STAKED_AVAX.balanceOf(address(this)),
            "Not enough shares to withdraw"
        );

        STAKED_AVAX.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, FORFEIT, block.timestamp);
        emit FortuneLost(msg.sender, fortune, block.timestamp);
    }

    function redeem() external nonReentrant {
        require(block.timestamp >= gameEnd, "Must be after game has ended");
				require(outstandingRolls == 0, "Must have no outstanding rolls");
				
        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        require(fortuneSeeker.deposit > 0, "Must have deposited");

        (uint256 seekerReward, uint256 protocolReward) = calculateRewardFor(
            msg.sender,
            fortuneSeeker
        );
        seekerReward += STAKED_AVAX.getSharesByPooledAvax(
            fortuneSeeker.deposit
        );

        totalDeposited -= fortuneSeeker.deposit;
        totalFortune -= fortuneSeeker.fortune;

        totalProtocolRewards += protocolReward;

        delete fortuneSeekers[msg.sender];

        require(
            seekerReward < STAKED_AVAX.balanceOf(address(this)),
            "Not enough shares to withdraw"
        );

        STAKED_AVAX.transfer(msg.sender, seekerReward);

        emit Withdraw(msg.sender, seekerReward, REDEEM, block.timestamp);
        emit FortuneLost(msg.sender, fortuneSeeker.fortune, block.timestamp);
    }

    function rollAdd() external returns (uint256) {
        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        uint256 requestId = rollDice(fortuneSeeker);

        rollingDie[requestId] = RollingDice({
            requestId: requestId,
            fortuneSeeker: msg.sender,
            action: RollAction.Add,
            multiplyStake: 0,
            grabbeningIndex: 0
        });

        emit DiceRolled(
            msg.sender,
            RollAction.Add,
            0,
            0,
            requestId,
            block.timestamp
        );

        return requestId;
    }

    function rollMultiply(uint256 stake) external returns (uint256) {
        uint256 stakeModulus = (stake % DICE_SIDES) + 1;

        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        uint256 requestId = rollDice(fortuneSeeker);

        rollingDie[requestId] = RollingDice({
            requestId: requestId,
            fortuneSeeker: msg.sender,
            action: RollAction.Multiply,
            multiplyStake: stakeModulus,
            grabbeningIndex: 0
        });

        emit DiceRolled(
            msg.sender,
            RollAction.Multiply,
            stakeModulus,
            0,
            requestId,
            block.timestamp
        );

        return requestId;
    }

    function rollGrab() external returns (uint256) {
        Grabbening storage grabbening = grabbenings[grabbeningIndex];
        require(
            block.timestamp >= grabbening.start &&
                block.timestamp <= grabbening.end,
            "Must be during open grabbening"
        );

        FortuneSeeker storage fortuneSeeker = fortuneSeekers[msg.sender];

        require(
            fortuneSeeker.fortune >= minimumFortuneToRollGrab,
            "Must have enough fortune to roll grabbening"
        );

        uint256 fee = (fortuneSeeker.fortune * grabbening.fee) / PRECISION;

        fortuneSeeker.fortune -= fee;
        totalFortune -= fee;
        potBalance += fee;

        uint256 requestId = rollDice(fortuneSeeker);

        rollingDie[requestId] = RollingDice({
            requestId: requestId,
            fortuneSeeker: msg.sender,
            action: RollAction.Grab,
            multiplyStake: 0,
            grabbeningIndex: grabbeningIndex
        });

        emit DiceRolled(
            msg.sender,
            RollAction.Grab,
            0,
            grabbeningIndex,
            requestId,
            block.timestamp
        );

        return requestId;
    }

    function closeCurrentGrabbening() external {
        Grabbening storage grabbening = grabbenings[grabbeningIndex];

        require(grabbening.start > 0, "Must have started grabbening");
        require(
            block.timestamp > grabbening.end,
            "Must be after grabbening end"
        );

        uint totalRewards = 0;

        for (uint256 i = 0; i < DICE_SIDES; i++) {
            totalRewards +=
                (grabbening.rewardShares[i] * potBalance) /
                PRECISION;
        }

        grabbening.rewardsSnapshot = totalRewards;
        potBalance -= totalRewards;
        totalFortune += totalRewards;

        emit GrabbeningClosed(
            grabbeningIndex,
            potBalance,
            totalRewards,
            block.timestamp
        );

        grabbeningIndex += 1;
    }

    function calculateGrabbeningRewards(
        address fortuneSeeker
    ) public view returns (uint256) {
        uint256 grabbeningRewards = 0;

        for (uint256 i = 0; i < grabbeningIndex; i++) {
            Grabbening storage grabbening = grabbenings[i];

            uint256 roll = grabbening.rolls[fortuneSeeker];

            if (roll == 0) {
                continue;
            }

            uint256 rollRewardShare = grabbening.rewardShares[roll - 1];

            uint256 rollReward = (rollRewardShare * grabbening.rewardsSnapshot) /
                grabbening.rewardSharesTotal;

            grabbeningRewards += rollReward / grabbening.grabberTallies[roll - 1];
        }

        return grabbeningRewards;
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    function setGrabbening(
        uint256 index,
        uint256 start,
        uint256 end,
        uint256 fee,
        uint256[] calldata rewardShares
    ) external onlyOwner {
        require(gameStart > 0, "Must have game start time");
        require(start > 0, "Must have start time");

        Grabbening storage grabbening = grabbenings[index];

        require(grabbening.start == 0, "Grabbening already exists");
        require(end > start, "Must have end time");
        require(fee > 0, "Must have fee");
        require(rewardShares.length == DICE_SIDES, "Must have rewards");

        uint256[DICE_SIDES] memory rewardSharesCopy;

        for (uint256 i = 0; i < DICE_SIDES; i++) {
            rewardSharesCopy[i] = rewardShares[i];
        }

        grabbening.start = start;
        grabbening.end = end;
        grabbening.fee = fee;
        grabbening.rewardShares = rewardSharesCopy;

        for (uint256 i = 0; i < DICE_SIDES; i++) {
            grabbening.rewardSharesTotal += rewardShares[i];
        }
    }

    function reclaimLinkTokens() external onlyOwner {
        LINK_TOKEN.transfer(msg.sender, LINK_TOKEN.balanceOf(address(this)));
    }

    function claimProtocolRewards() external onlyOwner {
        uint256 amount = totalProtocolRewards;

        totalProtocolRewards = 0;

        STAKED_AVAX.transfer(msg.sender, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                             Internal Functions                             */
    /* -------------------------------------------------------------------------- */

    function getTotalFortuneFor(
        address seekerAddress,
        FortuneSeeker storage fortuneSeeker
    ) internal view returns (uint256) {
        return fortuneSeeker.fortune + calculateGrabbeningRewards(seekerAddress);
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

    function calculateRewardFor(
        address seekerAddress,
        FortuneSeeker storage fortuneSeeker
    ) internal view returns (uint256, uint256) {
        uint256 totalRewards = STAKED_AVAX.balanceOf(address(this)) -
            STAKED_AVAX.getSharesByPooledAvax(totalDeposited);

        uint256 seekerFortune = getTotalFortuneFor(
            seekerAddress,
            fortuneSeeker
        );

        uint256 seekerReward = (totalRewards * seekerFortune) / totalFortune;
        uint256 protocolReward = (seekerReward * PROTOCOL_SHARE) / PRECISION;

        return (seekerReward - protocolReward, protocolReward);
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

				outstandingRolls += 1;

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
            potBalance += fortuneRewards;
        }
    }

    function finalizeGrabRoll(
        uint256 diceRoll,
        RollingDice storage rollingDice
    ) internal {
        uint256 prevRoll = grabbenings[rollingDice.grabbeningIndex].rolls[
            rollingDice.fortuneSeeker
        ];

        if (prevRoll > 0) {
            grabbenings[rollingDice.grabbeningIndex].grabberTallies[prevRoll - 1] -= 1;
        }

        grabbenings[rollingDice.grabbeningIndex].grabberTallies[diceRoll - 1] += 1;

        grabbenings[rollingDice.grabbeningIndex].rolls[
            rollingDice.fortuneSeeker
        ] = diceRoll;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        RollingDice storage rollingDice = rollingDie[requestId];
        FortuneSeeker storage fortuneSeeker = fortuneSeekers[
            rollingDice.fortuneSeeker
        ];

        uint256 diceRoll = (randomWords[0] % DICE_SIDES) + 1;

        if (rollingDice.action == RollAction.Add) {
            finalizeAddRoll(diceRoll, fortuneSeeker);
        } else if (rollingDice.action == RollAction.Multiply) {
            finalizeMultiplyRoll(
                diceRoll,
                fortuneSeeker,
                rollingDice.multiplyStake
            );
        } else if (rollingDice.action == RollAction.Grab) {
            finalizeGrabRoll(diceRoll, rollingDice);
        } else {
            revert("Invalid roll action");
        }

        delete rollingDie[requestId];

				outstandingRolls -= 1;

        emit DiceLanded(
            rollingDice.fortuneSeeker,
            rollingDice.action,
            rollingDice.multiplyStake,
            rollingDice.grabbeningIndex,
            requestId,
            diceRoll,
            block.timestamp
        );
    }
}
