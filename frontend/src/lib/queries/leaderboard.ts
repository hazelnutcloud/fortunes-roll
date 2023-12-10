import { api } from './api';

export async function getPlayerPositionOnLeaderboard(playerAddress: string) {
	const { data } = await api.v1.players[playerAddress].ranking.get();

	if (!data || (data && data.error)) {
		return null;
	}

	return {
		position: data.data.rank,
		twentyFourHourChange: 0
	};
}

export async function getPlayersByScore() {
	const { data, error } = await api.v1.players.get({
		$query: { sortBy: 'score', sortDirection: 'desc' }
	});

	if (error) {
		return null;
	}

	return data.data.map((player) => ({
		...player,
		lastRollTimestamp: player.lastRollTimestamp ? new Date(player.lastRollTimestamp) : null
	}));
}
