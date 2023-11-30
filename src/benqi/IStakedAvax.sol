// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {StakedAvaxStorage} from "./StakedAvaxStorage.sol";

interface IStakedAvax {
    /**
     * @notice Initialize the StakedAvax contract
     * @param _cooldownPeriod Time delay before shares can be burned for AVAX
     * @param _redeemPeriod AVAX redemption period after unlock cooldown has elapsed
     */
    function initialize(uint _cooldownPeriod, uint _redeemPeriod) external;

    /**
     * @return The name of the token.
     */
    function name() external pure returns (string memory);

    /**
     * @return The symbol of the token.
     */
    function symbol() external pure returns (string memory);

    /**
     * @return The number of decimals for getting user representation of a token amount.
     */
    function decimals() external pure returns (uint8);

    /**
     * @return The amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @return The amount of sAVAX tokens owned by the `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @notice Moves `amount` tokens from the caller's account to the `recipient` account.
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * - the contract must not be paused.
     *
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transfer(
        address recipient,
        uint amount
    ) external returns (bool);

    /**
     * @return The remaining number of tokens that `spender` is allowed to spend on behalf of `owner`
     * through `transferFrom`. This is zero by default.
     *
     * @dev This value changes when `approve` or `transferFrom` is called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - the contract must not be paused.
     *
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approve(
        address spender,
        uint amount
    ) external returns (bool);

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
     * is then deducted from the caller's allowance.
     *
     * @return A boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero addresses.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least `amount`.
     * - the contract must not be paused.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    /**
     * @return The amount of shares that corresponds to `avaxAmount` protocol-controlled AVAX.
     */
    function getSharesByPooledAvax(uint avaxAmount) external view returns (uint);

    /**
     * @return The amount of AVAX that corresponds to `shareAmount` token shares.
     */
    function getPooledAvaxByShares(
        uint shareAmount
    ) external view returns (uint);

    /**
     * @notice Start unlocking cooldown period for `shareAmount` AVAX
     * @param shareAmount Amount of shares to unlock
     */
    function requestUnlock(uint shareAmount) external;

    /**
     * @notice Get the number of active unlock requests by user
     * @param user User address
     */
    function getUnlockRequestCount(address user) external view returns (uint);

    /**
     * @notice Get a subsection of a user's unlock requests
     * @param user User account address
     * @param from List start index
     * @param to List end index
     */
    function getPaginatedUnlockRequests(
        address user,
        uint from,
        uint to
    )
        external
        view
        returns (StakedAvaxStorage.UnlockRequest[] memory, uint[] memory);

    /**
     * @notice Cancel all unlock requests that are pending the cooldown period to elapse.
     */
    function cancelPendingUnlockRequests() external;

    /**
     * @notice Cancel all unlock requests that are redeemable.
     */
    function cancelRedeemableUnlockRequests() external;

    /**
     * @notice Cancel an unexpired unlock request
     * @param unlockIndex Index number of the cancelled unlock
     */
    function cancelUnlockRequest(uint unlockIndex) external;

    /**
     * @notice Redeem all redeemable AVAX from all unlocks
     */
    function redeem() external;

    /**
     * @notice Redeem AVAX after cooldown has finished
     * @param unlockIndex Index number of the redeemed unlock request
     */
    function redeem(uint unlockIndex) external;

    /**
     * @notice Redeem all sAVAX held in custody for overdue unlock requests
     */
    function redeemOverdueShares() external;

    /**
     * @notice Redeem sAVAX held in custody for the given unlock request
     * @param unlockIndex Unlock request array index
     */
    function redeemOverdueShares(
        uint unlockIndex
    ) external;

    /**
     * @notice Process user deposit, mints liquid tokens and increase the pool buffer
     * @return Amount of sAVAX shares generated
     */
    function submit() external payable returns (uint);

    receive() external payable;
}
