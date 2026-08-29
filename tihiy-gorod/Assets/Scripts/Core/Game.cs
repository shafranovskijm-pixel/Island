namespace TihiyGorod
{
    public static class Game
    {
        public static AlignmentSystem Align;
        public static ResourceSystem Resources;
        public static CityGrid Grid;
        public static PlacementSystem Place;
        public static DayNightCycle Time;
        public static WeatherSystem Weather;
        public static UnitManager Units;
        public static AudioDirector Audio;
        public static IsoCamera Camera;
        public static GameHud Hud;
        public static WorldFx Fx;
        public static CozySystem Cozy;
        public static EveningSystem Evening;
        public static RiddleDirector Riddles;

        public static bool InputLocked
        {
            get
            {
                if (Riddles != null && Riddles.IsOpen) return true;
                if (GameFlow.I != null && GameFlow.I.MenuVisible) return true;
                return false;
            }
        }

        public static void Bind(
            AlignmentSystem align,
            ResourceSystem res,
            CityGrid grid,
            PlacementSystem place,
            DayNightCycle time,
            WeatherSystem weather,
            UnitManager units,
            AudioDirector audio,
            IsoCamera cam,
            WorldFx fx)
        {
            Align = align;
            Resources = res;
            Grid = grid;
            Place = place;
            Time = time;
            Weather = weather;
            Units = units;
            Audio = audio;
            Camera = cam;
            Fx = fx;
        }
    }
}
