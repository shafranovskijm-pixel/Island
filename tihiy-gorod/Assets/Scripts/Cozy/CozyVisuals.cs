using UnityEngine;

namespace TihiyGorod
{
    public static class CozyVisuals
    {
        public static void Build(CozyObject c)
        {
            var r = c.transform;
            switch (c.Def.Id)
            {
                case CozyId.Hearth: Hearth(c, r); break;
                case CozyId.Samovar: Samovar(r); break;
                case CozyId.PlaidBench: Bench(r); break;
                case CozyId.Lantern: Lantern(c, r); break;
                case CozyId.Curtain: Curtain(r); break;
                case CozyId.Bookshelf: Shelf(r); break;
                case CozyId.Geranium: Geranium(r); break;
                case CozyId.MusicBox: MusicBox(r); break;
                case CozyId.SleepingCat: Cushion(r); break;
            }
        }

        static void Hearth(CozyObject c, Transform r)
        {
            var stone = MatLib.Color(new Color(0.42f, 0.32f, 0.24f), 0.1f, 0.2f);
            var dark = MatLib.Color(new Color(0.12f, 0.08f, 0.06f), 0.05f, 0.15f);
            var fire = MatLib.Unique(new Color(1f, 0.5f, 0.12f), 0.05f, 0.7f, true, 2.2f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.18f, 0f), new Vector3(0.72f, 0.36f, 0.5f), stone, "Body");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.38f, 0f), new Vector3(0.78f, 0.08f, 0.56f), stone, "Mantel");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.16f, 0.18f), new Vector3(0.42f, 0.28f, 0.08f), dark, "Mouth");
            var flame = PrimitiveBuilder.Sphere(r, new Vector3(0f, 0.22f, 0.02f), new Vector3(0.22f, 0.3f, 0.16f), fire, "Flame");
            var lamp = Point(r, new Vector3(0f, 0.4f, 0.1f), new Color(1f, 0.55f, 0.22f), 3.4f, 1.4f);
            c.BindFlicker(flame.GetComponent<Renderer>(), lamp);
        }

        static void Samovar(Transform r)
        {
            var cop = MatLib.Color(new Color(0.72f, 0.42f, 0.18f), 0.65f, 0.55f, true, 0.4f);
            var wood = MatLib.Color(new Color(0.4f, 0.24f, 0.12f), 0.05f, 0.25f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.04f, 0f), new Vector3(0.32f, 0.06f, 0.32f), wood, "Tray");
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.28f, 0f), new Vector3(0.18f, 0.22f, 0.18f), cop, "Body");
            PrimitiveBuilder.Sphere(r, new Vector3(0f, 0.52f, 0f), Vector3.one * 0.16f, cop, "Lid");
            PrimitiveBuilder.Cyl(r, new Vector3(0.16f, 0.28f, 0f), new Vector3(0.04f, 0.04f, 0.12f), cop, "Spout");
            PrimitiveBuilder.Sphere(r, new Vector3(0f, 0.64f, 0f), Vector3.one * 0.08f, MatLib.Color(new Color(0.9f, 0.9f, 0.85f), 0f, 0.8f, true, 0.5f), "Steam");
        }

        static void Bench(Transform r)
        {
            var wood = MatLib.Color(new Color(0.46f, 0.3f, 0.16f), 0.05f, 0.25f);
            var plaid = MatLib.Color(new Color(0.72f, 0.22f, 0.18f), 0f, 0.35f);
            var cream = MatLib.Color(new Color(0.9f, 0.82f, 0.62f), 0f, 0.3f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.22f, 0f), new Vector3(0.85f, 0.08f, 0.36f), wood, "Seat");
            PrimitiveBuilder.Cube(r, new Vector3(-0.34f, 0.1f, 0f), new Vector3(0.08f, 0.2f, 0.32f), wood, "LegA");
            PrimitiveBuilder.Cube(r, new Vector3(0.34f, 0.1f, 0f), new Vector3(0.08f, 0.2f, 0.32f), wood, "LegB");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.28f, 0.02f), new Vector3(0.7f, 0.06f, 0.3f), plaid, "Plaid");
            PrimitiveBuilder.Cube(r, new Vector3(0.18f, 0.34f, 0.02f), new Vector3(0.22f, 0.08f, 0.22f), cream, "Fold");
        }

        static void Lantern(CozyObject c, Transform r)
        {
            var post = MatLib.Color(new Color(0.28f, 0.2f, 0.12f), 0.1f, 0.2f);
            var glow = MatLib.Unique(new Color(1f, 0.82f, 0.4f), 0.1f, 0.8f, true, 2.4f);
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.45f, 0f), new Vector3(0.06f, 0.45f, 0.06f), post, "Post");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.92f, 0f), new Vector3(0.22f, 0.22f, 0.22f), glow, "Cage");
            var lamp = Point(r, new Vector3(0f, 0.92f, 0f), new Color(1f, 0.78f, 0.42f), 2.6f, 0.75f);
            var cage = r.Find("Cage");
            c.BindFlicker(cage != null ? cage.GetComponent<Renderer>() : null, lamp);
        }

        static void Curtain(Transform r)
        {
            var cloth = MatLib.Color(new Color(0.72f, 0.38f, 0.22f), 0f, 0.35f);
            var rod = MatLib.Color(new Color(0.55f, 0.42f, 0.2f), 0.4f, 0.5f);
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.72f, 0f), new Vector3(0.32f, 0.03f, 0.03f), rod, "Rod");
            PrimitiveBuilder.Cube(r, new Vector3(-0.1f, 0.42f, 0.02f), new Vector3(0.16f, 0.58f, 0.05f), cloth, "L");
            PrimitiveBuilder.Cube(r, new Vector3(0.1f, 0.4f, 0.02f), new Vector3(0.16f, 0.54f, 0.05f), cloth, "R");
        }

        static void Shelf(Transform r)
        {
            var wood = MatLib.Color(new Color(0.4f, 0.24f, 0.12f), 0.05f, 0.22f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.42f, 0f), new Vector3(0.7f, 0.78f, 0.22f), wood, "Case");
            Color[] cols =
            {
                new Color(0.7f, 0.2f, 0.18f), new Color(0.2f, 0.35f, 0.55f),
                new Color(0.75f, 0.62f, 0.25f), new Color(0.3f, 0.5f, 0.28f),
                new Color(0.55f, 0.3f, 0.5f)
            };
            for (int i = 0; i < 5; i++)
            {
                float x = -0.24f + i * 0.12f;
                PrimitiveBuilder.Cube(r, new Vector3(x, 0.38f + (i % 2) * 0.22f, 0.04f),
                    new Vector3(0.08f, 0.2f, 0.12f), MatLib.Color(cols[i], 0f, 0.3f), "Book" + i);
            }
        }

        static void Geranium(Transform r)
        {
            var pot = MatLib.Color(new Color(0.62f, 0.28f, 0.18f), 0.05f, 0.25f);
            var soil = MatLib.Color(new Color(0.28f, 0.18f, 0.1f), 0f, 0.15f);
            var leaf = MatLib.Color(new Color(0.22f, 0.5f, 0.18f), 0f, 0.3f);
            var flower = MatLib.Color(new Color(0.9f, 0.2f, 0.22f), 0f, 0.45f, true, 0.6f);
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.12f, 0f), new Vector3(0.14f, 0.12f, 0.14f), pot, "Pot");
            PrimitiveBuilder.Cyl(r, new Vector3(0f, 0.24f, 0f), new Vector3(0.12f, 0.02f, 0.12f), soil, "Soil");
            PrimitiveBuilder.Sphere(r, new Vector3(0f, 0.38f, 0f), Vector3.one * 0.22f, leaf, "Leaves");
            PrimitiveBuilder.Sphere(r, new Vector3(0.06f, 0.48f, 0.04f), Vector3.one * 0.1f, flower, "F1");
            PrimitiveBuilder.Sphere(r, new Vector3(-0.05f, 0.5f, -0.02f), Vector3.one * 0.09f, flower, "F2");
        }

        static void MusicBox(Transform r)
        {
            var wood = MatLib.Color(new Color(0.48f, 0.28f, 0.14f), 0.15f, 0.4f);
            var gold = MatLib.Color(new Color(0.9f, 0.72f, 0.28f), 0.55f, 0.7f, true, 0.7f);
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.12f, 0f), new Vector3(0.36f, 0.2f, 0.28f), wood, "Box");
            PrimitiveBuilder.Cube(r, new Vector3(0f, 0.24f, 0f), new Vector3(0.38f, 0.04f, 0.3f), gold, "Lid");
            PrimitiveBuilder.Sphere(r, new Vector3(0.12f, 0.18f, 0.16f), Vector3.one * 0.06f, gold, "Key");
        }

        static void Cushion(Transform r)
        {
            var cloth = MatLib.Color(new Color(0.72f, 0.42f, 0.28f), 0f, 0.35f);
            PrimitiveBuilder.Sphere(r, new Vector3(0f, 0.1f, 0f), new Vector3(0.42f, 0.14f, 0.42f), cloth, "Cush");
        }

        static Light Point(Transform r, Vector3 local, Color col, float range, float intensity)
        {
            var go = new GameObject("Lamp");
            go.transform.SetParent(r, false);
            go.transform.localPosition = local;
            var l = go.AddComponent<Light>();
            l.type = LightType.Point;
            l.color = col;
            l.range = range;
            l.intensity = intensity;
            l.shadows = LightShadows.None;
            return l;
        }
    }
}
