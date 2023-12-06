<script lang="ts">

	export let dialog: HTMLDialogElement;

</script>

<dialog id="deposit_modal" class="modal" bind:this={dialog}>
	<div class="modal-box flex flex-col items-end outline outline-primary">
		<h3 class="font-bold text-lg self-start text-primary">Deposit sAVAX</h3>
		<label class="form-control w-full">
			<div class="label">
				<span class="label-text"></span>
				<span class="label-text-alt">Balance: <span class="link text-accent">69 sAVAX</span></span>
			</div>
			<input type="number" placeholder="0" class="input input-bordered w-full" />
		</label>
		<div class="modal-action">
			<form method="dialog">
				<!-- if there is a button in form, it will close the modal -->
				<button class="btn">cancel</button>
			</form>
			<button class="btn btn-primary">deposit</button>
		</div>
	</div>
</dialog>