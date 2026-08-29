using UnityEngine;
using UnityEngine.UI;

namespace TihiyGorod
{
    public static class UiKit
    {
        static Font _font;

        public static Font Font
        {
            get
            {
                if (_font != null) return _font;
                _font = Resources.GetBuiltinResource<Font>("Arial.ttf");
                if (_font == null) _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                if (_font == null)
                    _font = UnityEngine.Font.CreateDynamicFontFromOSFont(new[] { "Noto Sans", "Roboto", "Arial Unicode MS", "DejaVu Sans", "Arial" }, 22);
                return _font;
            }
        }

        public static Text Label(Transform parent, string name, string text, int size, Color color, TextAnchor anchor)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var t = go.AddComponent<Text>();
            t.font = Font;
            t.text = text;
            t.fontSize = size;
            t.color = color;
            t.alignment = anchor;
            t.horizontalOverflow = HorizontalWrapMode.Overflow;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            t.raycastTarget = false;
            var rt = t.rectTransform;
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
            return t;
        }

        public static Image Panel(Transform parent, string name, Color c)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var img = go.AddComponent<Image>();
            img.color = c;
            img.raycastTarget = true;
            return img;
        }

        public static Button Btn(Transform parent, string name, string caption, Color bg, Color fg, int fontSize)
        {
            var img = Panel(parent, name, bg);
            var btn = img.gameObject.AddComponent<Button>();
            var colors = btn.colors;
            colors.highlightedColor = Color.Lerp(bg, Color.white, 0.18f);
            colors.pressedColor = Color.Lerp(bg, Color.black, 0.2f);
            colors.selectedColor = Color.Lerp(bg, Color.white, 0.1f);
            btn.colors = colors;
            Label(img.transform, "Cap", caption, fontSize, fg, TextAnchor.MiddleCenter);
            return btn;
        }

        public static void Stretch(RectTransform rt, Vector2 aMin, Vector2 aMax, Vector2 offMin, Vector2 offMax)
        {
            rt.anchorMin = aMin;
            rt.anchorMax = aMax;
            rt.offsetMin = offMin;
            rt.offsetMax = offMax;
        }

        public static void Pixel(RectTransform rt, Vector2 aMin, Vector2 aMax, Vector2 pivot, Vector2 pos, Vector2 size)
        {
            rt.anchorMin = aMin;
            rt.anchorMax = aMax;
            rt.pivot = pivot;
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
        }

        public static Outline Stroke(GameObject go, Color c)
        {
            var o = go.AddComponent<Outline>();
            o.effectColor = c;
            o.effectDistance = new Vector2(1.2f, -1.2f);
            return o;
        }

        public static Slider MakeSlider(Transform parent, string name, float value)
        {
            var bg = Panel(parent, name, new Color(0.22f, 0.14f, 0.08f, 0.95f));
            var fill = Panel(bg.transform, "Fill", new Color(0.82f, 0.52f, 0.2f, 1f));
            Stretch(fill.rectTransform, new Vector2(0f, 0.15f), new Vector2(1f, 0.85f), new Vector2(4f, 0f), new Vector2(-4f, 0f));
            var handle = Panel(bg.transform, "Handle", new Color(0.96f, 0.86f, 0.62f, 1f));
            var hr = handle.rectTransform;
            hr.anchorMin = new Vector2(0f, 0.1f);
            hr.anchorMax = new Vector2(0f, 0.9f);
            hr.sizeDelta = new Vector2(28f, 0f);
            var slider = bg.gameObject.AddComponent<Slider>();
            slider.fillRect = fill.rectTransform;
            slider.handleRect = hr;
            slider.minValue = 0f;
            slider.maxValue = 1f;
            slider.value = Mathf.Clamp01(value);
            slider.direction = Slider.Direction.LeftToRight;
            slider.transition = Selectable.Transition.None;
            return slider;
        }
    }
}
