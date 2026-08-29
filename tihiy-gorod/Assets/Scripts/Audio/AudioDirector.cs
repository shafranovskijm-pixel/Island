using UnityEngine;

namespace TihiyGorod
{
    /// <summary>
    /// Layered procedural music: D Dorian pad, day/night motifs, rain bed, city pulse.
    /// Parameters are written on the main thread; oscillators run in PCM callbacks.
    /// </summary>
    public sealed class AudioDirector : MonoBehaviour
    {
        public static AudioDirector I { get; private set; }
        public static float MusicMul = 1f;
        public static float SfxMul = 1f;

        AudioSource _pad, _day, _night, _rain, _pulse, _box, _sfx;
        PadReader _padR;
        MotifReader _dayR;
        MotifReader _nightR;
        RainReader _rainR;
        PulseReader _pulseR;
        BoxReader _boxR;

        float _padVol = 0.22f, _dayVol, _nightVol, _rainVol, _pulseVol, _boxVol;

        void Awake()
        {
            I = this;
        }

        public void Build(Transform root)
        {
            var music = new GameObject("Music");
            music.transform.SetParent(root, false);

            _padR = new PadReader();
            _dayR = new MotifReader(true);
            _nightR = new MotifReader(false);
            _rainR = new RainReader();
            _pulseR = new PulseReader();
            _boxR = new BoxReader();

            _pad = Make(music.transform, "Pad", _padR.Read, 0.22f);
            _day = Make(music.transform, "Day", _dayR.Read, 0f);
            _night = Make(music.transform, "Night", _nightR.Read, 0f);
            _rain = Make(music.transform, "Rain", _rainR.Read, 0f);
            _pulse = Make(music.transform, "Pulse", _pulseR.Read, 0f);
            _box = Make(music.transform, "MusicBox", _boxR.Read, 0f);
            _sfx = music.AddComponent<AudioSource>();
            _sfx.playOnAwake = false;
            _sfx.spatialBlend = 0f;
        }

        AudioSource Make(Transform parent, string name, AudioClip.PCMReaderCallback cb, float vol)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var src = go.AddComponent<AudioSource>();
            var clip = AudioClip.Create(name, 44100, 1, 44100, true, cb);
            src.clip = clip;
            src.loop = true;
            src.volume = vol;
            src.spatialBlend = 0f;
            src.priority = 32;
            src.Play();
            return src;
        }

        void Update()
        {
            float night = Game.Time != null ? Game.Time.NightFactor : 0f;
            float rain = Game.Weather != null ? Game.Weather.Intensity : 0f;
            int buildings = CityGrid.I != null ? CityGrid.I.BuildingCount : 0;
            float density = Mathf.Clamp01(buildings / 14f);

            float ujut = CozySystem.I != null ? CozySystem.I.Normalized : 0.25f;
            int boxes = CozySystem.I != null ? CozySystem.I.MusicBoxCount : 0;
            float padTarget = 0.20f + density * 0.05f + ujut * 0.04f;
            if (rain > 0.2f) padTarget *= 0.72f;
            float dayTarget = (1f - night) * (0.11f + density * 0.04f) * (1f - rain * 0.35f);
            float nightTarget = night * (0.14f + density * 0.03f);
            float rainTarget = rain * 0.16f;
            float pulseTarget = 0.035f + density * 0.09f;
            if (night > 0.6f) pulseTarget *= 0.7f;

            _padVol = Mathf.MoveTowards(_padVol, padTarget, Time.deltaTime * 0.25f);
            _dayVol = Mathf.MoveTowards(_dayVol, dayTarget, Time.deltaTime * 0.2f);
            _nightVol = Mathf.MoveTowards(_nightVol, nightTarget, Time.deltaTime * 0.2f);
            _rainVol = Mathf.MoveTowards(_rainVol, rainTarget, Time.deltaTime * 0.3f);
            _pulseVol = Mathf.MoveTowards(_pulseVol, pulseTarget, Time.deltaTime * 0.15f);
            float boxTarget = Mathf.Clamp(boxes * 0.045f, 0f, 0.13f);
            _boxVol = Mathf.MoveTowards(_boxVol, boxTarget, Time.deltaTime * 0.12f);

            float mm = Mathf.Clamp01(MusicMul);
            if (_pad != null) _pad.volume = Mathf.Max(0.12f, _padVol) * mm;
            if (_day != null) _day.volume = _dayVol * mm;
            if (_night != null) _night.volume = _nightVol * mm;
            if (_rain != null) _rain.volume = _rainVol * mm;
            if (_pulse != null) _pulse.volume = _pulseVol * mm;
            if (_box != null) _box.volume = _boxVol * mm;

            float g = 0f, d = 0f, a = 0f, f = 0f;
            if (Game.Align != null)
            {
                g = Game.Align.Influence(AlignmentType.Good);
                d = Game.Align.Influence(AlignmentType.Dark);
                a = Game.Align.Influence(AlignmentType.Arcane);
                f = Game.Align.Influence(AlignmentType.Fairy);
            }
            _padR.SetMood(g, d, a, f, night, ujut);
            _dayR.SetMood(g, f);
            _nightR.SetMood(d, a);
            _pulseR.SetDensity(density);
        }

        public void NotifyRain(bool on)
        {
            // volumes handled in Update; keep method for hooks
        }

        public void PlayPlace()
        {
            if (_sfx == null) return;
            int n = 44100 / 3;
            var clip = AudioClip.Create("place", n, 1, 44100, false);
            var data = new float[n];
            double ph1 = 0, ph2 = 0;
            float f1 = 293.66f;
            float f2 = 440f;
            for (int i = 0; i < n; i++)
            {
                float t = i / 44100f;
                float env = Mathf.Exp(-t * 6f) * (1f - t * 3f);
                if (env < 0f) env = 0f;
                ph1 += 2.0 * System.Math.PI * f1 / 44100.0;
                ph2 += 2.0 * System.Math.PI * f2 / 44100.0;
                data[i] = (float)(System.Math.Sin(ph1) * 0.18 + System.Math.Sin(ph2) * 0.12) * env;
            }
            clip.SetData(data, 0);
            _sfx.PlayOneShot(clip, 0.45f * Mathf.Clamp01(SfxMul));
        }

        public void PlayChime(bool ok)
        {
            if (_sfx == null) return;
            int n = 44100 / 2;
            var clip = AudioClip.Create("chime", n, 1, 44100, false);
            var data = new float[n];
            double ph1 = 0, ph2 = 0;
            float f1 = ok ? 392f : 246.94f;
            float f2 = ok ? 523.25f : 293.66f;
            for (int i = 0; i < n; i++)
            {
                float t = i / 44100f;
                float env = Mathf.Exp(-t * (ok ? 3.2f : 5f));
                ph1 += 2.0 * System.Math.PI * f1 / 44100.0;
                ph2 += 2.0 * System.Math.PI * f2 / 44100.0;
                data[i] = (float)(System.Math.Sin(ph1) * 0.16 + System.Math.Sin(ph2) * 0.12) * env;
            }
            clip.SetData(data, 0);
            _sfx.PlayOneShot(clip, 0.4f * Mathf.Clamp01(SfxMul));
        }
    }

    sealed class PadReader
    {
        // D Dorian: D3 F3 A3 C4  then C3 E3 G3  then A2 C3 E3  then G2 B2 D3
        static readonly float[][] Chords =
        {
            new[] { 146.83f, 174.61f, 220.00f, 293.66f },
            new[] { 130.81f, 164.81f, 196.00f, 261.63f },
            new[] { 110.00f, 130.81f, 164.81f, 220.00f },
            new[] { 98.00f, 123.47f, 146.83f, 196.00f }
        };

        readonly double[] _ph = new double[4];
        int _chord;
        int _samplesInChord;
        float _g, _d, _a, _f, _night, _ujut;

        public void SetMood(float g, float d, float a, float f, float night, float ujut)
        {
            _g = g; _d = d; _a = a; _f = f; _night = night; _ujut = ujut;
        }

        public void Read(float[] data)
        {
            int chordLen = 44100 * 8;
            var chord = Chords[_chord];
            for (int i = 0; i < data.Length; i++)
            {
                _samplesInChord++;
                if (_samplesInChord >= chordLen)
                {
                    _samplesInChord = 0;
                    _chord = (_chord + 1) % Chords.Length;
                    chord = Chords[_chord];
                }
                double s = 0;
                for (int v = 0; v < 4; v++)
                {
                    float freq = chord[v];
                    if (v == 0) freq *= 1f - _d * 0.03f;
                    if (v == 3) freq *= 1f + _f * 0.02f + _a * 0.015f;
                    _ph[v] += 2.0 * System.Math.PI * freq / 44100.0;
                    if (_ph[v] > 2.0 * System.Math.PI * 32) _ph[v] -= 2.0 * System.Math.PI * 32;
                    double sine = System.Math.Sin(_ph[v]);
                    double tri = 2.0 * (System.Math.Abs((_ph[v] / System.Math.PI % 2.0) - 1.0) - 0.5);
                    double mix = sine * 0.78 + tri * 0.08;
                    float w = v == 0 ? 0.38f : (v == 1 ? 0.28f + _ujut * 0.18f : 0.18f);
                    if (v == 1) w += _ujut * 0.05f;
                    if (v == 3) w = 0.12f + _g * 0.06f + _f * 0.05f + _ujut * 0.05f;
                    s += mix * w;
                }
                float lfo = 0.85f + 0.15f * Mathf.Sin(_samplesInChord / 44100f * 0.25f * Mathf.PI * 2f);
                float warmth = 1f - _night * 0.08f + _g * 0.06f + _ujut * 0.14f;
                data[i] = (float)s * 0.45f * lfo * warmth;
            }
        }
    }

    sealed class MotifReader
    {
        readonly bool _day;
        readonly double[] _ph = new double[3];
        int _step;
        int _age;
        float _a, _b;

        static readonly float[] DayNotes = { 293.66f, 329.63f, 349.23f, 392.00f, 440.00f, 392.00f, 349.23f, 329.63f };
        static readonly float[] NightNotes = { 146.83f, 174.61f, 196.00f, 174.61f, 146.83f, 130.81f, 146.83f, 174.61f };

        public MotifReader(bool day) { _day = day; }

        public void SetMood(float a, float b) { _a = a; _b = b; }

        public void Read(float[] data)
        {
            var notes = _day ? DayNotes : NightNotes;
            int stepLen = _day ? 22050 : 33075;
            for (int i = 0; i < data.Length; i++)
            {
                _age++;
                if (_age >= stepLen)
                {
                    _age = 0;
                    _step = (_step + 1) % notes.Length;
                }
                float f = notes[_step] * (1f + _a * 0.01f + _b * 0.008f);
                _ph[0] += 2.0 * System.Math.PI * f / 44100.0;
                _ph[1] += 2.0 * System.Math.PI * (f * 1.498f) / 44100.0;
                _ph[2] += 2.0 * System.Math.PI * (f * 0.5f) / 44100.0;
                float env = 0.25f + 0.75f * Mathf.Sin(Mathf.PI * (_age / (float)stepLen));
                double s = System.Math.Sin(_ph[0]) * 0.55 + System.Math.Sin(_ph[1]) * 0.18 + System.Math.Sin(_ph[2]) * 0.22;
                data[i] = (float)s * env * 0.32f;
            }
        }
    }

    sealed class RainReader
    {
        readonly System.Random _rng = new System.Random(99);
        float _lp;
        double _dripPh;
        int _dripWait;
        int _dripAge;
        float _dripF;

        public void Read(float[] data)
        {
            for (int i = 0; i < data.Length; i++)
            {
                float white = (float)(_rng.NextDouble() * 2.0 - 1.0);
                _lp = _lp * 0.86f + white * 0.14f;
                float noise = _lp * 0.55f + white * 0.08f;

                if (_dripWait <= 0)
                {
                    _dripWait = 6000 + _rng.Next(18000);
                    _dripAge = 0;
                    _dripF = 700f + (float)_rng.NextDouble() * 900f;
                    _dripPh = 0;
                }
                _dripWait--;
                float drip = 0f;
                if (_dripAge < 3500)
                {
                    _dripAge++;
                    _dripPh += 2.0 * System.Math.PI * _dripF / 44100.0;
                    float env = Mathf.Exp(-_dripAge / 900f);
                    drip = (float)System.Math.Sin(_dripPh) * env * 0.22f;
                    _dripF *= 0.9996f;
                }
                data[i] = noise * 0.35f + drip;
            }
        }
    }

    sealed class PulseReader
    {
        double _ph;
        float _density;
        int _age;

        public void SetDensity(float d) { _density = d; }

        public void Read(float[] data)
        {
            float hz = 0.42f + _density * 0.18f;
            for (int i = 0; i < data.Length; i++)
            {
                _age++;
                _ph += 2.0 * System.Math.PI * 110.0 / 44100.0;
                float beat = 0.5f + 0.5f * Mathf.Sin(_age / 44100f * hz * Mathf.PI * 2f);
                beat = Mathf.Pow(Mathf.Clamp01(beat), 3.5f);
                double sine = System.Math.Sin(_ph) + 0.25 * System.Math.Sin(_ph * 2.0);
                data[i] = (float)sine * beat * 0.28f;
            }
        }
    }

    sealed class BoxReader
    {
        static readonly float[] Notes = { 659.25f, 783.99f, 880.00f, 987.77f, 880.00f, 783.99f, 698.46f, 659.25f };
        double _ph;
        int _step;
        int _age;

        public void Read(float[] data)
        {
            int stepLen = 28000;
            for (int i = 0; i < data.Length; i++)
            {
                _age++;
                if (_age >= stepLen)
                {
                    _age = 0;
                    _step = (_step + 1) % Notes.Length;
                }
                float f = Notes[_step];
                _ph += 2.0 * System.Math.PI * f / 44100.0;
                if (_ph > 2.0 * System.Math.PI * 32) _ph -= 2.0 * System.Math.PI * 32;
                float env = 0.15f + 0.85f * Mathf.Sin(Mathf.PI * (_age / (float)stepLen));
                env *= env;
                data[i] = (float)System.Math.Sin(_ph) * env * 0.18f;
            }
        }
    }
}
