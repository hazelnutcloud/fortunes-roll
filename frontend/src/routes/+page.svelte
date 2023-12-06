<script lang="ts">
	import { dice } from '$lib/dice';
	import { Info, Dices, Plus, X, Grab } from 'lucide-svelte';
	import { page } from '$app/stores';
	import PlayerStats from './PlayerStats.svelte';

	const distributionColors = ['#118ab2', '#06d6a0', '#ffd166', '#ef476f'];

	let dice1: number | null = null;
	let dice2: number | null = null;
	let rollsRemaining = 0;
	let selectedRollType: string | undefined = $page.url.searchParams.get('roll-action') ?? undefined;
	let multiplyStake = 6;
	let timeOut: NodeJS.Timeout;
	let seizeEnabled = true;
	let seizeRewardGroups = [
		{ percentage: 30, from: 6, to: 9 },
		{ percentage: 20, from: 10, to: 11 },
		{ percentage: 10, from: 12, to: 12 }
	];

	$: stakePercentage = getStakePercentage(multiplyStake);
	$: hasRolls = rollsRemaining > 0;
	$: canRoll = hasRolls && !!selectedRollType;
	$: infoTip =
		selectedRollType === 'multiply'
			? `you are betting ${stakePercentage} of your fortune. if you roll at or above ${multiplyStake}, you will win the amount you betted, otherwise you will lose it.`
			: selectedRollType === 'add'
			  ? 'you will win 100 fortune for each point you roll. i.e. if you roll 6, you will win 600 fortune.'
			  : selectedRollType === 'seizing'
			    ? 'you will pay 5% of your fortune for a chance to win a portion of the hoard according to your roll.'
			    : 'select a roll action.';

	const getStakePercentage = (roll: number) => {
		return `${((roll * 100) / 12).toFixed(0)}%`;
	};

	const roll = () => {
		clearTimeout(timeOut);
		dice1 = -1;
		dice2 = -1;
		timeOut = setTimeout(() => {
			dice1 = Math.ceil(Math.random() * 6);
			dice2 = Math.ceil(Math.random() * 6);
		}, 5000);
	};
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
				disabled={!hasRolls}
			>
				<option disabled selected value="">Roll for...</option>
				<option value="add"><Plus />Add</option>
				<option value="multiply"><X />Multiply</option>
				<option value="seizing" disabled={!seizeEnabled}><Grab />Seizing</option>
			</select>
			<button
				class="btn btn-secondary shadow ring-secondary ring-offset-base-100 ring-offset-2 tooltip tooltip-right"
				class:btn-disabled={!canRoll}
				class:ring={canRoll}
				data-tip={`${rollsRemaining} rolls remaining.`}
				disabled={!canRoll}
				on:click={roll}><Dices /></button
			>
		</div>

		<!-- countdown -->
		{#if rollsRemaining === 0}
			<div class="flex w-full items-center gap-2">
				<div class="flex-1"></div>
				<span class="text-sm">next roll: </span>
				<span class="countdown font-mono text-sm badge badge-accent">
					<span style="--value:1;"></span>h
					<span style="--value:24;"></span>m
					<span style="--value:50;"></span>s
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
			class:invisible={selectedRollType !== 'seizing'}
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
