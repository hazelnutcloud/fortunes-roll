<script lang="ts">
	import { CalendarSearch, Landmark } from 'lucide-svelte';
	import { onMount } from 'svelte';

	const daysMs = 1000 * 60 * 60 * 24;
	const hoursMs = 1000 * 60 * 60;
	const minutesMs = 1000 * 60;
	const secondsMs = 1000;

	let mode: 'none' | 'upcoming' | 'live' = 'live';
	let upComingTimestamp = Date.now() + 1000 * 60 * 60 * 24 * 7;
	let countdownInterval: NodeJS.Timeout;
	let timeLeft = upComingTimestamp - Date.now();

	onMount(() => {
		if (mode === 'none') return;
		countdownInterval = setInterval(() => {
			timeLeft = upComingTimestamp - Date.now();
		}, 1000);
		return () => clearInterval(countdownInterval);
	});
</script>

<div class="h-full flex flex-col items-center justify-center gap-8">
	{#if mode === 'none'}
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
				that's <span class="text-accent">21%</span> of the total fortune supply.
			</div>
		</div>
	</div>
</div>
