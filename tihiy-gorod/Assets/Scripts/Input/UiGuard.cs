using UnityEngine;
using UnityEngine.EventSystems;

namespace TihiyGorod
{
    public static class UiGuard
    {
        public static bool Over(int fingerId)
        {
            if (EventSystem.current == null) return false;
            if (fingerId >= 0)
            {
                if (EventSystem.current.IsPointerOverGameObject(fingerId)) return true;
            }
            else
            {
                if (EventSystem.current.IsPointerOverGameObject()) return true;
            }
            return false;
        }
    }
}
