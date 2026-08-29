using UnityEngine;

namespace TihiyGorod
{
    public static class Palette
    {
        public static Color Alignment(AlignmentType t)
        {
            switch (t)
            {
                case AlignmentType.Good: return new Color(1f, 0.84f, 0.42f);
                case AlignmentType.Dark: return new Color(0.42f, 0.16f, 0.55f);
                case AlignmentType.Arcane: return new Color(0.32f, 0.62f, 0.95f);
                case AlignmentType.Fairy: return new Color(0.95f, 0.42f, 0.78f);
                default: return new Color(0.7f, 0.7f, 0.68f);
            }
        }

        public static Color AlignmentSoft(AlignmentType t)
        {
            return Color.Lerp(Alignment(t), Color.white, 0.35f);
        }

        public static Color Resource(ResourceType t)
        {
            switch (t)
            {
                case ResourceType.Wood: return new Color(0.55f, 0.38f, 0.18f);
                case ResourceType.Stone: return new Color(0.55f, 0.58f, 0.6f);
                case ResourceType.Essence: return new Color(0.55f, 0.85f, 0.95f);
                case ResourceType.Light: return new Color(1f, 0.92f, 0.55f);
                case ResourceType.Shadow: return new Color(0.28f, 0.18f, 0.4f);
                case ResourceType.Runes: return new Color(0.4f, 0.55f, 1f);
                case ResourceType.FairyDust: return new Color(1f, 0.55f, 0.85f);
                default: return Color.white;
            }
        }

        public static Color TileA = new Color(0.45f, 0.62f, 0.38f);
        public static Color TileB = new Color(0.40f, 0.56f, 0.34f);
        public static Color Dirt = new Color(0.32f, 0.24f, 0.16f);
        public static Color WetMul = new Color(0.72f, 0.78f, 0.82f);

        public static Color WoodBg = new Color(0.28f, 0.16f, 0.08f, 0.86f);
        public static Color WoodDeep = new Color(0.18f, 0.1f, 0.05f, 0.92f);
        public static Color Amber = new Color(0.82f, 0.5f, 0.18f, 1f);
        public static Color Paper = new Color(0.96f, 0.9f, 0.74f, 1f);
        public static Color Ink = new Color(0.22f, 0.12f, 0.06f, 1f);
        public static Color Hearth = new Color(0.95f, 0.45f, 0.12f, 1f);
    }
}
