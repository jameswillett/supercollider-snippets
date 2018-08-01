(
SynthDef(\blips, {
	arg freq=40, partial=2, divisor=1, fmpartialup=0, fmpartialdown=0,
	pan=0, verb=0, vibRate=4, vibAmt=0.4, amp=0;
	var modEnv = Line.kr(0, vibAmt, 5);
	var viber = SinOsc.ar(vibRate, mul: modEnv);
	var sig = SinOsc.ar((freq.cpsmidi + viber).midicps * partial * divisor * SinOsc.ar(freq * fmpartialup / fmpartialdown * partial, add: 1));
	var env = EnvGen.kr(Env.new([0,1,0], [0,10], [1,-10]), doneAction:2);
	sig = Pan2.ar(sig, pan);
	sig = FreeVerb.ar(sig * env, verb * (1 - viber), verb * 2);
	Out.ar(0, sig * amp * 0.25);
}).add
);

(
SynthDef(\click, {
	arg r=0.125, amp=1, pan=0, modF = 1000, filter=5000, bw=4;
	var sig = SinOsc.ar(modF * WhiteNoise.ar(amp * 10));
	var env = EnvGen.kr(Env.new([0,1,0], [0,r], [1,-1]), doneAction:2);
	sig = BBandPass.ar(sig, filter * Line.ar(1,0.5,0.125),bw);
	sig = Pan2.ar(sig * 0.3, pan, env);
	Out.ar(0, sig);
}).add
);

(
SynthDef(\kick, {
	arg v = 1;
	var sig = SinOsc.ar(80 * Line.kr(1, 0.1, 1/4, doneAction: 2), mul:6);
	sig = BLowPass.ar(Pan2.ar(sig), 500 * Line.kr(1,0.1,1/4, doneAction: 2), 3);
	Out.ar(0, sig * 0.3 * v * Line.kr(1, 0, 1/4, doneAction: 2));
}).add
);

(
SynthDef(\bass, {
	arg freq=60, gate=1, phs=1;
	var sig=VarSaw.ar(freq, width: 1);
	var env = Linen.kr(gate, doneAction: Done.freeSelf);
	sig = MoogFF.ar(sig, 3000 * XLine.ar(1, 0.1, 4), 2);
	sig=Pan2.ar(sig);
	Out.ar(0, sig  * env * 0.6)
}).add
);

(
a = Pdef(
	\blipsdef,
	Pbind(
		\instrument, \blips,
		\freq, 40,
		\partial, Pwhite(2,18).round(3),
		\fmpartialup, Pwhite(0, 9).round(3),
		\fmpartialdown, Pwhite(0, 9).round(3),
		// \divisor, Prand([1, 2, 1/2, 4/3, 1/3, 2/3], inf),
		\dur, Pxrand([1/4, 3/8, 1, 3/4], inf),
		\pan, Pwhite(-0.8, 0.8),
		\verb, Pwhite(0, 0.999),
		\vibRate, Pwhite(0,6.1),
		\vibAmt, Pwhite(0.1, 1.1),
	)
)
);

(
b = Pdef(
	\hatdef,
	Pbind(
		\instrument, \click,
		\dur, 1/8,
		\r, Prand([1/32, 1/16, 1/8, 1/4], inf),
		\modF, Prand([500, 1000, 10000, 100000], inf),
		\pan, Pwhite(-0.5, 0.5),

	)
)
);

(
c = Pdef(
	\snaredef,
	Pbind(
		\instrument, \click,
		\filter, 2000,
		\modF, 80000,
		\r, Pwrand([1/2, 3/4, 1], [0.8, 0.1, 0.1], inf),
		\amp, Pseq([0,1], inf),
		\dur, 1/2,
		\bw, 6,
	)
)
);

(
d = Pdef(
	\bassdef,
	Pbind(
		\instrument, \bass,
		\freq, Pseq([
			Pseq([60, 40, 50], 7),
			Pseq([60, 40, 38]),
			Pseq([33.3, 40, 38, 50, 40], 3),
			Pseq([33.3, 40, 33.3, 38, 40, 50, 66.6]),
			// Pxrand([30, 33.3, 38, 40, 50, 60]),
		], inf),
		\dur, Pseq([
			Pseq([4,2,2], 8),
			Pseq([1, 3, 1, 2.5 ,0.5], 3),
			Pseq([1, 3, 1,1,1,0.5, 0.5]),
		], inf),
		\phs, Pwhite(0.02, 0.1),
	)
)
);

(
e = Pdef(
	\kickdef,
	Pbind(
		\instrument, \kick,
		\dur, 2,
	)
)
);

(
f = Pdef(
	\kickdef2,
	Pbind(
		\instrument, \kick,
		\v, Pseq([
			0, Pwhite(0, 0.999, 7) > 0.82
		], inf),
		\dur, 1/8
	)
)
);

(
g = Pdef(
	\hataccent,
	Pbind(
		\instrument, \click,
		\dur, 1/16,
		\amp, Pseq([0, (Pwhite(0, 0.99, 7) > 0.9)], inf),
		\r, Prand([1/32, 1/6], inf),
		\stretch, 1,
		\modF, Prand([500, 1000, 10000, 100000], inf),
		\pan, Pwhite(-0.5, 0.5),

	)
)
);



(
a.set(\amp, 0);
)

(
// Server.default.record;
q = Routine({
	var t=0;
	loop({
		if ((t%4) <= 0) { postf("\nbar: % \n\n",(t/4) + 1)};
		(( t%4 ) + 1).postln;
		t = t + 1;
		0.5.wait
	})
}).play(quant:4);

a.set(\amp, 0);
w = Routine ({
	var y=0;
	loop({
		if (y<0.1) {
			a.play(quant:2);
			a.set(\amp, 0);
			y=y+0.1;
			2.wait;
		} {
			if (y<1){
				a.set(\amp, y);
				y=y+0.1;
				2.wait;
			} {
				a.set(\amp, 1);
				w.stop;
			}
		}
	})
}).play(quant:4)
)

a.play(quant:4);

(
b.play(quant:4);
c.play(quant:4);
e.play(quant:4);
f.play(quant:4);
g.play(quant:4);
)

c.stop

d.play(quant:4);

d.stop;

(
b.stop;
c.stop;
e.stop;
f.stop;
g.stop;
)

d.play

(
x = Routine ({
	var z=1;
	loop({
		if (z>0){
			z=z-0.1;
			a.set(\amp, z);
			2.wait;
		} {
			a.stop;
			a.set(\amp, 1);
			"fin".postln;
			x.stop;
		}
	})
}).play
)

s.boot
		