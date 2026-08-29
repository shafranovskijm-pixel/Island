using UnityEngine;

namespace TihiyGorod
{
    public sealed class IsoCamera : MonoBehaviour
    {
        public Camera Cam;
        Vector3 _focus;
        float _size;
        float _pinchPrev;
        bool _pinching;
        Vector3 _lastPan;
        bool _panning;
        int _panFinger = -1;

        public void Bind(Camera cam, Vector3 focus)
        {
            Cam = cam;
            _focus = focus;
            _size = SimConfig.CameraStartSize;
            Apply();
        }

        public void Focus(Vector3 p)
        {
            _focus = p;
        }

        void Update()
        {
            if (!Game.InputLocked)
            {
                HandleTouches();
                HandleMouse();
            }
            Apply();
        }

        void HandleTouches()
        {
            if (Input.touchCount == 2)
            {
                var a = Input.GetTouch(0);
                var b = Input.GetTouch(1);
                float dist = Vector2.Distance(a.position, b.position);
                if (!_pinching)
                {
                    _pinching = true;
                    _pinchPrev = dist;
                    _panning = false;
                }
                else
                {
                    float delta = dist - _pinchPrev;
                    _size -= delta * 0.012f;
                    _pinchPrev = dist;
                }
                return;
            }

            _pinching = false;
            if (Input.touchCount == 1)
            {
                var t = Input.GetTouch(0);
                if (UiGuard.Over(t.fingerId))
                {
                    _panning = false;
                    return;
                }
                if (t.phase == TouchPhase.Began)
                {
                    _panning = false;
                    _panFinger = t.fingerId;
                    _lastPan = t.position;
                }
                else if (t.fingerId == _panFinger && (t.phase == TouchPhase.Moved || t.phase == TouchPhase.Stationary))
                {
                    Vector3 pos = t.position;
                    if (!_panning && (pos - _lastPan).magnitude > 14f) _panning = true;
                    if (_panning) PanPixels(pos - _lastPan);
                    _lastPan = pos;
                }
                else if (t.phase == TouchPhase.Ended || t.phase == TouchPhase.Canceled)
                {
                    _panning = false;
                    _panFinger = -1;
                }
            }
        }

        void HandleMouse()
        {
            if (Input.touchCount > 0) return;
            float scroll = Input.mouseScrollDelta.y;
            if (Mathf.Abs(scroll) > 0.01f) _size -= scroll * 0.65f;

            bool held = Input.GetMouseButton(1) || Input.GetMouseButton(2) ||
                        (Input.GetMouseButton(0) && (Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.LeftControl)));
            if (held)
            {
                if (!_panning)
                {
                    if (UiGuard.Over(-1) && !Input.GetMouseButton(1) && !Input.GetMouseButton(2)) return;
                    _panning = true;
                    _lastPan = Input.mousePosition;
                }
                else
                {
                    Vector3 pos = Input.mousePosition;
                    PanPixels(pos - _lastPan);
                    _lastPan = pos;
                }
            }
            else _panning = false;
        }

        void PanPixels(Vector3 delta)
        {
            if (Cam == null) return;
            float worldPerPixel = (2f * _size) / Mathf.Max(1f, Screen.height);
            Vector3 right = Cam.transform.right;
            Vector3 fwd = Vector3.ProjectOnPlane(Cam.transform.up, Vector3.up).normalized;
            if (fwd.sqrMagnitude < 0.01f) fwd = Vector3.forward;
            _focus -= right * delta.x * worldPerPixel + fwd * delta.y * worldPerPixel;
        }

        void Apply()
        {
            _size = Mathf.Clamp(_size, SimConfig.CameraMinSize, SimConfig.CameraMaxSize);
            if (CityGrid.I != null)
            {
                var c = CityGrid.I.WorldCenter;
                float lim = (CityGrid.I.Size * CityGrid.I.Cell) * 0.55f;
                _focus.x = Mathf.Clamp(_focus.x, c.x - lim, c.x + lim);
                _focus.z = Mathf.Clamp(_focus.z, c.z - lim, c.z + lim);
                _focus.y = 0f;
            }
            if (Cam == null) return;
            Cam.orthographic = true;
            Cam.orthographicSize = _size;
            Cam.nearClipPlane = 0.1f;
            Cam.farClipPlane = 120f;
            Cam.transform.rotation = Quaternion.Euler(30f, 45f, 0f);
            Cam.transform.position = _focus - Cam.transform.forward * 42f;
        }

        public bool WasPanning { get { return _panning || _pinching; } }
    }
}
