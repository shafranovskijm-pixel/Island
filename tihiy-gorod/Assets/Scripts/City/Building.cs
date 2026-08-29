using UnityEngine;

namespace TihiyGorod
{
    public sealed class Building : MonoBehaviour
    {
        public BuildingDef Def;
        public int X;
        public int Y;
        public int Level = 1;
        public SynergyKind NeighborMix = SynergyKind.None;

        Transform _aura;
        Renderer _auraRend;
        float _pulse;

        public Vector3 DoorWorld
        {
            get { return transform.position + new Vector3(0.55f, 0f, 0.55f); }
        }

        public static Building Spawn(BuildingDef def, int x, int y, Transform parent, Vector3 world)
        {
            var go = new GameObject("B_" + def.RuName);
            go.transform.SetParent(parent, false);
            go.transform.position = world;
            var b = go.AddComponent<Building>();
            b.Def = def;
            b.X = x;
            b.Y = y;
            BuildingVisuals.Build(b);

            var box = go.AddComponent<BoxCollider>();
            box.center = new Vector3(0f, 0.55f, 0f);
            box.size = new Vector3(1.05f, 1.2f, 1.05f);

            b.MakeAura();
            b.ApplyLevelScale();
            return b;
        }

        void MakeAura()
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            go.name = "Aura";
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(0f, 0.03f, 0f);
            go.transform.localScale = new Vector3(1.25f, 0.02f, 1.25f);
            Object.Destroy(go.GetComponent<Collider>());
            _auraRend = go.GetComponent<Renderer>();
            _auraRend.sharedMaterial = MatLib.Unique(new Color(1f, 1f, 1f, 0.0f), 0f, 0.2f, true, 0.4f);
            _aura = go.transform;
        }

        public bool TryUpgrade()
        {
            if (Level >= SimConfig.MaxBuildingLevel) return false;
            var cost = UpgradeCost();
            if (!ResourceSystem.I.TrySpend(cost)) return false;
            Level++;
            ApplyLevelScale();
            return true;
        }

        public ResourceCost UpgradeCost()
        {
            float m = 1f + Level * 0.75f;
            var c = Def.Cost;
            return new ResourceCost
            {
                Wood = Mathf.Ceil(c.Wood * 0.55f * m),
                Stone = Mathf.Ceil(c.Stone * 0.55f * m),
                Essence = Mathf.Ceil(Mathf.Max(4f, c.Essence * 0.6f * m)),
                Light = Mathf.Ceil(c.Light * 0.5f * m),
                Shadow = Mathf.Ceil(c.Shadow * 0.5f * m),
                Runes = Mathf.Ceil(c.Runes * 0.5f * m),
                FairyDust = Mathf.Ceil(c.FairyDust * 0.5f * m)
            };
        }

        void ApplyLevelScale()
        {
            float s = 0.92f + (Level - 1) * 0.12f;
            transform.localScale = new Vector3(s, 0.88f + Level * 0.12f, s);
        }

        public ResourceCost TickIncome(AlignmentSystem align, DayNightCycle day, WeatherSystem weather)
        {
            var inc = Def.IncomePerTick;
            float mul = 1f + (Level - 1) * 0.35f;
            if (align != null) mul += align.YieldBonus(Def.Alignment);
            mul *= SynergyTable.YieldMultiplier(NeighborMix);

            if (day != null)
            {
                if (Def.Alignment == AlignmentType.Dark && day.IsNight) mul *= 1.35f;
                if (Def.Alignment == AlignmentType.Good && !day.IsNight) mul *= 1.18f;
                if (Def.Alignment == AlignmentType.Arcane && day.NightFactor > 0.4f) mul *= 1.12f;
            }
            if (weather != null && weather.IsRaining && Def.Alignment == AlignmentType.Fairy)
                mul *= 1.22f;

            return new ResourceCost
            {
                Wood = inc.Wood * mul,
                Stone = inc.Stone * mul,
                Essence = inc.Essence * mul,
                Light = inc.Light * mul,
                Shadow = inc.Shadow * mul,
                Runes = inc.Runes * mul,
                FairyDust = inc.FairyDust * mul
            };
        }

        public void SetNeighborMix(SynergyKind k)
        {
            NeighborMix = k;
        }

        void Update()
        {
            _pulse += Time.deltaTime;
            if (_auraRend == null) return;
            var col = SynergyTable.Aura(NeighborMix);
            if (NeighborMix == SynergyKind.None)
            {
                col = Palette.Alignment(Def.Alignment);
                col.a = 0.12f + Mathf.Sin(_pulse * 1.5f) * 0.04f;
            }
            else
            {
                col.a = 0.35f + Mathf.Sin(_pulse * (SynergyNames.IsTension(NeighborMix) ? 4f : 2f)) * 0.12f;
            }
            var m = _auraRend.material;
            m.color = Color.Lerp(m.color, new Color(col.r, col.g, col.b, col.a * 0.55f), Time.deltaTime * 4f);
            if (m.HasProperty("_EmissionColor"))
                m.SetColor("_EmissionColor", new Color(col.r, col.g, col.b) * col.a);
            if (_aura != null)
            {
                float w = 1.2f + (SynergyNames.IsTension(NeighborMix) ? 0.08f * Mathf.Sin(_pulse * 6f) : 0f);
                _aura.localScale = new Vector3(w, 0.02f, w);
            }
        }
    }
}
