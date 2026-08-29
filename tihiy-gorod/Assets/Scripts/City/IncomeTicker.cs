using UnityEngine;

namespace TihiyGorod
{
    public sealed class IncomeTicker : MonoBehaviour
    {
        float _acc;

        void Update()
        {
            _acc += Time.deltaTime;
            if (_acc < SimConfig.BuildingTickSeconds) return;
            _acc = 0f;
            if (CityGrid.I == null || ResourceSystem.I == null) return;
            var sum = new ResourceCost();
            CityGrid.I.ForEachBuilding(b =>
            {
                var inc = b.TickIncome(Game.Align, Game.Time, Game.Weather);
                sum.Wood += inc.Wood;
                sum.Stone += inc.Stone;
                sum.Essence += inc.Essence;
                sum.Light += inc.Light;
                sum.Shadow += inc.Shadow;
                sum.Runes += inc.Runes;
                sum.FairyDust += inc.FairyDust;
            });
            ResourceSystem.I.Add(sum);
            if (CozySystem.I != null) CozySystem.I.Tick();
        }
    }
}
