export function splitAndRandomize(value: number) {

	const min = Math.max(1, value - 6);
	const max = Math.min(6, value - 1);
	const val1 = Math.round(Math.random() * (max - min)) + min;
	const val2 = value - val1;

	return [val1, val2]
}