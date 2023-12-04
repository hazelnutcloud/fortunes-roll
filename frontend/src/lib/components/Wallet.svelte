<script lang="ts">
	import { Wallet2 } from 'lucide-svelte';
	import { avalanche, mainnet } from '@wagmi/core/chains';
	import { createWeb3Modal, defaultWagmiConfig } from '@web3modal/wagmi';
	import { fetchEnsName, watchAccount } from '@wagmi/core';
	import { truncateAddress } from '$lib/utils/address';

	const projectId = '4c7843126d3374c92257f0198acf884c';
	const chains = [avalanche, mainnet];

	const metadata = {
		name: "Fortune's Roll",
		description: 'A game of chance',
		url: 'https://fortunesroll.com',
		icons: ['https://avatars.githubusercontent.com/u/37784886']
	};

	const wagmiConfig = defaultWagmiConfig({
		chains,
		projectId,
		metadata
	});

	const modal = createWeb3Modal({ wagmiConfig, projectId, chains, defaultChain: avalanche });

	let ensName: Promise<string | null> | undefined;
	let accountAddress: string | undefined;

	watchAccount((account) => {
		if (account.address) {
			ensName = fetchEnsName({ address: account.address, chainId: 1 });
			accountAddress = truncateAddress(account.address);
		}
	});
</script>

<button class="btn btn-primary" on:click={() => modal.open()}
	><Wallet2 />
	{#if ensName}
		{#await ensName}
			Loading...
		{:then name}
			{#if name}
				{name}
			{:else}
				{accountAddress}
			{/if}
		{:catch error}
			{#if accountAddress}
				{accountAddress}
			{:else}
				{error.message}
			{/if}
		{/await}
	{/if}
</button>
