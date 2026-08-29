using System.Collections.Generic;

namespace TihiyGorod
{
    public static class BuildingCatalog
    {
        static BuildingDef[] _all;

        public static BuildingDef[] All
        {
            get
            {
                if (_all == null) _all = Build();
                return _all;
            }
        }

        public static BuildingDef Get(BuildingId id)
        {
            var all = All;
            for (int i = 0; i < all.Length; i++)
                if (all[i].Id == id) return all[i];
            return null;
        }

        static BuildingDef[] Build()
        {
            var list = new List<BuildingDef>
            {
                new BuildingDef(
                    BuildingId.Sanctuary, "Святилище",
                    "Тёплый очаг. Даёт Свет и немного Дерева. Ночью окна светятся.",
                    AlignmentType.Good,
                    ResourceCost.Of(ResourceType.Wood, 18).Plus(ResourceType.Stone, 14).Plus(ResourceType.Light, 6),
                    ResourceCost.Of(ResourceType.Light, 1.6f).Plus(ResourceType.Wood, 0.45f),
                    ResourceType.Light),

                new BuildingDef(
                    BuildingId.Garden, "Цветущий сад",
                    "Грядки и цветы. Дерево и Свет. Рядом со Сказкой — цветение.",
                    AlignmentType.Good,
                    ResourceCost.Of(ResourceType.Wood, 12).Plus(ResourceType.Light, 4),
                    ResourceCost.Of(ResourceType.Wood, 1.4f).Plus(ResourceType.Light, 0.55f),
                    ResourceType.Wood),

                new BuildingDef(
                    BuildingId.Crypt, "Склеп",
                    "Холодный камень. Тень и Камень. Ночью доход растёт.",
                    AlignmentType.Dark,
                    ResourceCost.Of(ResourceType.Stone, 20).Plus(ResourceType.Shadow, 6),
                    ResourceCost.Of(ResourceType.Shadow, 1.5f).Plus(ResourceType.Stone, 0.5f),
                    ResourceType.Shadow),

                new BuildingDef(
                    BuildingId.ShadowTower, "Башня теней",
                    "Остриё тьмы. Тень и Сущность. Рядом с Магией — порча.",
                    AlignmentType.Dark,
                    ResourceCost.Of(ResourceType.Stone, 16).Plus(ResourceType.Wood, 10).Plus(ResourceType.Shadow, 8),
                    ResourceCost.Of(ResourceType.Shadow, 1.15f).Plus(ResourceType.Essence, 0.7f),
                    ResourceType.Shadow),

                new BuildingDef(
                    BuildingId.Observatory, "Обсерватория",
                    "Купол и линзы. Руны и Сущность.",
                    AlignmentType.Arcane,
                    ResourceCost.Of(ResourceType.Stone, 18).Plus(ResourceType.Essence, 10).Plus(ResourceType.Runes, 6),
                    ResourceCost.Of(ResourceType.Runes, 1.45f).Plus(ResourceType.Essence, 0.65f),
                    ResourceType.Runes),

                new BuildingDef(
                    BuildingId.Crystal, "Кристалл",
                    "Живой самоцвет. Сущность и Руны. Холодное сияние.",
                    AlignmentType.Arcane,
                    ResourceCost.Of(ResourceType.Essence, 14).Plus(ResourceType.Stone, 10).Plus(ResourceType.Runes, 5),
                    ResourceCost.Of(ResourceType.Essence, 1.5f).Plus(ResourceType.Runes, 0.5f),
                    ResourceType.Essence),

                new BuildingDef(
                    BuildingId.MushroomRing, "Грибной круг",
                    "Дикий рост. Сказка и Дерево. В дождь грибы жирнеют.",
                    AlignmentType.Fairy,
                    ResourceCost.Of(ResourceType.Wood, 14).Plus(ResourceType.FairyDust, 8),
                    ResourceCost.Of(ResourceType.FairyDust, 1.4f).Plus(ResourceType.Wood, 0.55f),
                    ResourceType.FairyDust),

                new BuildingDef(
                    BuildingId.FairyHouse, "Сказочный дом",
                    "Кривая крыша и удача. Сказка и Камень.",
                    AlignmentType.Fairy,
                    ResourceCost.Of(ResourceType.Wood, 12).Plus(ResourceType.Stone, 12).Plus(ResourceType.FairyDust, 6),
                    ResourceCost.Of(ResourceType.FairyDust, 1.2f).Plus(ResourceType.Stone, 0.55f),
                    ResourceType.FairyDust)
            };
            return list.ToArray();
        }
    }
}
