import { createPublicClient, fallback, http, webSocket } from 'viem';
import { avalanche, mainnet } from 'viem/chains';

export const publicClient = createPublicClient({
	chain: avalanche,
	transport: fallback([
		webSocket("wss://avalanche-c-chain.publicnode.com"),
		http('https://avalanche-mainnet.infura.io/v3/4883ecdf99f84bd3a4351502ea662fe2'),
		http(avalanche.rpcUrls.public.http[0])
	]),
});

export const mainnetPublicClient = createPublicClient({
	chain: mainnet,
	transport: fallback([
		http('https://mainnet.infura.io/v3/4883ecdf99f84bd3a4351502ea662fe2'),
		http(mainnet.rpcUrls.public.http[0])
	]),
})