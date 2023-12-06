import { erc20ABI, prepareWriteContract, writeContract, waitForTransaction } from '@wagmi/core';
import { maxUint256 } from 'viem';

export async function approve({
	spenderAddress,
	tokenAddress
}: {
	playerAddress: `0x${string}`;
	tokenAddress: `0x${string}`;
	spenderAddress: `0x${string}`;
}) {
	const config = await prepareWriteContract({
		abi: erc20ABI,
		address: tokenAddress,
		functionName: 'approve',
		args: [spenderAddress, maxUint256]
	});

	const tx = await writeContract(config);

	return await waitForTransaction({ hash: tx.hash });
}
