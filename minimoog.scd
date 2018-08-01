~notes = Array.newClear(128);

(
MIDIdef.noteOn(\noteon, {
	arg vel, nn, chan;
	[nn, vel].postln;
	~wheel1.postln;
	~notes[nn] = Synth.new(\syn, [
	\freq, nn.midicps,
	\gate, 1,
	\modEnvLevel, ~wheel1
	]);
});
)

(
MIDIdef.noteOff(\noteoff, {
	arg vel, nn;
	'note off'.postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});
)

~wheel1 = 0;

(
MIDIdef.cc(\cc, {
	arg val, b, c;
	~wheel1 = val.linlin(0,127,0,1);
	~notes.do{arg synth; synth.set(\modEnvLevel, ~wheel1)};

});
)



s.boot

(
SynthDef.new(\syn, {
	arg freq=440, masterVol=1, masterDetune=0, 	pan2 = 0,
	attack=0, decay=0, sust=0.7, rel=4,

	osc1coarse=8, osc1lev=1, osc1shape=0, fm=0,
	osc2coarse=8, osc2detune=0.1, osc2lev=1, osc2shape=0,
	osc3coarse=1, osc3detune=0, osc3lev=0, osc3shape=1,

	cutoff=1000, res=4, filterFM=2,
	attackf=0, decayf=0.2, sustf=1, relf=2, gate=1, amtToFilter=1,

	attackm=3, decaym=2, sustm=1, relm=0.1, modEnvLevel=1,
	widthRate=0, widthAmt=0, widthLfoOrOsc3=0, widthOffset=1;
	var fmEnv = 1;
	var freqPlusDetune = (freq.cpsmidi + masterDetune).midicps;
	var modEnv = EnvGen.ar(Env.adsr(attackm, decaym, sustm, relm)) * (modEnvLevel * -1);
	var osc3Freq = (freqPlusDetune.cpsmidi + osc3detune).midicps  * (8/osc3coarse) * (1 - modEnv);
	var fMarr = [Saw.ar(osc3Freq), SinOsc.ar(osc3Freq), Pulse.ar(osc3Freq)];
	var fMOsc = Select.ar(osc3shape, fMarr);
	var osc1Freq = freqPlusDetune  * (8/osc1coarse) + (fMOsc * fm * fmEnv);
	var osc2Freq = (freqPlusDetune.cpsmidi + osc2detune).midicps  * (8/osc2coarse);
	var widthOsc = Select.kr(widthLfoOrOsc3, [widthRate, osc3Freq]);
	var osc1arr = [
		VarSaw.ar(osc1Freq, width:SinOsc.ar(widthOsc, mul:widthAmt, add:widthOffset)),
		SinOsc.ar(osc1Freq, SinOsc.ar(widthOsc, mul:widthAmt * pi, add:widthOffset)),
		Pulse.ar(osc1Freq, SinOsc.ar(widthOsc, mul:widthAmt, add:widthOffset)),
	];
	var osc2arr = [
		VarSaw.ar(osc2Freq, width:SinOsc.ar(widthOsc, mul:widthAmt, add:widthOffset)),
		SinOsc.ar(osc2Freq, SinOsc.ar(widthOsc, mul:widthAmt * pi, add:widthOffset)),
		Pulse.ar(osc2Freq, SinOsc.ar(widthOsc, mul:widthAmt, add:widthOffset))
	];
	var osc3arr = [
		VarSaw.ar(osc3Freq, width:SinOsc.ar(widthOsc, mul:widthAmt, add:widthOffset)),
		SinOsc.ar(osc3Freq, SinOsc.ar(widthOsc, mul:widthAmt * pi, add:widthOffset)),
		Pulse.ar(osc3Freq, SinOsc.ar(widthOsc, mul:widthAmt, add:widthOffset))
	];
	var filterFMarr = [Saw.ar(osc3Freq), SinOsc.ar(osc3Freq), Pulse.ar(osc3Freq)];
	var osc1=Select.ar(osc1shape, osc1arr);
	var osc2=Select.ar(osc2shape, osc2arr);
	var osc3=Select.ar(osc3shape, osc3arr);
	var filterFMOsc = Select.ar(osc3shape, fMarr);
	var ampEnv = EnvGen.ar(Env.adsr(attack, decay, sust, rel), gate, doneAction:2);
	var filterEnv = EnvGen.ar(Env.adsr(attackf, decayf, sustf, relf), gate)* amtToFilter;
	var sig = Mix([(osc1 * osc1lev),(osc2 * osc2lev),(osc3 * osc3lev)]);
	var filtered = MoogFF.ar(sig, cutoff * filterEnv * (1 - (filterFMOsc * filterFM)), res);
	var amp = Pan2.ar(filtered, pan2, level: ampEnv);
	Out.ar(0, amp * masterVol);
}).add;
);



(
SynthDef.new(\hats, {
	var sig = BHiPass.ar(WhiteNoise.ar(0.6), 2000, 0.8);
	var amp = Pan2.ar(sig, 0, Line.ar(1,0,1/16, doneAction: 2));
	Out.ar(0, amp);
}).add;
);

(
SynthDef.new(\snare, {
	arg snaregate = 1;
	var sig = WhiteNoise.ar();
	var hi = BHiPass.ar(sig * 0.5, rq: 0.3);
	var mid = BBandPass.ar(sig * 1.5, 800, 1);
	var lo = BBandPass.ar(sig * 3, 600, 0.7);
	var amp = Pan2.ar(hi + mid + lo, 0, Line.ar(2,0.1,1/8, doneAction: 2));
	Out.ar(0, amp * snaregate);
}).add;
)

(
SynthDef.new(\kick, {
	var sig = SinOsc.ar(Line.ar(110, 20, 1/2, doneAction: 2));
	var amp = Pan2.ar(sig, 0, Line.ar(4,0,1/2, doneAction: 2));
	Out.ar(0, amp * 2);
}).add;
)


(
Pdef(
	\cutman,
	Pbind(
		\instrument, \syn,
		\midinote, Pseq([
			Pseq([[60, 64], [64, 67], [71, 74]],2),
			[71, 74], [67, 71], [64, 67], [60, 64],
			Pseq([[56, 60], [60, 63], [67, 70]],2),
		], inf),
		\dur, Pseq([1/4, 1/4, 3/4, 1/4, 1/4, 1/2, 1/4, 1/2, 1/2, 1/2, 1/4, 1/4, 3/4, 1/4, 1/4, 9/4], inf),
		\masterDetune, 0,
		\decay, 1,
		\sust, 0,
		\fm, 40,
	);
).play(quant:8)
);


(
Pdef(
	\cutbass,
	Pbind(
		\instrument, \syn,
		\midinote, Pseq([
			Pseq([60],16),
			Pseq([56],16),
		], inf),
		\dur, 1/4,
		\masterDetune, -12
		amountToFilter
	);
).play(quant:8)
);

(
Pdef(
	\dre,
	Pbind(
		\instrument, \syn,
		\midinote, Pseq([
			0, 7, 7, 5, 7, 5, 3, 5, 5, 3, 0, 3,
		] + 64, inf),
		\dur, Pseq([
			2/8, 2/8, 1/8, 1/8, 2/8, 1/8, 1/8, 2/8, 1/8, 1/8, 1/8, 1/8,
		], inf),
		\stretch, 2,
	);
).play(quant:4);
);

(
Pdef(
	\chords,
	Pbind(
		\instrument, \syn,
		\midinote, Pseq([
			[60, 64, 67],
			Pseq([[60, 65, 67]],4),
			[60, 64, 67],
			Pseq([[59, 62, 67]], 3),
		], inf),
		\dur, Pseq([3/4, 1, 1/8, 1/8, 1/4, 2/4, 1, 1/8, 1/8], inf),
		\masterVol, 1,
	);
).play(quant:4)
);
(

Pdef(
	\bass,
	Pbind(
		\instrument, \syn,
		\midinote, Pseq([
			36,
			Pseq([41], 3),
			36,
			Pseq([43], 2)
		], inf),
		\dur, Pseq([3/4, 1, 1/4, 1/4, 2/4, 1, 1/4], inf),
		\osc2lev, 1,
		\osc3shape, 1,
		\osc3coarse, 2,
		\filterFM, 50,
		\cutoff, 100,
		\decayf, 0.5,
		\sustf, 0,
		\amtToFilter, 0.4,
		\res, 3,
	);
).play(quant:4);
);

(
Pdef(
	\nextepisodehats,
	Pbind(
		\instrument, \hats,
		\dur, 1/8,
		\stretch, 2,
	);
).stop(quant:4);
);

(
Pdef(
	\nextepisodesnare,
	Pbind(
		\instrument, \snare,
		\dur, Pseq([Rest(1/4), 1/4], inf),
		\stretch, 2,
	);
).stop(quant:4);
);

(
Pdef(
	\nextepisodekick,
	Pbind(
		\instrument, \kick,
		\dur, Pseq([
			1/2, 1/8, 3/8, 1/8, 3/8, 1/8, 1/4, 1/8
		], inf),
		\stretch, 2,
	);
).stop(quant:4);
);
		