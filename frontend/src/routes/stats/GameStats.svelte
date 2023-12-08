<script lang="ts">
	import { getGameEnd, getGameStart, getTotalDeposited, getTotalFortune } from '$lib/queries/game';
	import { nowSeconds } from '$lib/stores/time';
	import { dateFormatter, formatBigint } from '$lib/utils/format';
	import { breakDownTimeLeft } from '$lib/utils/time';
	import { createQuery } from '@tanstack/svelte-query';
	import { Gamepad2, Sparkles, PiggyBank } from 'lucide-svelte';

	const totalDeposited = createQuery({
		queryKey: ['total-deposited'],
		queryFn: getTotalDeposited
	});
	const totalFortune = createQuery({
		queryKey: ['total-fortune'],
		queryFn: getTotalFortune
	});
	const gameStart = createQuery({
		queryKey: ['game-start'],
		queryFn: getGameStart
	});
	const gameEnd = createQuery({
		queryKey: ['game-end'],
		queryFn: getGameEnd
	});

	let timeLeftDays = 0;
	let timeLeftHours = 0;
	let timeLeftMinutes = 0;
	let timeLeftSeconds = 0;
	let startDate: Date | undefined;
	let endDate: Date | undefined;

	$: if ($gameEnd.data && $gameStart.data) {
		const { days, hours, minutes, seconds } = breakDownTimeLeft(
			Number($gameEnd.data - $nowSeconds)
		);
		timeLeftDays = days;
		timeLeftHours = hours;
		timeLeftMinutes = minutes;
		timeLeftSeconds = seconds;
		startDate = new Date(Number($gameStart.data * 1000n));
		endDate = new Date(Number($gameEnd.data * 1000n));
	}
</script>

<div class="stats bg-base-200 shadow">
	<div class="stat">
		<div class="stat-figure text-secondary">
			<Gamepad2 size={32} />
		</div>
		<div class="stat-title">Season 1</div>
		<div class="stat-value">
			<span class="countdown font-mono">
				<span style={`--value:${timeLeftDays};`}></span>d:
				<span style={`--value:${timeLeftHours};`}></span>h:
				<span style={`--value:${timeLeftMinutes};`}></span>m:
				<span style={`--value:${timeLeftSeconds};`}></span>s
			</span>
		</div>
		{#if startDate && endDate}
			<div class="stat-desc">
				{dateFormatter.format(startDate)} - {dateFormatter.format(endDate)}
			</div>
		{/if}
	</div>

	<div class="stat">
		<div class="stat-figure text-secondary">
			<PiggyBank size={32} />
		</div>
		<div class="stat-title">Total Deposit</div>
		{#if $totalDeposited.status === 'pending'}
			<div class="stat-value"><span class="loading loading-spinner loading-md"></span></div>
			<div class="stat-desc">AVAX</div>
		{:else if $totalDeposited.status === 'success'}
			<div class="stat-value">{formatBigint($totalDeposited.data, 18)}</div>
			<div class="stat-desc">AVAX</div>
		{:else}
			<div class="stat-value">-</div>
			<div class="stat-desc">AVAX</div>
		{/if}
	</div>

	<div class="stat">
		<div class="stat-figure text-secondary">
			<Sparkles size={32} />
		</div>
		<div class="stat-title">Total Fortune</div>
		{#if $totalFortune.status === 'pending'}
			<div class="stat-value"><span class="loading loading-spinner loading-md"></span></div>
			<div class="stat-desc">FORTUNE</div>
		{:else if $totalFortune.status === 'success'}
			<div class="stat-value">{formatBigint($totalFortune.data, 6)}</div>
			<div class="stat-desc">FORTUNE</div>
		{:else}
			<div class="stat-value">-</div>
			<div class="stat-desc">FORTUNE</div>
		{/if}
	</div>
</div>
