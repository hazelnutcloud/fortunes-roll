import { FORTUNES_ABI } from '$lib/abis/fortunes';
import { FORTUNES_ADDRESS } from '$lib/constants/contract-addresses';
import { publicClient } from '$lib/queries/public-client';
import type { WatchContractEventCallback } from '@wagmi/core';

export function watchDiceLand(
	callback: WatchContractEventCallback<typeof FORTUNES_ABI, 'DiceLanded'>
) {
	return publicClient.watchContractEvent({
		abi: FORTUNES_ABI,
		address: FORTUNES_ADDRESS,
		eventName: 'DiceLanded',
		pollingInterval: 1000,
		onLogs: callback
	})
}
