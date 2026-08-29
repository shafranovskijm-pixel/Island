using UnityEngine;

namespace TihiyGorod
{
    public sealed class ResourceSystem : MonoBehaviour
    {
        public static ResourceSystem I { get; private set; }

        readonly float[] _amt = new float[ResourceNames.Count];
        public event System.Action Changed;

        void Awake()
        {
            I = this;
        }

        public void GrantStart()
        {
            _amt[(int)ResourceType.Wood] = 90f;
            _amt[(int)ResourceType.Stone] = 90f;
            _amt[(int)ResourceType.Essence] = 48f;
            _amt[(int)ResourceType.Light] = 24f;
            _amt[(int)ResourceType.Shadow] = 24f;
            _amt[(int)ResourceType.Runes] = 24f;
            _amt[(int)ResourceType.FairyDust] = 24f;
            Ping();
        }

        public float Get(ResourceType t)
        {
            return _amt[(int)t];
        }

        public int GetInt(ResourceType t)
        {
            return Mathf.FloorToInt(_amt[(int)t]);
        }

        public void Add(ResourceType t, float v)
        {
            if (v == 0f) return;
            _amt[(int)t] = Mathf.Max(0f, _amt[(int)t] + v);
            Ping();
        }

        public void Add(ResourceCost c)
        {
            for (int i = 0; i < ResourceNames.Count; i++)
            {
                var t = (ResourceType)i;
                float v = c.Get(t);
                if (v != 0f) _amt[i] = Mathf.Max(0f, _amt[i] + v);
            }
            Ping();
        }

        public bool CanAfford(ResourceCost c)
        {
            for (int i = 0; i < ResourceNames.Count; i++)
            {
                if (_amt[i] + 0.001f < c.Get((ResourceType)i)) return false;
            }
            return true;
        }

        public bool TrySpend(ResourceCost c)
        {
            if (!CanAfford(c)) return false;
            for (int i = 0; i < ResourceNames.Count; i++)
                _amt[i] -= c.Get((ResourceType)i);
            Ping();
            return true;
        }

        void Ping()
        {
            if (Changed != null) Changed();
        }
    }
}
