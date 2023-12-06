<script lang="ts">
	import { Wallet2 } from 'lucide-svelte';
	import { avalanche } from '@wagmi/core/chains';
	import { EIP6963Connector, createWeb3Modal, walletConnectProvider } from '@web3modal/wagmi';
	import { watchAccount, configureChains, createConfig, InjectedConnector } from '@wagmi/core';
	import { publicProvider } from '@wagmi/core/providers/public';
	import { infuraProvider } from '@wagmi/core/providers/infura';
	import { WalletConnectConnector } from '@wagmi/core/connectors/walletConnect';
	import { CoinbaseWalletConnector } from '@wagmi/core/connectors/coinbaseWallet';
	import { truncateAddress } from '$lib/utils/address';
	import { getEnsName } from '$lib/queries/ens';
	import { account as accountStore } from '$lib/stores/account';

	const projectId = '4c7843126d3374c92257f0198acf884c';

	const { chains, publicClient } = configureChains(
		[avalanche],
		[
			walletConnectProvider({ projectId }),
			infuraProvider({ apiKey: '4883ecdf99f84bd3a4351502ea662fe2' }),
			publicProvider()
		],
		{ batch: { multicall: true } }
	);

	const metadata = {
		name: "Fortune's Roll",
		description: 'A game of chance',
		url: 'https://fortunes-roll.vercel.app',
		icons: ['https://avatars.githubusercontent.com/u/37784886']
	};

	const wagmiConfig = createConfig({
		autoConnect: true,
		connectors: [
			new WalletConnectConnector({ chains, options: { projectId, showQrModal: false, metadata } }),
			new EIP6963Connector({ chains }),
			new InjectedConnector({ chains, options: { shimDisconnect: true } }),
			new CoinbaseWalletConnector({ chains, options: { appName: metadata.name } })
		],
		publicClient
	});

	const modal = createWeb3Modal({ wagmiConfig, projectId, chains, defaultChain: avalanche });

	let ensName: Promise<string | null> | undefined;
	let accountAddress: string | undefined;

	watchAccount((account) => {
		if (account.address) {
			ensName = getEnsName(account.address);
			accountAddress = truncateAddress(account.address);
		}
		accountStore.set(account);
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
