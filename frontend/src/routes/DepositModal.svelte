<script lang="ts">
	import { FORTUNES_ADDRESS, SAVAX_ADDRESS } from '$lib/constants/contract-addresses';
	import { approve } from '$lib/mutations/allowance';
	import { deposit } from '$lib/mutations/deposit';
	import { getPlayer, getPlayerAllowance, getPlayerBalance } from '$lib/queries/player';
	import { account } from '$lib/stores/account';
	import { createMutation, createQuery, useQueryClient } from '@tanstack/svelte-query';
	import { writable } from 'svelte/store';
	import { formatUnits, maxUint256, parseUnits } from 'viem';

	export let dialog: HTMLDialogElement;

	const locale = new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 });
	const client = useQueryClient();
	let isDepositing = false;
	let isApproving = false;

	let value: number;

	$: parsedValue = parseUnits(locale.format(value ?? 0), 18);

	$: playerBalance = createQuery<Awaited<ReturnType<typeof getPlayerBalance>> | null>({
		queryKey: ['player-balance', $account?.address],
		queryFn: async () => {
			if (!$account?.address) return null;
			return await getPlayerBalance($account.address, SAVAX_ADDRESS);
		}
	});

	$: playerAllowance = createQuery<Awaited<ReturnType<typeof getPlayerAllowance>> | null>({
		queryKey: ['player-allowance', $account?.address],
		queryFn: async () => {
			if (!$account?.address) return null;
			return await getPlayerAllowance({
				playerAddress: $account.address,
				spender: FORTUNES_ADDRESS,
				tokenAddress: SAVAX_ADDRESS
			});
		}
	});

	$: approveMutation = createMutation({
		mutationFn: async () => {
			if (!$account?.address) return;

			return await approve({
				playerAddress: $account.address,
				tokenAddress: SAVAX_ADDRESS,
				spenderAddress: FORTUNES_ADDRESS
			});
		},
		onMutate: async () => {
			isApproving = true;
		},
		onError: async (_err, _, context) => {
			isApproving = false;
		},
		onSuccess: () => {
			isApproving = false;
			client.invalidateQueries({ queryKey: ['player-allowance', $account?.address] });
			if (parsedValue > 0) $depositMutation.mutate();
		}
	});

	$: depositMutation = createMutation({
		mutationFn: async () => {
			if (!$account?.address) return;

			return await deposit(parsedValue);
		},
		onMutate: async () => {
			isDepositing = true;
		},
		onError: async (_err, _, context) => {
			isDepositing = false;
		},
		onSuccess: () => {
			isDepositing = false;
			client.invalidateQueries({ queryKey: ['player-info', $account?.address] });
			client.invalidateQueries({ queryKey: ['total-fortune'] });
			client.invalidateQueries({ queryKey: ['total-deposited'] });
			dialog.close();
		}
	});

	const canDeposit = ({
		inputValue,
		playerBalance,
		isDepositing,
		isApproving
	}: {
		playerBalance: bigint;
		inputValue: bigint;
		isDepositing: boolean;
		isApproving: boolean;
	}) => {
		const enoughBalance = playerBalance >= inputValue;
		const valueInputted = inputValue > 0n;
		const reason = !enoughBalance
			? 'not enough balance'
			: !valueInputted
			  ? 'enter an amount'
			  : isDepositing
			    ? 'depositing...'
			    : isApproving
			      ? 'approving...'
			      : '';
		return { can: enoughBalance && valueInputted && !isDepositing && !isApproving, reason };
	};

	const needsAllowance = (playerAllowance: bigint, inputValue: bigint) => {
		return playerAllowance < inputValue || playerAllowance === 0n;
	};

	const fillBalance = (balance: bigint) => {
		value = parseFloat(formatUnits(balance, 18));
	};
</script>

<dialog id="deposit_modal" class="modal" bind:this={dialog}>
	<div class="modal-box flex flex-col items-end outline outline-primary">
		<h3 class="font-bold text-lg self-start text-primary">Deposit sAVAX</h3>
		<label class="form-control w-full">
			<div class="label">
				<span class="label-text"></span>
				<span class="label-text-alt"
					>Balance:
					{#if $playerBalance.status === 'pending'}
						<span class="link text-accent"
							><span class="loading loading-spinner loading-xs"></span></span
						>
					{:else if $playerBalance.status === 'success'}
						<button
							type="button"
							class="link text-accent"
							on:click={() => fillBalance($playerBalance.data ?? 0n)}
							>{formatUnits($playerBalance.data ?? 0n, 18)} sAVAX</button
						>
					{:else}
						<span class="link text-accent">- sAVAX</span>
					{/if}
				</span>
			</div>
			<input type="" placeholder="0" class="input input-bordered w-full" bind:value />
		</label>
		<div class="modal-action">
			<form method="dialog">
				<!-- if there is a button in form, it will close the modal -->
				<button class="btn">cancel</button>
			</form>
			{#if $playerAllowance.status === 'pending'}
				<button class="btn btn-primary"
					><span class="loading loading-spinner loading-xs"></span></button
				>
			{:else if $playerAllowance.status === 'success'}
				{@const { can, reason } = canDeposit({
					playerBalance: $playerBalance.data ?? 0n,
					inputValue: parsedValue,
					isDepositing: isDepositing,
					isApproving: isApproving
				})}
				{#if needsAllowance($playerAllowance.data ?? 0n, parsedValue)}
					<button
						class="btn btn-primary"
						disabled={!can}
						class:btn-disabled={!can}
						on:click={() => $approveMutation.mutate()}>{!can ? reason : 'approve'}</button
					>
				{:else}
					<button
						class="btn btn-primary"
						class:btn-disabled={!can}
						disabled={!can}
						on:click={() => $depositMutation.mutate()}>{!can ? reason : 'deposit'}</button
					>
				{/if}
			{:else}
				<button class="btn btn-primary btn-disabled" disabled>deposit</button>
			{/if}
		</div>
	</div>
</dialog>
