// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Fortunes} from "../src/Fortunes.sol";
import {FortunesFactory} from "../src/FortunesFactory.sol";
import {IStakedAvax} from "../src/benqi/IStakedAvax.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {VRFCoordinatorV2Interface} from "../src/chainlink/VRFCoordinatorV2Interface.sol";

contract FortunesTest is Test {
    using stdStorage for StdStorage;

    uint256 constant PRECISION = 1e6;
    uint256 private constant PROTOCOL_SHARE = 50000;

    FortunesFactory fortunesFactory;
    Fortunes fortunes;
    address vrfCoordinator = makeAddr("vrfCoordinator");
    address sAvax = makeAddr("sAvax");
    address link = makeAddr("link");
    bytes32 keyHash = bytes32(0);
    uint64 subscriptionId = 0;
    uint256 gameStart = block.timestamp + 10;
    uint256 gameEnd = block.timestamp + 100;
    uint256 diceRollGenerationRate = 278;
    uint256 generationRateDepositFactor = 10 * 1e18; // ~ 1 roll per hour per 10 AVAX
    uint256 additionMultiplier = 100 * PRECISION; // 100 fortune per dice point
    uint256 minimumFortuneToRollGrab = 500 * PRECISION;
    uint256 baseDiceRolls = 10 * PRECISION;

    function setUp() public {
        fortunesFactory = new FortunesFactory(
            address(this),
            vrfCoordinator,
            payable(sAvax),
            link,
            keyHash,
            subscriptionId
        );
        fortunes = fortunesFactory.createFortune(
            gameStart,
            gameEnd,
            diceRollGenerationRate,
            generationRateDepositFactor,
            additionMultiplier,
            minimumFortuneToRollGrab,
            baseDiceRolls
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                                Deposit Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_RevertIf_DepositIsZero() external {
        vm.expectRevert(bytes("Must deposit more than 0"));
        fortunes.deposit(0);
    }

    function test_Deposit() external {
        mockGetPooledAvaxByShares(100 * 1e18, 110 * 1e18);
        mockTransferFrom(
            address(sAvax),
            address(this),
            address(fortunes),
            100 * 1e18
        );
        fortunes.deposit(100 * 1e18);

        (
            uint fortune,
            uint deposit,
            uint diceRollsRemaining,
            uint lastDiceRollTimestamp,

        ) = fortunes.players(address(this));

        assertEq(fortune, 0);
        assertEq(deposit, 110 * 1e18);
        assertEq(diceRollsRemaining, 0);
        assertEq(lastDiceRollTimestamp, 0);
        assertEq(fortunes.totalDeposited(), 110 * 1e18);

        vm.warp(gameStart + 50);
        mockTransferFrom(
            address(sAvax),
            address(this),
            address(fortunes),
            50 * 1e18
        );
        mockGetPooledAvaxByShares(50 * 1e18, 58 * 1e18);
        fortunes.deposit(50 * 1e18);

        (, deposit, diceRollsRemaining, lastDiceRollTimestamp, ) = fortunes
            .players(address(this));

        assertEq(deposit, (110 + 58) * 1e18);
        assertEq(
            diceRollsRemaining,
            ((50 * diceRollGenerationRate * 110 * 1e18) /
                generationRateDepositFactor) + baseDiceRolls
        );
        assertEq(lastDiceRollTimestamp, gameStart + 50);
        assertEq(fortunes.totalDeposited(), (110 + 58) * 1e18);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Withdraw Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_RevertIf_WithdrawAfterGameStart() external {
        vm.warp(gameStart + 1);
        vm.expectRevert(bytes("Must be before game start"));
        fortunes.withdraw();
    }

    function test_RevertIf_WithdrawWithNoDeposit() external {
        vm.expectRevert(bytes("Must have a deposit"));
        fortunes.withdraw();
    }

    function test_RevertIf_WithdrawMoreThanContractBalance() external {
        mockGetPooledAvaxByShares(100 * 1e18, 110 * 1e18);
        mockGetSharesByPooledAvax(110 * 1e18, 100 * 1e18);
        mockBalanceOf(sAvax, address(fortunes), 10 * 1e18);
        mockTransferFrom(
            address(sAvax),
            address(this),
            address(fortunes),
            100 * 1e18
        );

        fortunes.deposit(100 * 1e18);

        vm.expectRevert("Not enough shares to withdraw");
        fortunes.withdraw();
    }

    function test_Withdraw() external {
        mockGetPooledAvaxByShares(100 * 1e18, 110 * 1e18);
        mockGetSharesByPooledAvax(110 * 1e18, 100 * 1e18);
        mockBalanceOf(sAvax, address(fortunes), 100 * 1e18);
        mockTransferFrom(
            address(sAvax),
            address(this),
            address(fortunes),
            100 * 1e18
        );
        mockTransfer(address(sAvax), address(this), 100 * 1e18);

        fortunes.deposit(100 * 1e18);
        fortunes.withdraw();

        (
            uint fortune,
            uint deposit,
            uint diceRollsRemaining,
            uint lastDiceRollTimestamp,

        ) = fortunes.players(address(this));

        assertEq(fortune, 0);
        assertEq(deposit, 0);
        assertEq(diceRollsRemaining, 0);
        assertEq(lastDiceRollTimestamp, 0);
        assertEq(fortunes.totalDeposited(), 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Forfeit Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_RevertIf_ForfeitOutsideGame() external {
        vm.warp(gameStart - 1);
        vm.expectRevert(bytes("Must be during game"));
        fortunes.forfeit();

        vm.warp(gameEnd + 1);
        vm.expectRevert(bytes("Must be during game"));
        fortunes.forfeit();
    }

    function test_RevertIf_ForfeitWithNoDeposit() external {
        vm.warp(gameStart);
        vm.expectRevert(bytes("Must have a deposit"));
        fortunes.forfeit();
    }

    function test_RevertIf_ForfeitMoreThanContractBalance() external {
        mockGetPooledAvaxByShares(100 * 1e18, 110 * 1e18);
        mockGetSharesByPooledAvax(110 * 1e18, 100 * 1e18);
        mockBalanceOf(sAvax, address(fortunes), 10 * 1e18);
        mockTransferFrom(
            address(sAvax),
            address(this),
            address(fortunes),
            100 * 1e18
        );

        fortunes.deposit(100 * 1e18);

        vm.warp(gameStart);
        vm.expectRevert("Not enough shares to withdraw");
        fortunes.forfeit();
    }

    function test_Forfeit() external {
        mockGetPooledAvaxByShares(100 * 1e18, 110 * 1e18);
        mockGetSharesByPooledAvax(110 * 1e18, 100 * 1e18);
        mockBalanceOf(sAvax, address(fortunes), 100 * 1e18);
        mockTransferFrom(
            address(sAvax),
            address(this),
            address(fortunes),
            100 * 1e18
        );
        mockTransfer(address(sAvax), address(this), 100 * 1e18);

        fortunes.deposit(100 * 1e18);

        vm.warp(gameStart);
        fortunes.forfeit();

        (
            uint fortune,
            uint deposit,
            uint diceRollsRemaining,
            uint lastDiceRollTimestamp,

        ) = fortunes.players(address(this));

        assertEq(fortune, 0);
        assertEq(deposit, 0);
        assertEq(diceRollsRemaining, 0);
        assertEq(lastDiceRollTimestamp, 0);
        assertEq(fortunes.totalDeposited(), 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Redeem Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_RevertIf_RedeemBeforeGameEndAndNoDeposit() external {
        vm.expectRevert(bytes("Must be after game has ended"));
        fortunes.redeem();

        vm.warp(gameEnd);
        vm.expectRevert("Must have deposited");
        fortunes.redeem();
    }

    function test_RevertIf_RedeemWithOutstandingRolls() external {
        vm.warp(gameEnd);
        stdstore
            .target(address(fortunes))
            .sig(fortunes.outstandingRolls.selector)
            .checked_write(1);
        vm.expectRevert(bytes("Must have no outstanding rolls"));
        fortunes.redeem();
    }

    function test_RevertIf_RedeemMoreThanContractBalance() external {
        mockGetPooledAvaxByShares(100 * 1e18, 110 * 1e18);
        mockGetSharesByPooledAvax(110 * 1e18, 100 * 1e18);
        mockBalanceOf(sAvax, address(fortunes), 10 * 1e18);
        mockTransferFrom(
            address(sAvax),
            address(this),
            address(fortunes),
            100 * 1e18
        );

        fortunes.deposit(100 * 1e18);

        vm.warp(gameEnd);
        vm.expectRevert(stdError.arithmeticError); // should be impossible to get this error
        fortunes.redeem();
    }

    function test_RedeemWithNoRewards() external {
        mockGetPooledAvaxByShares(100 * 1e18, 110 * 1e18);
        mockGetSharesByPooledAvax(110 * 1e18, 100 * 1e18);
        mockBalanceOf(sAvax, address(fortunes), 100 * 1e18);
        mockTransferFrom(
            address(sAvax),
            address(this),
            address(fortunes),
            100 * 1e18
        );
        mockTransfer(address(sAvax), address(this), 100 * 1e18);

        fortunes.deposit(100 * 1e18);

        vm.warp(gameEnd);
        fortunes.redeem();

        (
            uint fortune,
            uint deposit,
            uint diceRollsRemaining,
            uint lastDiceRollTimestamp,

        ) = fortunes.players(address(this));

        assertEq(fortune, 0);
        assertEq(deposit, 0);
        assertEq(diceRollsRemaining, 0);
        assertEq(lastDiceRollTimestamp, 0);
        assertEq(fortunes.totalDeposited(), 0);
    }

    function test_RedeemWithRewards() external {
        // testing redeem with 110 / 220 deposited, 80 / 100 fortune. Should get 80% - protocol share of the rewards.
        mockGetPooledAvaxByShares(100 * 1e18, 110 * 1e18);
        mockGetSharesByPooledAvax(110 * 1e18, 100 * 1e18);
        mockBalanceOf(sAvax, address(fortunes), 200 * 1e18);
        mockTransferFrom(
            address(sAvax),
            address(this),
            address(fortunes),
            100 * 1e18
        );

        uint256 initialDeposit = 100 * 1e18;

        fortunes.deposit(initialDeposit);

        uint256 playerFortune = 80 * 1e6;
        uint256 totalFortune = 100 * 1e6;

        mockGetSharesByPooledAvax(220 * 1e18, 180 * 1e18);
        stdstore.target(address(fortunes)).sig("totalFortune()").checked_write(
            totalFortune
        );
        stdstore
            .target(address(fortunes))
            .sig("totalDeposited()")
            .checked_write(220 * 1e18);
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .checked_write(playerFortune);

        uint256 yield = (200 - 180) * 1e18;
        uint256 expectedRedeemed = (((yield * playerFortune * (PRECISION - PROTOCOL_SHARE)) /
            totalFortune) / PRECISION) + (initialDeposit); // (20 sAVAX * 80 fortune * protocolShare / 100 totalFortune / precision) + 100 sAVAX

        mockTransfer(sAvax, address(this), expectedRedeemed);

        vm.warp(gameEnd);
        fortunes.redeem();

        (
            uint fortune,
            uint deposit,
            uint diceRollsRemaining,
            uint lastDiceRollTimestamp,

        ) = fortunes.players(address(this));

        assertEq(fortune, 0);
        assertEq(deposit, 0);
        assertEq(diceRollsRemaining, 0);
        assertEq(lastDiceRollTimestamp, 0);
        assertEq(fortunes.totalDeposited(), 110 * 1e18);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Roll Tests                                 */
    /* -------------------------------------------------------------------------- */

    function test_RevertIf_RollWithNoDeposit() external {
        vm.expectRevert(bytes("Must have a deposit"));
        fortunes.rollAdd();

        vm.expectRevert(bytes("Must have a deposit"));
        fortunes.rollMultiply(0);

        stdstore
            .target(address(fortunes))
            .sig("grabbenings(uint256)")
            .with_key(uint256(0))
            .checked_write(gameStart);
        stdstore
            .target(address(fortunes))
            .sig("grabbenings(uint256)")
            .with_key(uint256(0))
            .depth(1)
            .checked_write(gameEnd);
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .checked_write(minimumFortuneToRollGrab);

        vm.warp(gameStart + 1);
        vm.expectRevert(bytes("Must have a deposit"));
        fortunes.rollGrab();
    }

    function test_RevertIf_RollOutsideGame() external {
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .depth(1)
            .checked_write(100 * 1e18);

        vm.warp(gameStart - 1);

        vm.expectRevert(bytes("Must be during game"));
        fortunes.rollAdd();

        vm.expectRevert(bytes("Must be during game"));
        fortunes.rollMultiply(0);

        stdstore
            .target(address(fortunes))
            .sig("grabbenings(uint256)")
            .with_key(uint256(0))
            .checked_write(gameStart);
        stdstore
            .target(address(fortunes))
            .sig("grabbenings(uint256)")
            .with_key(uint256(0))
            .depth(1)
            .checked_write(gameEnd);
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .checked_write(minimumFortuneToRollGrab);

        // We check elsewhere that the grabbening cannot be set outside the game
        vm.expectRevert(bytes("Must be during open grabbening"));
        fortunes.rollGrab();

        vm.warp(gameEnd + 1);

        vm.expectRevert(bytes("Must be during game"));
        fortunes.rollAdd();

        vm.expectRevert(bytes("Must be during game"));
        fortunes.rollMultiply(0);

        vm.expectRevert(bytes("Must be during open grabbening"));
        fortunes.rollGrab();
    }

    function test_RevertIf_RollWithNotEnoughDiceRolls() external {
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .depth(1)
            .checked_write(100 * 1e18);
        stdstore.target(address(fortunes)).sig("baseDiceRolls()").checked_write(
            uint256(0)
        );

        vm.warp(gameStart);
        vm.expectRevert("Must have dice rolls remaining");
        fortunes.rollAdd();
    }

    function test_RevertIf_RollWithPendingRoll() external {
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .depth(1)
            .checked_write(100 * 1e18);
        vm.warp(gameStart);
        mockVrfCoordinatorRequestRandomWords(0);

        fortunes.rollAdd();
        vm.expectRevert("Must not have pending roll");
        fortunes.rollAdd();
    }

    function test_RevertIf_RollGrabWithNotEnoughFortune() external {
        stdstore
            .target(address(fortunes))
            .sig("grabbenings(uint256)")
            .with_key(uint256(0))
            .checked_write(gameStart);
        stdstore
            .target(address(fortunes))
            .sig("grabbenings(uint256)")
            .with_key(uint256(0))
            .depth(1)
            .checked_write(gameEnd);
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .checked_write(minimumFortuneToRollGrab - 1);

        vm.warp(gameStart);
        vm.expectRevert("Must have enough fortune to roll grabbening");
        fortunes.rollGrab();
    }

    function test_RollAdd(uint256 randomNumber) external {
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .depth(1)
            .checked_write(100 * 1e18);
        vm.warp(gameStart);
        mockVrfCoordinatorRequestRandomWords(0);

        uint256 requestId = fortunes.rollAdd();

        (
            uint256 fortune,
            ,
            uint256 diceRollsRemaining,
            uint256 lastDiceRollTimestamp,
            bool hasPendingRoll
        ) = fortunes.players(address(this));

        assertEq(diceRollsRemaining, baseDiceRolls - (1 * PRECISION));
        assertEq(lastDiceRollTimestamp, gameStart);
        assertEq(requestId, 0);
        assert(hasPendingRoll);
        assertEq(fortunes.outstandingRolls(), 1);
        assertEq(fortunes.totalFortune(), 0);
        assertEq(fortune, 0);

        (
            address player,
            uint256 multiplyStake,
            uint256 grabbeningIndex,
            Fortunes.RollAction action
        ) = fortunes.rollingDie(requestId);

        assertEq(player, address(this));
        assertEq(multiplyStake, 0);
        assertEq(grabbeningIndex, 0);
        assertEq(uint8(action), uint8(Fortunes.RollAction.Add));

        vm.roll(block.number + 1); // simulate VRFCoordinator callback at next block. Not really necessary, but makes the test more realistic
        vm.prank(vrfCoordinator);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomNumber;
        fortunes.rawFulfillRandomWords(requestId, randomWords);

        (fortune, , , , hasPendingRoll) = fortunes.players(address(this));
        uint256 expectedFortune = ((randomNumber % 12) + 1) *
            additionMultiplier;

        assertEq(fortune, expectedFortune);
        assertEq(fortunes.outstandingRolls(), 0);
        assertEq(fortunes.totalFortune(), expectedFortune);
        assert(!hasPendingRoll);

        (player, , , ) = fortunes.rollingDie(requestId);
        assertEq(player, address(0));
    }

    function test_RollMultiply(uint256 stake, uint256 randomNumber) external {
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .depth(1)
            .checked_write(100 * 1e18);
        uint256 initialFortune = 1_000 * 1e6;
        stdstore
            .target(address(fortunes))
            .sig("players(address)")
            .with_key(address(this))
            .checked_write(initialFortune);
        stdstore.target(address(fortunes)).sig("totalFortune()").checked_write(
            initialFortune
        );
        vm.warp(gameStart);
        mockVrfCoordinatorRequestRandomWords(0);

        uint256 requestId = fortunes.rollMultiply(stake);

        (
            uint256 fortune,
            ,
            uint256 diceRollsRemaining,
            uint256 lastDiceRollTimestamp,
            bool hasPendingRoll
        ) = fortunes.players(address(this));

        assertEq(diceRollsRemaining, baseDiceRolls - (1 * PRECISION));
        assertEq(lastDiceRollTimestamp, gameStart);
        assertEq(requestId, 0);
        assertEq(fortune, initialFortune);
        assert(hasPendingRoll);
        assertEq(fortunes.outstandingRolls(), 1);
        assertEq(fortunes.totalFortune(), initialFortune);

        (
            address player,
            uint256 multiplyStake,
            uint256 grabbeningIndex,
            Fortunes.RollAction action
        ) = fortunes.rollingDie(requestId);

        uint256 normalizedStake = (stake % 12) + 1;
        uint256 normalizedRandomNumber = (randomNumber % 12) + 1;

        assertEq(player, address(this));
        assertEq(multiplyStake, normalizedStake);
        assertEq(grabbeningIndex, 0);
        assertEq(uint8(action), uint8(Fortunes.RollAction.Multiply));

        vm.roll(block.number + 1); // simulate VRFCoordinator callback at next block. Not really necessary, but makes the test more realistic
        vm.prank(vrfCoordinator);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomNumber;
        fortunes.rawFulfillRandomWords(requestId, randomWords);

        (fortune, , , , hasPendingRoll) = fortunes.players(address(this));
        uint256 winnings = (normalizedStake * initialFortune) / 12;
        uint256 expectedFortune = normalizedRandomNumber >= normalizedStake
            ? initialFortune + winnings
            : initialFortune - winnings;

        assertEq(fortune, expectedFortune);
        assertEq(fortunes.outstandingRolls(), 0);
        assertEq(fortunes.totalFortune(), expectedFortune);
        assert(!hasPendingRoll);

        (player, , , ) = fortunes.rollingDie(requestId);
        assertEq(player, address(0));
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Mocks                                   */
    /* -------------------------------------------------------------------------- */

    function mockGetPooledAvaxByShares(
        uint256 shares,
        uint256 pooledAvax
    ) internal {
        vm.mockCall(
            sAvax,
            abi.encodeWithSelector(
                IStakedAvax.getPooledAvaxByShares.selector,
                shares
            ),
            abi.encode(pooledAvax)
        );
    }

    function mockGetSharesByPooledAvax(
        uint256 pooledAvax,
        uint256 shares
    ) internal {
        vm.mockCall(
            sAvax,
            abi.encodeWithSelector(
                IStakedAvax.getSharesByPooledAvax.selector,
                pooledAvax
            ),
            abi.encode(shares)
        );
    }

    function mockTransferFrom(
        address contractAddr,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes memory data = abi.encodeWithSelector(
            ERC20.transferFrom.selector,
            from,
            to,
            amount
        );
        vm.mockCall(contractAddr, data, abi.encode(0));
        vm.expectCall(contractAddr, data);
    }

    function mockTransfer(
        address contractAddr,
        address to,
        uint256 amount
    ) internal {
        bytes memory data = abi.encodeWithSelector(
            ERC20.transfer.selector,
            to,
            amount
        );
        vm.mockCall(contractAddr, data, abi.encode(0));
        vm.expectCall(contractAddr, data);
    }

    function mockBalanceOf(
        address contractAddr,
        address owner,
        uint balance
    ) internal {
        vm.mockCall(
            contractAddr,
            abi.encodeWithSelector(IStakedAvax.balanceOf.selector, owner),
            abi.encode(balance)
        );
    }

    function mockVrfCoordinatorRequestRandomWords(uint256 requestId) internal {
        vm.mockCall(
            vrfCoordinator,
            abi.encodeWithSelector(
                VRFCoordinatorV2Interface.requestRandomWords.selector
            ),
            abi.encode(requestId)
        );
    }
}
