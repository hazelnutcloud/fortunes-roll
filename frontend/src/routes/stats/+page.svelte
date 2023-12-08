<script lang="ts">
	import PlayerStats from '../PlayerStats.svelte';
	import GameStats from './GameStats.svelte';
	import GrabRewards from '../GrabRewards.svelte';
	import GrabStats from './GrabStats.svelte';
	import { getGrabbeningIndex, getGrabbening } from '$lib/queries/game';
	import { createQuery } from '@tanstack/svelte-query';
	import { CalendarSearch } from 'lucide-svelte';

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
	$: grabbeningSet = $grabbening.data && $grabbening.data[0] > 0n && $grabbening.data[1] > 0n;
</script>

<div class="flex justify-center w-full py-16 px-10">
	<div class="w-full max-w-screen-lg flex flex-col gap-4">
		<h2 class="font-extrabold text-lg underline">player statistics</h2>
		<PlayerStats />

		<h2 class="font-extrabold text-lg underline mt-8">game statistics</h2>
		<GameStats />

		<h2 class="font-extrabold text-lg underline mt-8">grabbing information</h2>
		{#if true}
			<GrabRewards><GrabStats /></GrabRewards>
		{:else}
			<div role="alert" class="alert shadow-lg">
				<CalendarSearch />
				<div>
					<h3 class="font-bold">no upcoming grab openings yet...</h3>
					<div class="text-xs">check back later!</div>
				</div>
			</div>
		{/if}
	</div>
	<!-- {#if mode === 'none'}
		<div role="alert" class="alert shadow-lg max-w-md">
			<CalendarSearch />
			<div>
				<h3 class="font-bold">no upcoming hoard seizings yet...</h3>
				<div class="text-xs">check back later!</div>
			</div>
		</div>
	{:else if mode === 'upcoming'}
		<div class="flex flex-col gap-2 items-center">
			<div>next hoard seizing in:</div>
			<span class="countdown font-mono text-2xl bg-base-200 py-4 px-6 rounded-box">
				<span style={`--value:${Math.floor(timeLeft / daysMs) % 99};`}></span>:
				<span style={`--value:${Math.floor(timeLeft / hoursMs) % 24};`}></span>:
				<span style={`--value:${Math.floor(timeLeft / minutesMs) % 60};`}></span>:
				<span style={`--value:${Math.floor(timeLeft / secondsMs) % 60};`}></span>
			</span>
		</div>
	{:else if mode === 'live'}
		<div class="flex flex-col gap-2 items-center">
			<div>hoard seizing ending in:</div>
			<div class="flex items-center gap-2">
				<span class="countdown font-mono text-2xl bg-base-200 py-4 px-6 rounded-box">
					<span style={`--value:${Math.floor(timeLeft / daysMs) % 99};`}></span>:
					<span style={`--value:${Math.floor(timeLeft / hoursMs) % 24};`}></span>:
					<span style={`--value:${Math.floor(timeLeft / minutesMs) % 60};`}></span>:
					<span style={`--value:${Math.floor(timeLeft / secondsMs) % 60};`}></span>
				</span>
				<a href="/?roll-action=seizing" class="btn btn-primary">go to roll</a> 
			</div>
		</div>
	{/if}
	<div class="stats shadow bg-base-200">
		<div class="stat">
			<div class="stat-title flex gap-2 items-end">
				<Landmark /><span class="leading-tight">Hoard Balance</span>
			</div>
			<div class="stat-value text-primary">102,286,934.19 FORTUNE</div>
			<div class="stat-desc">
				fortune from lost bets go here, that's <span class="text-accent">21%</span> of the total fortune supply.
			</div>
		</div>
	</div> -->
</div>
