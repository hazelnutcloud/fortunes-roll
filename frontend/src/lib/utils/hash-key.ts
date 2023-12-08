/* eslint-disable @typescript-eslint/ban-types */
/* eslint-disable @typescript-eslint/no-explicit-any */
import type { QueryKey, MutationKey } from '@tanstack/svelte-query';

function hasObjectPrototype(o: any): boolean {
	return Object.prototype.toString.call(o) === '[object Object]';
}

// Copied from: https://github.com/jonschlinkert/is-plain-object
export function isPlainObject(o: any): o is Object {
	if (!hasObjectPrototype(o)) {
		return false;
	}

	// If has no constructor
	const ctor = o.constructor;
	if (typeof ctor === 'undefined') {
		return true;
	}

	// If has modified prototype
	const prot = ctor.prototype;
	if (!hasObjectPrototype(prot)) {
		return false;
	}

	// If constructor does not have an Object-specific method
	if (!Object.prototype.hasOwnProperty.call(prot, 'isPrototypeOf')) {
		return false;
	}

	// Most likely a plain Object
	return true;
}

export function hashKey(queryKey: QueryKey | MutationKey) {
	return JSON.stringify(queryKey, (_, val) =>
		isPlainObject(val)
			? Object.keys(val)
					.sort()
					.reduce((result, key) => {
						result[key] = val[key];
						return result;
					}, {} as any)
			: typeof val === 'bigint'
			  ? val.toString()
			  : val
	);
}
