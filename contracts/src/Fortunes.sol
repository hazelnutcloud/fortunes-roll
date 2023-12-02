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

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    event FortuneGained(
        address indexed player,
        uint256 fortuneGained,
        uint256 timestamp
    );
    event FortuneLost(
        address indexed player,
        uint256 fortuneLost,
        uint256 timestamp
    );
    event Deposit(address indexed player, uint256 amount, uint256 timestamp);
    event Withdraw(
        address indexed player,
        uint256 amount,
        bytes32 kind,
        uint256 timestamp
    );
    event DiceRolled(
        address indexed player,
        RollAction action,
        uint256 multiplyStake,
        uint256 grabbeningIndex,
        uint256 requestId,
        uint256 timestamp
    );
    event DiceLanded(
        address indexed player,
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
    uint256 private constant PROTOCOL_SHARE = 50000; // 5% of generated yield goes to protocol

    bytes32 public constant WITHDRAW = keccak256(abi.encodePacked("withdraw"));
    bytes32 public constant FORFEIT = keccak256(abi.encodePacked("forfeit"));
    bytes32 public constant REDEEM = keccak256(abi.encodePacked("redeem"));

    struct Player {
        uint256 fortune;
        uint256 deposit;
        uint256 diceRollsRemaining;
        uint256 lastDiceRollTimestamp;
        bool hasPendingRoll;
    }

    struct Grabbening {
        uint256 start;
        uint256 end;
        uint256 fee;
        uint256 rewardSharesTotal;
        uint256 rewardsSnapshot;
    }

    struct RollingDice {
        address player;
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

    uint256 public gameStart;
    uint256 public gameEnd;
    uint256 public potBalance;
    uint256 public totalFortune;
    uint256 public totalDeposited;
    uint256 public grabbeningIndex;
    uint256 public totalProtocolRewards;
    uint256 public outstandingRolls;

    uint256 public diceRollGenerationRate;
    uint256 public diceRateDepositFactor; // how much to multiply the dice roll generation rate by based on deposit size. Must be in same precision as native token (e.g. 1e18 for AVAX)
    uint256 public additionMultiplier;
    uint256 public minimumFortuneToRollGrab;
    uint256 public baseDiceRolls;

    mapping(uint256 => Grabbening) public grabbenings;
    mapping(uint256 => uint256[]) public grabbeningRollToRewardGroup; // e.g: 1 - 4: 0, 5 - 8: 1, 9 - 12: 2
    mapping(uint256 => uint256) public grabbeningRewardGroupsLength;
    mapping(uint256 => uint256[]) public grabbeningRewardGroups; // e.g: 0: 0%, 1: 20%, 2: 40%. denominated in PRECISION e.g 50% = 0.5 * PRECISION. Total should never exceed 1 * PRECISION
    mapping(uint256 => uint256[]) public grabbeningGrabberTallies; // number of players who rolled in each group
    mapping(uint256 => mapping(address => uint256)) public grabbeningRolls;
    mapping(address => Player) public players;
    mapping(uint256 => RollingDice) public rollingDie;

    /* -------------------------------------------------------------------------- */
    /*                                 Constructor                                */
    /* -------------------------------------------------------------------------- */

    constructor(
        address _owner,
        address _vrfCoordinator,
        address payable _stakedAvax,
        uint256 _gameStart,
        uint256 _gameEnd,
        uint256 _diceRollGenerationRate,
        uint256 _diceRateDepositFactor,
        uint256 _additionMultiplier,
        uint256 _minimumFortuneToRollGrab,
        uint256 _baseDiceRolls,
        bytes32 keyHash,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) Owned(_owner) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        KEY_HASH = keyHash;
        SUBSCRIPTION_ID = subscriptionId;

        STAKED_AVAX = IStakedAvax(_stakedAvax);

        gameStart = _gameStart;
        gameEnd = _gameEnd;
        diceRollGenerationRate = _diceRollGenerationRate;
        diceRateDepositFactor = _diceRateDepositFactor;
        additionMultiplier = _additionMultiplier;
        minimumFortuneToRollGrab = _minimumFortuneToRollGrab;
        baseDiceRolls = _baseDiceRolls;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */

    function deposit(uint256 shareAmount) external {
        require(shareAmount > 0, "Must deposit more than 0");

        Player storage player = players[msg.sender];

        updateDiceRolls(player);

        uint256 underlyingAmount = STAKED_AVAX.getPooledAvaxByShares(
            shareAmount
        );

        player.deposit += underlyingAmount;
        totalDeposited += underlyingAmount;

        STAKED_AVAX.transferFrom(msg.sender, address(this), shareAmount);

        emit Deposit(msg.sender, shareAmount, block.timestamp);
    }

    function withdraw() public nonReentrant {
        require(block.timestamp < gameStart, "Must be before game start");

        Player storage player = players[msg.sender];

        require(player.deposit > 0, "Must have a deposit");

        uint256 deposited = player.deposit;

        totalDeposited -= deposited;
        player.deposit = 0;

        uint256 amount = STAKED_AVAX.getSharesByPooledAvax(deposited);

        require(
            amount <= STAKED_AVAX.balanceOf(address(this)),
            "Not enough shares to withdraw"
        );

        STAKED_AVAX.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, WITHDRAW, block.timestamp);
    }

    function forfeit() external nonReentrant {
        require(
            block.timestamp >= gameStart && block.timestamp <= gameEnd,
            "Must be during game"
        );

        Player storage player = players[msg.sender];

        require(player.deposit > 0, "Must have a deposit");

        uint256 deposited = player.deposit;
        uint256 fortune = getTotalFortuneFor(msg.sender, player);

        potBalance += fortune;
        totalFortune -= fortune;
        totalDeposited -= deposited;

        delete players[msg.sender];

        uint256 amount = STAKED_AVAX.getSharesByPooledAvax(deposited);

        require(
            amount <= STAKED_AVAX.balanceOf(address(this)),
            "Not enough shares to withdraw"
        );

        STAKED_AVAX.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, FORFEIT, block.timestamp);
        emit FortuneLost(msg.sender, fortune, block.timestamp);
    }

    function redeem() external nonReentrant {
        require(block.timestamp >= gameEnd, "Must be after game has ended");
        require(outstandingRolls == 0, "Must have no outstanding rolls");

        Player storage player = players[msg.sender];

        require(player.deposit > 0, "Must have deposited");

        (uint256 playerReward, uint256 protocolReward) = calculateRewardFor(
            msg.sender,
            player
        );
        playerReward += STAKED_AVAX.getSharesByPooledAvax(player.deposit);

        totalDeposited -= player.deposit;
        totalFortune -= player.fortune;

        totalProtocolRewards += protocolReward;

        delete players[msg.sender];

        STAKED_AVAX.transfer(msg.sender, playerReward);

        emit Withdraw(msg.sender, playerReward, REDEEM, block.timestamp);
        emit FortuneLost(msg.sender, player.fortune, block.timestamp);
    }

    function rollAdd() external returns (uint256) {
        Player storage player = players[msg.sender];

        uint256 requestId = rollDice(player);

        rollingDie[requestId] = RollingDice({
            player: msg.sender,
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

        Player storage player = players[msg.sender];

        uint256 requestId = rollDice(player);

        rollingDie[requestId] = RollingDice({
            player: msg.sender,
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

        Player storage player = players[msg.sender];

        require(
            player.fortune >= minimumFortuneToRollGrab,
            "Must have enough fortune to roll grabbening"
        );

        uint256 fee = (player.fortune * grabbening.fee) / PRECISION;

        player.fortune -= fee;
        totalFortune -= fee;
        potBalance += fee;

        uint256 requestId = rollDice(player);

        rollingDie[requestId] = RollingDice({
            player: msg.sender,
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

        for (
            uint256 i = 0;
            i < grabbeningRewardGroupsLength[grabbeningIndex];
            i++
        ) {
            totalRewards +=
                (grabbeningRewardGroups[grabbeningIndex][i] * potBalance) /
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

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    function setGrabbening(
        uint256 index,
        uint256 start,
        uint256 end,
        uint256 fee,
        uint256[] calldata rewardGroups,
        uint256[] calldata rollToRewardGroup
    ) external onlyOwner {
        require(start >= gameStart && end <= gameEnd, "Must be during game");
        require(end > start, "Must have end time");
        require(fee > 0 && fee <= PRECISION, "Invalid fee");
        require(rollToRewardGroup.length == DICE_SIDES, "Must have rewards");

        Grabbening storage grabbening = grabbenings[index];

        require(grabbening.start == 0, "Grabbening already exists");

        grabbening.start = start;
        grabbening.end = end;
        grabbening.fee = fee;
        grabbeningRewardGroups[index] = rewardGroups;
        grabbeningRollToRewardGroup[index] = rollToRewardGroup;
        grabbeningRewardGroupsLength[index] = rewardGroups.length;
        grabbeningGrabberTallies[index] = new uint256[](rewardGroups.length);

        for (uint256 i = 0; i < rewardGroups.length; i++) {
            grabbening.rewardSharesTotal += rewardGroups[i];
        }

        require(
            grabbening.rewardSharesTotal <= PRECISION,
            "Reward shares must not exceed 100%"
        );
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
        address playerAddress,
        Player storage player
    ) internal view returns (uint256) {
        return player.fortune + calculateGrabbeningRewards(playerAddress);
    }

    function calculateGrabbeningRewards(
        address player
    ) internal view returns (uint256) {
        uint256 grabbeningRewards = 0;

        for (uint256 i = 0; i < grabbeningIndex; i++) {
            Grabbening storage grabbening = grabbenings[i];

            uint256 roll = grabbeningRolls[grabbeningIndex][player];

            if (roll == 0) {
                continue;
            }

            uint256 rollRewardShare = grabbeningRewardGroups[grabbeningIndex][
                grabbeningRollToRewardGroup[grabbeningIndex][roll - 1]
            ];

            uint256 rollReward = (rollRewardShare *
                grabbening.rewardsSnapshot) / grabbening.rewardSharesTotal;

            grabbeningRewards +=
                rollReward /
                grabbeningGrabberTallies[grabbeningIndex][
                    grabbeningRollToRewardGroup[grabbeningIndex][roll - 1]
                ];
        }

        return grabbeningRewards;
    }

    function updateDiceRolls(Player storage player) internal returns (uint256) {
        if (block.timestamp < gameStart) {
            return 0;
        }

        if (player.lastDiceRollTimestamp == 0) {
            player.lastDiceRollTimestamp = gameStart;
            player.diceRollsRemaining = baseDiceRolls;
        }

        player.diceRollsRemaining +=
            ((block.timestamp - player.lastDiceRollTimestamp) *
                diceRollGenerationRate *
                player.deposit) /
            diceRateDepositFactor;
        player.lastDiceRollTimestamp = block.timestamp;

        return player.diceRollsRemaining;
    }

    function calculateRewardFor(
        address playerAddress,
        Player storage player
    ) internal view returns (uint256, uint256) {
        uint256 totalRewards = STAKED_AVAX.balanceOf(address(this)) -
            STAKED_AVAX.getSharesByPooledAvax(totalDeposited);

        uint256 playerFortune = getTotalFortuneFor(playerAddress, player);

        if (totalFortune == 0) {
            return (0, 0);
        }

        uint256 playerReward = (totalRewards * playerFortune) / totalFortune;
        uint256 protocolReward = (playerReward * PROTOCOL_SHARE) / PRECISION;

        return (playerReward - protocolReward, protocolReward);
    }

    function rollDice(Player storage player) internal returns (uint256) {
        require(!player.hasPendingRoll, "Must not have pending roll");
        require(player.deposit > 0, "Must have a deposit");
        require(
            block.timestamp >= gameStart && block.timestamp <= gameEnd,
            "Must be during game"
        );

        updateDiceRolls(player);

        require(
            player.diceRollsRemaining >= 1 * PRECISION,
            "Must have dice rolls remaining"
        );

        outstandingRolls += 1;

        player.diceRollsRemaining -= (1 * PRECISION);
        player.hasPendingRoll = true;

        uint256 requestId = COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            3,
            100_000,
            1
        );

        return requestId;
    }

    function finalizeAddRoll(uint256 diceRoll, Player storage player) internal {
        uint256 fortuneRewards = diceRoll * additionMultiplier;
        player.fortune += fortuneRewards;
        totalFortune += fortuneRewards;
    }

    function finalizeMultiplyRoll(
        uint256 diceRoll,
        Player storage player,
        uint256 stake,
        address playerAddress
    ) internal {
        bool isWin = diceRoll >= stake;

        uint256 fortuneRewards = (getTotalFortuneFor(playerAddress, player) *
            stake) / DICE_SIDES;

        if (isWin) {
            player.fortune += fortuneRewards;
            totalFortune += fortuneRewards;
        } else {
            player.fortune -= fortuneRewards;
            totalFortune -= fortuneRewards;
            potBalance += fortuneRewards;
        }
    }

    function finalizeGrabRoll(
        uint256 diceRoll,
        RollingDice storage rollingDice
    ) internal {
        uint256 prevRoll = grabbeningRolls[rollingDice.grabbeningIndex][
            rollingDice.player
        ];

        if (prevRoll > 0) {
            grabbeningGrabberTallies[rollingDice.grabbeningIndex][
                grabbeningRollToRewardGroup[rollingDice.grabbeningIndex][
                    prevRoll - 1
                ]
            ] -= 1;
        }

        grabbeningGrabberTallies[rollingDice.grabbeningIndex][
            grabbeningRollToRewardGroup[rollingDice.grabbeningIndex][
                diceRoll - 1
            ]
        ] += 1;

        grabbeningRolls[rollingDice.grabbeningIndex][
            rollingDice.player
        ] = diceRoll;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        RollingDice storage rollingDice = rollingDie[requestId];
        Player storage player = players[rollingDice.player];

        uint256 diceRoll = (randomWords[0] % DICE_SIDES) + 1;

        if (rollingDice.action == RollAction.Add) {
            finalizeAddRoll(diceRoll, player);
        } else if (rollingDice.action == RollAction.Multiply) {
            finalizeMultiplyRoll(
                diceRoll,
                player,
                rollingDice.multiplyStake,
                rollingDice.player
            );
        } else if (rollingDice.action == RollAction.Grab) {
            finalizeGrabRoll(diceRoll, rollingDice);
        } else {
            revert("Invalid roll action");
        }

        delete rollingDie[requestId];

        outstandingRolls -= 1;
        player.hasPendingRoll = false;

        emit DiceLanded(
            rollingDice.player,
            rollingDice.action,
            rollingDice.multiplyStake,
            rollingDice.grabbeningIndex,
            requestId,
            diceRoll,
            block.timestamp
        );
    }
}
