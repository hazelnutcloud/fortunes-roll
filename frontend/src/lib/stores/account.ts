import type { GetAccountResult, PublicClient } from '@wagmi/core';
import { writable } from 'svelte/store';

export const account = writable<GetAccountResult<PublicClient> | undefined>(undefined);
export const accountEnsName = writable<string | undefined>(undefined);
