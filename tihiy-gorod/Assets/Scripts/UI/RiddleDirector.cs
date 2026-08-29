using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace TihiyGorod
{
    public sealed class RiddleVisitor
    {
        public string File;
        public string RuName;
        public string Line;
        public string Riddle;
        public string[] Answers;
        public int Correct;
        public AlignmentType Align;
        public CozyId Unlock;
        public ResourceType Gift;
    }

    public sealed class RiddleDirector : MonoBehaviour
    {
        public static RiddleDirector I { get; private set; }

        public bool IsOpen { get; private set; }

        Image _root;
        Image _portrait;
        Text _name;
        Text _line;
        Text _riddle;
        Button[] _answers;
        Text[] _answerCaps;
        Text _result;
        float _age;
        float _nextIn = 45f;
        bool _first = true;
        bool _answersReady;
        bool _resolved;
        RiddleVisitor _current;
        int _shownMask;
        float _openTime;

        static readonly RiddleVisitor[] Visitors =
        {
            new RiddleVisitor
            {
                File = "riddle-hearth.png",
                RuName = "Бабушка у очага",
                Line = "Сядь ближе к огню, дитятко. Загадку старую загадаю — как в нашей избе.",
                Riddle = "Зимой греет, весной тлеет, летом молчит, а к осени снова дышит. Что это?",
                Answers = new[] { "Очаг", "Солнце", "Самовар" },
                Correct = 0,
                Align = AlignmentType.Good,
                Unlock = CozyId.Bookshelf,
                Gift = ResourceType.Light
            },
            new RiddleVisitor
            {
                File = "riddle-liat.png",
                RuName = "Эльфийка Лиат",
                Line = "Я из леса, где шапки красные. Отгадай — и сказка останется в доме.",
                Riddle = "Стоит Антошка на одной ножке. Маленький, удаленький, сквозь землю прошёл, красную шапочку нашёл.",
                Answers = new[] { "Гриб", "Метла", "Свеча" },
                Correct = 0,
                Align = AlignmentType.Fairy,
                Unlock = CozyId.MusicBox,
                Gift = ResourceType.FairyDust
            },
            new RiddleVisitor
            {
                File = "riddle-blood.png",
                RuName = "Купец крови",
                Line = "Товар мой тих, цена — загадка. Угадаешь — возьмёшь гостинец. Не угадаешь — всё равно оставлю мелочь.",
                Riddle = "Сидит дед, во сто шуб одет. Кто его раздевает, тот слёзы проливает.",
                Answers = new[] { "Капуста", "Лук", "Мешок с монетами" },
                Correct = 1,
                Align = AlignmentType.Dark,
                Unlock = CozyId.SleepingCat,
                Gift = ResourceType.Shadow
            },
            new RiddleVisitor
            {
                File = "riddle-shadow.png",
                RuName = "Теневой сосед",
                Line = "Я живу за стеной. Ночь слушает нас. Отгадай — и тень станет мягче.",
                Riddle = "Чёрная корова всех людей поборола, а белая встала — всех подняла.",
                Answers = new[] { "Ночь и день", "Туча и снег", "Зола и мука" },
                Correct = 0,
                Align = AlignmentType.Arcane,
                Unlock = CozyId.Curtain,
                Gift = ResourceType.Essence
            }
        };

        void Awake()
        {
            I = this;
        }

        public void Build(Transform canvas)
        {
            _root = UiKit.Panel(canvas, "RiddleRoot", new Color(0.12f, 0.07f, 0.04f, 0.96f));
            UiKit.Stretch(_root.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

            _portrait = UiKit.Panel(_root.transform, "Portrait", new Color(0.3f, 0.18f, 0.1f, 1f));
            UiKit.Stretch(_portrait.rectTransform, new Vector2(0.08f, 0.52f), new Vector2(0.92f, 0.96f), Vector2.zero, Vector2.zero);
            _portrait.preserveAspect = true;

            _name = UiKit.Label(_root.transform, "Name", "", 30, new Color(0.98f, 0.88f, 0.64f), TextAnchor.MiddleCenter);
            UiKit.Stretch(_name.rectTransform, new Vector2(0.06f, 0.46f), new Vector2(0.94f, 0.54f), Vector2.zero, Vector2.zero);

            _line = UiKit.Label(_root.transform, "Line", "", 20, new Color(0.93f, 0.84f, 0.7f), TextAnchor.UpperCenter);
            UiKit.Stretch(_line.rectTransform, new Vector2(0.08f, 0.38f), new Vector2(0.92f, 0.47f), Vector2.zero, Vector2.zero);
            _line.horizontalOverflow = HorizontalWrapMode.Wrap;
            _line.verticalOverflow = VerticalWrapMode.Overflow;

            _riddle = UiKit.Label(_root.transform, "Riddle", "", 22, new Color(0.98f, 0.92f, 0.78f), TextAnchor.UpperCenter);
            UiKit.Stretch(_riddle.rectTransform, new Vector2(0.08f, 0.26f), new Vector2(0.92f, 0.39f), Vector2.zero, Vector2.zero);
            _riddle.horizontalOverflow = HorizontalWrapMode.Wrap;
            _riddle.verticalOverflow = VerticalWrapMode.Overflow;

            _answers = new Button[3];
            _answerCaps = new Text[3];
            for (int i = 0; i < 3; i++)
            {
                var b = UiKit.Btn(_root.transform, "A" + i, "", new Color(0.55f, 0.32f, 0.14f, 1f),
                    new Color(0.98f, 0.92f, 0.78f), 22);
                float y1 = 0.24f - i * 0.07f;
                float y0 = y1 - 0.065f;
                UiKit.Stretch(b.GetComponent<RectTransform>(), new Vector2(0.1f, y0), new Vector2(0.9f, y1), Vector2.zero, Vector2.zero);
                _answers[i] = b;
                _answerCaps[i] = b.GetComponentInChildren<Text>();
                int captured = i;
                b.onClick.AddListener(() => OnAnswer(captured));
            }

            _result = UiKit.Label(_root.transform, "Result", "", 22, new Color(0.95f, 0.86f, 0.6f), TextAnchor.MiddleCenter);
            UiKit.Stretch(_result.rectTransform, new Vector2(0.08f, 0.015f), new Vector2(0.92f, 0.07f), Vector2.zero, Vector2.zero);
            _result.horizontalOverflow = HorizontalWrapMode.Wrap;

            _root.gameObject.SetActive(false);
        }

        void Update()
        {
            if (Game.Time == null) return;
            var ev = EveningSystem.I;
            if (ev == null || ev.Current < EveningId.Two) return;

            if (IsOpen)
            {
                if (!_answersReady && Time.unscaledTime - _openTime >= 1.35f)
                {
                    _answersReady = true;
                    SetAnswersVisible(true);
                }
                return;
            }

            _age += Time.deltaTime;
            if (_age < _nextIn) return;
            OpenNext();
        }

        void OpenNext()
        {
            _current = Pick();
            if (_current == null) return;
            IsOpen = true;
            _resolved = false;
            _answersReady = false;
            _openTime = Time.unscaledTime;
            _age = 0f;
            _nextIn = 90f;
            _first = false;

            _name.text = _current.RuName;
            _line.text = _current.Line;
            _riddle.text = _current.Riddle;
            _result.text = "Подождите… гость ещё говорит.";
            for (int i = 0; i < 3; i++)
                if (_answerCaps[i] != null) _answerCaps[i].text = _current.Answers[i];
            SetAnswersVisible(false);
            _root.gameObject.SetActive(true);

            StartCoroutine(ArtLoader.LoadPngRoutine(_current.File, tex =>
            {
                if (_portrait != null && tex != null)
                {
                    _portrait.sprite = ArtLoader.AsSprite(tex);
                    _portrait.color = Color.white;
                    _portrait.preserveAspect = true;
                }
            }));
        }

        RiddleVisitor Pick()
        {
            AlignmentType prefer = AlignmentType.Good;
            float best = -1f;
            if (Game.Align != null)
            {
                for (int i = 1; i <= 4; i++)
                {
                    float inf = Game.Align.Influence((AlignmentType)i);
                    if (inf > best) { best = inf; prefer = (AlignmentType)i; }
                }
            }

            RiddleVisitor chosen = null;
            for (int i = 0; i < Visitors.Length; i++)
            {
                if (Visitors[i].Align == prefer && (_shownMask & (1 << i)) == 0)
                {
                    chosen = Visitors[i];
                    _shownMask |= 1 << i;
                    break;
                }
            }
            if (chosen == null)
            {
                for (int i = 0; i < Visitors.Length; i++)
                {
                    if ((_shownMask & (1 << i)) == 0)
                    {
                        chosen = Visitors[i];
                        _shownMask |= 1 << i;
                        break;
                    }
                }
            }
            if (chosen == null)
            {
                _shownMask = 0;
                chosen = Visitors[Random.Range(0, Visitors.Length)];
            }
            return chosen;
        }

        void SetAnswersVisible(bool on)
        {
            if (_answers == null) return;
            for (int i = 0; i < _answers.Length; i++)
                if (_answers[i] != null) _answers[i].gameObject.SetActive(on);
            if (on && _result != null) _result.text = "";
        }

        void OnAnswer(int index)
        {
            if (!IsOpen || _resolved || !_answersReady || _current == null) return;
            _resolved = true;
            bool ok = index == _current.Correct;
            if (ok)
            {
                _result.text = "Верно. В доме стало тише и светлее.";
                if (CozySystem.I != null)
                {
                    CozySystem.I.AddInstant(10f);
                    if (_current.Unlock != CozyId.None) CozySystem.I.Unlock(_current.Unlock);
                }
                if (ResourceSystem.I != null) ResourceSystem.I.Add(_current.Gift, 8f);
                if (Game.Hud != null) Game.Hud.RefreshCozyTray();
                if (Game.Audio != null) Game.Audio.PlayChime(true);
            }
            else
            {
                _result.text = "Не беда. Вот тебе гостинчик — всё равно тепло.";
                if (CozySystem.I != null) CozySystem.I.AddInstant(3.5f);
                if (ResourceSystem.I != null) ResourceSystem.I.Add(_current.Gift, 3f);
                if (Game.Audio != null) Game.Audio.PlayChime(false);
            }
            if (EveningSystem.I != null) EveningSystem.I.NotifyGuest();
            Invoke("Close", 2.2f);
        }

        void Close()
        {
            IsOpen = false;
            _current = null;
            if (_root != null) _root.gameObject.SetActive(false);
            _nextIn = _first ? 45f : 90f;
            _age = 0f;
        }
    }
}
