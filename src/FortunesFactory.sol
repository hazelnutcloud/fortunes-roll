// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Owned} from "solmate/auth/Owned.sol";
import {Fortunes} from "./fortunes.sol";
import {IStakedAvax} from "./benqi/IStakedAvax.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract FortunesFactory is Owned {
    event FortuneCreated(uint256 indexed index, address indexed fortune);

    address public vrfCoordinator;
    address payable public stakedAvax;
    address public linkToken;
    bytes32 keyHash;
    uint64 subscriptionId;

    uint256 public index;

    mapping(uint256 => address payable) public fortunes;

    constructor(
        address owner,
        address _vrfCoordinator,
        address payable _stakedAvax,
        address _linkToken,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) Owned(owner) {
        vrfCoordinator = _vrfCoordinator;
        stakedAvax = _stakedAvax;
        linkToken = _linkToken;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }

    function createFortune(
        uint256 gameStart,
        uint256 gameEnd,
        uint256 diceRollGenerationRate,
        uint256 additionMultiplier,
        uint256 multiplicationMultiplier,
        uint256 minimumFortuneToRollSeize
    ) public onlyOwner returns (uint256) {
        fortunes[index] = payable(
            new Fortunes(
                address(this),
                vrfCoordinator,
                stakedAvax,
                linkToken,
                gameStart,
                gameEnd,
                diceRollGenerationRate,
                additionMultiplier,
                multiplicationMultiplier,
                minimumFortuneToRollSeize,
                keyHash,
                subscriptionId
            )
        );

        emit FortuneCreated(index, fortunes[index]);

        index++;
        return index;
    }

    function setSeizure(
        uint256 gameIndex,
        uint256 seizureIndex,
        uint256 start,
        uint256 end,
        uint256 fee,
        uint256[] memory rewardShares
    ) external onlyOwner {
        Fortunes(fortunes[gameIndex]).setSeizure(
            seizureIndex,
            start,
            end,
            fee,
            rewardShares
        );
    }

    function reclaimLinkTokens(uint256 gameIndex) external onlyOwner {
        Fortunes(fortunes[gameIndex]).reclaimLinkTokens();

        ERC20 linkTokenContract = ERC20(linkToken);

        uint256 balance = linkTokenContract.balanceOf(address(this));

        linkTokenContract.transfer(msg.sender, balance);
    }

    function claimProtocolRewards(uint256 gameIndex) external onlyOwner {
        Fortunes(fortunes[gameIndex]).claimProtocolRewards();

        IStakedAvax stakedAvaxContract = IStakedAvax(stakedAvax);

        uint256 balance = stakedAvaxContract.balanceOf(address(this));

        stakedAvaxContract.transfer(msg.sender, balance);
    }
}
