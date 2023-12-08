// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Fortunes.sol";
import "../src/FortunesFactory.sol";

contract DeployFortunesFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        bytes32 keyHash = vm.envBytes32("KEYHASH");
        address vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
        address stakedAvax = vm.envAddress("SAVAX");
        uint64 subscriptionId = uint64(vm.envUint("SUBSCRIPTION_ID"));

        vm.startBroadcast(deployerPrivateKey);

        new FortunesFactory(
            owner,
            vrfCoordinator,
            payable(stakedAvax),
            keyHash,
            subscriptionId
        );

        vm.stopBroadcast();
    }
}

contract CreateFortune is Script {
    function run() external {
        FortunesFactory fortunesFactory = FortunesFactory(
            vm.envAddress("FACTORY")
        );
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 diceRollGenerationRate = 278;
        uint256 generationRateDepositFactor = 1 * 1e18;
        uint256 additionMultiplier = 100 * 1e6;
        uint256 minimumFortuneToRollGrab = 500 * 1e6;
        uint256 baseDiceRolls = 10 * 1e6;

        vm.startBroadcast(deployerPrivateKey);

        fortunesFactory.createFortune(
            block.timestamp + 60, // now + 1 minute
            block.timestamp + (30 * 24 * 60 * 60) + (60 * 60), // 30 days + 1 hour
            diceRollGenerationRate,
            generationRateDepositFactor,
            additionMultiplier,
            minimumFortuneToRollGrab,
            baseDiceRolls
        );

        vm.stopBroadcast();
    }
}

contract SetGrabbening is Script {
    function run() external {
        FortunesFactory fortunesFactory = FortunesFactory(
            vm.envAddress("FACTORY")
        );
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 gameIndex = 0;
        uint256 grabbeningIndex = 0;
        uint256 start = block.timestamp + 60;
        uint256 end = block.timestamp + (20 * 24 * 60 * 60) + (60 * 60);
        uint256 fee = 1e5;

        uint256[] memory rewardGroups = new uint256[](4);
        rewardGroups[0] = 0;
        rewardGroups[1] = 3e5;
        rewardGroups[2] = 2e5;
        rewardGroups[3] = 1e5;

        uint256[] memory rollToRewardGroup = new uint256[](12);
        rollToRewardGroup[0] = 0;
        rollToRewardGroup[1] = 0;
        rollToRewardGroup[2] = 0;
        rollToRewardGroup[3] = 0;
        rollToRewardGroup[4] = 0;
        rollToRewardGroup[5] = 0;
        rollToRewardGroup[6] = 1;
        rollToRewardGroup[7] = 1;
        rollToRewardGroup[8] = 1;
        rollToRewardGroup[9] = 2;
        rollToRewardGroup[10] = 2;
        rollToRewardGroup[11] = 3;

        vm.startBroadcast(deployerPrivateKey);

        fortunesFactory.setGrabbening(
            gameIndex,
            grabbeningIndex,
            start,
            end,
            fee,
            rewardGroups,
            rollToRewardGroup
        );

        vm.stopBroadcast();
    }
}
