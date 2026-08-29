using UnityEngine;

namespace TihiyGorod
{
    public static class Query
    {
        public static T One<T>() where T : Object
        {
#if UNITY_2023_1_OR_NEWER
            return Object.FindFirstObjectByType<T>();
#else
#pragma warning disable 618
            return Object.FindObjectOfType<T>();
#pragma warning restore 618
#endif
        }

        public static T[] All<T>() where T : Object
        {
#if UNITY_2023_1_OR_NEWER
            return Object.FindObjectsByType<T>(FindObjectsSortMode.None);
#else
#pragma warning disable 618
            return Object.FindObjectsOfType<T>();
#pragma warning restore 618
#endif
        }
    }
}
