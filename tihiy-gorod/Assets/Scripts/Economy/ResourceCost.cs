using System.Text;

namespace TihiyGorod
{
    public struct ResourceCost
    {
        public float Wood, Stone, Essence, Light, Shadow, Runes, FairyDust;

        public float Get(ResourceType t)
        {
            switch (t)
            {
                case ResourceType.Wood: return Wood;
                case ResourceType.Stone: return Stone;
                case ResourceType.Essence: return Essence;
                case ResourceType.Light: return Light;
                case ResourceType.Shadow: return Shadow;
                case ResourceType.Runes: return Runes;
                case ResourceType.FairyDust: return FairyDust;
                default: return 0f;
            }
        }

        public ResourceCost Set(ResourceType t, float v)
        {
            switch (t)
            {
                case ResourceType.Wood: Wood = v; break;
                case ResourceType.Stone: Stone = v; break;
                case ResourceType.Essence: Essence = v; break;
                case ResourceType.Light: Light = v; break;
                case ResourceType.Shadow: Shadow = v; break;
                case ResourceType.Runes: Runes = v; break;
                case ResourceType.FairyDust: FairyDust = v; break;
            }
            return this;
        }

        public ResourceCost Plus(ResourceType t, float v)
        {
            return Set(t, Get(t) + v);
        }

        public static ResourceCost Of(ResourceType t, float v)
        {
            return new ResourceCost().Set(t, v);
        }

        public string RuLine()
        {
            var sb = new StringBuilder();
            Append(sb, ResourceType.Wood, Wood);
            Append(sb, ResourceType.Stone, Stone);
            Append(sb, ResourceType.Essence, Essence);
            Append(sb, ResourceType.Light, Light);
            Append(sb, ResourceType.Shadow, Shadow);
            Append(sb, ResourceType.Runes, Runes);
            Append(sb, ResourceType.FairyDust, FairyDust);
            return sb.Length == 0 ? "бесплатно" : sb.ToString();
        }

        static void Append(StringBuilder sb, ResourceType t, float v)
        {
            if (v <= 0.01f) return;
            if (sb.Length > 0) sb.Append("  ");
            sb.Append(ResourceNames.Ru(t));
            sb.Append(' ');
            sb.Append((int)v);
        }
    }
}
