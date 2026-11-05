defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.MovingWheels do
  @moduledoc "Independent global angular-momentum balance and Euler motor demand on declared sampled kinematics. No production physics calls."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, ResourceTimeline}
  alias Checker, as: C
  @keys ~w(wheel_1_momentum_nms wheel_2_momentum_nms wheel_3_momentum_nms)
  @tol 1.0e-8
  @rad :math.pi() / 180

  def check(i, r, asset, model, path) do
    segments = ResourceTimeline.segments(i, r, asset)
    c = model["configuration"]
    initial = i["study"]["attitude"]["assets"][asset]["initial"]

    require!(
      get_in(i, ["study", "attitude", "assets", asset, "rigid_body", "principal_moments_kg_m2"]) ==
        c["principal_moments_kg_m2"],
      "wheel_configuration",
      "body and wheel inertias differ"
    )

    models =
      get_in(r, ["attitude_planning", "resource_feasibility", "assets", asset, "models"]) || []

    found = Enum.filter(models, &(&1["id"] == model["id"]))
    require!(length(found) == 1, "wheel_evidence_identity", "one wheel evidence model required")
    levels = hd(found)["levels"]

    require!(
      is_list(levels) and length(levels) in 1..10,
      "wheel_evidence_missing",
      "bounded wheel levels required"
    )

    if Enum.any?(levels, fn l ->
         Enum.any?(l["samples"] || [], &(not is_map(&1["kinematics"])))
       end),
       do:
         throw(
           {:unsupported,
            "moving wheel histories require saved start/mid/end kinematics; regenerate the artifact"}
         )

    configured = i["study"]["resources"]["sample_steps_s"]

    require!(
      Enum.sort(Enum.map(levels, & &1["sample_step_s"])) == Enum.sort(configured),
      "wheel_coverage",
      "every configured cadence is required"
    )

    results = Enum.map(levels, &level(&1, i, segments, c, initial, asset, path))
    errors = Enum.flat_map(results, &elem(&1, 0))
    predictions = Enum.map(results, &elem(&1, 1))
    finest = Enum.min_by(predictions, & &1["sample_step_s"])
    # Execution hands off the finest configured resource level. Each coarser level
    # is checked against its own discrete quadrature, never against another grid.
    {errors,
     Map.merge(finest, %{
       "scope" => "sampled_global_momentum_balance_on_declared_kinematics",
       "levels" => predictions
     })}
  end

  defp level(l, i, segments, c, initial, asset, path) do
    samples = l["samples"]
    h = i["study"]["horizon"]
    first = h["starts_at_s"]
    stop = h["ends_at_s"]

    require!(
      is_list(samples) and length(samples) in 1..100_000,
      "wheel_samples_missing",
      "bounded wheel samples required"
    )

    require!(
      is_number(l["sample_step_s"]) and l["sample_step_s"] > 0,
      "wheel_coverage",
      "positive cadence required"
    )

    require!(
      initial["frame"] == "eci_j2000" and initial["time_scale"] == "utc" and
        initial["epoch_s"] == first,
      "wheel_initial_frame",
      "explicit initial J2000/UTC kinematics at the horizon start required"
    )

    initial =
      initial
      |> Map.put("angular_acceleration_inertial_deg_s2", [0, 0, 0])
      |> Map.update!("quaternion_wxyz", &unit/1)

    valid_pose!(initial)

    total = initial_total(c, initial)

    acc = %{
      last: first,
      total: total,
      previous: nil,
      errors: [],
      states: [c["initial_momentum_nms"]],
      hs: [],
      motors: []
    }

    acc =
      samples
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {s, index}, acc ->
        a = s["starts_at_s"]
        b = s["ends_at_s"]
        m = s["evaluated_at_s"]

        require!(
          is_number(a) and is_number(b) and a == acc.last and b <= stop and b >= a and
            (b > a or index == 0) and (index != 0 or (a == first and b == first)) and
            s["epoch_s"] == b and m == a + (b - a) / 2 and b - a <= l["sample_step_s"] + 1.0e-7,
          "wheel_coverage",
          "wheel intervals must cover the horizon without gaps or overlaps"
        )

        segment = Enum.find(segments, &(&1.a <= a and b <= &1.b and (b > a or &1.a == a)))

        require!(
          is_map(segment),
          "wheel_coverage",
          "wheel interval crosses a mandatory phase boundary"
        )

        mode = i["study"]["path_constraints"]["assets"][asset]["modes"][segment.mode]

        k = s["kinematics"]

        require!(
          Enum.sort(Map.keys(k)) == ~w(end mid start),
          "wheel_kinematics",
          "three kinematic points required"
        )

        [p0, pm, p1] = Enum.map(~w(start mid end), &k[&1])

        for {p, t} <- [{p0, a}, {pm, m}, {p1, b}] do
          valid_pose!(p)
          require!(p["epoch_s"] == t, "wheel_kinematics", "kinematic clock differs from interval")

          if expected = ResourceTimeline.pose(segment, t),
            do:
              require!(
                same_pose?(p, expected),
                "wheel_kinematics_binding",
                "kinematics differ from declared phase or saved activity profile"
              )
        end

        previous = acc.previous || initial

        require!(
          same_q?(p0["quaternion_wxyz"], previous["quaternion_wxyz"]) and
            near_vec?(
              p0["angular_velocity_inertial_deg_s"],
              previous["angular_velocity_inertial_deg_s"]
            ),
          "wheel_kinematics_continuity",
          "attitude or rate jumps at interval boundary"
        )

        unload = c["unload_modes"][segment.mode]
        unloading = segment.activity_type == "momentum_unload"

        require!(
          (unloading and is_map(unload) and mode["momentum_unloading"] == true) or
            (not unloading and unload == nil),
          "wheel_unload_mode",
          "external unloading requires its declared activity/mode"
        )

        require!(
          not unloading or
            Enum.all?([p0, pm, p1], fn p ->
              Enum.all?(
                p["angular_velocity_inertial_deg_s"] ++ p["angular_acceleration_inertial_deg_s2"],
                &(abs(&1) <= 1.0e-8)
              )
            end),
          "wheel_unload_stationary",
          "moving body cannot unload under the declared model"
        )

        require!(
          s["phase"] == segment.phase and s["scope"] == segment.scope and
            s["mode"] == %{"name" => segment.mode, "parameters" => mode},
          "wheel_interval_binding",
          "wheel phase/mode differs from saved timeline"
        )

        external =
          add(
            c["disturbance_torque_body_nm"],
            if(unloading, do: unload["external_torque_body_nm"], else: [0, 0, 0])
          )

        {te, hs, motors} = interval(c, [p0, pm, p1], acc.total, external, b - a)

        errors =
          C.check(
            state_near?(s["state"], List.last(hs)),
            "wheel_sample_state",
            path,
            "momentum differs from independent global impulse balance"
          ) ++
            C.check(
              near_vec?(s["metrics"]["rotor_momentum_mid_nms"], Enum.at(hs, 1)) and
                near_vec?(s["metrics"]["motor_torque_mid_nm"], Enum.at(motors, 1)) and
                near_vec?(s["metrics"]["total_inertial_angular_momentum_nms"], te) and
                near_vec?(
                  s["metrics"]["disturbance_torque_body_nm"],
                  c["disturbance_torque_body_nm"]
                ) and
                near_vec?(
                  s["metrics"]["applied_unload_torque_body_nm"],
                  if(unloading, do: unload["external_torque_body_nm"], else: [0, 0, 0])
                ),
              "wheel_sample_demand",
              path,
              "motor torque or momentum metrics differ from independent Euler balance"
            )

        errors =
          errors ++
            Enum.flat_map(0..2, fn axis ->
              Enum.flat_map(
                [
                  {hs, c["momentum_capacity_nms"], "momentum"},
                  {motors, c["max_motor_torque_nm"], "motor_torque"}
                ],
                fn {values, caps, suffix} ->
                  margin = Enum.at(caps, axis) - peak(values, axis)
                  check = Enum.filter(s["checks"], &(&1["id"] == "wheel_#{axis + 1}_#{suffix}"))

                  C.check(
                    margin >= -1.0e-12,
                    if(suffix == "momentum",
                      do: "wheel_momentum_capacity",
                      else: "wheel_motor_capacity"
                    ),
                    path,
                    "sampled wheel demand exceeds declared capacity"
                  ) ++
                    C.check(
                      length(check) == 1 and C.near?(hd(check)["margin"], margin) and
                        hd(check)["status"] ==
                          if(margin >= -1.0e-12, do: "supported", else: "violated"),
                      "wheel_sample_margin",
                      path,
                      "sampled capacity evidence differs"
                    )
                end
              )
            end)

        %{
          acc
          | last: b,
            total: te,
            previous: p1,
            errors: errors ++ acc.errors,
            states: [List.last(hs) | acc.states],
            hs: hs ++ acc.hs,
            motors: motors ++ acc.motors
        }
      end)

    errors =
      acc.errors ++
        C.check(
          acc.last == stop and l["evaluated_through_s"] == stop and l["uncovered_intervals"] == [],
          "wheel_coverage",
          path,
          "wheel propagation ends before the horizon"
        ) ++
        C.check(
          state_near?(l["initial_state"], c["initial_momentum_nms"]),
          "wheel_initial_state",
          path,
          "initial momentum differs"
        ) ++
        C.check(
          state_near?(l["final_state"], hd(acc.states)),
          "wheel_final_state",
          path,
          "final momentum differs"
        )

    errors =
      errors ++
        Enum.flat_map(0..2, fn axis ->
          key = Enum.at(@keys, axis)
          values = Enum.map(acc.states, &Enum.at(&1, axis))

          C.check(
            C.near?(get_in(l, ["state_extrema", key, "min"]), Enum.min(values)) and
              C.near?(get_in(l, ["state_extrema", key, "max"]), Enum.max(values)),
            "wheel_extrema",
            path,
            "signed endpoint extrema differ"
          ) ++
            C.check(
              C.near?(
                get_in(l, ["minimum_margins", "wheel_#{axis + 1}_momentum", "margin"]),
                Enum.at(c["momentum_capacity_nms"], axis) - peak(acc.hs, axis)
              ) and
                C.near?(
                  get_in(l, ["minimum_margins", "wheel_#{axis + 1}_motor_torque", "margin"]),
                  Enum.at(c["max_motor_torque_nm"], axis) - peak(acc.motors, axis)
                ),
              "wheel_margins",
              path,
              "minimum sampled wheel margins differ"
            )
        end)

    {errors,
     %{
       "sample_step_s" => l["sample_step_s"],
       "final_momentum_nms" => hd(acc.states),
       "maximum_absolute_momentum_nms" => Enum.map(0..2, &peak(acc.hs, &1)),
       "maximum_absolute_motor_torque_nm" => Enum.map(0..2, &peak(acc.motors, &1))
     }}
  end

  @doc "Global impulse balance for one declared three-point interval; also checked against the frozen independent RK4 bundle."
  def interval(c, [p0, pm, p1], total, external, dt) do
    impulse = scale(rotate(pm["quaternion_wxyz"], external), dt)
    tm = add(total, scale(impulse, 0.5))
    te = add(total, impulse)
    hs = [rotor(c, p0, total), rotor(c, pm, tm), rotor(c, p1, te)]
    motors = Enum.zip_with([p0, pm, p1], hs, fn p, h -> motor(c, p, h, external) end)
    {te, hs, motors}
  end

  def initial_total(c, p),
    do: rotate(p["quaternion_wxyz"], add(diag(c, rate(p)), body(c, c["initial_momentum_nms"])))

  defp rotor(c, p, total),
    do: project(c, sub(rotate(p["quaternion_wxyz"], total, true), diag(c, rate(p))))

  defp motor(c, p, h, external) do
    w = rate(p)
    a = rotate(p["quaternion_wxyz"], scale(p["angular_acceleration_inertial_deg_s2"], @rad), true)
    project(c, sub(sub(external, diag(c, a)), cross(w, add(diag(c, w), body(c, h)))))
  end

  defp rate(p),
    do: rotate(p["quaternion_wxyz"], scale(p["angular_velocity_inertial_deg_s"], @rad), true)

  defp diag(c, v), do: Enum.zip_with(c["principal_moments_kg_m2"], v, &(&1 * &2))
  defp project(c, v), do: Enum.map(c["wheel_axes_body"], &dot(&1, v))

  defp body(c, h),
    do:
      c["wheel_axes_body"]
      |> Enum.zip(h)
      |> Enum.reduce([0, 0, 0], fn {axis, x}, v -> add(v, scale(axis, x)) end)

  defp peak(vs, a), do: vs |> Enum.map(&abs(Enum.at(&1, a))) |> Enum.max()
  defp state_near?(s, v), do: is_map(s) and near_vec?(Enum.map(@keys, &s[&1]), v)

  defp near_vec?(a, b),
    do:
      is_list(a) and is_list(b) and length(a) == length(b) and
        Enum.zip_with(a, b, fn x, y -> is_number(x) and is_number(y) and abs(x - y) <= @tol end)
        |> Enum.all?()

  defp same_q?(a, b) do
    a = unit(a)
    b = unit(b)
    near_vec?(a, b) or near_vec?(a, scale(b, -1))
  end

  defp unit(q) do
    require!(
      is_list(q) and length(q) == 4 and Enum.all?(q, &is_number/1) and dot(q, q) > 0,
      "wheel_kinematics",
      "nonzero finite quaternion required"
    )

    scale(q, 1 / :math.sqrt(dot(q, q)))
  end

  defp same_pose?(a, b),
    do:
      same_q?(a["quaternion_wxyz"], b["quaternion_wxyz"]) and
        Enum.all?(
          ~w(angular_velocity_inertial_deg_s angular_acceleration_inertial_deg_s2),
          &near_vec?(a[&1], b[&1])
        )

  defp valid_pose!(p) do
    require!(
      is_map(p) and
        Enum.all?(
          [
            {p["quaternion_wxyz"], 4},
            {p["angular_velocity_inertial_deg_s"], 3},
            {p["angular_acceleration_inertial_deg_s2"], 3}
          ],
          fn {v, n} ->
            is_list(v) and length(v) == n and Enum.all?(v, &(is_number(&1) and abs(&1) <= 1.0e15))
          end
        ) and abs(dot(p["quaternion_wxyz"], p["quaternion_wxyz"]) - 1) <= 1.0e-8,
      "wheel_kinematics",
      "finite normalized kinematics required"
    )
  end

  # Explicit direction-cosine matrix; production uses quaternion vector products.
  defp rotate([w, x, y, z], v, inverse \\ false) do
    rows = [
      [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
      [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
      [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]
    ]

    rows = if inverse, do: rows |> Enum.zip() |> Enum.map(&Tuple.to_list/1), else: rows
    Enum.map(rows, &dot(&1, v))
  end

  defp add(a, b), do: Enum.zip_with(a, b, &(&1 + &2))
  defp sub(a, b), do: Enum.zip_with(a, b, &(&1 - &2))
  defp scale(a, k), do: Enum.map(a, &(&1 * k))
  defp dot(a, b), do: Enum.zip_with(a, b, &(&1 * &2)) |> Enum.sum()
  defp cross([a, b, c], [x, y, z]), do: [b * z - c * y, c * x - a * z, a * y - b * x]
  defp require!(true, _, _), do: :ok
  defp require!(false, code, why), do: throw({:wheel, code, why})
end
