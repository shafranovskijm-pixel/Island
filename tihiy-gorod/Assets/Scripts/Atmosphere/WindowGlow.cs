using UnityEngine;

namespace TihiyGorod
{
    public sealed class WindowGlow : MonoBehaviour
    {
        public Material Lit;
        Renderer _r;
        Color _on;
        static readonly Color Off = new Color(0.18f, 0.16f, 0.14f);

        void Awake()
        {
            _r = GetComponent<Renderer>();
            if (Lit == null && _r != null) Lit = _r.material;
            if (Lit != null) _on = Lit.HasProperty("_EmissionColor") ? Lit.GetColor("_EmissionColor") : Lit.color;
        }

        void LateUpdate()
        {
            var day = DayNightCycle.I;
            if (day == null || _r == null) return;
            float night = day.NightFactor;
            float u = CozySystem.I != null ? CozySystem.I.Normalized : 0.3f;
            float rain = Game.Weather != null && Game.Weather.IsRaining ? Game.Weather.Intensity : 0f;
            float glow = 0.25f + night * 0.75f;
            glow += u * 0.28f;
            if (rain > 0.1f) glow += 0.22f + u * 0.35f;
            if (CozySystem.I != null) glow += CozySystem.I.CurtainCount * 0.06f;
            glow = Mathf.Clamp01(glow);
            var m = _r.material;
            Color c = Color.Lerp(Off, Lit != null ? Lit.color : Color.yellow, glow);
            m.color = c;
            if (m.HasProperty("_EmissionColor"))
            {
                if (glow > 0.15f) m.EnableKeyword("_EMISSION");
                m.SetColor("_EmissionColor", Color.Lerp(Color.black, _on, glow));
            }
        }
    }
}
