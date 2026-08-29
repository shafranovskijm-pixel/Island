using UnityEngine;

namespace TihiyGorod
{
    public sealed class DayNightCycle : MonoBehaviour
    {
        public static DayNightCycle I { get; private set; }

        public float Day01 { get; private set; }
        public Light Sun;
        public Camera Cam;
        float _clock;

        public bool IsNight
        {
            get { return Day01 >= SimConfig.NightStart && Day01 <= SimConfig.NightEnd; }
        }

        public float NightFactor
        {
            get
            {
                if (Day01 < 0.45f) return 0f;
                if (Day01 < SimConfig.NightStart) return Mathf.InverseLerp(0.45f, SimConfig.NightStart, Day01);
                if (Day01 < 0.88f) return 1f;
                if (Day01 < SimConfig.NightEnd) return 1f - Mathf.InverseLerp(0.88f, SimConfig.NightEnd, Day01);
                return 0f;
            }
        }

        public string RuClock
        {
            get
            {
                int minutes = Mathf.FloorToInt(Day01 * 24f * 60f);
                int h = (minutes / 60) % 24;
                int m = minutes % 60;
                string phase;
                if (Day01 < 0.2f) phase = "утро";
                else if (Day01 < 0.45f) phase = "день";
                else if (Day01 < 0.58f) phase = "вечер";
                else if (Day01 < 0.9f) phase = "ночь";
                else phase = "рассвет";
                return string.Format("{0:00}:{1:00}  {2}", h, m, phase);
            }
        }

        void Awake()
        {
            I = this;
            _clock = 0.18f * SimConfig.DayLengthSeconds;
        }

        public void Bind(Light sun, Camera cam)
        {
            Sun = sun;
            Cam = cam;
        }

        void Update()
        {
            _clock += Time.deltaTime;
            if (_clock > SimConfig.DayLengthSeconds) _clock -= SimConfig.DayLengthSeconds;
            Day01 = _clock / SimConfig.DayLengthSeconds;
            Apply();
        }

        void Apply()
        {
            float elev = Mathf.Lerp(-15f, 72f, Mathf.Sin(Day01 * Mathf.PI * 2f) * 0.5f + 0.5f);
            float az = 40f + Day01 * 220f;
            if (Sun != null)
            {
                Sun.transform.rotation = Quaternion.Euler(Mathf.Max(8f, elev), az, 0f);
                Color dawn = new Color(1f, 0.55f, 0.32f);
                Color dusk = new Color(1f, 0.42f, 0.22f);
                Color noon = new Color(1f, 0.96f, 0.88f);
                Color night = new Color(0.35f, 0.45f, 0.85f);
                Color sunC;
                float t = Day01;
                if (t < 0.2f) sunC = Color.Lerp(dawn, noon, t / 0.2f);
                else if (t < 0.45f) sunC = noon;
                else if (t < 0.58f) sunC = Color.Lerp(noon, dusk, (t - 0.45f) / 0.13f);
                else sunC = Color.Lerp(dusk, night, Mathf.Clamp01((t - 0.58f) / 0.15f));

                if (Game.Align != null && Game.Align.HasChosen)
                    sunC = Color.Lerp(sunC, Palette.Alignment(Game.Align.Primary), 0.12f + Game.Align.TierOf(Game.Align.Primary) * 0.04f);

                float uSun = CozySystem.I != null ? CozySystem.I.Normalized : 0.25f;
                sunC = Color.Lerp(sunC, new Color(1f, 0.72f, 0.42f), uSun * 0.22f);
                if (CozySystem.I != null && CozySystem.I.HearthCount > 0)
                    sunC = Color.Lerp(sunC, new Color(1f, 0.55f, 0.22f), 0.08f);
                Sun.color = sunC;
                Sun.intensity = Mathf.Lerp(0.09f, 1.15f, 1f - NightFactor);
                if (IsNight)
                {
                    float nightLit = Mathf.Lerp(0.05f, 0.26f, uSun);
                    if (CozySystem.I != null) nightLit += CozySystem.I.LanternCount * 0.03f;
                    Sun.intensity = nightLit;
                }
            }

            Color skyDay = new Color(0.48f, 0.68f, 0.88f);
            Color skyDusk = new Color(0.72f, 0.38f, 0.32f);
            Color skyNight = new Color(0.035f, 0.04f, 0.08f);
            Color sky;
            if (Day01 < 0.45f) sky = skyDay;
            else if (Day01 < 0.58f) sky = Color.Lerp(skyDay, skyDusk, (Day01 - 0.45f) / 0.13f);
            else if (Day01 < 0.7f) sky = Color.Lerp(skyDusk, skyNight, (Day01 - 0.58f) / 0.12f);
            else sky = skyNight;

            if (Game.Weather != null && Game.Weather.IsRaining)
                sky = Color.Lerp(sky, new Color(0.28f, 0.32f, 0.36f), Game.Weather.Intensity * 0.65f);

            float ujut = CozySystem.I != null ? CozySystem.I.Normalized : 0.25f;
            sky = Color.Lerp(sky, new Color(0.72f, 0.52f, 0.32f), ujut * 0.18f);
            if (ujut < 0.3f && NightFactor > 0.5f)
                sky = Color.Lerp(sky, new Color(0.02f, 0.02f, 0.06f), (0.3f - ujut) * 0.7f);

            if (Cam != null)
            {
                Cam.clearFlags = CameraClearFlags.SolidColor;
                Cam.backgroundColor = sky;
            }

            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
            Color ambDay = new Color(0.55f, 0.6f, 0.58f);
            Color ambNight = new Color(0.05f, 0.06f, 0.12f);
            Color amb = Color.Lerp(ambDay, ambNight, NightFactor);
            if (Game.Align != null)
                amb = Color.Lerp(amb, Game.Align.MoodTint(), 0.18f);
            float uAmb = CozySystem.I != null ? CozySystem.I.Normalized : 0.25f;
            Color cozyAmb = new Color(0.28f, 0.16f, 0.08f);
            amb = Color.Lerp(amb, cozyAmb, uAmb * 0.35f * NightFactor);
            amb = Color.Lerp(amb, new Color(0.04f, 0.04f, 0.07f), (1f - uAmb) * NightFactor * 0.35f);
            if (CozySystem.I != null) amb += new Color(0.04f, 0.025f, 0.01f) * CozySystem.I.LanternCount * NightFactor;
            RenderSettings.ambientLight = amb;
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogColor = Color.Lerp(sky, amb, 0.4f);
            RenderSettings.fogDensity = Mathf.Lerp(0.012f, 0.035f, NightFactor);
            RenderSettings.fogDensity *= Mathf.Lerp(1.15f, 0.72f, uAmb);
            if (Game.Weather != null && Game.Weather.IsRaining)
                RenderSettings.fogDensity += Game.Weather.Intensity * 0.018f;
        }
    }
}
