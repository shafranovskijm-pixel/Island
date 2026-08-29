namespace TihiyGorod
{
    public enum ResourceType
    {
        Wood = 0,
        Stone = 1,
        Essence = 2,
        Light = 3,
        Shadow = 4,
        Runes = 5,
        FairyDust = 6
    }

    public static class ResourceNames
    {
        public const int Count = 7;

        public static string Ru(ResourceType t)
        {
            switch (t)
            {
                case ResourceType.Wood: return "Дерево";
                case ResourceType.Stone: return "Камень";
                case ResourceType.Essence: return "Сущность";
                case ResourceType.Light: return "Свет";
                case ResourceType.Shadow: return "Тень";
                case ResourceType.Runes: return "Руны";
                case ResourceType.FairyDust: return "Сказка";
                default: return "?";
            }
        }

        public static string Glyph(ResourceType t)
        {
            switch (t)
            {
                case ResourceType.Wood: return "дерево";
                case ResourceType.Stone: return "камень";
                case ResourceType.Essence: return "сущ.";
                case ResourceType.Light: return "свет";
                case ResourceType.Shadow: return "тень";
                case ResourceType.Runes: return "руны";
                case ResourceType.FairyDust: return "сказка";
                default: return "";
            }
        }

        public static ResourceType[] All
        {
            get
            {
                return new[]
                {
                    ResourceType.Wood,
                    ResourceType.Stone,
                    ResourceType.Essence,
                    ResourceType.Light,
                    ResourceType.Shadow,
                    ResourceType.Runes,
                    ResourceType.FairyDust
                };
            }
        }
    }
}
