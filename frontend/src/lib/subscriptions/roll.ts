import { FORTUNES_ABI } from '$lib/abis/fortunes';
import { FORTUNES_ADDRESS } from '$lib/constants/contract-addresses';
import { watchContractEvent, type WatchContractEventCallback } from '@wagmi/core';

export function watchDiceLand(
	callback: WatchContractEventCallback<typeof FORTUNES_ABI, 'DiceLanded'>
) {
	return watchContractEvent(
		{
			abi: FORTUNES_ABI,
			address: FORTUNES_ADDRESS,
			eventName: 'DiceLanded',
		},
		callback
	);
}
