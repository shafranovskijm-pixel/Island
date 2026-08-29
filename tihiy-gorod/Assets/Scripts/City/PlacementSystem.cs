using UnityEngine;

namespace TihiyGorod
{
    public sealed class PlacementSystem : MonoBehaviour
    {
        public BuildingId Selected = BuildingId.None;
        public CozyId SelectedCozy = CozyId.None;
        public Building SelectedBuilding { get; private set; }
        public CozyObject SelectedCozyObject { get; private set; }
        public event System.Action SelectionChanged;

        public void SelectType(BuildingId id)
        {
            Selected = id;
            SelectedCozy = CozyId.None;
            SelectedBuilding = null;
            SelectedCozyObject = null;
            Ping();
        }

        public void SelectCozy(CozyId id)
        {
            SelectedCozy = id;
            Selected = BuildingId.None;
            SelectedBuilding = null;
            SelectedCozyObject = null;
            Ping();
        }

        public void ClearSelection()
        {
            Selected = BuildingId.None;
            SelectedCozy = CozyId.None;
            SelectedBuilding = null;
            SelectedCozyObject = null;
            Ping();
        }

        public void HandleTap(Vector3 world, Building hitBuilding, GridTile tile, CozyObject hitCozy = null)
        {
            if (hitCozy != null && SelectedCozy == CozyId.None)
            {
                SelectedCozyObject = hitCozy;
                SelectedBuilding = hitCozy.Host;
                Selected = BuildingId.None;
                Ping();
                if (Game.Hud != null && hitCozy.Def != null)
                    Game.Hud.SetHint(hitCozy.Def.RuName + " — " + hitCozy.Def.RuDesc);
                return;
            }
            if (hitBuilding != null)
            {
                if (SelectedCozy != CozyId.None)
                {
                    TryPlaceCozy(hitBuilding.X, hitBuilding.Y);
                    return;
                }
                SelectedBuilding = hitBuilding;
                Selected = BuildingId.None;
                SelectedCozy = CozyId.None;
                Ping();
                return;
            }

            int x, y;
            if (tile != null)
            {
                x = tile.X;
                y = tile.Y;
            }
            else if (!CityGrid.I.TryWorldToCell(world, out x, out y))
            {
                return;
            }

            var existing = CityGrid.I.At(x, y);
            if (SelectedCozy != CozyId.None)
            {
                TryPlaceCozy(x, y);
                return;
            }
            if (existing != null)
            {
                SelectedBuilding = existing;
                Selected = BuildingId.None;
                Ping();
                return;
            }

            if (Selected == BuildingId.None) return;
            TryPlace(x, y);
        }

        public bool TryPlace(int x, int y)
        {
            var def = BuildingCatalog.Get(Selected);
            if (def == null) return false;
            if (CityGrid.I.At(x, y) != null) return false;
            if (CozySystem.I != null && CozySystem.I.BlocksCell(x, y)) return false;
            if (!ResourceSystem.I.TrySpend(def.Cost)) return false;
            var b = CityGrid.I.Place(def, x, y);
            if (b == null) return false;
            SelectedBuilding = b;
            if (Game.Audio != null) Game.Audio.PlayPlace();
            Ping();
            return true;
        }

        public bool TryPlaceCozy(int x, int y)
        {
            if (SelectedCozy == CozyId.None || CozySystem.I == null) return false;
            bool ok = CozySystem.I.TryPlace(SelectedCozy, x, y);
            if (ok)
            {
                SelectedCozyObject = CozySystem.I.AtStandalone(x, y) ?? CozySystem.I.AddonAt(x, y);
                Ping();
            }
            else if (Game.Hud != null)
            {
                var def = CozyCatalog.Get(SelectedCozy);
                if (def != null && def.AddonOnly)
                    Game.Hud.SetHint("Занавеску вешают на дом — коснитесь здания.");
                else
                    Game.Hud.SetHint("Сюда не поставить. Нужны ресурсы или свободная клетка.");
            }
            return ok;
        }

        void Ping()
        {
            if (SelectionChanged != null) SelectionChanged();
        }
    }
}
