<script lang="ts">
	import { getGrabbening, getGrabbeningIndex, getPotBalance } from '$lib/queries/game';
	import { nowSeconds } from '$lib/stores/time';
	import { dateFormatter, formatBigint } from '$lib/utils/format';
	import { breakDownTimeLeft } from '$lib/utils/time';
	import { createQuery } from '@tanstack/svelte-query';
	import { Hourglass, Grab } from 'lucide-svelte';

	let timeLeftDays = 0;
	let timeLeftHours = 0;
	let timeLeftMinutes = 0;
	let timeLeftSeconds = 0;
	let startDate: Date | undefined;
	let endDate: Date | undefined;
	let grabStatus: 'upcoming' | 'active' = 'upcoming';

	const grabbeningIndex = createQuery({
		queryKey: ['grabbening-index'],
		queryFn: getGrabbeningIndex
	});
	const potBalance = createQuery({
		queryKey: ['pot-balance'],
		queryFn: getPotBalance
	});

	$: grabbening = createQuery({
		queryKey: ['grabbening', $grabbeningIndex.data],
		queryFn: async () => {
			if ($grabbeningIndex.data === undefined) return null;
			return await getGrabbening($grabbeningIndex.data);
		}
	});

	$: if ($grabbening.data) {
		const [start, end] = $grabbening.data;
		const { days, hours, minutes, seconds } = breakDownTimeLeft(Number(end - $nowSeconds));
		timeLeftDays = days;
		timeLeftHours = hours;
		timeLeftMinutes = minutes;
		timeLeftSeconds = seconds;
		startDate = new Date(Number(start * 1000n));
		endDate = new Date(Number(end * 1000n));

		if ($nowSeconds < start) {
			grabStatus = 'upcoming';
		} else if ($nowSeconds < end) {
			grabStatus = 'active';
		}
	}
</script>

<div class="stats bg-base-200 shadow">
	<div class="stat">
		<div class="stat-figure text-secondary">
			<Hourglass size={32} />
		</div>
		<div class="stat-title">{grabStatus === 'active' ? 'Ends in' : 'Next opening'}</div>
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
			<Grab size={32} />
		</div>
		<div class="stat-title">Hoard Total</div>
		{#if $potBalance.status === 'pending'}
			<div class="stat-value"><span class="loading loading-spinner loading-md"></span></div>
			<div class="stat-desc">FORTUNE</div>
		{:else if $potBalance.status === 'success'}
			<div class="stat-value">{formatBigint($potBalance.data, 6)}</div>
			<div class="stat-desc">FORTUNE</div>
		{:else}
			<div class="stat-value">-</div>
			<div class="stat-desc">FORTUNE</div>
		{/if}
	</div>
</div>
