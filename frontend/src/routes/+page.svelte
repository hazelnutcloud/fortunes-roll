<script lang="ts">
	import { dice } from '$lib/dice';

	let dice1: number | null = null;
	let dice2: number | null = null;
	let timeOut: NodeJS.Timeout

	const roll = () => {
		clearTimeout(timeOut);
		dice1 = 0;
		dice2 = 0;
		timeOut = setTimeout(() => {
			dice1 = Math.floor(Math.random() * 6);
			dice2 = Math.floor(Math.random() * 6);
		}, 2000)
	}
</script>

<div class="flex">
	<canvas width="250" height="400" use:dice={dice1}></canvas>
	<canvas width="250" height="400" use:dice={dice2}></canvas>
</div>
<button class="btn btn-primary" on:click={roll}>ROLL</button>
