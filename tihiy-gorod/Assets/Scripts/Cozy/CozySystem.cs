using System.Collections.Generic;
using UnityEngine;

namespace TihiyGorod
{
    public sealed class CozySystem : MonoBehaviour
    {
        public static CozySystem I { get; private set; }

        public float Value { get; private set; }
        public float Normalized { get { return Mathf.Clamp01(Value / 100f); } }

        readonly List<CozyObject> _all = new List<CozyObject>();
        CozyObject[,] _standalone;
        CozyObject[,] _addon;
        Transform _root;
        readonly bool[] _unlocked = new bool[10];

        public event System.Action Changed;

        public int Count { get { return _all.Count; } }
        public int HearthCount { get; private set; }
        public int LanternCount { get; private set; }
        public int CurtainCount { get; private set; }
        public int MusicBoxCount { get; private set; }
        public int BenchCount { get; private set; }
        public int SamovarCount { get; private set; }

        void Awake()
        {
            I = this;
            int n = SimConfig.GridSize;
            _standalone = new CozyObject[n, n];
            _addon = new CozyObject[n, n];
            Value = 8f;
        }

        public void Build(Transform world)
        {
            _root = new GameObject("Cozy").transform;
            _root.SetParent(world, false);
        }

        public void ApplyEveningUnlocks(EveningId evening)
        {
            for (int i = 0; i < _unlocked.Length; i++) _unlocked[i] = false;
            Unlock(CozyId.Hearth);
            Unlock(CozyId.PlaidBench);
            Unlock(CozyId.Geranium);
            if (evening >= EveningId.Two)
            {
                Unlock(CozyId.Samovar);
                Unlock(CozyId.Lantern);
                Unlock(CozyId.Bookshelf);
            }
            if (evening >= EveningId.Three)
            {
                Unlock(CozyId.Curtain);
                Unlock(CozyId.MusicBox);
                Unlock(CozyId.SleepingCat);
            }
            int mask = PlayerPrefs.GetInt("tg.cozyUnlock", 0);
            for (int i = 1; i <= 9; i++)
                if ((mask & (1 << i)) != 0) _unlocked[i] = true;
        }

        public bool IsUnlocked(CozyId id)
        {
            int i = (int)id;
            if (i < 0 || i >= _unlocked.Length) return false;
            return _unlocked[i];
        }

        public void Unlock(CozyId id)
        {
            int i = (int)id;
            if (i <= 0 || i >= _unlocked.Length) return;
            _unlocked[i] = true;
            int mask = PlayerPrefs.GetInt("tg.cozyUnlock", 0);
            mask |= 1 << i;
            PlayerPrefs.SetInt("tg.cozyUnlock", mask);
            PlayerPrefs.Save();
            if (Changed != null) Changed();
        }

        public bool BlocksCell(int x, int y)
        {
            if (!In(x, y)) return false;
            return _standalone[x, y] != null;
        }

        public CozyObject AtStandalone(int x, int y)
        {
            if (!In(x, y)) return null;
            return _standalone[x, y];
        }

        public CozyObject AddonAt(int x, int y)
        {
            if (!In(x, y)) return null;
            return _addon[x, y];
        }

        public bool TryPlace(CozyId id, int x, int y)
        {
            var def = CozyCatalog.Get(id);
            if (def == null || CityGrid.I == null || !CityGrid.I.InBounds(x, y)) return false;
            if (!IsUnlocked(id)) return false;
            var building = CityGrid.I.At(x, y);

            if (def.AddonOnly)
            {
                if (building == null) return false;
                if (_addon[x, y] != null) return false;
            }
            else if (def.StandaloneOnly)
            {
                if (building != null) return false;
                if (_standalone[x, y] != null) return false;
            }
            else
            {
                if (building != null)
                {
                    if (_addon[x, y] != null) return false;
                }
                else if (_standalone[x, y] != null) return false;
            }

            if (ResourceSystem.I != null && !ResourceSystem.I.TrySpend(def.Cost)) return false;

            Vector3 world = CityGrid.I.CellCenter(x, y);
            Building host = null;
            if (building != null)
            {
                host = building;
                world += new Vector3(0.42f, 0f, 0.38f);
            }
            var obj = CozyObject.Spawn(def, x, y, _root, world, host);
            if (host != null) _addon[x, y] = obj;
            else _standalone[x, y] = obj;
            _all.Add(obj);
            Recount();
            AddInstant(Mathf.Min(6f, def.UjutPerTick * 1.5f));
            if (Game.Audio != null) Game.Audio.PlayPlace();
            if (Changed != null) Changed();
            if (EveningSystem.I != null) EveningSystem.I.NotifyCozyPlaced();
            return true;
        }

        public void AddInstant(float v)
        {
            Value = Mathf.Clamp(Value + v, 0f, 100f);
            if (Changed != null) Changed();
        }

        public void Tick()
        {
            float add = 0f;
            bool night = Game.Time != null && Game.Time.IsNight;
            bool rain = Game.Weather != null && Game.Weather.IsRaining;
            for (int i = 0; i < _all.Count; i++)
            {
                var o = _all[i];
                if (o == null || o.Def == null) continue;
                float u = o.Def.UjutPerTick;
                if (o.Def.Id == CozyId.Hearth && night) u *= 1.25f;
                if (o.Def.Id == CozyId.Lantern && night) u *= 1.35f;
                if (o.Def.Id == CozyId.Curtain && rain) u *= 1.3f;
                add += u;
            }
            float decay = 0.48f;
            Value = Mathf.Clamp(Value + add - decay, 0f, 100f);
            if (Changed != null) Changed();
        }

        public CozyObject Nearest(CozyId id, Vector3 pos)
        {
            CozyObject best = null;
            float d = 1e9f;
            for (int i = 0; i < _all.Count; i++)
            {
                var o = _all[i];
                if (o == null || o.Def == null || o.Def.Id != id) continue;
                float dd = (o.transform.position - pos).sqrMagnitude;
                if (dd < d) { d = dd; best = o; }
            }
            return best;
        }

        public CozyObject NearestSit(Vector3 pos)
        {
            CozyObject a = Nearest(CozyId.PlaidBench, pos);
            CozyObject b = Nearest(CozyId.SleepingCat, pos);
            if (a == null) return b;
            if (b == null) return a;
            return (a.transform.position - pos).sqrMagnitude <= (b.transform.position - pos).sqrMagnitude ? a : b;
        }

        void Recount()
        {
            HearthCount = LanternCount = CurtainCount = MusicBoxCount = BenchCount = SamovarCount = 0;
            for (int i = 0; i < _all.Count; i++)
            {
                var o = _all[i];
                if (o == null || o.Def == null) continue;
                switch (o.Def.Id)
                {
                    case CozyId.Hearth: HearthCount++; break;
                    case CozyId.Lantern: LanternCount++; break;
                    case CozyId.Curtain: CurtainCount++; break;
                    case CozyId.MusicBox: MusicBoxCount++; break;
                    case CozyId.PlaidBench: BenchCount++; break;
                    case CozyId.Samovar: SamovarCount++; break;
                }
            }
        }

        static bool In(int x, int y)
        {
            return x >= 0 && y >= 0 && x < SimConfig.GridSize && y < SimConfig.GridSize;
        }
    }
}
