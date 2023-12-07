<script lang="ts">
	import { dice } from '$lib/dice';
	import { Info, Dices, Plus, X, Grab } from 'lucide-svelte';
	import { page } from '$app/stores';
	import PlayerStats from './PlayerStats.svelte';
	import { createQuery, useQueryClient } from '@tanstack/svelte-query';
	import { account } from '$lib/stores/account';
	import { getPlayer } from '$lib/queries/player';
	import {
		BASE_DICE_ROLLS,
		DEPOSIT_FACTOR,
		DICE_PER_SECOND,
		PRECISION
	} from '$lib/constants/param';
	import { getGameStart } from '$lib/queries/game';
	import { formatUnits } from 'viem';
	import { watchDiceLand } from '$lib/subscriptions/roll';
	import { rollFor } from '$lib/mutations/roll';
	import { onMount } from 'svelte';
	import { breakDownTimeLeft } from '$lib/utils/time';
	import { splitAndRandomize } from '$lib/utils/math';

	const distributionColors = ['#118ab2', '#06d6a0', '#ffd166', '#ef476f'];
	const ONE = PRECISION;
	const client = useQueryClient();
	const gameStart = createQuery({
		queryKey: ['game-start'],
		queryFn: getGameStart
	});

	let dice1: number | null = null;
	let dice2: number | null = null;
	let selectedRollType: 'add' | 'multiply' | 'grab' | undefined =
		($page.url.searchParams.get('roll-action') as any) ?? undefined;
	let multiplyStake = 6;
	let unwatchDiceLand: () => void;
	let interval: NodeJS.Timeout;
	let timer = 0;
	let secondsToNextRoll = 0;
	let rollsRemaining = 0n;

	let seizeEnabled = true;
	let seizeRewardGroups = [
		{ percentage: 30, from: 6, to: 9 },
		{ percentage: 20, from: 10, to: 11 },
		{ percentage: 10, from: 12, to: 12 }
	];
	let seizeFee = 5;

	$: playerInfo = createQuery({
		queryKey: ['player-info', $account?.address],
		queryFn: async () => {
			if (!$account?.address) return null;
			return await getPlayer($account.address);
		}
	});
	$: infoTip =
		selectedRollType === 'multiply'
			? `you are betting ${getStakePercentage(
					multiplyStake
			  )} of your fortune. if you roll at or above ${multiplyStake}, you will win the amount you betted, otherwise you will lose it.`
			: selectedRollType === 'add'
			  ? 'you will win 100 fortune for each point you roll. i.e. if you roll 6, you will win 600 fortune.'
			  : selectedRollType === 'grab'
			    ? `you will pay ${seizeFee} of your fortune for a chance to win a portion of the hoard according to your roll.`
			    : 'select a roll action.';
	$: if (timer && $gameStart.data && $playerInfo.data)
		rollsRemaining = calculateRollsRemaining({
			gameStart: $gameStart.data,
			playerDeposit: $playerInfo.data[1],
			lastRollTimestamp: $playerInfo.data[3],
			rollsRemaining: $playerInfo.data[2]
		});
	$: isRolling = $playerInfo.data?.[4] || (dice1 === -1 && dice2 === -1);
	$: canRoll = rollsRemaining >= ONE && !isRolling;
	$: if ($playerInfo.data?.[1] && $playerInfo.data?.[1] > 0n && rollsRemaining < ONE) {
		secondsToNextRoll = Number(
			calculateTimeToNextRoll({
				playerDeposit: $playerInfo.data?.[1] ?? 0n,
				rollsRemaining
			})
		);
	}

	const getStakePercentage = (roll: number) => {
		return `${((roll * 100) / 12).toFixed(0)}%`;
	};

	const calculateRollsRemaining = ({
		playerDeposit,
		rollsRemaining,
		lastRollTimestamp,
		gameStart
	}: {
		playerDeposit: bigint;
		rollsRemaining: bigint;
		lastRollTimestamp: bigint;
		gameStart: bigint;
	}) => {
		if (playerDeposit === 0n) return 0n;
		const now = BigInt(Math.floor(Date.now() / 1000));
		const isFirstRoll = lastRollTimestamp === 0n;
		const start = isFirstRoll ? gameStart : lastRollTimestamp;
		const baseDice = isFirstRoll ? BASE_DICE_ROLLS : 0n;
		const newRolls = ((now - start) * DICE_PER_SECOND * playerDeposit) / DEPOSIT_FACTOR;
		return rollsRemaining + newRolls + baseDice;
	};

	const calculateTimeToNextRoll = ({
		playerDeposit,
		rollsRemaining
	}: {
		playerDeposit: bigint;
		rollsRemaining: bigint;
	}) => {
		if (playerDeposit === 0n) return 0;
		const diff = ONE - rollsRemaining;

		const secondsRemaining = (diff * DEPOSIT_FACTOR) / (DICE_PER_SECOND * playerDeposit);

		return secondsRemaining;
	};

	const roll = async () => {
		if (!selectedRollType) return;
		try {
			dice1 = -1;
			dice2 = -1;
			await rollFor({
				type: selectedRollType,
				multiplyStake: BigInt(multiplyStake)
			});
			unwatchDiceLand = playerWatchDiceLand();
		} catch (e) {
			console.error(e);
			dice1 = 0;
			dice2 = 0;
		}
	};

	const playerWatchDiceLand = () =>
		watchDiceLand((diceLands) => {
			const playersDice = diceLands.find(
				({ args: { player } }) =>
					player && player.toLowerCase() === $account?.address?.toLowerCase()
			);
			if (playersDice && playersDice.args.diceRoll) {
				const point = Number(playersDice.args.diceRoll);
				console.log('point', point);
				if (point === 1) {
					dice1 = 1;
					dice2 = 0;
				} else {
					[dice1, dice2] = splitAndRandomize(point);
				}
				client.invalidateQueries({ queryKey: ['player-info', $account?.address] });
				client.invalidateQueries({ queryKey: ['total-fortune'] });
				client.invalidateQueries({ queryKey: ['total-deposited'] });
				unwatchDiceLand?.();
			}
		});

	onMount(() => {
		interval = setInterval(() => {
			timer = timer + 1;
		}, 1000);
		return () => {
			clearInterval(interval);
		};
	});
</script>

<div class="h-full grid place-items-center">
	<div class="flex flex-col items-center gap-4">
		<PlayerStats />

		<!-- dice -->
		<div class="flex bg-base-200 rounded-box justify-center w-full py-10 gap-4 shadow">
			<canvas width="250" height="250" class="hover:cursor-move" use:dice={dice1}></canvas>
			<canvas width="250" height="250" class="hover:cursor-move" use:dice={dice2}></canvas>
		</div>

		<!-- roll -->
		<div class="flex items-center gap-4 w-full">
			<div class="flex-1"></div>
			<span class="tooltip tooltip-left" data-tip={infoTip}>
				<Info />
			</span>
			<select
				class="select select-bordered shadow"
				bind:value={selectedRollType}
				disabled={!canRoll}
			>
				<option disabled selected value="">Roll for...</option>
				<option value="add"><Plus />Add</option>
				<option value="multiply"><X />Multiply</option>
				<option value="grab" disabled={!seizeEnabled}><Grab />Seizing</option>
			</select>
			<button
				class="btn btn-secondary shadow ring-secondary ring-offset-base-100 ring-offset-2 tooltip tooltip-right"
				class:btn-disabled={!canRoll}
				class:ring={canRoll}
				data-tip={`${Math.floor(parseFloat(formatUnits(rollsRemaining, 6)))} rolls remaining.`}
				disabled={!canRoll}
				on:click={roll}><Dices /></button
			>
		</div>

		<!-- countdown -->
		{#if rollsRemaining < ONE && ($playerInfo.data?.[1] ?? 0n) > 0n}
			{@const { hours, minutes, seconds } = breakDownTimeLeft(secondsToNextRoll)}
			<div class="flex w-full items-center gap-2">
				<div class="flex-1"></div>
				<span class="text-sm">next roll: </span>
				<span class="countdown font-mono text-sm badge badge-accent">
					<span style={`--value:${hours};`}></span>h
					<span style={`--value:${minutes};`}></span>m
					<span style={`--value:${seconds};`}></span>s
				</span>
			</div>
		{/if}

		<!-- slider -->
		<div class="flex flex-col gap-2 w-full" class:invisible={selectedRollType !== 'multiply'}>
			<input
				type="range"
				min="1"
				max="12"
				bind:value={multiplyStake}
				class="range range-secondary w-full"
				step="1"
				disabled={selectedRollType !== 'multiply'}
			/>
			<div class="w-full flex justify-between text-xs px-2">
				{#each Array(12) as _, i}
					<span class="tooltip font-mono" data-tip={getStakePercentage(i + 1)}>{i + 1}</span>
				{/each}
			</div>
		</div>

		<!-- seizing info -->
		<div
			class="flex flex-col gap-2 w-full relative -top-16"
			class:invisible={selectedRollType !== 'grab'}
		>
			<div class="w-full flex h-6">
				{#each seizeRewardGroups as group, i}
					<div
						class={'h-full tooltip'}
						class:rounded-l={i === 0}
						class:rounded-r={i === seizeRewardGroups.length - 1}
						style={`flex: ${group.percentage}; background-color: ${
							distributionColors[i % distributionColors.length]
						}`}
						data-tip={`roll ${
							group.from === group.to ? group.from : `${group.from} - ${group.to}`
						} (shares ${group.percentage}% of hoard)`}
					></div>
				{/each}
			</div>
			<div class="text-center w-full text-sm">roll → rewards distribution</div>
		</div>
	</div>
</div>
