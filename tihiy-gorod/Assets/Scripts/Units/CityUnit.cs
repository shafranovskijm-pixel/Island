using UnityEngine;

namespace TihiyGorod
{
    public sealed class CityUnit : MonoBehaviour
    {
        public UnitKind Kind;
        public UnitAiState State = UnitAiState.Wander;
        public AlignmentType Tint = AlignmentType.None;

        Vector3 _target;
        Building _focus;
        float _timer;
        float _bob;
        float _speedMul = 1f;
        Transform _hood;
        Transform _lantern;
        Renderer[] _body;
        Color _baseColor;
        bool _sheltered;

        public void Setup(UnitKind kind, Vector3 pos)
        {
            Kind = kind;
            transform.position = pos;
            BuildMesh();
            PickWander();
        }

        void BuildMesh()
        {
            Color cloth;
            switch (Kind)
            {
                case UnitKind.Spirit:
                    cloth = new Color(0.65f, 0.85f, 1f, 0.9f);
                    PrimitiveBuilder.Sphere(transform, new Vector3(0f, 0.45f, 0f), Vector3.one * 0.38f, MatLib.Unique(cloth, 0.05f, 0.8f, true, 1.1f), "Body");
                    PrimitiveBuilder.Sphere(transform, new Vector3(0f, 0.72f, 0f), Vector3.one * 0.22f, MatLib.Unique(Color.white, 0f, 0.7f, true, 0.8f), "Head");
                    break;
                case UnitKind.Wisp:
                    cloth = new Color(1f, 0.9f, 0.55f);
                    PrimitiveBuilder.Sphere(transform, new Vector3(0f, 0.55f, 0f), Vector3.one * 0.28f, MatLib.Unique(cloth, 0.1f, 0.9f, true, 2.2f), "Body");
                    break;
                case UnitKind.Cat:
                    cloth = new Color(0.82f, 0.48f, 0.22f);
                    PrimitiveBuilder.Sphere(transform, new Vector3(0f, 0.16f, 0.02f), new Vector3(0.28f, 0.18f, 0.42f), MatLib.Unique(cloth, 0.05f, 0.35f), "Body");
                    PrimitiveBuilder.Sphere(transform, new Vector3(0f, 0.24f, 0.2f), Vector3.one * 0.16f, MatLib.Unique(cloth, 0.05f, 0.35f), "Head");
                    PrimitiveBuilder.Cube(transform, new Vector3(-0.06f, 0.34f, 0.18f), new Vector3(0.06f, 0.1f, 0.04f), MatLib.Color(cloth), "EarL");
                    PrimitiveBuilder.Cube(transform, new Vector3(0.06f, 0.34f, 0.18f), new Vector3(0.06f, 0.1f, 0.04f), MatLib.Color(cloth), "EarR");
                    PrimitiveBuilder.Sphere(transform, new Vector3(0f, 0.18f, -0.22f), new Vector3(0.06f, 0.06f, 0.18f), MatLib.Unique(cloth, 0.05f, 0.3f), "Tail");
                    break;
                default:
                    cloth = new Color(0.62f, 0.48f, 0.35f);
                    PrimitiveBuilder.Capsule(transform, new Vector3(0f, 0.42f, 0f), new Vector3(0.28f, 0.32f, 0.28f), MatLib.Unique(cloth, 0.05f, 0.25f), "Body");
                    PrimitiveBuilder.Sphere(transform, new Vector3(0f, 0.78f, 0f), Vector3.one * 0.22f, MatLib.Unique(new Color(0.92f, 0.78f, 0.65f), 0f, 0.35f), "Head");
                    PrimitiveBuilder.Cube(transform, new Vector3(0f, 0.22f, 0.02f), new Vector3(0.22f, 0.12f, 0.16f), MatLib.Color(new Color(0.3f, 0.22f, 0.18f)), "Boots");
                    break;
            }

            var hoodGo = PrimitiveBuilder.Cube(transform, new Vector3(0f, 0.82f, 0.02f), new Vector3(0.26f, 0.12f, 0.28f), MatLib.Color(new Color(0.18f, 0.2f, 0.28f)), "Hood");
            _hood = hoodGo.transform;
            _hood.gameObject.SetActive(false);

            var lan = PrimitiveBuilder.Sphere(transform, new Vector3(0.18f, 0.55f, 0.12f), Vector3.one * 0.1f, MatLib.Unique(new Color(1f, 0.82f, 0.35f), 0.1f, 0.8f, true, 2.5f), "Lantern");
            _lantern = lan.transform;
            _lantern.gameObject.SetActive(false);

            _body = GetComponentsInChildren<Renderer>();
            _baseColor = cloth;
        }

        public void ApplyAlignmentTint(AlignmentType t)
        {
            Tint = t;
            if (t == AlignmentType.None || _body == null) return;
            var c = Color.Lerp(_baseColor, Palette.Alignment(t), 0.45f);
            for (int i = 0; i < _body.Length; i++)
            {
                if (_body[i] == null) continue;
                if (_body[i].transform == _hood || _body[i].transform == _lantern) continue;
                if (_body[i].name == "Head" || _body[i].name == "Boots") continue;
                _body[i].material.color = c;
            }
        }

        void Update()
        {
            var day = Game.Time;
            var weather = Game.Weather;
            bool night = day != null && day.IsNight;
            bool rain = weather != null && weather.IsRaining;

            _speedMul = 1f;
            if (rain) _speedMul *= 0.62f;
            if (night && Kind == UnitKind.Villager) _speedMul *= 0.72f;
            if (Kind == UnitKind.Wisp) _speedMul *= 1.15f;
            if (Kind == UnitKind.Spirit && night) _speedMul *= 1.2f;
            if (Kind == UnitKind.Cat) _speedMul *= 0.7f;
            float ujut = CozySystem.I != null ? CozySystem.I.Normalized : 0.35f;
            if (ujut > 0.55f) _speedMul *= Mathf.Lerp(1f, 0.68f, (ujut - 0.55f) / 0.45f);
            else if (ujut < 0.28f) _speedMul *= Mathf.Lerp(1.28f, 1f, ujut / 0.28f);

            if (_hood != null) _hood.gameObject.SetActive(rain && Kind == UnitKind.Villager);
            if (_lantern != null) _lantern.gameObject.SetActive(night && Kind != UnitKind.Wisp && Kind != UnitKind.Cat);

            if (rain && !_sheltered && State != UnitAiState.Shelter && State != UnitAiState.GoHome)
                Enter(UnitAiState.Shelter);
            else if (!rain && State == UnitAiState.Shelter)
                Enter(UnitAiState.Wander);

            if (night && Kind == UnitKind.Villager && State != UnitAiState.GoHome && State != UnitAiState.Idle && State != UnitAiState.Shelter && State != UnitAiState.Sit && State != UnitAiState.Drink)
                Enter(UnitAiState.GoHome);
            else if (!night && State == UnitAiState.Idle && !rain)
                Enter(UnitAiState.Wander);

            if (Kind == UnitKind.Cat && State != UnitAiState.Sit && State != UnitAiState.Travel)
            {
                if (Random.value < 0.008f) Enter(UnitAiState.Sit);
            }

            StepAi();
            Move();
            _bob += Time.deltaTime * (Kind == UnitKind.Wisp ? 4f : 2.4f);
            float bobAmp = Kind == UnitKind.Villager ? 0.03f : (Kind == UnitKind.Cat ? 0.02f : 0.08f);
            var p = transform.position;
            p.y = 0.02f + Mathf.Abs(Mathf.Sin(_bob)) * bobAmp;
            if (Kind != UnitKind.Villager && Kind != UnitKind.Cat) p.y += 0.18f;
            if (Kind == UnitKind.Cat && State == UnitAiState.Sit && Arrived()) p.y = 0.08f;
            transform.position = p;
        }

        void Enter(UnitAiState s)
        {
            State = s;
            _timer = 0f;
            _sheltered = false;
            switch (s)
            {
                case UnitAiState.Wander: PickWander(); break;
                case UnitAiState.Travel:
                case UnitAiState.Gather:
                    _focus = CityGrid.I != null ? CityGrid.I.RandomBuilding() : null;
                    if (_focus != null) _target = _focus.DoorWorld;
                    else PickWander();
                    break;
                case UnitAiState.GoHome:
                case UnitAiState.Shelter:
                    _focus = CityGrid.I != null ? CityGrid.I.NearestBuilding(transform.position) : null;
                    if (_focus != null) _target = _focus.DoorWorld;
                    else PickWander();
                    break;
                case UnitAiState.Idle:
                    _target = transform.position;
                    _timer = Random.Range(2.5f, 6f);
                    break;
                case UnitAiState.Sit:
                {
                    var bench = CozySystem.I != null ? CozySystem.I.NearestSit(transform.position) : null;
                    if (bench != null) { _target = bench.SitWorld; }
                    else PickWander();
                    _timer = Kind == UnitKind.Cat ? Random.Range(6f, 14f) : Random.Range(2.5f, 5.5f);
                    break;
                }
                case UnitAiState.Drink:
                {
                    var tea = CozySystem.I != null ? CozySystem.I.Nearest(CozyId.Samovar, transform.position) : null;
                    if (tea != null) { _target = tea.SitWorld; _timer = Random.Range(2.2f, 4.2f); }
                    else Enter(UnitAiState.Wander);
                    break;
                }
            }
        }

        void StepAi()
        {
            _timer += Time.deltaTime;
            switch (State)
            {
                case UnitAiState.Wander:
                    if (Arrived())
                    {
                        float u = CozySystem.I != null ? CozySystem.I.Normalized : 0.3f;
                        if (Kind == UnitKind.Cat)
                            Enter(UnitAiState.Sit);
                        else if (u > 0.4f && CozySystem.I != null && CozySystem.I.SamovarCount > 0 && Random.value < 0.22f)
                            Enter(UnitAiState.Drink);
                        else if (u > 0.4f && CozySystem.I != null && CozySystem.I.BenchCount > 0 && Random.value < 0.28f)
                            Enter(UnitAiState.Sit);
                        else if (CityGrid.I != null && CityGrid.I.BuildingCount > 0 && Random.value < 0.55f)
                            Enter(UnitAiState.Travel);
                        else
                            PickWander();
                    }
                    break;
                case UnitAiState.Travel:
                    if (_focus == null) { Enter(UnitAiState.Wander); break; }
                    if (Arrived())
                    {
                        State = UnitAiState.Gather;
                        _timer = 0f;
                    }
                    break;
                case UnitAiState.Gather:
                    if (_timer >= SimConfig.GatherSeconds)
                    {
                        if (_focus != null && ResourceSystem.I != null)
                            ResourceSystem.I.Add(_focus.Def.PrimaryResource, 0.35f + _focus.Level * 0.15f);
                        Enter(UnitAiState.Wander);
                    }
                    break;
                case UnitAiState.GoHome:
                    if (_focus == null) { Enter(UnitAiState.Idle); break; }
                    if (Arrived()) Enter(UnitAiState.Idle);
                    break;
                case UnitAiState.Shelter:
                    if (_focus == null) break;
                    if (Arrived())
                    {
                        _sheltered = true;
                        _target = _focus.transform.position + Quaternion.Euler(0f, _timer * 18f, 0f) * new Vector3(0.45f, 0f, 0f);
                    }
                    break;
                case UnitAiState.Idle:
                    if (_timer > 4f && Game.Time != null && !Game.Time.IsNight)
                        Enter(UnitAiState.Wander);
                    break;
                case UnitAiState.Sit:
                    if (Arrived() && _timer > (Kind == UnitKind.Cat ? 8f : 3.5f))
                        Enter(UnitAiState.Wander);
                    break;
                case UnitAiState.Drink:
                    if (Arrived() && _timer > 2.4f)
                        Enter(UnitAiState.Wander);
                    break;
            }
        }

        void PickWander()
        {
            State = UnitAiState.Wander;
            if (CityGrid.I == null)
            {
                _target = transform.position + new Vector3(Random.Range(-2f, 2f), 0f, Random.Range(-2f, 2f));
                return;
            }
            int x = Random.Range(0, CityGrid.I.Size);
            int y = Random.Range(0, CityGrid.I.Size);
            _target = CityGrid.I.CellCenter(x, y) + new Vector3(Random.Range(-0.3f, 0.3f), 0f, Random.Range(-0.3f, 0.3f));
        }

        bool Arrived()
        {
            var a = transform.position;
            a.y = 0f;
            var t = _target;
            t.y = 0f;
            return (a - t).sqrMagnitude < 0.08f;
        }

        void Move()
        {
            if (State == UnitAiState.Gather && !_sheltered) return;
            if (State == UnitAiState.Idle && !_sheltered) return;
            if ((State == UnitAiState.Sit || State == UnitAiState.Drink) && Arrived()) return;
            var pos = transform.position;
            var dest = _target;
            dest.y = pos.y;
            Vector3 delta = dest - pos;
            delta.y = 0f;
            float dist = delta.magnitude;
            if (dist < 0.02f) return;
            float step = SimConfig.UnitWalkSpeed * _speedMul * Time.deltaTime;
            if (step > dist) step = dist;
            transform.position = pos + delta.normalized * step;
            if (delta.sqrMagnitude > 0.0001f)
            {
                var look = Quaternion.LookRotation(delta.normalized, Vector3.up);
                transform.rotation = Quaternion.Slerp(transform.rotation, look, Time.deltaTime * 6f);
            }
        }
    }
}
