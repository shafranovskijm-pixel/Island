namespace TihiyGorod
{
    public enum SynergyKind
    {
        None = 0,
        Bloom = 1,
        Blight = 2,
        Conflict = 3,
        Enchant = 4,
        WildShadow = 5,
        Dreamweave = 6
    }

    public static class SynergyNames
    {
        public static string Ru(SynergyKind k)
        {
            switch (k)
            {
                case SynergyKind.Bloom: return "Цветение";
                case SynergyKind.Blight: return "Порча";
                case SynergyKind.Conflict: return "Разлад";
                case SynergyKind.Enchant: return "Чары";
                case SynergyKind.WildShadow: return "Дикая тень";
                case SynergyKind.Dreamweave: return "Сновидение";
                default: return "";
            }
        }

        public static bool IsTension(SynergyKind k)
        {
            return k == SynergyKind.Conflict || k == SynergyKind.WildShadow;
        }
    }
}
