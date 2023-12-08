<script lang="ts">
	import { PiggyBank, Coins } from 'lucide-svelte';
	import DepositModal from './DepositModal.svelte';
	import { createQuery } from '@tanstack/svelte-query';
	import { getPlayer } from '$lib/queries/player';
	import { account } from '$lib/stores/account';
	import { formatUnits } from 'viem';
	import { DEPOSIT_FACTOR, DICE_PER_SECOND, PRECISION_PLACES } from '$lib/constants/param';
	import { getTotalDeposited, getTotalFortune } from '$lib/queries/game';
	import { getPlayerPositionOnLeaderboard } from '$lib/queries/leaderboard';

	const locale = new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 });

	const totalFortune = createQuery<Awaited<ReturnType<typeof getTotalFortune>>>({
		queryKey: ['total-fortune'],
		queryFn: getTotalFortune
	});

	const totalDeposited = createQuery<Awaited<ReturnType<typeof getTotalDeposited>>>({
		queryKey: ['total-deposited'],
		queryFn: getTotalDeposited
	});

	let dialog: HTMLDialogElement;

	$: playerInfo = createQuery<Awaited<ReturnType<typeof getPlayer>> | null>({
		queryKey: ['player-info', $account?.address],
		queryFn: async () => {
			if (!$account?.address) return null;
			return await getPlayer($account.address);
		}
	});

	$: playerPosition = createQuery<ReturnType<typeof getPlayerPositionOnLeaderboard> | null>({
		queryKey: ['player-position', $account?.address],
		queryFn: () => {
			if (!$account?.address) {
				return null;
			}
			return getPlayerPositionOnLeaderboard($account.address);
		}
	});

	const getRollsPerHour = (deposit: bigint) => {
		return parseFloat(
			formatUnits((DICE_PER_SECOND * 60n * 60n * deposit) / DEPOSIT_FACTOR, PRECISION_PLACES)
		).toLocaleString('en-US', { maximumFractionDigits: 1 });
	};

	const getRollsPerDay = (deposit: bigint) => {
		return parseFloat(
			formatUnits((DICE_PER_SECOND * 60n * 60n * 24n * deposit) / DEPOSIT_FACTOR, PRECISION_PLACES)
		).toLocaleString('en-US', { maximumFractionDigits: 1 });
	};

	const getPositionChangeString = (positionChange: number) => {
		if (positionChange === 0) {
			return '';
		}
		if (positionChange > 0) {
			return `(↑ ${positionChange})`;
		}
		return `(↓ ${positionChange})`;
	};

	const getYieldChangeString = ({
		playerDeposit,
		playerFortune,
		totalDeposited,
		totalFortune
	}: {
		playerDeposit: bigint;
		playerFortune: bigint;
		totalDeposited: bigint;
		totalFortune: bigint;
	}) => {
		if (
			totalDeposited === 0n ||
			totalFortune === 0n ||
			playerDeposit === 0n ||
			playerFortune === 0n
		) {
			return {
				string: '0',
				sign: '+'
			};
		}
		const precision = 10n ** 6n;

		const depositRatio = (playerDeposit * precision) / totalDeposited;
		const fortuneRatio = (playerFortune * precision) / totalFortune;

		const sign = fortuneRatio >= depositRatio ? '+' : '';

		const yieldChange = ((fortuneRatio - depositRatio) * precision) / depositRatio;

		return {
			string: parseFloat(formatUnits(yieldChange, 6)).toLocaleString('en-US', {
				maximumFractionDigits: 1
			}),
			sign
		};
	};

	const openDeposit = () => {
		dialog.showModal();
	};

	const withdraw = () => {
		console.log('withdraw')
	}
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
			<div class="stat-desc">
				<span class="loading loading-spinner loading-sm"></span>
			</div>
		{:else if $playerInfo.status === 'success'}
			<div class="stat-value text-primary">
				{locale.format(parseFloat(formatUnits($playerInfo.data?.[1] ?? 0n, 18)))} AVAX
			</div>
			<div class="stat-desc">
				<span class="text-accent">~ {getRollsPerHour($playerInfo.data?.[1] ?? 0n)}</span> rolls per
				hour,
				<span class="text-accent">{getRollsPerDay($playerInfo.data?.[1] ?? 0n)}</span> rolls per day.
			</div>
		{:else}
			<div class="stat-value text-primary">- AVAX</div>
			<div class="stat-desc">
				<span class="text-accent">-</span> rolls per hour,
				<span class="text-accent">-</span> rolls per day.
			</div>
		{/if}
		<div class="stat-actions flex gap-2">
			<button
				class="btn btn-sm btn-secondary ring ring-secondary ring-offset-2 ring-offset-base-200"
				on:click={openDeposit}>deposit</button
			>
				<button class="btn btn-sm btn-ghost" on:click={withdraw}>withdraw</button>
		</div>
	</div>
	<div
		class="stat bg-base-200 overflow-hidden
	"
	>
		<div class="stat-title flex gap-2 items-end">
			<Coins /><span class="leading-none">Your Score</span>
		</div>
		{#if $playerInfo.status === 'pending' || $totalDeposited.status === 'pending' || $totalFortune.status === 'pending' || $playerPosition.status === 'pending'}
			<div class="stat-value text-primary">
				<span class="loading loading-spinner loading-md"></span>
			</div>
			<div class="stat-desc">
				<span class="loading loading-spinner loading-sm"></span>
			</div>
		{:else if $playerInfo.status === 'success' && $totalDeposited.status === 'success' && $totalFortune.status === 'success' && $playerPosition.status === 'success'}
			{@const yieldChange = getYieldChangeString({
				playerDeposit: $playerInfo.data?.[1] ?? 0n,
				playerFortune: $playerInfo.data?.[0] ?? 0n,
				totalDeposited: $totalDeposited.data,
				totalFortune: $totalFortune.data
			})}
			<div class="stat-value text-primary">
				{locale.format(parseFloat(formatUnits($playerInfo.data?.[0] ?? 0n, PRECISION_PLACES)))} FORTUNE
			</div>
			<div class="stat-desc">
				<span
					class:text-accent={yieldChange.sign === '+'}
					class:text-error={yieldChange.sign === ''}
					>{yieldChange.sign}{yieldChange.string}%
				</span>{yieldChange.sign === '+' ? 'increased' : 'decreased'} yield, no.
				<span class="text-accent">{$playerPosition.data?.position ?? '-'}</span>
				<span class="text-success"
					>{getPositionChangeString($playerPosition.data?.twentyFourHourChange ?? 0)}</span
				> on the leaderboard.
			</div>
		{:else}
			<div class="stat-value text-primary">- FORTUNE</div>
			<div class="stat-desc">
				<span class="text-accent">-</span>
			</div>
		{/if}
		<div class="stat-actions">
			<a href="/leaderboard" class="btn btn-sm btn-accent">see leaderboard</a>
		</div>
	</div>
</div>

<DepositModal bind:dialog />
