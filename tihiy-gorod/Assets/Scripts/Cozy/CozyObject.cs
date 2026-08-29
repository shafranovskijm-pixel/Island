using UnityEngine;

namespace TihiyGorod
{
    public sealed class CozyObject : MonoBehaviour
    {
        public CozyDef Def;
        public int X;
        public int Y;
        public bool IsAddon;
        public Building Host;

        Renderer _flicker;
        Light _lamp;
        float _phase;

        public Vector3 SitWorld
        {
            get { return transform.position + new Vector3(0.15f, 0f, 0.2f); }
        }

        public static CozyObject Spawn(CozyDef def, int x, int y, Transform parent, Vector3 world, Building host)
        {
            var go = new GameObject("C_" + def.RuName);
            go.transform.SetParent(parent, false);
            go.transform.position = world;
            var c = go.AddComponent<CozyObject>();
            c.Def = def;
            c.X = x;
            c.Y = y;
            c.Host = host;
            c.IsAddon = host != null;
            CozyVisuals.Build(c);

            var box = go.AddComponent<BoxCollider>();
            box.center = new Vector3(0f, 0.28f, 0f);
            box.size = new Vector3(0.72f, 0.7f, 0.72f);

            if (def.Id == CozyId.SleepingCat && UnitManager.I != null)
                UnitManager.I.SpawnCat(world);

            return c;
        }

        public void BindFlicker(Renderer r, Light lamp)
        {
            _flicker = r;
            _lamp = lamp;
        }

        void Update()
        {
            _phase += Time.deltaTime;
            if (_flicker == null && _lamp == null) return;
            float f = 0.82f + 0.18f * Mathf.PerlinNoise(12.1f, _phase * 3.4f);
            if (_flicker != null)
            {
                var m = _flicker.material;
                Color c = new Color(1f, 0.45f + 0.2f * f, 0.12f);
                m.color = c;
                if (m.HasProperty("_EmissionColor"))
                    m.SetColor("_EmissionColor", c * (1.4f * f));
            }
            if (_lamp != null)
                _lamp.intensity = (Def != null && Def.Id == CozyId.Hearth ? 1.35f : 0.7f) * f;
        }
    }
}
