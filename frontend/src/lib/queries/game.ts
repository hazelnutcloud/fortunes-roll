import { FORTUNES_ABI } from '$lib/abis/fortunes';
import { FORTUNES_ADDRESS } from '$lib/constants/contract-addresses';
import { readContract } from '@wagmi/core';

const contract = { address: FORTUNES_ADDRESS, abi: FORTUNES_ABI } as const;

export function getTotalFortune() {
	return readContract({
		...contract,
		functionName: 'totalFortune'
	});
}

export function getTotalDeposited() {
	return readContract({
		...contract,
		functionName: 'totalDeposited'
	});
}

export function getGameStart() {
	return readContract({
		...contract,
		functionName: 'gameStart'
	});
}

export function getGameEnd() {
	return readContract({
		...contract,
		functionName: 'gameEnd'
	});
}

export function getGrabbeningIndex() {
	return readContract({
		...contract,
		functionName: 'grabbeningIndex'
	});
}

export function getGrabbening(index: bigint) {
	return readContract({
		...contract,
		functionName: 'grabbenings',
		args: [index]
	});
}

export async function getGrabbeningRewardsInfo(index: bigint) {
	const rollsToRewards = await Promise.all(
		Array(12)
			.fill(0)
			.map((_, i) =>
				readContract({
					...contract,
					functionName: 'grabbeningRollToRewardGroup',
					args: [index, BigInt(i)]
				})
			)
	);

	const groups = rollsToRewards.reduce((acc, curr) => {
		if (curr > acc) return curr;
		return acc;
	}, 0n);

	const rewardGroups = await Promise.all(
		Array(Number(groups) + 1)
			.fill(0)
			.map((_, i) =>
				readContract({
					...contract,
					functionName: 'grabbeningRewardGroups',
					args: [index, BigInt(i)]
				})
			)
	);

	return { rollsToRewards, rewardGroups };
}

export async function getPlayerGrabbening(index: bigint, playerAddress: `0x${string}`, rollToRewards: bigint[]) {
	const roll = await readContract({
		...contract,
		functionName: 'grabbeningRolls',
		args: [index, playerAddress]
	});
	
	const rewardGroup = rollToRewards[Number(roll) - 1];

	const tally = await getGrabbeningTallies(index, rewardGroup);

	return { roll, tally };
}

export function getGrabbeningTallies(index: bigint, rewardGroup: bigint) {
	return readContract({
		...contract,
		functionName: 'grabbeningGrabberTallies',
		args: [index, rewardGroup]
	});
}

export function getPotBalance() {
	return readContract({
		...contract,
		functionName: 'potBalance'
	});
}
