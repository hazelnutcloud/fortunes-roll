<script>
	import '../app.css';
	import ChatBox from '$lib/components/ChatBox.svelte';
	import { QueryClient, QueryClientProvider } from '@tanstack/svelte-query';
	import { browser } from '$app/environment';
	import Navbar from './Navbar.svelte';

	const queryClient = new QueryClient({
		defaultOptions: {
			queries: {
				enabled: browser
			}
		}
	});
</script>

<Navbar />

<QueryClientProvider client={queryClient}>
	<div class="flex h-[calc(100vh-72px)]">
		<div
			class="flex-1 h-full bg-dice bg-[url('/bg.svg')] bg-[length:480px] max-h-[calc(100vh-72px)] overflow-y-auto"
		>
			<slot />
		</div>
		<ChatBox />
	</div>
</QueryClientProvider>
