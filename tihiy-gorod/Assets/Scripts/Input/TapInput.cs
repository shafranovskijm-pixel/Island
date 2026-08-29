using UnityEngine;

namespace TihiyGorod
{
    public sealed class TapInput : MonoBehaviour
    {
        Camera _cam;
        float _downTime;
        Vector2 _downPos;
        bool _down;
        int _finger = -1;

        public void Bind(Camera cam)
        {
            _cam = cam;
        }

        void Update()
        {
            if (_cam == null) return;
            if (Game.InputLocked) return;
            if (Input.touchCount == 1)
            {
                var t = Input.GetTouch(0);
                if (t.phase == TouchPhase.Began)
                {
                    if (UiGuard.Over(t.fingerId)) return;
                    _down = true;
                    _finger = t.fingerId;
                    _downTime = Time.unscaledTime;
                    _downPos = t.position;
                }
                else if (t.phase == TouchPhase.Ended && _down && t.fingerId == _finger)
                {
                    _down = false;
                    if (Time.unscaledTime - _downTime < 0.35f && (t.position - _downPos).magnitude < 28f)
                        RayTap(t.position);
                }
                return;
            }

            if (Input.GetMouseButtonDown(0) && Input.touchCount == 0)
            {
                if (UiGuard.Over(-1)) return;
                _down = true;
                _downTime = Time.unscaledTime;
                _downPos = Input.mousePosition;
            }
            if (Input.GetMouseButtonUp(0) && _down && Input.touchCount == 0)
            {
                _down = false;
                if (Game.Camera != null && Game.Camera.WasPanning) return;
                if (Time.unscaledTime - _downTime < 0.35f && ((Vector2)Input.mousePosition - _downPos).magnitude < 22f)
                    RayTap(Input.mousePosition);
            }
        }

        void RayTap(Vector2 screen)
        {
            var ray = _cam.ScreenPointToRay(screen);
            RaycastHit hit;
            if (!Physics.Raycast(ray, out hit, 200f)) return;
            var b = hit.collider.GetComponentInParent<Building>();
            var tile = hit.collider.GetComponent<GridTile>();
            var cozy = hit.collider.GetComponentInParent<CozyObject>();
            if (Game.Place != null) Game.Place.HandleTap(hit.point, b, tile, cozy);
        }
    }
}
