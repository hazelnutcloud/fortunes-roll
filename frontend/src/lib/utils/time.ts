export function breakDownTimeLeft(timeLeftSeconds: number) {
	const daysSeconds = 60 * 60 * 24;
	const hoursSeconds = 60 * 60;
	const minutesSeconds = 60;

	const days = Math.floor(timeLeftSeconds / daysSeconds);
	const hours = Math.floor(timeLeftSeconds / hoursSeconds) % 24;
	const minutes = Math.floor(timeLeftSeconds / minutesSeconds) % 60;
	const seconds = timeLeftSeconds % 60;

	return {
		days,
		hours,
		minutes,
		seconds
	}
}