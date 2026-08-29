using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace TihiyGorod
{
    /// <summary>
    /// Entry: shows the main menu, then starts Bootstrap city for a chosen evening.
    /// </summary>
    [DefaultExecutionOrder(-250)]
    public sealed class GameFlow : MonoBehaviour
    {
        public static GameFlow I { get; private set; }
        public static EveningId PendingEvening = EveningId.One;

        public bool MenuVisible { get; private set; }

        MainMenu _menu;
        bool _cityStarted;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void AutoBoot()
        {
            if (Query.One<GameFlow>() != null) return;
            var go = new GameObject("GameFlow");
            go.AddComponent<GameFlow>();
        }

        void Awake()
        {
            if (I != null && I != this)
            {
                Destroy(gameObject);
                return;
            }
            I = this;
            EnsureEventSystem();
            EnsureCamera();
            ShowMenu();
        }

        public void ShowMenu()
        {
            MenuVisible = true;
            if (_menu == null)
            {
                var canvas = BuildMenuCanvas();
                _menu = gameObject.AddComponent<MainMenu>();
                _menu.Build(canvas);
            }
            else _menu.Show();
        }

        public void PlayContinue()
        {
            EveningId e = EveningId.One;
            if (PlayerPrefs.GetInt("tg.continue", 0) == 1)
            {
                int v = PlayerPrefs.GetInt("tg.evening", 1);
                if (v < 1) v = 1;
                if (v > 3) v = 3;
                e = (EveningId)v;
            }
            BeginCity(e);
        }

        public void BeginCity(EveningId evening)
        {
            if (_cityStarted) return;
            PendingEvening = evening;
            MenuVisible = false;
            if (_menu != null) _menu.Hide();
            _cityStarted = true;

            var boot = Query.One<Bootstrap>();
            if (boot == null)
            {
                var go = new GameObject("Bootstrap");
                boot = go.AddComponent<Bootstrap>();
            }
            boot.StartWorld();
        }

        static void EnsureEventSystem()
        {
            if (EventSystem.current != null) return;
            if (Query.One<EventSystem>() != null) return;
            var go = new GameObject("EventSystem");
            go.AddComponent<EventSystem>();
            go.AddComponent<StandaloneInputModule>();
        }

        static void EnsureCamera()
        {
            if (Camera.main != null) return;
            var found = Query.One<Camera>();
            if (found != null) return;
            var go = new GameObject("Main Camera");
            var cam = go.AddComponent<Camera>();
            go.AddComponent<AudioListener>();
            go.tag = "MainCamera";
            cam.orthographic = true;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.28f, 0.16f, 0.08f);
        }

        static Canvas BuildMenuCanvas()
        {
            var go = new GameObject("MainMenuCanvas");
            var canvas = go.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 40;
            var scaler = go.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080f, 1920f);
            scaler.matchWidthOrHeight = 0.5f;
            go.AddComponent<GraphicRaycaster>();
            return canvas;
        }
    }
}
