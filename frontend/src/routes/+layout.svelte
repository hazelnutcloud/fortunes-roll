<script>
	import ChatBox from '$lib/components/ChatBox.svelte';
	import Wallet from '$lib/components/Wallet.svelte';
	import '../app.css';
	import { Dices, Clover, Landmark, ListOrdered } from 'lucide-svelte';
</script>

<div class="navbar bg-base-300">
	<div class="navbar-start gap-2">
		<a href="/" class="btn btn-ghost text-xl"><Dices /> Fortune's Roll</a>
	</div>
	<div class="navbar-center">
		<ul class="menu menu-horizontal">
			<li>
				<a href="/" class="group"
					><Clover /><span class="w-0 invisible group-hover:visible group-hover:w-auto">roll</span
					></a
				>
			</li>
			<li>
				<a href="/" class="group"
					><Landmark /><span class="w-0 invisible group-hover:visible group-hover:w-auto">pot</span
					></a
				>
			</li>
			<li>
				<a href="/" class="group"
					><ListOrdered /><span class="w-0 invisible group-hover:visible group-hover:w-auto"
						>leaderboard</span
					></a
				>
			</li>
		</ul>
	</div>
	<div class="navbar-end">
		<Wallet />
	</div>
</div>
<div class="flex h-[calc(100vh-4rem)]">
	<div class="flex-1 h-full flex flex-col justify-center items-center">
		<slot />
	</div>
	<ChatBox />
</div>
