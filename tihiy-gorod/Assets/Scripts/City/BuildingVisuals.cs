using UnityEngine;

namespace TihiyGorod
{
    public static class BuildingVisuals
    {
        public static void Build(Building b)
        {
            var root = b.transform;
            switch (b.Def.Id)
            {
                case BuildingId.Sanctuary: Sanctuary(root); break;
                case BuildingId.Garden: Garden(root); break;
                case BuildingId.Crypt: Crypt(root); break;
                case BuildingId.ShadowTower: ShadowTower(root); break;
                case BuildingId.Observatory: Observatory(root); break;
                case BuildingId.Crystal: Crystal(root); break;
                case BuildingId.MushroomRing: Mushrooms(root); break;
                case BuildingId.FairyHouse: FairyHouse(root); break;
            }
        }

        static void Sanctuary(Transform r)
        {
            var stone = MatLib.Color(new Color(0.86f, 0.82f, 0.72f), 0.15f, 0.4f);
            var gold = MatLib.Color(new Color(0.95f, 0.78f, 0.28f), 0.55f, 0.7f, true, 1.3f);
            var roof = MatLib.Color(new Color(0.72f, 0.32f, 0.18f), 0.1f, 0.35f);
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.45f, 0f), new Vector3(0.72f, 0.45f, 0.72f), stone, "Nave");
            PrimitiveBuilder.Cone(r, new Vector3(0f, 1.05f, 0f), new Vector3(0.82f, 0.55f, 0.82f), roof, "Dome");
            PrimitiveBuilder.Sphere(r, new Vector3(0f, 1.42f, 0f), Vector3.one * 0.22f, gold, "Orb");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.55f, 0.38f), new Vector3(0.22f, 0.5f, 0.08f), gold, "Door");
            PrimitiveBuilder.Window(r, new Vector3(0.36f, 0.55f, 0f), new Vector3(0.06f, 0.22f, 0.12f), Quaternion.identity);
            PrimitiveBuilder.Window(r, new Vector3(-0.36f, 0.55f, 0f), new Vector3(0.06f, 0.22f, 0.12f), Quaternion.identity);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 1.62f, 0f), new Vector3(0.05f, 0.28f, 0.05f), gold, "Spire");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 1.72f, 0f), new Vector3(0.18f, 0.05f, 0.05f), gold, "CrossA");
        }

        static void Garden(Transform r)
        {
            var soil = MatLib.Color(new Color(0.36f, 0.24f, 0.12f), 0f, 0.15f);
            var hedge = MatLib.Color(new Color(0.28f, 0.55f, 0.22f), 0f, 0.25f);
            var flowerA = MatLib.Color(new Color(1f, 0.45f, 0.55f), 0f, 0.5f, true, 0.8f);
            var flowerB = MatLib.Color(new Color(1f, 0.85f, 0.3f), 0f, 0.5f, true, 0.8f);
            var path = MatLib.Color(new Color(0.72f, 0.68f, 0.48f), 0f, 0.2f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.04f, 0f), new Vector3(1.05f, 0.08f, 1.05f), soil, "Bed");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.06f, 0f), new Vector3(0.18f, 0.04f, 1.0f), path, "Path");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.18f, -0.42f), new Vector3(1.0f, 0.22f, 0.1f), hedge, "HedgeS");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.18f, 0.42f), new Vector3(1.0f, 0.22f, 0.1f), hedge, "HedgeN");
            PrimitiveBuilder.Sphere(r, new Vector3(-0.28f, 0.28f, -0.18f), Vector3.one * 0.22f, flowerA, "F1");
            PrimitiveBuilder.Sphere(r, new Vector3(0.3f, 0.26f, 0.2f), Vector3.one * 0.18f, flowerB, "F2");
            PrimitiveBuilder.Sphere(r, new Vector3(-0.32f, 0.24f, 0.28f), Vector3.one * 0.16f, flowerB, "F3");
            PrimitiveBuilder.Sphere(r, new Vector3(0.28f, 0.3f, -0.22f), Vector3.one * 0.2f, flowerA, "F4");
            PrimitiveBuilder.Cyl(r, new Vector3(0.02f, 0.22f, 0.02f), new Vector3(0.06f, 0.22f, 0.06f), MatLib.Color(new Color(0.4f, 0.25f, 0.1f)), "Stem");
            PrimitiveBuilder.Sphere(r, new Vector3(0.02f, 0.48f, 0.02f), Vector3.one * 0.28f, hedge, "Tree");
        }

        static void Crypt(Transform r)
        {
            var stone = MatLib.Color(new Color(0.28f, 0.27f, 0.3f), 0.2f, 0.15f);
            var dark = MatLib.Color(new Color(0.12f, 0.1f, 0.14f), 0.3f, 0.2f);
            var moss = MatLib.Color(new Color(0.22f, 0.32f, 0.16f), 0f, 0.1f);
            var purple = MatLib.Color(new Color(0.55f, 0.18f, 0.7f), 0.2f, 0.6f, true, 1.6f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.28f, 0f), new Vector3(1.05f, 0.55f, 0.8f), stone, "Body");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.58f, 0f), new Vector3(1.12f, 0.08f, 0.86f), dark, "Lid");
            PrimitiveBuilder.Cube(r, new Vector3(0.42f, 0.12f, 0.48f), new Vector3(0.22f, 0.1f, 0.22f), stone, "Step1");
            PrimitiveBuilder.Cube(r, new Vector3(0.28f, 0.2f, 0.48f), new Vector3(0.22f, 0.1f, 0.18f), stone, "Step2");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.32f, 0.42f), new Vector3(0.2f, 0.28f, 0.06f), dark, "Door");
            PrimitiveBuilder.Cube(r, new Vector3(-0.38f, 0.62f, 0.28f), new Vector3(0.18f, 0.35f, 0.18f), stone, "Stele");
            PrimitiveBuilder.Sphere(r, new Vector3(-0.38f, 0.86f, 0.28f), Vector3.one * 0.14f, purple, "Eye");
            PrimitiveBuilder.Cube(r, new Vector3(0.4f, 0.08f, -0.3f), new Vector3(0.25f, 0.06f, 0.4f), moss, "Moss");
            PrimitiveBuilder.Window(r, new Vector3(0f, 0.4f, -0.41f), new Vector3(0.18f, 0.16f, 0.05f), Quaternion.identity);
        }

        static void ShadowTower(Transform r)
        {
            var stone = MatLib.Color(new Color(0.18f, 0.16f, 0.22f), 0.35f, 0.2f);
            var band = MatLib.Color(new Color(0.45f, 0.1f, 0.55f), 0.4f, 0.5f, true, 1.1f);
            var roof = MatLib.Color(new Color(0.08f, 0.06f, 0.1f), 0.5f, 0.3f);
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.85f, 0f), new Vector3(0.48f, 0.85f, 0.48f), stone, "Shaft");
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.15f, 0f), new Vector3(0.62f, 0.15f, 0.62f), stone, "Base");
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.7f, 0f), new Vector3(0.52f, 0.06f, 0.52f), band, "Band");
            PrimitiveBuilder.Cone(r, new Vector3(0f, 1.95f, 0f), new Vector3(0.55f, 0.55f, 0.55f), roof, "Spire");
            PrimitiveBuilder.Sphere(r, new Vector3(0f, 1.78f, 0.22f), Vector3.one * 0.16f, band, "Eye");
            PrimitiveBuilder.Window(r, new Vector3(0.25f, 1.1f, 0f), new Vector3(0.05f, 0.18f, 0.1f), Quaternion.identity);
            PrimitiveBuilder.Window(r, new Vector3(-0.25f, 1.35f, 0f), new Vector3(0.05f, 0.14f, 0.1f), Quaternion.identity);
            PrimitiveBuilder.Cube(r, new Vector3(0.32f, 0.55f, 0.32f), new Vector3(0.12f, 0.55f, 0.12f), stone, "Buttress");
        }

        static void Observatory(Transform r)
        {
            var teal = MatLib.Color(new Color(0.22f, 0.4f, 0.52f), 0.25f, 0.45f);
            var copper = MatLib.Color(new Color(0.72f, 0.42f, 0.22f), 0.6f, 0.55f);
            var glass = MatLib.Color(new Color(0.45f, 0.75f, 1f), 0.1f, 0.9f, true, 1.5f);
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.45f, 0f), new Vector3(0.7f, 0.45f, 0.7f), teal, "Drum");
            PrimitiveBuilder.Sphere(r, new Vector3(0f, 1.05f, 0f), Vector3.one * 0.72f, glass, "Dome");
            PrimitiveBuilder.Cyl(r, new Vector3(0.18f, 1.42f, 0.1f), new Vector3(0.12f, 0.28f, 0.12f), copper, "Scope");
            var scope = r.Find("Scope");
            if (scope != null) scope.localRotation = Quaternion.Euler(35f, 25f, 0f);
            PrimitiveBuilder.Cube(r, new Vector3(0.4f, 0.15f, 0.4f), new Vector3(0.18f, 0.3f, 0.18f), teal, "Pillar");
            PrimitiveBuilder.Window(r, new Vector3(0f, 0.5f, 0.36f), new Vector3(0.2f, 0.22f, 0.05f), Quaternion.identity);
            PrimitiveBuilder.Cyl(r, new Vector3(-0.38f, 0.12f, -0.1f), new Vector3(0.16f, 0.08f, 0.16f), copper, "Gear");
        }

        static void Crystal(Transform r)
        {
            var cyan = MatLib.Color(new Color(0.35f, 0.85f, 1f), 0.15f, 0.85f, true, 1.8f);
            var mag = MatLib.Color(new Color(0.7f, 0.35f, 1f), 0.15f, 0.85f, true, 1.6f);
            var baseM = MatLib.Color(new Color(0.3f, 0.32f, 0.4f), 0.4f, 0.3f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.08f, 0f), new Vector3(0.7f, 0.14f, 0.7f), baseM, "Plinth");
            var a = PrimitiveBuilder.Cube(r, new Vector3(0f, 0.7f, 0f), new Vector3(0.38f, 1.15f, 0.38f), cyan, "ShardA");
            a.transform.localRotation = Quaternion.Euler(0f, 25f, 12f);
            var b = PrimitiveBuilder.Cube(r, new Vector3(0.18f, 0.5f, -0.1f), new Vector3(0.22f, 0.85f, 0.22f), mag, "ShardB");
            b.transform.localRotation = Quaternion.Euler(8f, -20f, -18f);
            var c = PrimitiveBuilder.Cube(r, new Vector3(-0.16f, 0.4f, 0.12f), new Vector3(0.18f, 0.65f, 0.18f), cyan, "ShardC");
            c.transform.localRotation = Quaternion.Euler(-12f, 40f, 10f);
            PrimitiveBuilder.Sphere(r, new Vector3(0f, 1.25f, 0f), Vector3.one * 0.16f, mag, "Core");
        }

        static void Mushrooms(Transform r)
        {
            var grass = MatLib.Color(new Color(0.34f, 0.58f, 0.28f), 0f, 0.2f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.03f, 0f), new Vector3(1.1f, 0.06f, 1.1f), grass, "Moss");
            Cap(r, new Vector3(-0.28f, 0f, -0.22f), 0.55f, new Color(0.95f, 0.35f, 0.55f));
            Cap(r, new Vector3(0.32f, 0f, 0.18f), 0.42f, new Color(0.85f, 0.45f, 1f));
            Cap(r, new Vector3(0.22f, 0f, -0.32f), 0.32f, new Color(1f, 0.75f, 0.4f));
            Cap(r, new Vector3(-0.32f, 0f, 0.3f), 0.28f, new Color(0.55f, 0.9f, 0.85f));
            Cap(r, new Vector3(0.02f, 0f, 0.02f), 0.2f, new Color(1f, 0.55f, 0.75f));
        }

        static void Cap(Transform r, Vector3 p, float h, Color c)
        {
            var stem = MatLib.Color(new Color(0.92f, 0.86f, 0.75f), 0f, 0.4f);
            var cap = MatLib.Color(c, 0.05f, 0.55f, true, 0.9f);
            PrimitiveBuilder.Cyl(r, p + new Vector3(0f, h * 0.35f, 0f), new Vector3(0.1f * h * 2f, h * 0.35f, 0.1f * h * 2f), stem, "Stem");
            PrimitiveBuilder.Sphere(r, p + new Vector3(0f, h * 0.72f, 0f), new Vector3(h * 0.7f, h * 0.42f, h * 0.7f), cap, "Cap");
        }

        static void FairyHouse(Transform r)
        {
            var wall = MatLib.Color(new Color(0.95f, 0.72f, 0.55f), 0.05f, 0.3f);
            var roof = MatLib.Color(new Color(0.85f, 0.25f, 0.7f), 0.1f, 0.45f, true, 0.7f);
            var trim = MatLib.Color(new Color(0.45f, 0.85f, 0.55f), 0.05f, 0.4f);
            var door = MatLib.Color(new Color(0.55f, 0.3f, 0.15f), 0.1f, 0.3f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.38f, 0f), new Vector3(0.78f, 0.7f, 0.7f), wall, "Wall");
            PrimitiveBuilder.Cone(r, new Vector3(0f, 1.05f, 0f), new Vector3(0.95f, 0.7f, 0.95f), roof, "Roof");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.28f, 0.36f), new Vector3(0.22f, 0.38f, 0.06f), door, "Door");
            PrimitiveBuilder.Sphere(r, new Vector3(0.1f, 0.28f, 0.4f), Vector3.one * 0.08f, MatLib.Color(new Color(1f, 0.85f, 0.2f), 0.4f, 0.7f, true, 1.2f), "Knob");
            PrimitiveBuilder.Window(r, new Vector3(0.28f, 0.5f, 0.36f), new Vector3(0.16f, 0.16f, 0.05f), Quaternion.identity);
            PrimitiveBuilder.Cube(r, new Vector3(-0.42f, 0.15f, 0.2f), new Vector3(0.12f, 0.3f, 0.12f), trim, "Post");
            PrimitiveBuilder.Sphere(r, new Vector3(0.05f, 1.42f, 0f), Vector3.one * 0.16f, roof, "Finial");
            PrimitiveBuilder.Cyl(r, new Vector3(0.48f, 0.02f, -0.2f), new Vector3(0.08f, 0.02f, 0.08f), trim, "Shroom");
        }
    }
}
