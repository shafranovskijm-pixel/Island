namespace TihiyGorod
{
    public sealed class BuildingDef
    {
        public BuildingId Id;
        public string RuName;
        public string RuDesc;
        public AlignmentType Alignment;
        public ResourceCost Cost;
        public ResourceCost IncomePerTick;
        public ResourceType PrimaryResource;

        public BuildingDef(BuildingId id, string name, string desc, AlignmentType al,
            ResourceCost cost, ResourceCost income, ResourceType primary)
        {
            Id = id;
            RuName = name;
            RuDesc = desc;
            Alignment = al;
            Cost = cost;
            IncomePerTick = income;
            PrimaryResource = primary;
        }
    }
}
