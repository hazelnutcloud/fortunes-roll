import { edenTreaty } from '@elysiajs/eden';
import type { app as App } from 'fortunes-backend';
import { PUBLIC_API_SERVER_URL } from '$env/static/public';

export const api = edenTreaty<typeof App>(PUBLIC_API_SERVER_URL);
