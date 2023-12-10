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
	import { getGameStart, getGrabbening, getGrabbeningIndex } from '$lib/queries/game';
	import { formatUnits } from 'viem';
	import { watchDiceLand } from '$lib/subscriptions/roll';
	import { rollFor } from '$lib/mutations/roll';
	import { breakDownTimeLeft } from '$lib/utils/time';
	import { splitAndRandomize } from '$lib/utils/math';
	import { nowSeconds } from '$lib/stores/time';
	import GrabInfo from './GrabRewards.svelte';
	import { numberFormatter } from '$lib/utils/format';

	const ONE = PRECISION;
	const client = useQueryClient();
	const gameStart = createQuery({
		queryKey: ['game-start'],
		queryFn: getGameStart
	});
	const grabbeningIndex = createQuery({
		queryKey: ['grabbening-index'],
		queryFn: getGrabbeningIndex
	});

	let dice1: number | null = null;
	let dice2: number | null = null;
	let selectedRollType: 'add' | 'multiply' | 'grab' | undefined =
		($page.url.searchParams.get('roll-action') as any) ?? undefined;
	let multiplyStake = 6;
	let addMultiplier = 1;
	let unwatchDiceLand: () => void;
	let secondsToNextRoll = 0;
	let rollsRemaining = 0n;

	$: grabbening = createQuery({
		queryKey: ['grabbening', $grabbeningIndex.data],
		queryFn: async () => {
			if ($grabbeningIndex.data === undefined) return null;
			return await getGrabbening($grabbeningIndex.data);
		}
	});
	$: grabEnabled =
		($grabbening.data && $grabbening.data[0] > 0n && $nowSeconds < $grabbening.data[1]) ?? false;
	$: grabbeningFee = formatUnits($grabbening.data?.[2] ?? 0n, 4);

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
			  ? 'you will win 100 fortune for each point you roll. i.e. if you roll 6, you will win 600 fortune. multiply your winnings by consuming multiple rolls at once.'
			  : selectedRollType === 'grab'
			    ? `you will pay ${grabbeningFee}% of your fortune for a chance to win a portion of the hoard according to your roll.`
			    : 'select a roll action.';
	$: if ($gameStart.data && $playerInfo.data)
		rollsRemaining = calculateRollsRemaining({
			now: $nowSeconds,
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

	const getFortuneFraction = (roll: number, fortune: bigint) => {
		return numberFormatter.format(parseFloat(formatUnits((fortune * BigInt(roll)) / 12n, 6)));
	};

	const calculateRollsRemaining = ({
		playerDeposit,
		rollsRemaining,
		lastRollTimestamp,
		gameStart,
		now
	}: {
		playerDeposit: bigint;
		rollsRemaining: bigint;
		lastRollTimestamp: bigint;
		gameStart: bigint;
		now: bigint;
	}) => {
		if (playerDeposit === 0n) return 0n;
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
				multiplyStake: BigInt(multiplyStake),
				addMultiplier
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
			if (playersDice && playersDice.args.result) {
				const point = Number(playersDice.args.result);
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
				client.invalidateQueries({
					queryKey: ['player-grabbening', $account?.address, $grabbeningIndex.data]
				});
				unwatchDiceLand?.();
				addMultiplier = 1;
			}
		});
</script>

<div class="h-full grid place-items-center">
	<div class="flex w-full flex-col items-center gap-4 max-w-screen-sm">
		<PlayerStats />

		<!-- dice -->
		<div
			class="flex flex-col items-center bg-base-200 rounded-box justify-center w-full py-10 shadow"
		>
			<div class="flex gap-4">
				<canvas width="250" height="250" class="hover:cursor-move" use:dice={dice1}></canvas>
				<canvas width="250" height="250" class="hover:cursor-move" use:dice={dice2}></canvas>
			</div>
			{#if dice1 === -1}
				<div class="w-full text-center">rolling...</div>
			{:else if dice1 && dice2}
				<div class="w-full text-center">
					you rolled a <span class="text-accent">{dice1 + dice2}</span>!
				</div>
			{:else}
				<div class="w-full text-center h-6"></div>
			{/if}
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
				<option value="grab" disabled={!grabEnabled}><Grab />Grab</option>
			</select>
			<div class="indicator">
				<span class="indicator-item indicator-center indicator-bottom badge badge-primary font-bold"
					>{Math.floor(parseFloat(formatUnits(rollsRemaining, 6)))}</span
				>
				<button
					class="btn btn-secondary shadow ring-secondary ring-offset-base-100 ring-offset-2 tooltip tooltip-right"
					data-tip={`${Math.floor(parseFloat(formatUnits(rollsRemaining, 6)))} rolls remaining.`}
					class:btn-disabled={!canRoll}
					class:ring={canRoll}
					disabled={!canRoll}
					on:click={roll}><Dices /></button
				>
			</div>
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

		<!-- add slider -->
		{#if selectedRollType === 'add'}
			{@const rollsRemainingParsed = Math.floor(Number(formatUnits(rollsRemaining, 6)))}
			<div class="flex flex-col gap-2 w-full h-16">
				<input
					type="range"
					min="1"
					max={rollsRemainingParsed}
					bind:value={addMultiplier}
					class="range range-accent w-full"
					step="1"
					disabled={selectedRollType !== 'add'}
				/>
				<span
					class="w-full text-center tooltip tooltip-top"
					data-tip={`consume ${addMultiplier} dice roll${
						addMultiplier > 1 ? 's' : ''
					} to multiply your winnings ${addMultiplier}x. for when you want to spend multiple rolls at once.`}
				>
					Roll multiplier: <span class="text-accent">x{addMultiplier}</span></span
				>
			</div>
		{/if}

		{#if selectedRollType !== 'multiply' && selectedRollType !== 'grab' && selectedRollType !== 'add'}
			<div class="h-16"></div>
		{/if}

		<!-- slider -->
		{#if selectedRollType === 'multiply'}
			<div class="flex flex-col gap-2 w-full h-16">
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
						{@const winnings = getFortuneFraction(i + 1, $playerInfo.data?.[0] ?? 0n)}
						<span
							class="tooltip"
							data-tip={i === 1
								? `roll 12, win ${winnings} FORTUNE`
								: `roll more than or equal ${i + 1}, win ${winnings} FORTUNE`}>{i + 1}</span
						>
					{/each}
				</div>
			</div>
		{/if}

		<!-- seizing info -->
		{#if selectedRollType === 'grab'}
			<GrabInfo />
		{/if}
	</div>
</div>
