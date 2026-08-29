using System.Collections.Generic;
using UnityEngine;

namespace TihiyGorod
{
    public sealed class UnitManager : MonoBehaviour
    {
        public static UnitManager I { get; private set; }
        readonly List<CityUnit> _units = new List<CityUnit>();
        Transform _root;

        void Awake()
        {
            I = this;
        }

        public void SpawnInitial(Transform world)
        {
            _root = new GameObject("Units").transform;
            _root.SetParent(world, false);
            int n = SimConfig.UnitCount;
            for (int i = 0; i < n; i++)
            {
                UnitKind kind;
                if (i < 7) kind = UnitKind.Villager;
                else if (i < 10) kind = UnitKind.Spirit;
                else kind = UnitKind.Wisp;

                var go = new GameObject("Unit_" + kind + "_" + i);
                go.transform.SetParent(_root, false);
                var u = go.AddComponent<CityUnit>();
                Vector3 pos;
                if (CityGrid.I != null)
                {
                    int x = Random.Range(1, CityGrid.I.Size - 1);
                    int y = Random.Range(1, CityGrid.I.Size - 1);
                    pos = CityGrid.I.CellCenter(x, y);
                }
                else pos = new Vector3(i, 0f, 0f);
                u.Setup(kind, pos);
                _units.Add(u);
            }
            Retint();
            if (Game.Align != null) Game.Align.Changed += Retint;
        }

        public void Retint()
        {
            var align = Game.Align;
            for (int i = 0; i < _units.Count; i++)
            {
                AlignmentType t = AlignmentType.None;
                if (align != null && align.HasChosen)
                {
                    float r = (i * 0.37f + 0.13f) % 1f;
                    if (r < 0.55f) t = align.Primary;
                    else if (r < 0.72f) t = AlignmentType.Good;
                    else if (r < 0.84f) t = AlignmentType.Dark;
                    else if (r < 0.93f) t = AlignmentType.Arcane;
                    else t = AlignmentType.Fairy;
                }
                _units[i].ApplyAlignmentTint(t);
            }
        }

        public int Count { get { return _units.Count; } }

        public CityUnit SpawnCat(Vector3 pos)
        {
            if (_root == null)
            {
                _root = new GameObject("Units").transform;
                if (CityGrid.I != null) _root.SetParent(CityGrid.I.BuildingRoot.parent, false);
            }
            var go = new GameObject("Unit_Cat_" + _units.Count);
            go.transform.SetParent(_root, false);
            var u = go.AddComponent<CityUnit>();
            u.Setup(UnitKind.Cat, pos);
            _units.Add(u);
            return u;
        }
    }
}
