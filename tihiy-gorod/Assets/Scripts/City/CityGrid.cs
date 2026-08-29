using System.Collections.Generic;
using UnityEngine;

namespace TihiyGorod
{
    public sealed class CityGrid : MonoBehaviour
    {
        public static CityGrid I { get; private set; }

        public int Size { get { return SimConfig.GridSize; } }
        public float Cell { get { return SimConfig.CellSize; } }

        Building[,] _cells;
        public Transform GroundRoot { get; private set; }
        public Transform BuildingRoot { get; private set; }
        readonly List<Renderer> _tiles = new List<Renderer>();
        Color[] _tileBase;

        public int BuildingCount { get; private set; }

        void Awake()
        {
            I = this;
            _cells = new Building[Size, Size];
        }

        public void BuildGround(Transform world)
        {
            GroundRoot = new GameObject("Ground").transform;
            GroundRoot.SetParent(world, false);
            BuildingRoot = new GameObject("Buildings").transform;
            BuildingRoot.SetParent(world, false);

            var dirt = GameObject.CreatePrimitive(PrimitiveType.Cube);
            dirt.name = "Dirt";
            dirt.transform.SetParent(GroundRoot, false);
            float worldSize = Size * Cell;
            dirt.transform.localPosition = new Vector3(worldSize * 0.5f - Cell * 0.5f, -0.08f, worldSize * 0.5f - Cell * 0.5f);
            dirt.transform.localScale = new Vector3(worldSize + 1.6f, 0.12f, worldSize + 1.6f);
            dirt.GetComponent<Renderer>().sharedMaterial = MatLib.Color(Palette.Dirt, 0f, 0.12f);
            Object.Destroy(dirt.GetComponent<Collider>());

            _tileBase = new Color[Size * Size];
            for (int y = 0; y < Size; y++)
            {
                for (int x = 0; x < Size; x++)
                {
                    var tile = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    tile.name = "Tile_" + x + "_" + y;
                    tile.transform.SetParent(GroundRoot, false);
                    tile.transform.position = CellCenter(x, y) + new Vector3(0f, 0.01f, 0f);
                    tile.transform.localScale = new Vector3(Cell * 0.92f, 0.05f, Cell * 0.92f);
                    var col = ((x + y) & 1) == 0 ? Palette.TileA : Palette.TileB;
                    _tileBase[y * Size + x] = col;
                    tile.GetComponent<Renderer>().sharedMaterial = MatLib.Unique(col, 0f, 0.18f, false, 1f);
                    var box = tile.GetComponent<BoxCollider>();
                    box.size = new Vector3(1f, 4f, 1f);
                    box.center = new Vector3(0f, 0f, 0f);
                    var marker = tile.AddComponent<GridTile>();
                    marker.X = x;
                    marker.Y = y;
                    _tiles.Add(tile.GetComponent<Renderer>());
                }
            }

            var rim = MatLib.Color(new Color(0.25f, 0.32f, 0.22f), 0f, 0.1f);
            for (int i = 0; i < 4; i++)
            {
                var wall = GameObject.CreatePrimitive(PrimitiveType.Cube);
                wall.name = "Rim" + i;
                wall.transform.SetParent(GroundRoot, false);
                Object.Destroy(wall.GetComponent<Collider>());
                wall.GetComponent<Renderer>().sharedMaterial = rim;
                float mid = worldSize * 0.5f - Cell * 0.5f;
                if (i == 0) { wall.transform.position = new Vector3(mid, 0.12f, -0.7f); wall.transform.localScale = new Vector3(worldSize + 1.4f, 0.28f, 0.18f); }
                if (i == 1) { wall.transform.position = new Vector3(mid, 0.12f, worldSize - Cell * 0.5f + 0.7f); wall.transform.localScale = new Vector3(worldSize + 1.4f, 0.28f, 0.18f); }
                if (i == 2) { wall.transform.position = new Vector3(-0.7f, 0.12f, mid); wall.transform.localScale = new Vector3(0.18f, 0.28f, worldSize + 1.4f); }
                if (i == 3) { wall.transform.position = new Vector3(worldSize - Cell * 0.5f + 0.7f, 0.12f, mid); wall.transform.localScale = new Vector3(0.18f, 0.28f, worldSize + 1.4f); }
            }
        }

        public Vector3 CellCenter(int x, int y)
        {
            return new Vector3(x * Cell, 0f, y * Cell);
        }

        public Vector3 WorldCenter
        {
            get
            {
                float m = (Size - 1) * Cell * 0.5f;
                return new Vector3(m, 0f, m);
            }
        }

        public bool InBounds(int x, int y)
        {
            return x >= 0 && y >= 0 && x < Size && y < Size;
        }

        public Building At(int x, int y)
        {
            if (!InBounds(x, y)) return null;
            return _cells[x, y];
        }

        public bool TryWorldToCell(Vector3 world, out int x, out int y)
        {
            x = Mathf.RoundToInt(world.x / Cell);
            y = Mathf.RoundToInt(world.z / Cell);
            return InBounds(x, y);
        }

        public Building Place(BuildingDef def, int x, int y)
        {
            if (!InBounds(x, y) || _cells[x, y] != null || def == null) return null;
            var b = Building.Spawn(def, x, y, BuildingRoot, CellCenter(x, y));
            _cells[x, y] = b;
            BuildingCount++;
            RefreshSynergiesAround(x, y);
            if (Game.Align != null) Game.Align.RecalcInfluence();
            return b;
        }

        public void ForEachBuilding(System.Action<Building> fn)
        {
            for (int y = 0; y < Size; y++)
                for (int x = 0; x < Size; x++)
                    if (_cells[x, y] != null) fn(_cells[x, y]);
        }

        public Building RandomBuilding()
        {
            if (BuildingCount == 0) return null;
            int skip = Random.Range(0, BuildingCount);
            for (int y = 0; y < Size; y++)
                for (int x = 0; x < Size; x++)
                    if (_cells[x, y] != null && skip-- == 0) return _cells[x, y];
            return null;
        }

        public Building NearestBuilding(Vector3 pos)
        {
            Building best = null;
            float d = 1e9f;
            ForEachBuilding(b =>
            {
                float dd = (b.transform.position - pos).sqrMagnitude;
                if (dd < d) { d = dd; best = b; }
            });
            return best;
        }

        public void RefreshSynergiesAround(int x, int y)
        {
            RefreshCell(x, y);
            RefreshCell(x + 1, y);
            RefreshCell(x - 1, y);
            RefreshCell(x, y + 1);
            RefreshCell(x, y - 1);
        }

        void RefreshCell(int x, int y)
        {
            var b = At(x, y);
            if (b == null) return;
            SynergyKind mix = SynergyKind.None;
            Check(b, At(x + 1, y), ref mix);
            Check(b, At(x - 1, y), ref mix);
            Check(b, At(x, y + 1), ref mix);
            Check(b, At(x, y - 1), ref mix);
            b.SetNeighborMix(mix);
        }

        static void Check(Building self, Building other, ref SynergyKind mix)
        {
            if (other == null) return;
            var k = SynergyTable.Between(self.Def.Alignment, other.Def.Alignment);
            if (k == SynergyKind.None) return;
            if (mix == SynergyKind.None || SynergyNames.IsTension(k)) mix = k;
        }

        public void TintTiles(Color wetMul, float t)
        {
            for (int i = 0; i < _tiles.Count; i++)
            {
                if (_tiles[i] == null) continue;
                var baseC = _tileBase[i];
                _tiles[i].sharedMaterial.color = Color.Lerp(baseC, new Color(baseC.r * wetMul.r, baseC.g * wetMul.g, baseC.b * wetMul.b), t);
            }
        }
    }

    public sealed class GridTile : MonoBehaviour
    {
        public int X;
        public int Y;
    }
}
