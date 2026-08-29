using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace TihiyGorod
{
    public sealed class MainMenu : MonoBehaviour
    {
        Canvas _canvas;
        Image _root;
        Image _evenings;
        Image _settings;
        Slider _music;
        Slider _sfx;

        static readonly Color Wood = new Color(0.42f, 0.26f, 0.12f, 0.96f);
        static readonly Color Amber = new Color(0.78f, 0.48f, 0.18f, 1f);
        static readonly Color Paper = new Color(0.96f, 0.90f, 0.76f, 1f);
        static readonly Color Ink = new Color(0.22f, 0.12f, 0.06f, 1f);
        static readonly Color PaperDim = new Color(0.32f, 0.2f, 0.1f, 0.92f);

        public void Build(Canvas canvas)
        {
            _canvas = canvas;
            _root = UiKit.Panel(canvas.transform, "MenuRoot", new Color(0.18f, 0.1f, 0.05f, 1f));
            UiKit.Stretch(_root.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

            var bg = UiKit.Panel(_root.transform, "Bg", Color.white);
            UiKit.Stretch(bg.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            bg.preserveAspect = false;
            StartCoroutine(ArtLoader.LoadPngRoutine("menu-cozy.png", tex =>
            {
                if (bg != null && tex != null)
                {
                    bg.sprite = ArtLoader.AsSprite(tex);
                    bg.color = Color.white;
                    bg.preserveAspect = false;
                }
            }));

            var veil = UiKit.Panel(_root.transform, "Veil", new Color(0.18f, 0.08f, 0.03f, 0.28f));
            UiKit.Stretch(veil.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            veil.raycastTarget = false;

            var title = UiKit.Label(_root.transform, "Title", "Тихий город", 56, Paper, TextAnchor.MiddleCenter);
            UiKit.Stretch(title.rectTransform, new Vector2(0.06f, 0.78f), new Vector2(0.94f, 0.94f), Vector2.zero, Vector2.zero);
            UiKit.Stroke(title.gameObject, new Color(0.18f, 0.08f, 0.03f, 0.85f));

            var sub = UiKit.Label(_root.transform, "Sub", "вечера уюта", 28, new Color(0.95f, 0.78f, 0.48f), TextAnchor.MiddleCenter);
            UiKit.Stretch(sub.rectTransform, new Vector2(0.1f, 0.72f), new Vector2(0.9f, 0.8f), Vector2.zero, Vector2.zero);

            var play = Big(_root.transform, "Play", "Играть", 0.54f, 0.68f);
            play.onClick.AddListener(() => { if (GameFlow.I != null) GameFlow.I.PlayContinue(); });

            var ev = Big(_root.transform, "Evenings", "Вечера", 0.38f, 0.52f);
            ev.onClick.AddListener(() => ShowEvenings(true));

            var st = Big(_root.transform, "Settings", "Настройки", 0.22f, 0.36f);
            st.onClick.AddListener(() => ShowSettings(true));

            BuildEvenings();
            BuildSettings();
        }

        Button Big(Transform parent, string name, string cap, float y0, float y1)
        {
            var b = UiKit.Btn(parent, name, cap, Amber, Paper, 34);
            UiKit.Stretch(b.GetComponent<RectTransform>(), new Vector2(0.14f, y0), new Vector2(0.86f, y1), Vector2.zero, Vector2.zero);
            return b;
        }

        void BuildEvenings()
        {
            _evenings = UiKit.Panel(_root.transform, "EveningsPanel", PaperDim);
            UiKit.Stretch(_evenings.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

            UiKit.Label(_evenings.transform, "T", "Вечера", 40, Paper, TextAnchor.MiddleCenter)
                .rectTransform.offsetMin = new Vector2(0f, 0f);

            var t = _evenings.transform.Find("T");
            if (t != null) UiKit.Stretch(t.GetComponent<RectTransform>(), new Vector2(0.08f, 0.82f), new Vector2(0.92f, 0.96f), Vector2.zero, Vector2.zero);

            AddEvening(EveningId.One, "Вечер 1\nПервый огонь", 0.62f, 0.80f);
            AddEvening(EveningId.Two, "Вечер 2\nГости", 0.42f, 0.60f);
            AddEvening(EveningId.Three, "Вечер 3\nДождь", 0.22f, 0.40f);

            var back = UiKit.Btn(_evenings.transform, "Back", "Назад", Wood, Paper, 26);
            UiKit.Stretch(back.GetComponent<RectTransform>(), new Vector2(0.18f, 0.06f), new Vector2(0.82f, 0.16f), Vector2.zero, Vector2.zero);
            back.onClick.AddListener(() => ShowEvenings(false));
            _evenings.gameObject.SetActive(false);
        }

        void AddEvening(EveningId id, string cap, float y0, float y1)
        {
            var b = UiKit.Btn(_evenings.transform, id.ToString(), cap, Amber, Paper, 26);
            UiKit.Stretch(b.GetComponent<RectTransform>(), new Vector2(0.12f, y0), new Vector2(0.88f, y1), Vector2.zero, Vector2.zero);
            var captured = id;
            b.onClick.AddListener(() =>
            {
                if (GameFlow.I != null) GameFlow.I.BeginCity(captured);
            });
        }

        void BuildSettings()
        {
            _settings = UiKit.Panel(_root.transform, "SettingsPanel", PaperDim);
            UiKit.Stretch(_settings.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

            var title = UiKit.Label(_settings.transform, "T", "Настройки", 40, Paper, TextAnchor.MiddleCenter);
            UiKit.Stretch(title.rectTransform, new Vector2(0.08f, 0.82f), new Vector2(0.92f, 0.96f), Vector2.zero, Vector2.zero);

            var mLab = UiKit.Label(_settings.transform, "ML", "Музыка", 26, Paper, TextAnchor.MiddleLeft);
            UiKit.Stretch(mLab.rectTransform, new Vector2(0.12f, 0.68f), new Vector2(0.88f, 0.76f), Vector2.zero, Vector2.zero);
            _music = UiKit.MakeSlider(_settings.transform, "Music", PlayerPrefs.GetFloat("tg.music", 1f));
            UiKit.Stretch(_music.GetComponent<RectTransform>(), new Vector2(0.12f, 0.58f), new Vector2(0.88f, 0.68f), Vector2.zero, Vector2.zero);
            _music.onValueChanged.AddListener(v =>
            {
                PlayerPrefs.SetFloat("tg.music", v);
                AudioDirector.MusicMul = v;
            });

            var sLab = UiKit.Label(_settings.transform, "SL", "Звук", 26, Paper, TextAnchor.MiddleLeft);
            UiKit.Stretch(sLab.rectTransform, new Vector2(0.12f, 0.46f), new Vector2(0.88f, 0.54f), Vector2.zero, Vector2.zero);
            _sfx = UiKit.MakeSlider(_settings.transform, "Sfx", PlayerPrefs.GetFloat("tg.sfx", 1f));
            UiKit.Stretch(_sfx.GetComponent<RectTransform>(), new Vector2(0.12f, 0.36f), new Vector2(0.88f, 0.46f), Vector2.zero, Vector2.zero);
            _sfx.onValueChanged.AddListener(v =>
            {
                PlayerPrefs.SetFloat("tg.sfx", v);
                AudioDirector.SfxMul = v;
            });

            AudioDirector.MusicMul = PlayerPrefs.GetFloat("tg.music", 1f);
            AudioDirector.SfxMul = PlayerPrefs.GetFloat("tg.sfx", 1f);

            var back = UiKit.Btn(_settings.transform, "Back", "Назад", Wood, Paper, 26);
            UiKit.Stretch(back.GetComponent<RectTransform>(), new Vector2(0.18f, 0.08f), new Vector2(0.82f, 0.18f), Vector2.zero, Vector2.zero);
            back.onClick.AddListener(() =>
            {
                PlayerPrefs.Save();
                ShowSettings(false);
            });
            _settings.gameObject.SetActive(false);
        }

        void ShowEvenings(bool on)
        {
            if (_evenings != null) _evenings.gameObject.SetActive(on);
        }

        void ShowSettings(bool on)
        {
            if (_settings != null) _settings.gameObject.SetActive(on);
        }

        public void Hide()
        {
            if (_canvas != null) _canvas.gameObject.SetActive(false);
        }

        public void Show()
        {
            if (_canvas != null) _canvas.gameObject.SetActive(true);
        }
    }
}
