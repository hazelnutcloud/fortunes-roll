import { FORTUNES_ABI } from '$lib/abis/fortunes';
import { erc20ABI, readContract } from '@wagmi/core';
import { FORTUNES_ADDRESS } from '$lib/constants/contract-addresses';

export function getPlayer(playerAddress: `0x${string}`) {
	return readContract({
		address: FORTUNES_ADDRESS,
		abi: FORTUNES_ABI,
		functionName: 'players',
		args: [playerAddress]
	});
}
export function getPlayerBalance(playerAddress: `0x${string}`, tokenAddress: `0x${string}`) {
	return readContract({
		address: tokenAddress,
		abi: erc20ABI,
		functionName: 'balanceOf',
		args: [playerAddress]
	});
}

export function getPlayerAllowance({
	playerAddress,
	tokenAddress,
	spender
}: {
	playerAddress: `0x${string}`;
	tokenAddress: `0x${string}`;
	spender: `0x${string}`;
}) {
	return readContract({
		address: tokenAddress,
		abi: erc20ABI,
		functionName: 'allowance',
		args: [playerAddress, spender]
	});
}
