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
