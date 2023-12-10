<script lang="ts">
	import { getPlayersByScore } from '$lib/queries/leaderboard';
	import { truncateAddress } from '$lib/utils/address';
	import { createQuery } from '@tanstack/svelte-query';
	import { formatDistanceToNow } from 'date-fns';

	const playerLeaderboard = createQuery({
		queryKey: ['player-leaderboard'],
		queryFn: getPlayersByScore
	});
</script>

<div class="overflow-x-auto max-h-[calc(100vh-72px)]">
	<table class="table table-pin-rows table-pin-cols">
		<thead>
			<tr>
				<th></th>
				<td>account</td>
				<td>fortune</td>
				<td>deposit</td>
				<td>total rolls</td>
				<td>last roll</td>
				<th></th>
			</tr>
		</thead>
		<tbody>
			{#if $playerLeaderboard.data}
				{#each $playerLeaderboard.data as player, i}
					<tr>
						<th>{i + 1}</th>
						<td>{truncateAddress(player.address)}</td>
						<td>{player.score}</td>
						<td>{player.deposit}</td>
						<td>{player.rolls}</td>
						<td>{player.lastRollTimestamp ? formatDistanceToNow(player.lastRollTimestamp) : '-'} ago</td>
						<th></th>
					</tr>
				{/each}
			{/if}
		</tbody>
		<tfoot>
			<tr>
				<th></th>
				<td>account</td>
				<td>fortune</td>
				<td>deposit</td>
				<td>total rolls</td>
				<td>last roll</td>
				<th></th>
			</tr>
		</tfoot>
	</table>
</div>
