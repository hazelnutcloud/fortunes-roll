<script lang="ts">
	import { dice } from '$lib/dice';
	import { PiggyBank, Coins, Info, Dices } from 'lucide-svelte';

	let dice1: number | null = null;
	let dice2: number | null = null;
	let rollsRemaining = 10;
	let selectedRollType: string;
	let multiplyStake = 6;
	let timeOut: NodeJS.Timeout;
	let dialog: HTMLDialogElement;

	$: stakePercentage = getStakePercentage(multiplyStake);
	$: hasRolls = rollsRemaining > 0;
	$: canRoll = hasRolls && !!selectedRollType;

	const openDeposit = () => {
		dialog.showModal();
	};

	const getStakePercentage = (roll: number) => {
		return `${((roll * 100) / 12).toFixed(0)}%`;
	};

	const roll = () => {
		clearTimeout(timeOut);
		dice1 = 0;
		dice2 = 0;
		timeOut = setTimeout(() => {
			dice1 = Math.ceil(Math.random() * 6);
			dice2 = Math.ceil(Math.random() * 6);
		}, 5000);
	};
</script>

<div class="flex-1 h-full grid place-items-center">
	<div class="flex flex-col container items-center gap-4">
		<!-- stats -->
		<div class="stats shadow">
			<div class="stat bg-base-200">
				<div class="stat-title flex gap-2 items-end">
					<PiggyBank /><span class="leading-tight">Your Deposit</span>
				</div>
				<div class="stat-value text-primary">89,400 AVAX</div>
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
				<div class="stat-value text-primary">69,420 FORTUNE</div>
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

		<!-- dice -->
		<div class="flex bg-base-200 rounded-box justify-center w-full py-10 gap-4 shadow">
			<canvas width="250" height="250" class="hover:cursor-move" use:dice={dice1}></canvas>
			<canvas width="250" height="250" class="hover:cursor-move" use:dice={dice2}></canvas>
		</div>

		<!-- roll -->
		<div class="flex gap-4 w-full">
			<div class="flex-1"></div>
			<select
				class="select select-bordered shadow"
				bind:value={selectedRollType}
				disabled={!hasRolls}
			>
				<option disabled selected value="">Roll for...</option>
				<option value="add">Add</option>
				<option value="multiply">Multiply</option>
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
		<div
			class="flex gap-2 opacity-0 transition-opacity duration-30 w-full"
			class:opacity-100={selectedRollType === 'multiply'}
		>
			<div class="flex-1">
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
						<span class="tooltip" data-tip={getStakePercentage(i + 1)}>{i + 1}</span>
					{/each}
				</div>
			</div>
			<span
				class="tooltip"
				data-tip={`you are betting ${stakePercentage} of your fortune. if you roll at or above ${multiplyStake}, you will win the amount you betted, otherwise you will lose it.`}
			>
				<Info />
			</span>
		</div>
	</div>
</div>

<dialog id="deposit_modal" class="modal" bind:this={dialog}>
	<div class="modal-box flex flex-col items-end outline outline-primary">
		<h3 class="font-bold text-lg self-start text-primary">Deposit sAVAX</h3>
		<label class="form-control w-full">
			<div class="label">
				<span class="label-text"></span>
				<span class="label-text-alt">Balance: <span class="link text-accent">69 sAVAX</span></span>
			</div>
			<input type="number" placeholder="0" class="input input-bordered w-full" />
		</label>
		<div class="modal-action">
			<form method="dialog">
				<!-- if there is a button in form, it will close the modal -->
				<button class="btn">cancel</button>
			</form>
			<button class="btn btn-primary">deposit</button>
		</div>
	</div>
</dialog>
