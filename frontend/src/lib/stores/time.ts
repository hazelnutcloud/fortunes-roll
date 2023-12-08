import { derived, writable } from 'svelte/store';

export const nowMs = writable(Date.now());

export const nowSeconds = derived(nowMs, ($nowMs) => BigInt(Math.floor($nowMs / 1000)));
