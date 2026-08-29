using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace TihiyGorod
{
    /// <summary>
    /// Scene entry. Builds lighting, isometric camera, city grid, UI, audio and units at runtime
    /// so Play works even from a nearly empty scene.
    /// </summary>
    [DefaultExecutionOrder(-200)]
    public sealed class Bootstrap : MonoBehaviour
    {
        static bool _booted;

        void Awake()
        {
            if (_booted && Game.Grid != null)
            {
                if (this != Query.One<Bootstrap>()) Destroy(gameObject);
            }
        }

        public void StartWorld()
        {
            if (_booted && Game.Grid != null) return;
            _booted = true;
            BuildWorld();
        }

        void BuildWorld()
        {
            QualitySettings.vSyncCount = 0;
            Application.targetFrameRate = 60;
            Screen.sleepTimeout = SleepTimeout.NeverSleep;

            var world = new GameObject("World").transform;
            world.SetParent(transform, false);

            var cam = EnsureCamera();
            var sun = EnsureLight();
            EnsureEventSystem();

            var grid = gameObject.AddComponent<CityGrid>();
            var align = gameObject.AddComponent<AlignmentSystem>();
            var res = gameObject.AddComponent<ResourceSystem>();
            var place = gameObject.AddComponent<PlacementSystem>();
            var time = gameObject.AddComponent<DayNightCycle>();
            var weather = gameObject.AddComponent<WeatherSystem>();
            var units = gameObject.AddComponent<UnitManager>();
            var audio = gameObject.AddComponent<AudioDirector>();
            var iso = gameObject.AddComponent<IsoCamera>();
            var tap = gameObject.AddComponent<TapInput>();
            var fx = gameObject.AddComponent<WorldFx>();
            var cozy = gameObject.AddComponent<CozySystem>();
            var evening = gameObject.AddComponent<EveningSystem>();
            var riddles = gameObject.AddComponent<RiddleDirector>();
            gameObject.AddComponent<IncomeTicker>();

            Game.Bind(align, res, grid, place, time, weather, units, audio, iso, fx);
            Game.Cozy = cozy;
            Game.Evening = evening;
            Game.Riddles = riddles;

            grid.BuildGround(world);
            weather.Build(world);
            fx.Build(world);
            cozy.Build(world);
            audio.Build(transform);
            time.Bind(sun, cam);
            iso.Bind(cam, grid.WorldCenter);
            tap.Bind(cam);
            res.GrantStart();
            cozy.ApplyEveningUnlocks(GameFlow.PendingEvening);

            SeedTown();
            units.SpawnInitial(world);
            align.RecalcInfluence();

            var canvas = BuildCanvas();
            var hud = gameObject.AddComponent<GameHud>();
            hud.Build(canvas.transform);
            evening.Build(canvas.transform);
            riddles.Build(canvas.transform);

            Debug.Log("Тихий город: мир собран. Сетка " + SimConfig.GridSize + "x" + SimConfig.GridSize +
                      ", жителей " + units.Count + ".");
        }

        void SeedTown()
        {
            PlaceFree(BuildingId.Garden, 3, 3);
            PlaceFree(BuildingId.Sanctuary, 4, 3);
            PlaceFree(BuildingId.Crypt, 6, 6);
            PlaceFree(BuildingId.ShadowTower, 7, 6);
            PlaceFree(BuildingId.Observatory, 2, 7);
            PlaceFree(BuildingId.Crystal, 2, 6);
            PlaceFree(BuildingId.MushroomRing, 7, 2);
            PlaceFree(BuildingId.FairyHouse, 8, 3);
        }

        static void PlaceFree(BuildingId id, int x, int y)
        {
            var def = BuildingCatalog.Get(id);
            if (def != null) CityGrid.I.Place(def, x, y);
        }

        Camera EnsureCamera()
        {
            var cam = Camera.main;
            if (cam == null)
            {
                var found = Query.One<Camera>();
                cam = found;
            }
            if (cam == null)
            {
                var go = new GameObject("Main Camera");
                cam = go.AddComponent<Camera>();
                go.AddComponent<AudioListener>();
                go.tag = "MainCamera";
            }
            if (cam.GetComponent<AudioListener>() == null)
                cam.gameObject.AddComponent<AudioListener>();
            cam.orthographic = true;
            cam.orthographicSize = SimConfig.CameraStartSize;
            cam.nearClipPlane = 0.1f;
            cam.farClipPlane = 120f;
            cam.allowHDR = true;
            cam.allowMSAA = true;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.48f, 0.68f, 0.88f);
            cam.transform.rotation = Quaternion.Euler(30f, 45f, 0f);
            return cam;
        }

        Light EnsureLight()
        {
            var lights = Query.All<Light>();
            Light sun = null;
            if (lights != null)
            {
                for (int i = 0; i < lights.Length; i++)
                    if (lights[i] != null && lights[i].type == LightType.Directional) { sun = lights[i]; break; }
            }
            if (sun == null)
            {
                var go = new GameObject("Sun");
                sun = go.AddComponent<Light>();
                sun.type = LightType.Directional;
            }
            sun.shadows = LightShadows.Soft;
            sun.shadowStrength = 0.65f;
            sun.intensity = 1.05f;
            sun.color = new Color(1f, 0.95f, 0.86f);
            sun.transform.rotation = Quaternion.Euler(50f, 40f, 0f);
            return sun;
        }

        static void EnsureEventSystem()
        {
            if (EventSystem.current != null) return;
            if (Query.One<EventSystem>() != null) return;
            var go = new GameObject("EventSystem");
            go.AddComponent<EventSystem>();
            go.AddComponent<StandaloneInputModule>();
        }

        static Canvas BuildCanvas()
        {
            var go = new GameObject("HUD");
            var canvas = go.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.pixelPerfect = false;
            canvas.sortingOrder = 10;
            var scaler = go.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080f, 1920f);
            scaler.matchWidthOrHeight = 0.5f;
            scaler.referencePixelsPerInch = 120f;
            go.AddComponent<GraphicRaycaster>();
            return canvas;
        }
    }
}
