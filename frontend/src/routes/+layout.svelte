<script>
	import ChatBox from '$lib/components/ChatBox.svelte';
	import Wallet from '$lib/components/Wallet.svelte';
import '../app.css';
	import { Wallet2, Dices } from 'lucide-svelte';
</script>

<div class="navbar bg-base-200">
	<div class="navbar-start gap-2">
		<a href="/" class="btn btn-ghost text-xl"><Dices /> Fortune's Roll</a>
	</div>
	<div class="navbar-center">
		<ul class="menu menu-horizontal">
			<li><a href="/">roll</a></li>
			<li><a href="/pot">pot</a></li>
			<li><a href="/leaderboard">leaderboard</a></li>
		</ul>
	</div>
	<div class="navbar-end">
		<Wallet />
	</div>
</div>
<div class="flex h-[calc(100vh-4rem)]">
	<div class="flex-1">
		<slot />
	</div>
	<ChatBox />
</div>
