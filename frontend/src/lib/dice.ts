import { Illustration, TAU, Hemisphere, Box, Group, easeInOut } from 'zdog';

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

	const faceAngles = [
		{
			x: (TAU / 4) * -1,
			y: 0,
			z: 0
		},

		{
			x: TAU / 2,
			y: 0,
			z: 0
		},
		{
			x: 0,
			y: (TAU / 4) * -1,
			z: 0
		},
		{
			x: 0,
			y: TAU / 4,
			z: 0
		},
		{
			x: 0,
			y: 0,
			z: 0
		},
		{
			x: TAU / 4,
			y: 0,
			z: 0
		}
	];

	const illustration = new Illustration({
		element: canvas,
		zoom: 2,
		rotate: {
			x: (TAU / 14) * -1,
			y: TAU / 8
		},
		dragRotate: true
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

	let frame: number | null = null;
	let ticker = 0;
	const cycle = 200;

	const angles = {
		x: illustration.rotate.x,
		y: illustration.rotate.y,
		z: illustration.rotate.z
	};

	let anglesNext = { ...angles };

	const setValue = (newValue: number | null) => {
		value = newValue;
	};

	const animate = (lastTimestamp: number) => {
		const now = performance.now();
		const delta = now - lastTimestamp;

		if (value === 0) {
			// waiting for roll to land
			if (ticker < cycle / 2) {
				const ease = easeInOut((ticker / cycle) % 1, 2);

				illustration.rotate.y += (ease * TAU * delta) / 100;
				illustration.rotate.x += (ease * TAU * delta) / 200;
				illustration.rotate.z += (ease * TAU * delta) / 400;

				angles.x = illustration.rotate.x;
				angles.y = illustration.rotate.y;
				angles.z = illustration.rotate.z;

				ticker++;
			} else {
				illustration.rotate.y += (TAU * delta) / 100;
				illustration.rotate.x += (TAU * delta) / 200;
				illustration.rotate.z += (TAU * delta) / 400;

				angles.x = illustration.rotate.x;
				angles.y = illustration.rotate.y;
				angles.z = illustration.rotate.z;
			}
		} else if (value !== null) {
			if (ticker < cycle) {
				const ease = (easeInOut((ticker / cycle) % 1, 2) - 0.5) * 2;

				illustration.rotate.x = angles.x + (((anglesNext.x - angles.x) % TAU) + TAU) * ease;
				illustration.rotate.y = angles.y + (((anglesNext.y - angles.y) % TAU) + TAU) * ease;
				illustration.rotate.z = angles.z + (((anglesNext.z - angles.z) % TAU) + TAU) * ease;

				ticker++;
			} else {
				angles.x = anglesNext.x;
				angles.y = anglesNext.y;
				angles.z = anglesNext.z;

				illustration.rotate.x = angles.x;
				illustration.rotate.y = angles.y;
				illustration.rotate.z = angles.z;

				ticker = 0;

				value = null;
			}
		}

		illustration.updateRenderGraph();
		frame = requestAnimationFrame(animate);
	};

	animate(performance.now());

	return {
		update(value: number) {
			if (value) {
				const rawAnglesNext = faceAngles[value - 1];
				anglesNext = {
					x: rawAnglesNext.x + (Math.random() * TAU) / 30,
					y: rawAnglesNext.y + (Math.random() * TAU) / 30,
					z: rawAnglesNext.z + (Math.random() * TAU) / 30
				};
			}
			setValue(value);
		},
		destroy() {
			frame && cancelAnimationFrame(frame);
			illustration.remove();
		}
	};
}
