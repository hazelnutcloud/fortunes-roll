<script lang="ts">
	import '../app.css';
	import ChatBox from '$lib/components/ChatBox.svelte';
	import { QueryClient, QueryClientProvider } from '@tanstack/svelte-query';
	import { browser } from '$app/environment';
	import Navbar from './Navbar.svelte';
	import { hashKey } from '$lib/utils/hash-key';
	import { onMount } from 'svelte';
	import { nowMs } from '$lib/stores/time';

	const queryClient = new QueryClient({
		defaultOptions: {
			queries: {
				enabled: browser,
				queryKeyHashFn: hashKey
			}
		}
	});

	let interval: NodeJS.Timeout;

	onMount(() => {
		interval = setInterval(() => {
			$nowMs = Date.now();
		}, 1000);
		return () => clearInterval(interval);
	});
</script>

<Navbar />

<QueryClientProvider client={queryClient}>
	<div class="flex h-[calc(100vh-72px)]">
		<div
			class="w-full h-full bg-dice bg-[url('/bg.svg')] bg-[length:480px] max-h-[calc(100vh-72px)] overflow-y-auto"
		>
			<slot />
		</div>
		<ChatBox />
	</div>
</QueryClientProvider>
