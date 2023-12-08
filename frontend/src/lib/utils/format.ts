import { PRECISION } from '$lib/constants/param';
import { formatUnits } from 'viem';

export function formatRewardGroups(rollToRewards: bigint[], rewardGroups: bigint[]) {
	const grouped = rollToRewards.reduce(
		(acc, curr, i) => {
			const group = Number(rewardGroups[Number(curr)]);
			if (acc[group]) {
				acc[group].to = i + 1;
			} else {
				const percentage = parseFloat(
					formatUnits((rewardGroups[Number(curr)] * 10000n) / PRECISION, 2)
				);
				acc[group] = {
					percentage,
					from: i + 1,
					to: i + 1
				};
			}
			return acc;
		},
		{} as Record<number, { percentage: number; from: number; to: number }>
	);

	return Object.values(grouped).sort((a, b) => a.from - b.from);
}

export const numberFormatter = new Intl.NumberFormat('en-US', {
	maximumFractionDigits: 2
});

export function formatBigint(value: bigint, decimals: number) {
	return numberFormatter.format(parseFloat(formatUnits(value, decimals)));
}

export const dateFormatter = new Intl.DateTimeFormat('en-US', {
	year: 'numeric',
	month: 'short',
	day: 'numeric'
});
