using UnityEngine;
using UnityEngine.UI;

namespace TihiyGorod
{
    public enum EveningId
    {
        One = 1,
        Two = 2,
        Three = 3
    }

    public sealed class EveningSystem : MonoBehaviour
    {
        public static EveningSystem I { get; private set; }

        public EveningId Current { get; private set; }
        public bool Completed { get; private set; }
        public bool GuestAccepted { get; private set; }
        public bool CozyPlaced { get; private set; }

        Image _banner;
        Text _bannerText;
        Text _goalText;
        Image _donePanel;
        float _bannerLeft;
        float _age;
        bool _rainForced;

        public string RuTitle
        {
            get
            {
                switch (Current)
                {
                    case EveningId.One: return "Вечер 1  ·  Первый огонь";
                    case EveningId.Two: return "Вечер 2  ·  Гости";
                    case EveningId.Three: return "Вечер 3  ·  Дождь";
                    default: return "Вечер";
                }
            }
        }

        public string RuGoal
        {
            get
            {
                switch (Current)
                {
                    case EveningId.One: return "Поставьте уютную вещь и наберите 20 уюта.";
                    case EveningId.Two: return "Примите гостя — отгадайте загадку.";
                    case EveningId.Three: return "Дождь. Укройте город очагом или фонарём и держите уют.";
                    default: return "";
                }
            }
        }

        void Awake()
        {
            I = this;
            Current = GameFlow.PendingEvening;
            if (Current < EveningId.One) Current = EveningId.One;
            if (Current > EveningId.Three) Current = EveningId.Three;
        }

        public void Build(Transform canvas)
        {
            _banner = UiKit.Panel(canvas, "EveningBanner", new Color(0.28f, 0.16f, 0.08f, 0.94f));
            UiKit.Stretch(_banner.rectTransform, new Vector2(0.08f, 0.62f), new Vector2(0.92f, 0.78f), Vector2.zero, Vector2.zero);
            _bannerText = UiKit.Label(_banner.transform, "T", RuTitle + "\n" + RuGoal, 26,
                new Color(0.98f, 0.9f, 0.72f), TextAnchor.MiddleCenter);
            _bannerText.horizontalOverflow = HorizontalWrapMode.Wrap;
            UiKit.Stroke(_bannerText.gameObject, new Color(0.15f, 0.08f, 0.04f, 0.7f));
            _bannerLeft = 4.6f;

            _goalText = UiKit.Label(canvas, "EveningGoal", RuTitle, 18,
                new Color(0.95f, 0.84f, 0.58f, 0.95f), TextAnchor.MiddleRight);
            UiKit.Stretch(_goalText.rectTransform, new Vector2(0.42f, 1f), new Vector2(0.98f, 1f),
                new Vector2(0f, -168f), new Vector2(-16f, -132f));
            UiKit.Stroke(_goalText.gameObject, new Color(0f, 0f, 0f, 0.55f));

            _donePanel = UiKit.Panel(canvas, "EveningDone", new Color(0.18f, 0.1f, 0.05f, 0.94f));
            UiKit.Stretch(_donePanel.rectTransform, new Vector2(0.1f, 0.34f), new Vector2(0.9f, 0.66f), Vector2.zero, Vector2.zero);
            UiKit.Label(_donePanel.transform, "D", "Вечер окончен", 28, new Color(0.98f, 0.9f, 0.7f), TextAnchor.UpperCenter);
            var next = UiKit.Btn(_donePanel.transform, "Next", "Дальше",
                new Color(0.72f, 0.42f, 0.16f, 1f), new Color(0.98f, 0.92f, 0.78f), 24);
            UiKit.Stretch(next.GetComponent<RectTransform>(), new Vector2(0.18f, 0.12f), new Vector2(0.82f, 0.42f), Vector2.zero, Vector2.zero);
            next.onClick.AddListener(Advance);
            _donePanel.gameObject.SetActive(false);

            if (CozySystem.I != null) CozySystem.I.ApplyEveningUnlocks(Current);
            Persist();
            RefreshGoal();
        }

        public void NotifyCozyPlaced()
        {
            CozyPlaced = true;
            Check();
        }

        public void NotifyGuest()
        {
            GuestAccepted = true;
            Check();
        }

        void Update()
        {
            _age += Time.deltaTime;
            if (_banner != null && _bannerLeft > 0f)
            {
                _bannerLeft -= Time.deltaTime;
                if (_bannerLeft <= 0f) _banner.gameObject.SetActive(false);
            }

            if (Current == EveningId.Three && !_rainForced && _age > 10f)
            {
                _rainForced = true;
                if (Game.Weather != null) Game.Weather.ForceRain(48f);
            }

            if (!Completed) Check();
            RefreshGoal();
        }

        void Check()
        {
            if (Completed) return;
            bool ok = false;
            float u = CozySystem.I != null ? CozySystem.I.Value : 0f;
            switch (Current)
            {
                case EveningId.One:
                    ok = CozyPlaced && u >= 20f;
                    break;
                case EveningId.Two:
                    ok = GuestAccepted;
                    break;
                case EveningId.Three:
                    bool shelter = CozySystem.I != null && (CozySystem.I.HearthCount > 0 || CozySystem.I.LanternCount > 0);
                    ok = shelter && u >= 28f && _rainForced;
                    break;
            }
            if (!ok) return;
            Completed = true;
            if (_donePanel != null) _donePanel.gameObject.SetActive(true);
            if (Game.Hud != null) Game.Hud.SetHint("Вечер окончен. Город стал тише.");
        }

        void Advance()
        {
            if (_donePanel != null) _donePanel.gameObject.SetActive(false);
            if (Current >= EveningId.Three)
            {
                if (Game.Hud != null) Game.Hud.SetHint("Город уютный. Можно жить дальше — гости ещё придут.");
                Persist();
                return;
            }
            Current = (EveningId)((int)Current + 1);
            Completed = false;
            GuestAccepted = false;
            _age = 0f;
            _rainForced = false;
            _bannerLeft = 4.6f;
            if (_banner != null)
            {
                _banner.gameObject.SetActive(true);
                if (_bannerText != null) _bannerText.text = RuTitle + "\n" + RuGoal;
            }
            if (CozySystem.I != null) CozySystem.I.ApplyEveningUnlocks(Current);
            if (Game.Hud != null)
            {
                Game.Hud.SetHint(RuGoal);
                Game.Hud.RefreshCozyTray();
            }
            Persist();
            RefreshGoal();
        }

        void RefreshGoal()
        {
            if (_goalText == null) return;
            string extra = "";
            if (CozySystem.I != null) extra = "   уют " + Mathf.FloorToInt(CozySystem.I.Value);
            _goalText.text = RuTitle + extra;
        }

        void Persist()
        {
            PlayerPrefs.SetInt("tg.evening", (int)Current);
            PlayerPrefs.SetInt("tg.continue", 1);
            PlayerPrefs.Save();
        }
    }
}
