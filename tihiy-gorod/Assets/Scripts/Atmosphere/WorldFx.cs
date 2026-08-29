using UnityEngine;

namespace TihiyGorod
{
    public sealed class WorldFx : MonoBehaviour
    {
        ParticleSystem _bloom;
        ParticleSystem _blight;

        public void Build(Transform world)
        {
            _bloom = Make(world, "BloomFx", new Color(1f, 0.85f, 0.35f), 18f);
            _blight = Make(world, "BlightFx", new Color(0.35f, 0.9f, 0.25f), 14f);
        }

        ParticleSystem Make(Transform world, string name, Color c, float rate)
        {
            var go = new GameObject(name);
            go.transform.SetParent(world, false);
            var ps = go.AddComponent<ParticleSystem>();
            var main = ps.main;
            main.loop = true;
            main.startLifetime = 2.5f;
            main.startSpeed = 0.15f;
            main.startSize = 0.08f;
            main.startColor = c;
            main.maxParticles = 80;
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            var em = ps.emission;
            em.rateOverTime = 0f;
            var sh = ps.shape;
            sh.shapeType = ParticleSystemShapeType.Box;
            sh.scale = new Vector3(12f, 0.4f, 12f);
            var rend = go.GetComponent<ParticleSystemRenderer>();
            var fxShader = Shader.Find("Sprites/Default");
            if (fxShader == null) fxShader = Shader.Find("Unlit/Color");
            var mat = new Material(fxShader);
            mat.color = c;
            rend.sharedMaterial = mat;
            ps.Play();
            return ps;
        }

        void LateUpdate()
        {
            if (CityGrid.I == null) return;
            int bloom = 0, blight = 0, n = 0;
            Vector3 accB = Vector3.zero, accL = Vector3.zero;
            CityGrid.I.ForEachBuilding(b =>
            {
                n++;
                if (b.NeighborMix == SynergyKind.Bloom) { bloom++; accB += b.transform.position; }
                if (b.NeighborMix == SynergyKind.Blight) { blight++; accL += b.transform.position; }
            });
            Place(_bloom, bloom, accB, 22f);
            Place(_blight, blight, accL, 18f);
        }

        static void Place(ParticleSystem ps, int count, Vector3 acc, float rate)
        {
            if (ps == null) return;
            var em = ps.emission;
            if (count <= 0)
            {
                em.rateOverTime = 0f;
                return;
            }
            ps.transform.position = acc / count + Vector3.up * 0.6f;
            em.rateOverTime = rate * count;
        }
    }
}
