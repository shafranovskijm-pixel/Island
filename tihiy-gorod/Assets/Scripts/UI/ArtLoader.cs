using System.Collections;
using System.IO;
using UnityEngine;
using UnityEngine.Networking;

namespace TihiyGorod
{
    /// <summary>
    /// Loads PNGs from StreamingAssets via Texture2D.LoadImage so Play works
    /// without an Editor texture importer.
    /// </summary>
    public static class ArtLoader
    {
        public static Texture2D LoadPng(string fileName)
        {
            string[] candidates =
            {
                Path.Combine(Application.streamingAssetsPath, "Art", fileName),
                Path.Combine(Application.dataPath, "StreamingAssets", "Art", fileName),
                Path.Combine(Application.dataPath, "Art", "UI", fileName),
                Path.Combine(Application.dataPath, "Art", "Portraits", fileName)
            };
            for (int i = 0; i < candidates.Length; i++)
            {
                try
                {
                    if (!File.Exists(candidates[i])) continue;
                    var bytes = File.ReadAllBytes(candidates[i]);
                    var tex = MakeTex();
                    if (tex.LoadImage(bytes)) return tex;
                    Object.Destroy(tex);
                }
                catch { }
            }
            return Fallback(fileName);
        }

        public static IEnumerator LoadPngRoutine(string fileName, System.Action<Texture2D> done)
        {
            string url = Path.Combine(Application.streamingAssetsPath, "Art", fileName);
            if (url.Contains("://") || url.Contains("jar:"))
            {
                using (var req = UnityWebRequest.Get(url))
                {
                    yield return req.SendWebRequest();
                    bool ok = req.result == UnityWebRequest.Result.Success && req.downloadHandler != null &&
                              req.downloadHandler.data != null && req.downloadHandler.data.Length > 32;
                    if (ok)
                    {
                        var tex = MakeTex();
                        if (tex.LoadImage(req.downloadHandler.data))
                        {
                            if (done != null) done(tex);
                            yield break;
                        }
                        Object.Destroy(tex);
                    }
                }
            }
            if (done != null) done(LoadPng(fileName));
        }

        public static Sprite AsSprite(Texture2D tex)
        {
            if (tex == null) return null;
            return Sprite.Create(tex, new Rect(0f, 0f, tex.width, tex.height), new Vector2(0.5f, 0.5f), 100f);
        }

        public static Sprite HearthIcon()
        {
            var t = new Texture2D(32, 32, TextureFormat.RGBA32, false);
            t.filterMode = FilterMode.Point;
            t.wrapMode = TextureWrapMode.Clamp;
            t.name = "HearthIcon";
            for (int y = 0; y < 32; y++)
            {
                for (int x = 0; x < 32; x++)
                {
                    Color c = new Color(0f, 0f, 0f, 0f);
                    if (y <= 9 && x >= 5 && x <= 26)
                        c = new Color(0.38f, 0.22f, 0.12f, 1f);
                    if (y >= 2 && y <= 10 && x >= 9 && x <= 22)
                        c = new Color(0.12f, 0.07f, 0.05f, 1f);
                    if (y <= 3 && x >= 4 && x <= 27)
                        c = new Color(0.32f, 0.18f, 0.1f, 1f);
                    float dx = (x - 16) / 7.2f;
                    float dy = (y - 17) / 11f;
                    float flame = 1f - dx * dx - dy * dy;
                    if (y > 8 && flame > 0f)
                    {
                        float a = Mathf.Clamp01(flame * 1.4f);
                        Color hot = new Color(1f, 0.88f, 0.35f, a);
                        Color cool = new Color(0.95f, 0.32f, 0.06f, a);
                        c = Color.Lerp(cool, hot, Mathf.Clamp01(flame));
                    }
                    t.SetPixel(x, y, c);
                }
            }
            t.Apply(false, false);
            return Sprite.Create(t, new Rect(0f, 0f, 32f, 32f), new Vector2(0.5f, 0.5f), 32f);
        }

        static Texture2D MakeTex()
        {
            var tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
            tex.wrapMode = TextureWrapMode.Clamp;
            tex.filterMode = FilterMode.Bilinear;
            tex.name = "ArtPng";
            return tex;
        }

        static Texture2D Fallback(string fileName)
        {
            var tex = new Texture2D(8, 8, TextureFormat.RGBA32, false);
            Color a = new Color(0.55f, 0.32f, 0.16f);
            Color b = new Color(0.85f, 0.62f, 0.32f);
            if (fileName != null && fileName.Contains("blood")) { a = new Color(0.35f, 0.08f, 0.1f); b = new Color(0.7f, 0.15f, 0.18f); }
            if (fileName != null && fileName.Contains("shadow")) { a = new Color(0.1f, 0.1f, 0.18f); b = new Color(0.28f, 0.22f, 0.4f); }
            if (fileName != null && fileName.Contains("liat")) { a = new Color(0.2f, 0.4f, 0.28f); b = new Color(0.7f, 0.85f, 0.45f); }
            for (int y = 0; y < 8; y++)
                for (int x = 0; x < 8; x++)
                    tex.SetPixel(x, y, ((x + y) & 1) == 0 ? a : b);
            tex.Apply();
            return tex;
        }
    }
}
