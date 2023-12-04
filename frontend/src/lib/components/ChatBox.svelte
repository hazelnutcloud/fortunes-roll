<script>
	import { MessagesSquare, Megaphone, SendHorizonal } from 'lucide-svelte';

	let selectedTab = 'chat';
</script>

<div class="bg-base-200 w-72 flex flex-col p-2">
	<div role="tablist" class="tabs tabs-bordered">
		<button
			role="tab"
			class="tab"
			class:tab-active={selectedTab === 'chat'}
			on:click={() => (selectedTab = 'chat')}><MessagesSquare /></button
		>
		<button
			role="tab"
			class="tab"
			class:tab-active={selectedTab === 'announcements'}
			on:click={() => (selectedTab = 'announcements')}><Megaphone /></button
		>
	</div>
	<div class="flex-1"></div>
	{#if selectedTab === 'chat'}
		<div class="flex gap-2">
			<input
				type="text"
				name=""
				id=""
				class="input input-bordered flex-1"
				placeholder="say something..."
			/>
			<button class="btn px-2 btn-primary"><SendHorizonal class="ml-1" /></button>
		</div>
	{/if}
</div>
