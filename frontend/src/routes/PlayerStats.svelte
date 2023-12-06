<script lang="ts">
	import { PiggyBank, Coins } from 'lucide-svelte';
	import DepositModal from './DepositModal.svelte';
	import { createQuery } from '@tanstack/svelte-query';
	import { getPlayer } from '$lib/queries/player';
	import { getAccount } from '@wagmi/core';
	import { account } from '$lib/stores/account';
	import { formatUnits } from 'viem';

	let dialog: HTMLDialogElement;

	$: playerInfo = createQuery<Awaited<ReturnType<typeof getPlayer>> | null>({
		queryKey: ['player-info', $account?.address],
		queryFn: async () => {
			if (!$account?.address) return null;
			return await getPlayer($account.address);
		}
	});

	const openDeposit = () => {
		dialog.showModal();
	};
</script>

<div class="stats shadow">
	<div class="stat bg-base-200">
		<div class="stat-title flex gap-2 items-end">
			<PiggyBank /><span class="leading-tight">Your Deposit</span>
		</div>
		{#if $playerInfo.status === 'pending'}
			<div class="stat-value text-primary">
				<span class="loading loading-spinner loading-md"></span>
			</div>
		{:else if $playerInfo.status === 'success'}
			<div class="stat-value text-primary">
				{formatUnits($playerInfo.data?.[1] ?? 0n, 18)} AVAX
			</div>
		{:else}
			<div class="stat-value text-primary">? AVAX</div>
		{/if}
		<div class="stat-desc">
			<span class="text-accent">1.24</span> rolls per hour,
			<span class="text-accent">29.76</span> rolls per day.
		</div>
		<div class="stat-actions">
			<button
				class="btn btn-sm btn-secondary ring ring-secondary ring-offset-2 ring-offset-base-200"
				on:click={openDeposit}>deposit more</button
			>
		</div>
	</div>
	<div
		class="stat bg-base-200 overflow-hidden
	"
	>
		<div class="stat-title flex gap-2 items-end">
			<Coins /><span class="leading-none">Your Fortune</span>
		</div>
		{#if $playerInfo.status === 'pending'}
			<div class="stat-value text-primary">
				<span class="loading loading-spinner loading-md"></span>
			</div>
		{:else if $playerInfo.status === 'success'}
			<div class="stat-value text-primary">
				{formatUnits($playerInfo.data?.[0] ?? 0n, 18)} FORTUNE
			</div>
		{:else}
			<div class="stat-value text-primary">? FORTUNE</div>
		{/if}
		<div class="stat-desc">
			<span class="text-accent">+2.5% </span>bonus yield, no.
			<span class="text-accent">69</span>
			<span class="text-success"> (↑ 2)</span> on the leaderboard.
		</div>
		<div class="stat-actions">
			<a href="/leaderboard" class="btn btn-sm btn-accent">see leaderboard</a>
		</div>
	</div>
</div>

<DepositModal bind:dialog />
