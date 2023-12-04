<script lang="ts">
	import { truncateAddress } from '$lib/utils/address';
	import { faker } from '@faker-js/faker';
</script>

<div class="overflow-x-auto max-h-[calc(100vh-72px)]">
	<table class="table table-pin-rows table-pin-cols">
		<thead>
			<tr>
				<th></th>
				<td>account</td>
				<td>fortune</td>
				<td>deposit</td>
				<td>no. of rolls</td>
				<td>rolls remaining</td>
				<th></th>
			</tr>
		</thead>
		<tbody>
			{#each Array(1000).fill(0) as _, i}
				<tr>
					<th>{i + 1}</th>
					<td
						>{Math.random() > 0.6
							? truncateAddress(faker.finance.ethereumAddress())
							: `${faker.person.firstName().toLowerCase()}.eth`}</td
					>
					<td>{faker.finance.amount()} FORTUNE</td>
					<td>{faker.finance.amount()} AVAX</td>
					<td>{faker.number.int({max: 500})}</td>
					<td>{faker.number.int({max: 500})}</td>
				</tr>
			{/each}
		</tbody>
		<tfoot>
			<tr>
				<th></th>
				<td>account</td>
				<td>fortune</td>
				<td>deposit</td>
				<td>no. of rolls</td>
				<td>rolls remaining</td>
				<th></th>
			</tr>
		</tfoot>
	</table>
</div>
