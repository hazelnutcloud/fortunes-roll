import { prepareWriteContract, waitForTransaction, writeContract } from '@wagmi/core';
import { FORTUNES_ABI } from '../abis/fortunes';
import { FORTUNES_ADDRESS } from '../constants/contract-addresses';

export async function deposit(amount: bigint) {
	const config = await prepareWriteContract({
		abi: FORTUNES_ABI,
		address: FORTUNES_ADDRESS,
		functionName: 'deposit',
		args: [amount]
	});

	const tx = await writeContract(config);

	return await waitForTransaction({ hash: tx.hash });
}
