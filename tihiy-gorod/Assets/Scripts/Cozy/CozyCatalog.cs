namespace TihiyGorod
{
    public enum CozyId
    {
        None = 0,
        Hearth = 1,
        Samovar = 2,
        PlaidBench = 3,
        Lantern = 4,
        Curtain = 5,
        Bookshelf = 6,
        Geranium = 7,
        MusicBox = 8,
        SleepingCat = 9
    }

    public sealed class CozyDef
    {
        public CozyId Id;
        public string RuName;
        public string RuDesc;
        public ResourceCost Cost;
        public float UjutPerTick;
        public bool AddonOnly;
        public bool StandaloneOnly;
        public AlignmentType Flavor;

        public CozyDef(CozyId id, string name, string desc, ResourceCost cost, float ujut,
            bool addonOnly, bool standaloneOnly, AlignmentType flavor)
        {
            Id = id;
            RuName = name;
            RuDesc = desc;
            Cost = cost;
            UjutPerTick = ujut;
            AddonOnly = addonOnly;
            StandaloneOnly = standaloneOnly;
            Flavor = flavor;
        }
    }

    public static class CozyCatalog
    {
        static CozyDef[] _all;

        public static CozyDef[] All
        {
            get
            {
                if (_all == null) _all = Build();
                return _all;
            }
        }

        public static CozyDef Get(CozyId id)
        {
            var all = All;
            for (int i = 0; i < all.Length; i++)
                if (all[i].Id == id) return all[i];
            return null;
        }

        static CozyDef[] Build()
        {
            return new[]
            {
                new CozyDef(CozyId.Hearth, "Очаг",
                    "Камин. Сильнее всех греет уют и подложку музыки.",
                    ResourceCost.Of(ResourceType.Wood, 10).Plus(ResourceType.Stone, 6),
                    3.6f, false, false, AlignmentType.Good),

                new CozyDef(CozyId.Samovar, "Самовар",
                    "Чай. Жители останавливаются выпить.",
                    ResourceCost.Of(ResourceType.Wood, 8).Plus(ResourceType.Essence, 4),
                    1.8f, false, false, AlignmentType.Good),

                new CozyDef(CozyId.PlaidBench, "Плед на лавке",
                    "Сесть и замереть. Жители и кот любят это место.",
                    ResourceCost.Of(ResourceType.Wood, 6),
                    1.45f, false, false, AlignmentType.Good),

                new CozyDef(CozyId.Lantern, "Фонарь",
                    "Ночь мягче. Тёплый кружок света.",
                    ResourceCost.Of(ResourceType.Wood, 5).Plus(ResourceType.Light, 4),
                    1.25f, false, false, AlignmentType.Good),

                new CozyDef(CozyId.Curtain, "Занавеска",
                    "На окно дома. Свечение и уют, в дождь — как внутри.",
                    ResourceCost.Of(ResourceType.Wood, 4).Plus(ResourceType.Light, 3),
                    1.05f, true, false, AlignmentType.Good),

                new CozyDef(CozyId.Bookshelf, "Книжная полка",
                    "Тихие корешки. Уют без спешки.",
                    ResourceCost.Of(ResourceType.Wood, 8),
                    1.15f, false, false, AlignmentType.Arcane),

                new CozyDef(CozyId.Geranium, "Горшок с геранью",
                    "Красные шапки на подоконнике.",
                    ResourceCost.Of(ResourceType.Wood, 4),
                    0.95f, false, false, AlignmentType.Fairy),

                new CozyDef(CozyId.MusicBox, "Музыкальная шкатулка",
                    "Тихий высокий мотив поверх музыки города.",
                    ResourceCost.Of(ResourceType.Wood, 8).Plus(ResourceType.FairyDust, 6),
                    1.35f, false, false, AlignmentType.Fairy),

                new CozyDef(CozyId.SleepingCat, "Спящий кот",
                    "Крошечный житель. Спит на лавках, ореол уюта.",
                    ResourceCost.Of(ResourceType.Wood, 8).Plus(ResourceType.FairyDust, 8),
                    1.7f, false, true, AlignmentType.Fairy)
            };
        }
    }
}
