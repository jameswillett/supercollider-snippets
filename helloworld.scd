
(

SynthDef.new(\sawww, {
  arg freq = 40, q = 10, detune=0.1;
  var osc1, osc2, sum, env, env2, sig;
  sum = 0;
  env = EnvGen.kr(
    Env.perc(0.01, 5, 1, -2),
    doneAction:2
  );
  env2 = XLine.ar(1, 0.001, 5,doneAction: 2);
  osc1 = VarSaw.ar(
    freq.midicps!2,
    {Rand(0, 1)}!2,
    {ExpRand(0.005, 0.05)}!2
  );
  osc2 = VarSaw.ar(
    (freq + detune).midicps!2,
    {Rand(0, 1)}!2,
    {ExpRand(0.005, 0.05)}!2
  );
  sum = osc2 + osc1;

  sum = sum * 0.4 * env;
  sig = BLowPass4.ar(sum, 3000 * env2, q);
  Out.ar(0, sig);
}).add;

a = Task({
  loop({
    1.do({
      arg note;
      Synth.new(\sawww, [
        \freq, ({[-7,-5,0,4,5,7,12,16].choose}+36),
        \q, 0.1,
        \detune, 0.1
      ]);
    });
    1.wait;
  });
});

b = Task({
  loop({
    if (10.rand > 4, {
      1.do({
        arg note;
        Synth.new(\sawww, [
          \freq, ({[0,2,4,7].choose}+60),
          \q, 2
        ]);
      });

    });
    0.125.wait;
  })
})
)

(
SynthDef.new(\hats, {
  var sig;
  sig = WhiteNoise.ar(Line.kr(1, 0, 0.125, doneAction:2)!2);
  sig = BBandPass.ar(sig, 6000, 0.5, 2);
  Out.ar(0, sig);
}).add;
)

(
c = Task({
  loop({
    Synth.new(\hats);
    0.0625.wait;
    if (10.rand > 9, {
      Synth.new(\hats);
    });
    0.0625.wait;
  })
})
)

c.start

(
SynthDef.new(\snare, {
  arg vel = 2;
  var sig;
  sig = WhiteNoise.ar();
  sig = MoogFF.ar(sig, XLine.ar(5000, 100, doneAction:2)!2);
  sig = sig * Line.ar(1,0,0.33) * vel;
  Out.ar(0, sig);
}).add;
)

(
d = Task({
  0.5.wait;
  loop({
    Synth.new(\snare);
    1.wait;
  })
})
)

(
SynthDef.new(\kick, {
  var sig;
  sig = SinOsc.ar(XLine.ar(90, 40, doneAction:2)!2);
  // sig = BLowPass4.ar(sig, XLine.ar(200, 40, doneAction:2)!2, 1);
  sig = sig * Line.ar(1,0);
  Out.ar(0, sig);
}).add
)

Synth.new(\kick);

(
e = Task({
  loop({
    Synth.new(\kick);
    0.25.wait;
    if (10.rand>3, {
      Synth.new(\kick);
    });
    0.5.wait;
    if (10.rand>3, {
      Synth.new(\kick);
    });
    0.5.wait;
    if (10.rand>3, {
      Synth.new(\kick);
    });
    0.5.wait;
    if (10.rand>3, {
      Synth.new(\kick);
    });
    0.25.wait;
  })
})
)

e.start
e.stop

(
[55, 59, 62, 67].do({arg note; Synth.new(\sawww, [
  \freq, note,
  \q, 0.02,
]);
})
)

(
[60, 64, 67].do({arg note; Synth.new(\sawww, [
  \freq, note,
  \q, 1,
]);
})
)

(
[60, 65, 67].do({arg note; Synth.new(\sawww, [
  \freq, note,
  \q, 0.1,
]);
})
)

(
a.start;
b.start;
c.start;
d.start;
e.start;
)
e.start
(
a.stop;
b.stop;
c.stop;
d.stop;
e.stop;
)

(
c.start;
d.start;
e.start;
)

b.play;

s.boot
