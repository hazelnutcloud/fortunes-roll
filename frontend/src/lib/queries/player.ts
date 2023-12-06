import { FORTUNES_ABI } from '$lib/abis/fortunes';
import { readContract } from '@wagmi/core';
import {FORTUNES_ADDRESS} from "$lib/constants/contract-addresses"

export function getPlayer(address: `0x${string}`) {
	return readContract({
		address: FORTUNES_ADDRESS,
		abi: FORTUNES_ABI,
		functionName: 'players',
		args: [address]
	});
}