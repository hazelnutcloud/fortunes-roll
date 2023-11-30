// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Owned} from "solmate/auth/Owned.sol";

contract FortunesFactory is Owned {
	constructor(address owner) Owned(owner) {}
}