using UnityEngine;

namespace TihiyGorod
{
    public sealed class WeatherSystem : MonoBehaviour
    {
        public static WeatherSystem I { get; private set; }

        public bool IsRaining { get; private set; }
        public float Intensity { get; private set; }

        ParticleSystem _rain;
        float _nextRoll;
        float _rainLeft;
        bool _forced;

        void Awake()
        {
            I = this;
            _nextRoll = Random.Range(18f, 36f);
        }

        public void Build(Transform world)
        {
            var go = new GameObject("Rain");
            go.transform.SetParent(world, false);
            _rain = go.AddComponent<ParticleSystem>();
            var main = _rain.main;
            main.loop = true;
            main.playOnAwake = false;
            main.duration = 5f;
            main.startLifetime = 1.4f;
            main.startSpeed = 12f;
            main.startSize = new ParticleSystem.MinMaxCurve(0.02f, 0.045f);
            main.startColor = new Color(0.75f, 0.82f, 0.92f, 0.7f);
            main.maxParticles = 1600;
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.gravityModifier = 0.8f;

            var em = _rain.emission;
            em.rateOverTime = 0f;

            var sh = _rain.shape;
            sh.shapeType = ParticleSystemShapeType.Box;
            sh.scale = new Vector3(18f, 0.2f, 18f);

            var vol = _rain.velocityOverLifetime;
            vol.enabled = true;
            vol.y = new ParticleSystem.MinMaxCurve(-10f, -14f);

            var rend = go.GetComponent<ParticleSystemRenderer>();
            rend.renderMode = ParticleSystemRenderMode.Stretch;
            rend.lengthScale = 3.2f;
            rend.velocityScale = 0.08f;
            var rainShader = Shader.Find("Particles/Standard Unlit");
            if (rainShader == null) rainShader = Shader.Find("Sprites/Default");
            if (rainShader == null) rainShader = Shader.Find("Unlit/Color");
            var mat = new Material(rainShader);
            mat.color = new Color(0.8f, 0.85f, 0.95f, 0.65f);
            rend.sharedMaterial = mat;
        }

        public void ToggleRain()
        {
            _forced = true;
            if (IsRaining) StopRain();
            else StartRain(Random.Range(22f, 40f));
        }

        public void ForceRain(float duration)
        {
            _forced = true;
            if (!IsRaining) StartRain(duration);
            else _rainLeft = Mathf.Max(_rainLeft, duration);
        }

        void Update()
        {
            if (_rain != null && CityGrid.I != null)
            {
                var c = CityGrid.I.WorldCenter;
                _rain.transform.position = c + new Vector3(0f, 9f, 0f);
            }

            if (IsRaining)
            {
                Intensity = Mathf.MoveTowards(Intensity, 1f, Time.deltaTime * 0.6f);
                _rainLeft -= Time.deltaTime;
                if (_rainLeft <= 0f && !_forced) StopRain();
            }
            else
            {
                Intensity = Mathf.MoveTowards(Intensity, 0f, Time.deltaTime * 0.4f);
                _forced = false;
                _nextRoll -= Time.deltaTime;
                if (_nextRoll <= 0f)
                {
                    _nextRoll = Random.Range(40f, 85f);
                    if (Random.value < 0.55f) StartRain(Random.Range(16f, 34f));
                }
            }

            if (CityGrid.I != null)
                CityGrid.I.TintTiles(Palette.WetMul, Intensity);

            if (_rain != null)
            {
                var em = _rain.emission;
                em.rateOverTime = Intensity * 900f;
                if (Intensity > 0.05f && !_rain.isPlaying) _rain.Play();
                if (Intensity <= 0.02f && _rain.isPlaying) _rain.Stop();
            }
        }

        void StartRain(float duration)
        {
            IsRaining = true;
            _rainLeft = duration;
            if (Game.Audio != null) Game.Audio.NotifyRain(true);
        }

        void StopRain()
        {
            IsRaining = false;
            _forced = false;
            if (Game.Audio != null) Game.Audio.NotifyRain(false);
        }

        public string RuLabel
        {
            get { return IsRaining ? "дождь" : "ясно"; }
        }
    }
}
