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
		{#if grabbeningSet}
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
</div>
