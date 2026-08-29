using UnityEngine;

namespace TihiyGorod
{
    public sealed class AlignmentSystem : MonoBehaviour
    {
        public AlignmentType Primary { get; private set; }
        public bool HasChosen { get; private set; }

        readonly int[] _tier = new int[5];
        readonly float[] _influence = new float[5];

        public event System.Action Changed;

        public int TierOf(AlignmentType t)
        {
            return _tier[(int)t];
        }

        public float Influence(AlignmentType t)
        {
            return _influence[(int)t];
        }

        public float PrimaryStrength
        {
            get { return HasChosen ? 0.55f + 0.15f * TierOf(Primary) : 0.25f; }
        }

        public void ChoosePrimary(AlignmentType t)
        {
            if (t == AlignmentType.None) return;
            Primary = t;
            HasChosen = true;
            if (_tier[(int)t] < 1) _tier[(int)t] = 1;
            RecalcInfluence();
            if (Changed != null) Changed();
        }

        public bool CanUpgrade(AlignmentType t)
        {
            if (t == AlignmentType.None) return false;
            int next = _tier[(int)t] + 1;
            if (next > SimConfig.MaxAlignmentTier) return false;
            return ResourceSystem.I != null && ResourceSystem.I.CanAfford(UpgradeCost(t, next));
        }

        public ResourceCost UpgradeCost(AlignmentType t, int nextTier)
        {
            var unique = AlignmentNames.UniqueResource(t);
            if (nextTier <= 1)
                return ResourceCost.Of(ResourceType.Essence, 8f).Plus(unique, 12f);
            if (nextTier == 2)
                return ResourceCost.Of(ResourceType.Essence, 22f).Plus(unique, 36f).Plus(ResourceType.Stone, 18f);
            return ResourceCost.Of(ResourceType.Essence, 48f)
                .Plus(unique, 70f)
                .Plus(ResourceType.Wood, 32f)
                .Plus(ResourceType.Stone, 32f);
        }

        public bool TryUpgrade(AlignmentType t)
        {
            if (t == AlignmentType.None) return false;
            int next = _tier[(int)t] + 1;
            if (next > SimConfig.MaxAlignmentTier) return false;
            var cost = UpgradeCost(t, next);
            if (!ResourceSystem.I.TrySpend(cost)) return false;
            _tier[(int)t] = next;
            if (!HasChosen) ChoosePrimary(t);
            RecalcInfluence();
            if (Changed != null) Changed();
            return true;
        }

        public float YieldBonus(AlignmentType t)
        {
            int tier = _tier[(int)t];
            float b = 0f;
            if (tier >= 1) b += 0.10f;
            if (tier >= 2) b += 0.15f;
            if (tier >= 3) b += 0.25f;
            if (HasChosen && t == Primary) b += 0.08f;
            return b;
        }

        public void RecalcInfluence()
        {
            for (int i = 0; i < 5; i++) _influence[i] = 0f;
            if (CityGrid.I == null) return;
            int total = 0;
            var counts = new int[5];
            CityGrid.I.ForEachBuilding(b =>
            {
                counts[(int)b.Def.Alignment]++;
                total++;
            });
            if (HasChosen) _influence[(int)Primary] += 2.5f + TierOf(Primary);
            if (total == 0)
            {
                Normalize();
                return;
            }
            for (int i = 1; i < 5; i++)
                _influence[i] += counts[i] + _tier[i] * 0.8f;
            Normalize();
        }

        void Normalize()
        {
            float s = 0f;
            for (int i = 1; i < 5; i++) s += _influence[i];
            if (s < 0.01f)
            {
                if (HasChosen) _influence[(int)Primary] = 1f;
                return;
            }
            for (int i = 1; i < 5; i++) _influence[i] /= s;
        }

        public Color MoodTint()
        {
            Color c = new Color(0.65f, 0.68f, 0.7f);
            float w = 0f;
            for (int i = 1; i < 5; i++)
            {
                float inf = _influence[i];
                if (inf <= 0f) continue;
                c += Palette.Alignment((AlignmentType)i) * inf;
                w += inf;
            }
            if (w > 0.01f) c /= (1f + w);
            return c;
        }
    }
}
