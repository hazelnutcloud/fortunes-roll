import { Illustration, TAU, Hemisphere, Box, Group } from 'zdog';

export function dice(canvas: HTMLCanvasElement, value: number | null) {
	const colors = {
		white: 'hsl(0 0% 99%)',
		black: 'hsl(206 6% 24%)',
		red: 'hsl(4 77% 55%)'
	};

	const stroke = 20;
	const size = 50;
	const diameter = 13;
	const offset = 16;

	const illustration = new Illustration({
		element: canvas,
		zoom: 2,
		rotate: {
			x: (TAU / 14) * -1,
			y: TAU / 8
		}
	});

	const dice = new Box({
		addTo: illustration,
		color: colors.white,
		stroke,
		width: size,
		height: size,
		depth: size
	});

	const dot = new Hemisphere({
		color: colors.black,
		stroke: 0,
		diameter
	});

	const one = new Group({
		addTo: dice,
		translate: {
			y: (size / 2 + stroke / 2) * -1
		},
		rotate: {
			x: TAU / 4
		}
	});

	dot.copy({
		addTo: one,
		color: colors.red
	});

	const six = new Group({
		addTo: dice,
		translate: {
			y: size / 2 + stroke / 2
		},
		rotate: {
			x: (TAU / 4) * -1
		}
	});

	for (const { x, y } of [
		{ x: offset, y: offset * -1 },
		{ x: offset, y: 0 },
		{ x: offset, y: offset },
		{ x: offset * -1, y: offset },
		{ x: offset * -1, y: 0 },
		{ x: offset * -1, y: offset * -1 }
	]) {
		dot.copy({
			addTo: six,
			translate: {
				x,
				y
			}
		});
	}

	const two = new Group({
		addTo: dice,
		translate: {
			z: (size / 2 + stroke / 2) * -1
		},
		rotate: {
			x: TAU / 2
		}
	});

	for (const { x, y } of [
		{ x: offset, y: offset * -1 },
		{ x: offset * -1, y: offset }
	]) {
		dot.copy({
			addTo: two,
			translate: {
				x,
				y
			}
		});
	}

	const five = new Group({
		addTo: dice,
		translate: {
			z: size / 2 + stroke / 2
		}
	});

	for (const { x, y } of [
		{ x: 0, y: 0 },
		{ x: offset, y: offset * -1 },
		{ x: offset, y: offset },
		{ x: offset * -1, y: offset },
		{ x: offset * -1, y: offset * -1 }
	]) {
		dot.copy({
			addTo: five,
			translate: {
				x,
				y
			}
		});
	}

	const three = new Group({
		addTo: dice,
		translate: {
			x: (size / 2 + stroke / 2) * -1
		},
		rotate: {
			y: TAU / 4
		}
	});

	for (const { x, y } of [
		{ x: 0, y: -0 },
		{ x: offset, y: offset * -1 },
		{ x: offset * -1, y: offset }
	]) {
		dot.copy({
			addTo: three,
			translate: {
				x,
				y
			}
		});
	}

	const four = new Group({
		addTo: dice,
		translate: {
			x: size / 2 + stroke / 2
		},
		rotate: {
			y: (TAU / 4) * -1
		}
	});

	for (const { x, y } of [
		{ x: offset, y: offset * -1 },
		{ x: offset, y: offset },
		{ x: offset * -1, y: offset },
		{ x: offset * -1, y: offset * -1 }
	]) {
		dot.copy({
			addTo: four,
			translate: {
				x,
				y
			}
		});
	}

	illustration.updateRenderGraph();

	// let frame = null;
	// let ticker = 0;
	// const cycle = 125;

	// let angles = {
	// 	x: illustration.rotate.x,
	// 	y: illustration.rotate.y,
	// 	z: illustration.rotate.z
	// };

	// let anglesNext = { ...angles };

	// const setValue = (newValue: number | null) => {
	// 	value = newValue;
	// };

	// const animate = () => {
	// 	if (value === null) {
	// 		return;
	// 	} else if (value === 0) { // waiting for roll to land
	// 		if (ticker < cycle / 2) {
	// 			const ease = easeInOut((ticker / cycle) % 1, 3) * 2;
	// 			ticker++;
	// 		} else {
	// 		}
	// 		frame = requestAnimationFrame(animate);
	// 	} else {
	// 	}
	// };

	value;
	return {
		// update(value: number) {
		// 	setValue(value);
		// 	animate();
		// }
	};
}
