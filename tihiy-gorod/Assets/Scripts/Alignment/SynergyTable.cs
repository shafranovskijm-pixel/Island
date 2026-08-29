using UnityEngine;

namespace TihiyGorod
{
    public static class SynergyTable
    {
        public static SynergyKind Between(AlignmentType a, AlignmentType b)
        {
            if (a == AlignmentType.None || b == AlignmentType.None || a == b)
                return SynergyKind.None;

            if (a > b)
            {
                var tmp = a;
                a = b;
                b = tmp;
            }

            if (a == AlignmentType.Good && b == AlignmentType.Fairy) return SynergyKind.Bloom;
            if (a == AlignmentType.Dark && b == AlignmentType.Arcane) return SynergyKind.Blight;
            if (a == AlignmentType.Good && b == AlignmentType.Dark) return SynergyKind.Conflict;
            if (a == AlignmentType.Good && b == AlignmentType.Arcane) return SynergyKind.Enchant;
            if (a == AlignmentType.Dark && b == AlignmentType.Fairy) return SynergyKind.WildShadow;
            if (a == AlignmentType.Arcane && b == AlignmentType.Fairy) return SynergyKind.Dreamweave;
            return SynergyKind.None;
        }

        public static float YieldMultiplier(SynergyKind kind)
        {
            switch (kind)
            {
                case SynergyKind.Bloom: return 1.28f;
                case SynergyKind.Blight: return 1.22f;
                case SynergyKind.Conflict: return 0.72f;
                case SynergyKind.Enchant: return 1.18f;
                case SynergyKind.WildShadow: return 0.88f;
                case SynergyKind.Dreamweave: return 1.24f;
                default: return 1f;
            }
        }

        public static Color Aura(SynergyKind kind)
        {
            switch (kind)
            {
                case SynergyKind.Bloom: return new Color(1f, 0.82f, 0.35f, 0.85f);
                case SynergyKind.Blight: return new Color(0.35f, 0.85f, 0.28f, 0.8f);
                case SynergyKind.Conflict: return new Color(0.95f, 0.2f, 0.15f, 0.9f);
                case SynergyKind.Enchant: return new Color(0.45f, 0.7f, 1f, 0.85f);
                case SynergyKind.WildShadow: return new Color(0.55f, 0.15f, 0.7f, 0.85f);
                case SynergyKind.Dreamweave: return new Color(0.95f, 0.45f, 0.95f, 0.85f);
                default: return Color.clear;
            }
        }
    }
}
