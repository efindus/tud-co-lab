const d = require('fs').readFileSync('./brainfuck/mandelbrot.b').toString()

let count = 0;
for (let i = 0; i < d.length; i++) {
	if (d[i] === '[') {
		console.log(d[i], i, count);
		count++;
	} else if (d[i] === ']') {
		count--;
		console.log(d[i], i, count);
	}
}
