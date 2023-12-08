<script lang="ts">
	import { PRECISION } from '$lib/constants/param';
	import {
		getGrabbeningIndex,
		getGrabbening,
		getPlayerGrabbening,
		getGrabbeningRewardsInfo,
		getPotBalance
	} from '$lib/queries/game';
	import { account } from '$lib/stores/account';
	import { formatRewardGroups } from '$lib/utils/format';
	import { createQuery } from '@tanstack/svelte-query';
	import { formatUnits } from 'viem';

	const distributionColors = ['#ef476f', '#ffd166', '#06d6a0', '#118ab2'];
	const numberFormatter = new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 });
	const potBalance = createQuery({
		queryKey: ['pot-balance'],
		queryFn: getPotBalance
	});
	const grabbeningIndex = createQuery({
		queryKey: ['grabbening-index'],
		queryFn: getGrabbeningIndex
	});

	$: grabbening = createQuery({
		queryKey: ['grabbening', $grabbeningIndex.data],
		queryFn: async () => {
			if ($grabbeningIndex.data === undefined) return null;
			return await getGrabbening($grabbeningIndex.data);
		}
	});
	$: playerGrabbening = createQuery({
		queryKey: ['player-grabbening', $account?.address, $grabbeningIndex.data],
		queryFn: async () => {
			if (!$account?.address) return null;
			if ($grabbeningIndex.data === undefined) return null;
			if (!$grabbeningRewards.data) return null;

			return await getPlayerGrabbening(
				$grabbeningIndex.data,
				$account.address,
				$grabbeningRewards.data.rollsToRewards
			);
		}
	});
	$: grabbeningRewards = createQuery({
		queryKey: ['grabbening-rewards', $grabbening.data],
		queryFn: async () => {
			if (!$grabbening.data) return null;
			if ($grabbening.data[0] === 0n) return null;
			if ($grabbeningIndex.data === undefined) return null;

			return await getGrabbeningRewardsInfo($grabbeningIndex.data);
		}
	});
	$: grabbeningRewardGroups = $grabbeningRewards.data
		? formatRewardGroups(
				$grabbeningRewards.data.rollsToRewards,
				$grabbeningRewards.data.rewardGroups
		  )
		: [];

	const calculatePotentialWinnings = ({
		playerRoll,
		potBalance,
		rewardGroups,
		rollTally,
		rollsToRewards
	}: {
		potBalance: bigint;
		playerRoll: bigint;
		rollTally: bigint;
		rollsToRewards: bigint[];
		rewardGroups: bigint[];
	}) => {
		if (rollTally === 0n) return 0;
		const rewardsGroupIndex = Number(rollsToRewards[Number(playerRoll) - 1]);
		const rewardShare = rewardGroups[rewardsGroupIndex];
		const rewards = parseFloat(
			formatUnits((potBalance * rewardShare * PRECISION) / PRECISION / rollTally, 12)
		);
		return rewards;
	};
</script>

<div class="flex flex-col gap-2 w-full relative min-h-[4rem]">
	<slot />
	<div class="w-full flex h-6">
		{#each grabbeningRewardGroups as group, i}
			{@const rewards = numberFormatter.format(
				(parseFloat(formatUnits($potBalance.data ?? 0n, 6)) * group.percentage) / 100
			)}
			<div
				class={'h-full tooltip text-primary-content'}
				class:rounded-l-box={i === 0}
				class:rounded-r-box={i === grabbeningRewardGroups.length - 1}
				style={`flex: ${group.percentage + 10}; background-color: ${
					distributionColors[i % distributionColors.length]
				}`}
				data-tip={`${group.percentage}% (${rewards} FORTUNE shared)`}
			>
				{group.from === group.to ? group.from : `${group.from} - ${group.to}`}
			</div>
		{/each}
	</div>
	{#if $playerGrabbening.data && $grabbeningRewards.data}
		{#if $playerGrabbening.data.roll === 0n}
			<div class="text-center w-full text-sm">roll to earn a share of the hoard.</div>
		{:else}
			{@const potentialReward = calculatePotentialWinnings({
				playerRoll: $playerGrabbening.data.roll,
				potBalance: $potBalance.data ?? 0n,
				rewardGroups: $grabbeningRewards.data.rewardGroups,
				rollsToRewards: $grabbeningRewards.data.rollsToRewards,
				rollTally: $playerGrabbening.data.tally
			})}
			<div class="text-center w-full text-sm">
				your roll: <span class="text-accent">{$playerGrabbening.data.roll}</span>
				(<span class="text-accent">{numberFormatter.format(potentialReward)} FORTUNE</span> potential
				winnings.)
			</div>
		{/if}
	{/if}
</div>
