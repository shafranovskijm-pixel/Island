using UnityEngine;

namespace TihiyGorod
{
    public static class PrimitiveBuilder
    {
        public static GameObject Part(PrimitiveType type, Transform parent, Vector3 localPos, Vector3 localScale, Quaternion rot, Material mat, string name)
        {
            var go = GameObject.CreatePrimitive(type);
            go.name = name;
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            go.transform.localRotation = rot;
            go.transform.localScale = localScale;
            var col = go.GetComponent<Collider>();
            if (col != null) Object.Destroy(col);
            var r = go.GetComponent<Renderer>();
            if (r != null) r.sharedMaterial = mat;
            return go;
        }

        public static GameObject Cube(Transform p, Vector3 pos, Vector3 scale, Material mat, string n)
        {
            return Part(PrimitiveType.Cube, p, pos, scale, Quaternion.identity, mat, n);
        }

        public static GameObject Sphere(Transform p, Vector3 pos, Vector3 scale, Material mat, string n)
        {
            return Part(PrimitiveType.Sphere, p, pos, scale, Quaternion.identity, mat, n);
        }

        public static GameObject Cyl(Transform p, Vector3 pos, Vector3 scale, Material mat, string n)
        {
            return Part(PrimitiveType.Cylinder, p, pos, scale, Quaternion.identity, mat, n);
        }

        public static GameObject Capsule(Transform p, Vector3 pos, Vector3 scale, Material mat, string n)
        {
            return Part(PrimitiveType.Capsule, p, pos, scale, Quaternion.identity, mat, n);
        }

        public static GameObject Cone(Transform p, Vector3 pos, Vector3 scale, Material mat, string n)
        {
            return MeshFactory.MeshObject(n, MeshFactory.Cone, mat, p).Tap(go =>
            {
                go.transform.localPosition = pos;
                go.transform.localScale = scale;
            });
        }

        public static GameObject Window(Transform p, Vector3 pos, Vector3 scale, Quaternion rot)
        {
            var m = MatLib.Unique(new Color(1f, 0.85f, 0.35f), 0.1f, 0.8f, true, 2.2f);
            var go = Cube(p, pos, scale, m, "Window");
            go.transform.localRotation = rot;
            var glow = go.AddComponent<WindowGlow>();
            glow.Lit = m;
            return go;
        }
    }

    static class GoExt
    {
        public static GameObject Tap(this GameObject go, System.Action<GameObject> a)
        {
            a(go);
            return go;
        }
    }
}
