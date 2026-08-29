using System.Collections.Generic;
using UnityEngine;

namespace TihiyGorod
{
    public static class MeshFactory
    {
        static Mesh _cone;
        static Mesh _pyramid;

        public static Mesh Cone
        {
            get
            {
                if (_cone == null) _cone = BuildCone(16);
                return _cone;
            }
        }

        public static Mesh Pyramid
        {
            get
            {
                if (_pyramid == null) _pyramid = BuildCone(4);
                return _pyramid;
            }
        }

        public static GameObject MeshObject(string name, Mesh mesh, Material mat, Transform parent)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var mf = go.AddComponent<MeshFilter>();
            mf.sharedMesh = mesh;
            var mr = go.AddComponent<MeshRenderer>();
            mr.sharedMaterial = mat;
            mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
            mr.receiveShadows = true;
            return go;
        }

        static Mesh BuildCone(int segments)
        {
            var verts = new List<Vector3>(segments + 2);
            var tris = new List<int>(segments * 6);
            verts.Add(new Vector3(0f, 1f, 0f));
            for (int i = 0; i < segments; i++)
            {
                float a = (i / (float)segments) * Mathf.PI * 2f + (segments == 4 ? Mathf.PI * 0.25f : 0f);
                verts.Add(new Vector3(Mathf.Cos(a), 0f, Mathf.Sin(a)));
            }
            verts.Add(Vector3.zero);
            int baseCenter = verts.Count - 1;
            for (int i = 0; i < segments; i++)
            {
                int n = 1 + ((i + 1) % segments);
                int c = 1 + i;
                tris.Add(0);
                tris.Add(n);
                tris.Add(c);
                tris.Add(baseCenter);
                tris.Add(c);
                tris.Add(n);
            }
            var mesh = new Mesh { name = "Cone" + segments };
            mesh.SetVertices(verts);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            return mesh;
        }
    }
}
