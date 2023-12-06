import { FORTUNES_ABI } from "$lib/abis/fortunes";
import { FORTUNES_ADDRESS } from "$lib/constants/contract-addresses";
import { readContract } from "@wagmi/core";

export function getTotalFortune() {
	return readContract({
		address: FORTUNES_ADDRESS,
		abi: FORTUNES_ABI,
		functionName: 'totalFortune',
	})
}

export function getTotalDeposited()  {
	return readContract({
		address: FORTUNES_ADDRESS,
		abi: FORTUNES_ABI,
		functionName: 'totalDeposited'
	})
}