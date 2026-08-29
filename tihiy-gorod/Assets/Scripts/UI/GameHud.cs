using UnityEngine;
using UnityEngine.UI;

namespace TihiyGorod
{
    public sealed class GameHud : MonoBehaviour
    {
        public enum TrayTab { Buildings, Cozy }

        Text[] _res;
        Text _clock;
        Text _hint;
        Text _info;
        Text _ujutLabel;
        Image _ujutFill;
        Image _picker;
        Image _infoPanel;
        BuildingId[] _trayIds;
        Image[] _trayBg;
        Image[] _alignBg;
        AlignmentType[] _alignIds;
        Button _upgradeAlign;
        Button _upgradeBld;
        Text _upgradeAlignCap;
        Text _upgradeBldCap;
        GameObject _alignRow;
        GameObject _buildGrid;
        GameObject _cozyGrid;
        Image _tabBuild;
        Image _tabCozy;
        CozyId[] _cozyIds;
        Image[] _cozyBg;
        public TrayTab Tab { get; private set; }

        public void Build(Transform canvas)
        {
            Game.Hud = this;
            BuildTop(canvas);
            BuildBottom(canvas);
            BuildInfo(canvas);
            BuildPicker(canvas);
            if (ResourceSystem.I != null) ResourceSystem.I.Changed += RefreshResources;
            if (Game.Place != null) Game.Place.SelectionChanged += RefreshSelection;
            if (Game.Align != null) Game.Align.Changed += RefreshAlign;
            if (CozySystem.I != null) CozySystem.I.Changed += RefreshUjut;
            RefreshResources();
            RefreshSelection();
            RefreshAlign();
            RefreshUjut();
            RefreshCozyTray();
        }

        public void SetHint(string s)
        {
            if (_hint != null) _hint.text = s;
        }

        void BuildTop(Transform canvas)
        {
            var bar = UiKit.Panel(canvas, "TopBar", Palette.WoodBg);
            UiKit.Stretch(bar.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(8f, -128f), new Vector2(-8f, -8f));

            var types = ResourceNames.All;
            _res = new Text[types.Length];
            float w = 1f / types.Length;
            for (int i = 0; i < types.Length; i++)
            {
                var slot = UiKit.Panel(bar.transform, types[i].ToString(), new Color(0.12f, 0.07f, 0.04f, 0.45f));
                UiKit.Stretch(slot.rectTransform, new Vector2(i * w, 0.46f), new Vector2((i + 1) * w, 1f), new Vector2(4f, 4f), new Vector2(-4f, -4f));
                var accent = UiKit.Panel(slot.transform, "A", Palette.Resource(types[i]));
                UiKit.Stretch(accent.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 1f), new Vector2(0f, 6f), new Vector2(6f, -6f));
                _res[i] = UiKit.Label(slot.transform, "T", ResourceNames.Ru(types[i]) + "\n0", 18, Palette.Paper, TextAnchor.MiddleCenter);
            }

            var clockBg = UiKit.Panel(bar.transform, "Clock", new Color(0.2f, 0.12f, 0.06f, 0.9f));
            UiKit.Stretch(clockBg.rectTransform, new Vector2(0f, 0f), new Vector2(0.38f, 0.46f), new Vector2(4f, 4f), new Vector2(-4f, -2f));
            _clock = UiKit.Label(clockBg.transform, "C", "12:00  день   ясно", 18, Palette.Paper, TextAnchor.MiddleLeft);
            _clock.rectTransform.offsetMin = new Vector2(12f, 0f);

            var ujutBg = UiKit.Panel(bar.transform, "Ujut", new Color(0.22f, 0.12f, 0.06f, 0.92f));
            UiKit.Stretch(ujutBg.rectTransform, new Vector2(0.38f, 0f), new Vector2(0.68f, 0.46f), new Vector2(4f, 4f), new Vector2(-4f, -2f));
            var icon = UiKit.Panel(ujutBg.transform, "Icon", Color.white);
            icon.sprite = ArtLoader.HearthIcon();
            icon.preserveAspect = true;
            icon.raycastTarget = false;
            UiKit.Stretch(icon.rectTransform, new Vector2(0f, 0.1f), new Vector2(0.22f, 0.9f), new Vector2(4f, 0f), new Vector2(0f, 0f));
            var track = UiKit.Panel(ujutBg.transform, "Track", new Color(0.12f, 0.07f, 0.04f, 0.9f));
            UiKit.Stretch(track.rectTransform, new Vector2(0.22f, 0.18f), new Vector2(0.98f, 0.52f), new Vector2(4f, 0f), new Vector2(-8f, 0f));
            _ujutFill = UiKit.Panel(track.transform, "Fill", Palette.Hearth);
            UiKit.Stretch(_ujutFill.rectTransform, new Vector2(0f, 0f), new Vector2(0.4f, 1f), Vector2.zero, Vector2.zero);
            _ujutLabel = UiKit.Label(ujutBg.transform, "UL", "Уют  8", 16, Palette.Paper, TextAnchor.MiddleLeft);
            UiKit.Stretch(_ujutLabel.rectTransform, new Vector2(0.24f, 0.48f), new Vector2(1f, 1f), Vector2.zero, Vector2.zero);

            var rain = UiKit.Btn(bar.transform, "Rain", "Дождь", new Color(0.42f, 0.32f, 0.22f, 0.95f), Palette.Paper, 22);
            UiKit.Stretch(rain.GetComponent<RectTransform>(), new Vector2(0.68f, 0f), new Vector2(1f, 0.46f), new Vector2(4f, 4f), new Vector2(-4f, -2f));
            rain.onClick.AddListener(() => { if (Game.Weather != null) Game.Weather.ToggleRain(); });

            _hint = UiKit.Label(canvas, "Hint", "Выберите путь города. Постройки и уют — внизу. Жители ходят сами.", 20, new Color(1f, 0.95f, 0.82f, 0.94f), TextAnchor.UpperCenter);
            UiKit.Stretch(_hint.rectTransform, new Vector2(0.04f, 1f), new Vector2(0.96f, 1f), new Vector2(0f, -176f), new Vector2(0f, -130f));
            UiKit.Stroke(_hint.gameObject, new Color(0.12f, 0.06f, 0.02f, 0.7f));
        }

        void BuildBottom(Transform canvas)
        {
            var tray = UiKit.Panel(canvas, "Tray", Palette.WoodDeep);
            UiKit.Stretch(tray.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(8f, 8f), new Vector2(-8f, 252f));

            _tabBuild = UiKit.Btn(tray.transform, "TabBuild", "Постройки", Palette.Amber, Palette.Paper, 22).GetComponent<Image>();
            UiKit.Stretch(_tabBuild.rectTransform, new Vector2(0f, 0.86f), new Vector2(0.5f, 1f), new Vector2(6f, 4f), new Vector2(-3f, -4f));
            _tabBuild.GetComponent<Button>().onClick.AddListener(() => SetTab(TrayTab.Buildings));

            _tabCozy = UiKit.Btn(tray.transform, "TabCozy", "Уют", new Color(0.38f, 0.22f, 0.1f, 0.95f), Palette.Paper, 22).GetComponent<Image>();
            UiKit.Stretch(_tabCozy.rectTransform, new Vector2(0.5f, 0.86f), new Vector2(1f, 1f), new Vector2(3f, 4f), new Vector2(-6f, -4f));
            _tabCozy.GetComponent<Button>().onClick.AddListener(() => SetTab(TrayTab.Cozy));

            _alignRow = UiKit.Panel(tray.transform, "AlignRow", new Color(0f, 0f, 0f, 0.12f)).gameObject;
            UiKit.Stretch(_alignRow.GetComponent<RectTransform>(), new Vector2(0f, 0.68f), new Vector2(1f, 0.86f), new Vector2(6f, 2f), new Vector2(-6f, -2f));

            _alignIds = AlignmentNames.Playable;
            _alignBg = new Image[_alignIds.Length];
            for (int i = 0; i < _alignIds.Length; i++)
            {
                var al = _alignIds[i];
                var col = Color.Lerp(Palette.Alignment(al), new Color(0.22f, 0.14f, 0.08f), 0.45f);
                col.a = 0.95f;
                var b = UiKit.Btn(_alignRow.transform, al.ToString(), AlignmentNames.Ru(al) + " I", col, Palette.Paper, 20);
                float x0 = i / 5f;
                float x1 = (i + 1) / 5f;
                UiKit.Stretch(b.GetComponent<RectTransform>(), new Vector2(x0, 0f), new Vector2(x1, 1f), new Vector2(3f, 3f), new Vector2(-3f, -3f));
                _alignBg[i] = b.GetComponent<Image>();
                var captured = al;
                b.onClick.AddListener(() => OnAlignTap(captured));
            }

            _upgradeAlign = UiKit.Btn(_alignRow.transform, "UpA", "Путь ↑", new Color(0.42f, 0.28f, 0.14f, 0.95f), new Color(1f, 0.92f, 0.7f), 18);
            UiKit.Stretch(_upgradeAlign.GetComponent<RectTransform>(), new Vector2(0.8f, 0f), new Vector2(1f, 1f), new Vector2(3f, 3f), new Vector2(-3f, -3f));
            _upgradeAlignCap = _upgradeAlign.GetComponentInChildren<Text>();
            _upgradeAlign.onClick.AddListener(OnUpgradeAlign);

            _buildGrid = UiKit.Panel(tray.transform, "BuildGrid", Color.clear).gameObject;
            _buildGrid.GetComponent<Image>().raycastTarget = false;
            UiKit.Stretch(_buildGrid.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0.68f), new Vector2(6f, 4f), new Vector2(-6f, -2f));

            var defs = BuildingCatalog.All;
            _trayIds = new BuildingId[defs.Length];
            _trayBg = new Image[defs.Length];
            for (int i = 0; i < defs.Length; i++)
            {
                _trayIds[i] = defs[i].Id;
                int row = i / 4;
                int col = i % 4;
                float x0 = col / 4f;
                float x1 = (col + 1) / 4f;
                float y0 = row == 1 ? 0f : 0.5f;
                float y1 = row == 1 ? 0.5f : 1f;
                var bg = Color.Lerp(Palette.Alignment(defs[i].Alignment), new Color(0.18f, 0.1f, 0.06f), 0.5f);
                bg.a = 0.95f;
                string cap = defs[i].RuName + "\n" + ShortCost(defs[i].Cost);
                var b = UiKit.Btn(_buildGrid.transform, defs[i].Id.ToString(), cap, bg, Palette.Paper, 16);
                UiKit.Stretch(b.GetComponent<RectTransform>(), new Vector2(x0, y0), new Vector2(x1, y1), new Vector2(3f, 3f), new Vector2(-3f, -3f));
                _trayBg[i] = b.GetComponent<Image>();
                var id = defs[i].Id;
                b.onClick.AddListener(() => OnBuildTap(id));
            }

            _cozyGrid = UiKit.Panel(tray.transform, "CozyGrid", Color.clear).gameObject;
            _cozyGrid.GetComponent<Image>().raycastTarget = false;
            UiKit.Stretch(_cozyGrid.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0.86f), new Vector2(6f, 4f), new Vector2(-6f, -2f));

            var cozy = CozyCatalog.All;
            _cozyIds = new CozyId[cozy.Length];
            _cozyBg = new Image[cozy.Length];
            for (int i = 0; i < cozy.Length; i++)
            {
                _cozyIds[i] = cozy[i].Id;
                int row = i / 3;
                int col = i % 3;
                float x0 = col / 3f;
                float x1 = (col + 1) / 3f;
                float y1 = 1f - row / 3f;
                float y0 = y1 - 1f / 3f;
                var bg = Color.Lerp(Palette.Amber, new Color(0.22f, 0.12f, 0.06f), 0.45f);
                bg.a = 0.95f;
                string cap = cozy[i].RuName + "\n" + ShortCost(cozy[i].Cost);
                var b = UiKit.Btn(_cozyGrid.transform, cozy[i].Id.ToString(), cap, bg, Palette.Paper, 16);
                UiKit.Stretch(b.GetComponent<RectTransform>(), new Vector2(x0, y0), new Vector2(x1, y1), new Vector2(3f, 3f), new Vector2(-3f, -3f));
                _cozyBg[i] = b.GetComponent<Image>();
                var id = cozy[i].Id;
                b.onClick.AddListener(() => OnCozyTap(id));
            }

            SetTab(TrayTab.Buildings);
        }

        void BuildInfo(Transform canvas)
        {
            _infoPanel = UiKit.Panel(canvas, "Info", new Color(0.22f, 0.13f, 0.07f, 0.92f));
            UiKit.Stretch(_infoPanel.rectTransform, new Vector2(0.08f, 0.34f), new Vector2(0.92f, 0.52f), Vector2.zero, Vector2.zero);
            _info = UiKit.Label(_infoPanel.transform, "I", "", 20, Palette.Paper, TextAnchor.UpperLeft);
            var ir = _info.rectTransform;
            ir.offsetMin = new Vector2(16f, 56f);
            ir.offsetMax = new Vector2(-16f, -12f);
            _info.horizontalOverflow = HorizontalWrapMode.Wrap;
            _info.verticalOverflow = VerticalWrapMode.Overflow;

            _upgradeBld = UiKit.Btn(_infoPanel.transform, "UpB", "Улучшить", new Color(0.42f, 0.5f, 0.28f, 1f), Palette.Paper, 22);
            UiKit.Stretch(_upgradeBld.GetComponent<RectTransform>(), new Vector2(0.02f, 0.06f), new Vector2(0.62f, 0.42f), Vector2.zero, Vector2.zero);
            _upgradeBldCap = _upgradeBld.GetComponentInChildren<Text>();
            _upgradeBld.onClick.AddListener(OnUpgradeBuilding);

            var close = UiKit.Btn(_infoPanel.transform, "X", "Закрыть", new Color(0.42f, 0.22f, 0.16f, 1f), Palette.Paper, 20);
            UiKit.Stretch(close.GetComponent<RectTransform>(), new Vector2(0.64f, 0.06f), new Vector2(0.98f, 0.42f), Vector2.zero, Vector2.zero);
            close.onClick.AddListener(() =>
            {
                if (Game.Place != null) Game.Place.ClearSelection();
            });
            _infoPanel.gameObject.SetActive(false);
        }

        void BuildPicker(Transform canvas)
        {
            _picker = UiKit.Panel(canvas, "Picker", new Color(0.16f, 0.09f, 0.04f, 0.9f));
            UiKit.Stretch(_picker.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

            var title = UiKit.Label(_picker.transform, "T", "Тихий город\nВыберите путь", 36, Palette.Paper, TextAnchor.MiddleCenter);
            UiKit.Stretch(title.rectTransform, new Vector2(0.05f, 0.72f), new Vector2(0.95f, 0.95f), Vector2.zero, Vector2.zero);

            var playable = AlignmentNames.Playable;
            for (int i = 0; i < playable.Length; i++)
            {
                var al = playable[i];
                var col = Color.Lerp(Palette.Alignment(al), new Color(0.2f, 0.12f, 0.06f), 0.28f);
                col.a = 1f;
                string cap = AlignmentNames.Ru(al) + "\n" + AlignmentNames.Hint(al);
                var b = UiKit.Btn(_picker.transform, al.ToString(), cap, col, Palette.Paper, 22);
                float y1 = 0.70f - i * 0.14f;
                float y0 = y1 - 0.13f;
                UiKit.Stretch(b.GetComponent<RectTransform>(), new Vector2(0.12f, y0), new Vector2(0.88f, y1), Vector2.zero, Vector2.zero);
                var captured = al;
                b.onClick.AddListener(() =>
                {
                    if (Game.Align != null) Game.Align.ChoosePrimary(captured);
                    _picker.gameObject.SetActive(false);
                    if (_hint != null)
                        _hint.text = "Ставьте дома и уют. Вкладка «Уют» — очаг, самовар, плед. Жители сами присядут.";
                    RefreshAlign();
                });
            }
        }

        void SetTab(TrayTab tab)
        {
            Tab = tab;
            if (_buildGrid != null) _buildGrid.SetActive(tab == TrayTab.Buildings);
            if (_alignRow != null) _alignRow.SetActive(tab == TrayTab.Buildings);
            if (_cozyGrid != null) _cozyGrid.SetActive(tab == TrayTab.Cozy);
            if (_tabBuild != null) _tabBuild.color = tab == TrayTab.Buildings ? Palette.Amber : new Color(0.32f, 0.2f, 0.1f, 0.95f);
            if (_tabCozy != null) _tabCozy.color = tab == TrayTab.Cozy ? Palette.Amber : new Color(0.32f, 0.2f, 0.1f, 0.95f);
            if (Game.Place != null) Game.Place.ClearSelection();
            if (tab == TrayTab.Cozy && _hint != null)
                _hint.text = "Уютные вещи: на клетку или как пристройка к дому. Занавеска — только на здание.";
        }

        static string ShortCost(ResourceCost c)
        {
            if (c.Wood > 0) return (int)c.Wood + " дер.  " + (int)c.Stone + " кам.";
            if (c.Stone > 0) return (int)c.Stone + " кам.";
            return c.RuLine();
        }

        void OnBuildTap(BuildingId id)
        {
            if (Game.Place == null) return;
            if (Game.Place.Selected == id) Game.Place.ClearSelection();
            else Game.Place.SelectType(id);
            var def = BuildingCatalog.Get(id);
            if (def != null && _hint != null)
                _hint.text = def.RuName + " — " + def.RuDesc + "  Стоимость: " + def.Cost.RuLine();
        }

        void OnCozyTap(CozyId id)
        {
            if (Game.Place == null) return;
            if (CozySystem.I != null && !CozySystem.I.IsUnlocked(id))
            {
                if (_hint != null) _hint.text = "Ещё не открыто. Гость с загадкой может принести это.";
                return;
            }
            if (Game.Place.SelectedCozy == id) Game.Place.ClearSelection();
            else Game.Place.SelectCozy(id);
            var def = CozyCatalog.Get(id);
            if (def != null && _hint != null)
                _hint.text = def.RuName + " — " + def.RuDesc + "  " + def.Cost.RuLine();
            RefreshCozyTray();
        }

        void OnAlignTap(AlignmentType t)
        {
            if (Game.Align == null) return;
            if (!Game.Align.HasChosen) Game.Align.ChoosePrimary(t);
            if (_hint != null)
            {
                int tier = Game.Align.TierOf(t);
                _hint.text = AlignmentNames.Ru(t) + "  уровень " + Roman(tier) + ". " + AlignmentNames.Hint(t) +
                             "  Улучшение: " + Game.Align.UpgradeCost(t, tier + 1).RuLine();
            }
        }

        void OnUpgradeAlign()
        {
            if (Game.Align == null || !Game.Align.HasChosen) return;
            var t = Game.Align.Primary;
            if (Game.Align.TryUpgrade(t))
            {
                if (_hint != null) _hint.text = AlignmentNames.Ru(t) + " теперь " + Roman(Game.Align.TierOf(t)) + ".";
            }
            else if (_hint != null) _hint.text = "Не хватает ресурсов: " + Game.Align.UpgradeCost(t, Game.Align.TierOf(t) + 1).RuLine();
            RefreshAlign();
        }

        void OnUpgradeBuilding()
        {
            var b = Game.Place != null ? Game.Place.SelectedBuilding : null;
            if (b == null) return;
            if (b.TryUpgrade())
            {
                if (Game.Audio != null) Game.Audio.PlayPlace();
                RefreshSelection();
            }
            else if (_hint != null)
                _hint.text = b.Level >= SimConfig.MaxBuildingLevel ? "Максимум." : "Нужно: " + b.UpgradeCost().RuLine();
        }

        void Update()
        {
            if (_clock != null && Game.Time != null && Game.Weather != null)
                _clock.text = "  " + Game.Time.RuClock + "    " + Game.Weather.RuLabel;
            RefreshUjutVisual();
        }

        void RefreshResources()
        {
            if (_res == null || ResourceSystem.I == null) return;
            var types = ResourceNames.All;
            for (int i = 0; i < types.Length && i < _res.Length; i++)
            {
                _res[i].text = ResourceNames.Ru(types[i]) + "\n" + ResourceSystem.I.GetInt(types[i]);
            }
        }

        void RefreshUjut()
        {
            RefreshUjutVisual();
            RefreshCozyTray();
        }

        void RefreshUjutVisual()
        {
            if (CozySystem.I == null) return;
            float v = CozySystem.I.Value;
            if (_ujutLabel != null) _ujutLabel.text = "Уют  " + Mathf.FloorToInt(v);
            if (_ujutFill != null)
            {
                var rt = _ujutFill.rectTransform;
                rt.anchorMin = Vector2.zero;
                rt.anchorMax = new Vector2(Mathf.Clamp01(v / 100f), 1f);
                rt.offsetMin = Vector2.zero;
                rt.offsetMax = Vector2.zero;
            }
        }

        public void RefreshCozyTray()
        {
            if (_cozyBg == null) return;
            for (int i = 0; i < _cozyBg.Length; i++)
            {
                bool open = CozySystem.I == null || CozySystem.I.IsUnlocked(_cozyIds[i]);
                var cap = _cozyBg[i].GetComponentInChildren<Text>();
                var def = CozyCatalog.Get(_cozyIds[i]);
                if (cap != null && def != null)
                    cap.text = open ? (def.RuName + "\n" + ShortCost(def.Cost)) : (def.RuName + "\nещё закрыто");
                var c = _cozyBg[i].color;
                c.a = open ? 0.95f : 0.4f;
                _cozyBg[i].color = c;
                bool on = Game.Place != null && Game.Place.SelectedCozy == _cozyIds[i];
                _cozyBg[i].transform.localScale = on ? Vector3.one * 1.04f : Vector3.one;
            }
        }

        void RefreshSelection()
        {
            if (Game.Place == null) return;
            if (_trayBg != null)
            {
                for (int i = 0; i < _trayBg.Length; i++)
                {
                    bool on = Game.Place.Selected == _trayIds[i];
                    _trayBg[i].transform.localScale = on ? Vector3.one * 1.04f : Vector3.one;
                }
            }
            RefreshCozyTray();

            var b = Game.Place.SelectedBuilding;
            if (_infoPanel != null)
            {
                bool show = b != null;
                _infoPanel.gameObject.SetActive(show);
                if (show)
                {
                    string syn = b.NeighborMix == SynergyKind.None ? "нет" : SynergyNames.Ru(b.NeighborMix);
                    _info.text = b.Def.RuName + "  ур. " + b.Level + "  ·  " + AlignmentNames.Ru(b.Def.Alignment) +
                                 "\n" + b.Def.RuDesc + "\nСоседство: " + syn;
                    if (_upgradeBldCap != null)
                    {
                        if (b.Level >= SimConfig.MaxBuildingLevel) _upgradeBldCap.text = "Максимум";
                        else _upgradeBldCap.text = "Улучшить  " + b.UpgradeCost().RuLine();
                    }
                }
            }
        }

        void RefreshAlign()
        {
            if (Game.Align == null || _alignBg == null) return;
            for (int i = 0; i < _alignIds.Length; i++)
            {
                var t = _alignIds[i];
                int tier = Game.Align.TierOf(t);
                var cap = _alignBg[i].GetComponentInChildren<Text>();
                if (cap != null) cap.text = AlignmentNames.Ru(t) + " " + Roman(tier);
                bool prim = Game.Align.HasChosen && Game.Align.Primary == t;
                _alignBg[i].transform.localScale = prim ? Vector3.one * 1.05f : Vector3.one;
            }
            if (_upgradeAlignCap != null && Game.Align.HasChosen)
            {
                int next = Game.Align.TierOf(Game.Align.Primary) + 1;
                if (next > SimConfig.MaxAlignmentTier) _upgradeAlignCap.text = "Путь III";
                else _upgradeAlignCap.text = "Путь " + Roman(next);
            }
        }

        static string Roman(int n)
        {
            if (n <= 0) return "·";
            if (n == 1) return "I";
            if (n == 2) return "II";
            return "III";
        }
    }
}
