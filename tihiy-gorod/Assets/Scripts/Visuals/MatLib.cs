using System.Collections.Generic;
using UnityEngine;

namespace TihiyGorod
{
    public static class MatLib
    {
        static readonly Dictionary<string, Material> Cache = new Dictionary<string, Material>();
        static Shader _shader;

        static Shader Lit
        {
            get
            {
                if (_shader == null)
                {
                    _shader = Shader.Find("Standard");
                    if (_shader == null) _shader = Shader.Find("Diffuse");
                    if (_shader == null) _shader = Shader.Find("Unlit/Color");
                }
                return _shader;
            }
        }

        public static Material Color(Color c, float metallic = 0.08f, float smooth = 0.38f, bool emit = false, float emitMul = 1.4f)
        {
            string key = c.ToString() + metallic + smooth + emit + emitMul;
            Material m;
            if (Cache.TryGetValue(key, out m) && m != null)
                return m;

            m = new Material(Lit);
            m.name = "TG_" + key.GetHashCode();
            if (m.HasProperty("_Color")) m.SetColor("_Color", c);
            m.color = c;
            if (m.HasProperty("_Metallic")) m.SetFloat("_Metallic", metallic);
            if (m.HasProperty("_Glossiness")) m.SetFloat("_Glossiness", smooth);
            if (emit && m.HasProperty("_EmissionColor"))
            {
                m.EnableKeyword("_EMISSION");
                m.SetColor("_EmissionColor", c * emitMul);
            }
            Cache[key] = m;
            return m;
        }

        public static Material Unique(Color c, float metallic, float smooth, bool emit, float emitMul)
        {
            var m = new Material(Lit);
            if (m.HasProperty("_Color")) m.SetColor("_Color", c);
            m.color = c;
            if (m.HasProperty("_Metallic")) m.SetFloat("_Metallic", metallic);
            if (m.HasProperty("_Glossiness")) m.SetFloat("_Glossiness", smooth);
            if (emit && m.HasProperty("_EmissionColor"))
            {
                m.EnableKeyword("_EMISSION");
                m.SetColor("_EmissionColor", c * emitMul);
            }
            return m;
        }
    }
}
