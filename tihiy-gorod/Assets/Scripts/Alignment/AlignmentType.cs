namespace TihiyGorod
{
    public enum AlignmentType
    {
        None = 0,
        Good = 1,
        Dark = 2,
        Arcane = 3,
        Fairy = 4
    }

    public static class AlignmentNames
    {
        public static string Ru(AlignmentType t)
        {
            switch (t)
            {
                case AlignmentType.Good: return "Добро";
                case AlignmentType.Dark: return "Тьма";
                case AlignmentType.Arcane: return "Магия";
                case AlignmentType.Fairy: return "Сказка";
                default: return "—";
            }
        }

        public static string RuShort(AlignmentType t)
        {
            switch (t)
            {
                case AlignmentType.Good: return "Добро";
                case AlignmentType.Dark: return "Тьма";
                case AlignmentType.Arcane: return "Магия";
                case AlignmentType.Fairy: return "Сказка";
                default: return "";
            }
        }

        public static string Hint(AlignmentType t)
        {
            switch (t)
            {
                case AlignmentType.Good: return "Тёплый свет, исцеление и цветение.";
                case AlignmentType.Dark: return "Жёсткий контраст, порча, сила ночи.";
                case AlignmentType.Arcane: return "Холодное сияние, рост сущности.";
                case AlignmentType.Fairy: return "Яркий цвет, удача и дикий рост.";
                default: return "";
            }
        }

        public static ResourceType UniqueResource(AlignmentType t)
        {
            switch (t)
            {
                case AlignmentType.Good: return ResourceType.Light;
                case AlignmentType.Dark: return ResourceType.Shadow;
                case AlignmentType.Arcane: return ResourceType.Runes;
                case AlignmentType.Fairy: return ResourceType.FairyDust;
                default: return ResourceType.Essence;
            }
        }

        public static AlignmentType[] Playable
        {
            get
            {
                return new[]
                {
                    AlignmentType.Good,
                    AlignmentType.Dark,
                    AlignmentType.Arcane,
                    AlignmentType.Fairy
                };
            }
        }
    }
}
