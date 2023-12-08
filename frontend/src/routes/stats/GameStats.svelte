<script lang="ts">
	import { Gamepad2, Sparkles, Landmark } from "lucide-svelte"
</script>

<div class="stats bg-base-200 shadow">
	<div class="stat">
		<div class="stat-figure text-secondary">
			<Gamepad2 size={32} />
		</div>
		<div class="stat-title">Season 1</div>
		<div class="stat-value">
			<span class="countdown font-mono">
				<span style="--value:10;"></span>h
				<span style="--value:24;"></span>m
				<span style="--value:3;"></span>s
			</span>
		</div>
		<div class="stat-desc">Jan 1st - Feb 1st</div>
	</div>

	<div class="stat">
		<div class="stat-figure text-secondary">
			<Landmark size={32} />
		</div>
		<div class="stat-title">Total Deposit</div>
		<div class="stat-value">4,200</div>
		<div class="stat-desc">24h ↗︎ 400 (22%)</div>
	</div>

	<div class="stat">
		<div class="stat-figure text-secondary">
			<Sparkles size={32} />
		</div>
		<div class="stat-title">Total Fortune</div>
		<div class="stat-value">1,200</div>
		<div class="stat-desc">24h ↘︎ 90 (14%)</div>
	</div>
</div>
