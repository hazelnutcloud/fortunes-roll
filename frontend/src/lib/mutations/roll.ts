import { prepareWriteContract, waitForTransaction, writeContract } from '@wagmi/core';
import { FORTUNES_ABI } from '../abis/fortunes';
import { FORTUNES_ADDRESS } from '../constants/contract-addresses';

export type RollParams = { type: string; multiplyStake?: bigint; addMultiplier: number };

export async function rollFor({ type, multiplyStake, addMultiplier }: RollParams) {
	let config;

	const params = {
		address: FORTUNES_ADDRESS,
		abi: FORTUNES_ABI
	} as const;

	if (type === 'add') {
		if (addMultiplier > 1) {
			config = await prepareWriteContract({
				...params,
				functionName: 'rollAddMultiple',
				args: [BigInt(addMultiplier)]
			});
		} else {
			config = await prepareWriteContract({
				...params,
				functionName: 'rollAdd'
			});
		}
	} else if (type === 'multiply') {
		if (!multiplyStake) multiplyStake = 1n;
		config = await prepareWriteContract({
			...params,
			functionName: 'rollMultiply',
			args: [multiplyStake]
		});
	} else {
		config = await prepareWriteContract({
			...params,
			functionName: 'rollGrab'
		});
	}

	const res = await writeContract(config);

	return await waitForTransaction({ hash: res.hash });
}
