import { edenTreaty } from '@elysiajs/eden';
import type { app as App } from 'fortunes-backend';

export const api = edenTreaty<typeof App>('http://server:3000');
