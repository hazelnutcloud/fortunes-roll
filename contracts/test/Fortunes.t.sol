// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Fortunes} from "../src/Fortunes.sol";
import {FortunesFactory} from "../src/FortunesFactory.sol";
import {IStakedAvax} from "../src/benqi/IStakedAvax.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract FortunesTest is Test {
    using stdStorage for StdStorage;

    uint256 constant PRECISION = 1e6;

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
            minimumFortuneToRollGrab
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
        mockGetPooledAvaxByShares(100 * 1e18, 90 * 1e18);
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
            uint lastDiceRollTimestamp
        ) = fortunes.fortuneSeekers(address(this));

        assertEq(fortune, 0);
        assertEq(deposit, 90 * 1e18);
        assertEq(diceRollsRemaining, 0);
        assertEq(lastDiceRollTimestamp, 0);
        assertEq(fortunes.totalDeposited(), 90 * 1e18);
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
        mockGetPooledAvaxByShares(100 * 1e18, 90 * 1e18);
        mockGetSharesByPooledAvax(90 * 1e18, 100 * 1e18);
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
        mockGetPooledAvaxByShares(100 * 1e18, 90 * 1e18);
        mockGetSharesByPooledAvax(90 * 1e18, 100 * 1e18);
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
            uint lastDiceRollTimestamp
        ) = fortunes.fortuneSeekers(address(this));

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
        mockGetPooledAvaxByShares(100 * 1e18, 90 * 1e18);
        mockGetSharesByPooledAvax(90 * 1e18, 100 * 1e18);
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
        mockGetPooledAvaxByShares(100 * 1e18, 90 * 1e18);
        mockGetSharesByPooledAvax(90 * 1e18, 100 * 1e18);
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
						uint lastDiceRollTimestamp
				) = fortunes.fortuneSeekers(address(this));

				assertEq(fortune, 0);
				assertEq(deposit, 0);
				assertEq(diceRollsRemaining, 0);
				assertEq(lastDiceRollTimestamp, 0);
				assertEq(fortunes.totalDeposited(), 0);
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
}
