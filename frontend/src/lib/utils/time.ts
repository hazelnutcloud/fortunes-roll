export function breakDownTimeLeft(timeLeftSeconds: number) {
	const hoursSeconds = 60 * 60;
	const minutesSeconds = 60;

	const hours = Math.floor(timeLeftSeconds / hoursSeconds);
	const minutes = Math.floor(timeLeftSeconds / minutesSeconds) % 60;
	const seconds = timeLeftSeconds % 60;

	return {
		hours,
		minutes,
		seconds
	}
}