<script lang="ts">
	import { api } from '$lib/queries/api';
	import { account, accountEnsName } from '$lib/stores/account';
	import { findAndTruncateAddress } from '$lib/utils/address';
	import { signMessage } from '@wagmi/core';
	import { MessagesSquare, Megaphone, SendHorizonal } from 'lucide-svelte';
	import { onMount } from 'svelte';
	import { verifyMessage } from 'viem';

	let selectedTab = 'chat';
	let signedIn = false;
	let input: string;

	let ws: ReturnType<(typeof api)['v1']['chat']['subscribe']>;
	let messages: { id: string; msg: string }[] = [
		{
			id: '🔮 Fortune Master',
			msg: "Welcome to Fortune's Roll! Feelin' lucky?"
		}
	];

	const signIn = async () => {
		if (!$account?.address) return;
		const nonce = Math.floor(Math.random() * 1000000000);
		const msg = `Sign this message to chat! nonce: ${nonce.toString(16)}`;
		const signature = await signMessage({
			message: msg
		});

		const correct = await verifyMessage({
			message: msg,
			signature,
			address: $account.address
		});

		if (!correct) return;
		const id = $accountEnsName ?? $account.address;

		ws = api.v1.chat.subscribe({ $query: { id: $accountEnsName ?? $account.address } });

		ws.subscribe((msg) => {
			if (msg.data.id === id) return;
			if (msg.data.id === 'admin') {
				msg.data.msg = `📢 ${findAndTruncateAddress((msg.data.msg as string).replace('}', ''))}`;
			}
			messages = [...messages, msg.data];
		});

		signedIn = true;
	};

	const send = () => {
		if (!signedIn) return;
		if (!ws) return;
		if (!input.trim()) return;

		ws.send(input.trim());

		messages = [...messages, { id: 'self', msg: input }];

		input = '';
	};

	onMount(() => {
		return () => {
			ws?.close();
		};
	});
</script>

<div class="bg-base-200 w-72 max-w-72 flex flex-col p-2">
	<div role="tablist" class="tabs tabs-bordered">
		<button
			role="tab"
			class="tab"
			class:tab-active={selectedTab === 'chat'}
			on:click={() => (selectedTab = 'chat')}><MessagesSquare /></button
		>
		<!-- <button
			role="tab"
			class="tab"
			class:tab-active={selectedTab === 'announcements'}
			on:click={() => (selectedTab = 'announcements')}><Megaphone /></button
		> -->
	</div>
	<div class="flex-1 flex flex-col justify-end py-2">
		{#each messages as message}
			<div
				class="chat"
				class:chat-start={message.id !== 'self'}
				class:chat-end={message.id === 'self'}
			>
				<div class="chat-header">
					{message.id === 'self' ? 'You' : findAndTruncateAddress(message.id)}
				</div>
				<div class="chat-bubble whitespace-normal overflow-auto text-sm">{message.msg}</div>
			</div>
		{/each}
	</div>
	{#if selectedTab === 'chat'}
		<div class="flex gap-2">
			{#if !signedIn}
				<button class="btn px-2 btn-primary w-full" on:click={signIn}>Sign in to chat!</button>
			{:else}
				<input
					type="text"
					name=""
					id=""
					class="input input-bordered w-full"
					class:disabled={!signedIn}
					placeholder="say something..."
					disabled={!signedIn}
					bind:value={input}
				/>
				<button class="btn px-2 btn-primary" on:click={(e) => send()}
					><SendHorizonal class="ml-1" /></button
				>
			{/if}
		</div>
	{/if}
</div>
