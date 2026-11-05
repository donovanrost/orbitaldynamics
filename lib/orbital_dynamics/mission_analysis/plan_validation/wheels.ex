defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Wheels do
  @moduledoc "Independent analytic stationary and sampled moving-wheel accounting for signed coordinate wheel axes. Calls no production physics."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker, as: C
  @keys ~w(wheel_1_momentum_nms wheel_2_momentum_nms wheel_3_momentum_nms)

  def check(inputs, report, label) do
    configs = get_in(inputs, ["study", "resources", "assets"]) || %{}

    Enum.reduce(configs, {[], %{}}, fn {asset, models}, acc ->
      wheels = Enum.filter(models, &(&1["model"] == "reaction_wheels"))

      {issues, expected} = acc

      issues =
        issues ++
          C.check(
            length(wheels) <= 1,
            "wheel_array_count",
            label <> "/" <> asset,
            "one wheel array per asset is supported"
          )

      Enum.reduce(wheels, {issues, expected}, fn model, {issues, expected} ->
        path = label <> "/" <> asset <> "/" <> model["id"]
        {more, prediction} = model(inputs, report, asset, model, path)

        expected =
          if prediction,
            do:
              Map.update(
                expected,
                asset,
                %{model["id"] => prediction},
                &Map.put(&1, model["id"], prediction)
              ),
            else: expected

        {issues ++ more, expected}
      end)
    end)
  end

  defp model(i, r, asset, model, path) do
    try do
      c = model["configuration"]
      validate_config!(c)

      evidence =
        get_in(r, ["attitude_planning", "resource_feasibility", "assets", asset, "models"]) || []

      current = Enum.find(evidence, &(&1["id"] == model["id"]))

      if current &&
           Enum.any?(current["levels"] || [], fn l ->
             Enum.any?(l["samples"] || [], &Map.has_key?(&1, "kinematics"))
           end),
         do: throw({:moving, c})

      stationary =
        try do
          stationary!(i, r, asset, c)
          true
        catch
          {:unsupported, _} -> false
        end

      if not stationary, do: throw({:moving, c})
      h = i["study"]["horizon"]
      acts = Enum.filter(r["activities"], &(&1["asset_id"] == asset))
      modes = get_in(i, ["study", "path_constraints", "assets", asset])
      requests = Map.new(i["mission"]["requests"], &{&1["id"], &1})

      times =
        [h["starts_at_s"], h["ends_at_s"]] ++
          Enum.flat_map(acts, &[&1["starts_at_s"], &1["ends_at_s"]])

      times = Enum.sort(Enum.uniq(times))

      segments =
        Enum.map(Enum.chunk_every(times, 2, 1, :discard), fn [a, b] ->
          active = Enum.find(acts, &(&1["starts_at_s"] <= a and &1["ends_at_s"] >= b))

          mode =
            if active,
              do: modes["activity_modes"][active["request_id"]],
              else: modes["transition_mode"]

          unload = c["unload_modes"][mode]

          unloading =
            active && requests[active["request_id"]]["activity_type"] == "momentum_unload"

          valid_mode =
            if unloading,
              do: unload != nil and get_in(modes, ["modes", mode, "momentum_unloading"]) == true,
              else: unload == nil

          require!(
            valid_mode,
            "wheel_unload_mode",
            "unloading must use its declared external-torque activity and mode"
          )

          external =
            Enum.zip_with(
              c["disturbance_torque_body_nm"],
              if(unloading, do: unload["external_torque_body_nm"], else: [0, 0, 0]),
              &(&1 + &2)
            )

          %{a: a, b: b, motor: Enum.map(c["wheel_axes_body"], &dot(&1, external))}
        end)

      at = fn t -> momentum(c["initial_momentum_nms"], segments, t) end
      boundary_states = Enum.map(times, at)

      peak_h =
        for axis <- 0..2, do: Enum.map(boundary_states, &abs(Enum.at(&1, axis))) |> Enum.max()

      peak_motor =
        for axis <- 0..2, do: Enum.map(segments, &abs(Enum.at(&1.motor, axis))) |> Enum.max()

      errors =
        Enum.flat_map(0..2, fn axis ->
          C.check(
            Enum.at(peak_h, axis) <= Enum.at(c["momentum_capacity_nms"], axis) + 1.0e-12,
            "wheel_momentum_capacity",
            path,
            "analytic momentum crosses wheel #{axis + 1} capacity"
          ) ++
            C.check(
              Enum.at(peak_motor, axis) <= Enum.at(c["max_motor_torque_nm"], axis) + 1.0e-12,
              "wheel_motor_capacity",
              path,
              "analytic motor torque crosses wheel #{axis + 1} capacity"
            )
        end)

      models =
        get_in(r, ["attitude_planning", "resource_feasibility", "assets", asset, "models"]) || []

      found = Enum.filter(models, &(&1["id"] == model["id"]))
      require!(length(found) == 1, "wheel_evidence_identity", "one wheel evidence model required")
      levels = hd(found)["levels"]

      require!(
        is_list(levels) and length(levels) in 1..10,
        "wheel_evidence_missing",
        "wheel levels required"
      )

      errors =
        errors ++
          Enum.flat_map(levels, fn level ->
            samples = level["samples"]

            require!(
              is_list(samples) and length(samples) in 1..100_000,
              "wheel_samples_missing",
              "bounded wheel samples required"
            )

            first = h["starts_at_s"]
            stop = h["ends_at_s"]
            epochs = Enum.map(samples, & &1["epoch_s"])

            es =
              C.check(
                hd(epochs) == first and List.last(epochs) == stop and
                  level["evaluated_through_s"] == stop and
                  Enum.all?(times, fn t -> Enum.any?(epochs, &(&1 == t)) end) and
                  is_number(level["sample_step_s"]) and
                  level["sample_step_s"] > 0 and
                  Enum.all?(Enum.chunk_every(epochs, 2, 1, :discard), fn [a, b] ->
                    is_number(a) and is_number(b) and b > a and
                      b - a <= level["sample_step_s"] + 1.0e-7
                  end),
                "wheel_coverage",
                path,
                "wheel samples must cover the horizon and activity boundaries"
              )

            es =
              es ++
                C.check(
                  state_near?(level["initial_state"], c["initial_momentum_nms"]),
                  "wheel_initial_state",
                  path,
                  "reported initial wheel momentum differs"
                ) ++
                C.check(
                  state_near?(level["final_state"], at.(stop)),
                  "wheel_final_state",
                  path,
                  "reported final momentum differs from analytic balance"
                )

            es =
              es ++
                Enum.flat_map(0..2, fn axis ->
                  key = Enum.at(@keys, axis)
                  values = Enum.map(boundary_states, &Enum.at(&1, axis))

                  C.check(
                    C.near?(get_in(level, ["state_extrema", key, "min"]), Enum.min(values)) and
                      C.near?(get_in(level, ["state_extrema", key, "max"]), Enum.max(values)),
                    "wheel_extrema",
                    path,
                    "reported signed momentum extrema differ"
                  ) ++
                    C.check(
                      C.near?(
                        get_in(level, ["minimum_margins", "wheel_#{axis + 1}_momentum", "margin"]),
                        Enum.at(c["momentum_capacity_nms"], axis) - Enum.at(peak_h, axis)
                      ) and
                        C.near?(
                          get_in(level, [
                            "minimum_margins",
                            "wheel_#{axis + 1}_motor_torque",
                            "margin"
                          ]),
                          Enum.at(c["max_motor_torque_nm"], axis) - Enum.at(peak_motor, axis)
                        ),
                      "wheel_margins",
                      path,
                      "reported wheel margin differs from independent limits"
                    )
                end)

            es ++
              Enum.flat_map(samples, fn sample ->
                t = sample["epoch_s"]

                require!(
                  is_number(t) and t >= first and t <= stop,
                  "wheel_sample_epoch",
                  "sample outside horizon"
                )

                mid = sample["evaluated_at_s"]

                require!(
                  is_number(mid) and mid >= first and mid <= stop,
                  "wheel_sample_epoch",
                  "evaluation epoch outside horizon"
                )

                segment =
                  Enum.find(segments, &(&1.a <= mid and mid < &1.b)) || List.last(segments)

                C.check(
                  state_near?(sample["state"], at.(t)),
                  "wheel_sample_state",
                  path,
                  "sample momentum differs from analytic history"
                ) ++
                  C.check(
                    vector_near?(get_in(sample, ["metrics", "rotor_momentum_mid_nms"]), at.(mid)) and
                      vector_near?(
                        get_in(sample, ["metrics", "motor_torque_mid_nm"]),
                        segment.motor
                      ),
                    "wheel_sample_demand",
                    path,
                    "sample midpoint momentum or motor demand differs"
                  )
              end)
          end)

      prediction = %{
        "final_momentum_nms" => at.(h["ends_at_s"]),
        "maximum_absolute_momentum_nms" => peak_h,
        "maximum_absolute_motor_torque_nm" => peak_motor,
        "scope" => "stationary_fixed_attitude_signed_coordinate_axes"
      }

      {errors, prediction}
    catch
      {:moving, _} ->
        try do
          OrbitalDynamics.MissionAnalysis.PlanValidation.MovingWheels.check(
            i,
            r,
            asset,
            model,
            path
          )
        catch
          {:unsupported, why} ->
            {[C.issue("wheel_dynamics_unsupported", path, why, "unsupported")], nil}

          {:wheel, code, why} ->
            {[C.issue(code, path, why)], nil}
        end

      {:unsupported, why} ->
        {[C.issue("wheel_dynamics_unsupported", path, why, "unsupported")], nil}

      {:wheel, code, why} ->
        {[C.issue(code, path, why)], nil}
    end
  end

  defp validate_config!(c) do
    require!(
      is_map(c) and c["frame"] == "body_principal_axes",
      "wheel_configuration",
      "body principal axes required"
    )

    for key <-
          ~w(initial_momentum_nms principal_moments_kg_m2 momentum_capacity_nms max_motor_torque_nm disturbance_torque_body_nm max_unload_torque_body_nm) do
      require!(vector?(c[key]), "wheel_configuration", "three finite components required: #{key}")
    end

    require!(
      Enum.all?(
        c["principal_moments_kg_m2"] ++ c["momentum_capacity_nms"] ++ c["max_motor_torque_nm"],
        &(&1 > 0)
      ),
      "wheel_configuration",
      "positive inertia and capacities required"
    )

    [x, y, z] = c["principal_moments_kg_m2"]

    require!(
      x <= y + z and y <= x + z and z <= x + y,
      "wheel_configuration",
      "inertia triangle inequalities required"
    )

    axes = c["wheel_axes_body"]

    require!(
      is_list(axes) and length(axes) == 3 and Enum.all?(axes, &vector?/1),
      "wheel_configuration",
      "three wheel axes required"
    )

    require!(
      Enum.all?(axes, &(abs(dot(&1, &1) - 1) <= 1.0e-10)) and
        Enum.all?([{0, 1}, {0, 2}, {1, 2}], fn {a, b} ->
          abs(dot(Enum.at(axes, a), Enum.at(axes, b))) <= 1.0e-10
        end),
      "wheel_configuration",
      "orthonormal wheel axes required"
    )

    if not Enum.all?(axes, fn axis ->
         Enum.all?(axis, &(&1 == -1 or &1 == 0 or &1 == 1)) and dot(axis, axis) == 1
       end) or
         not Enum.all?([{0, 1}, {0, 2}, {1, 2}], fn {a, b} ->
           dot(Enum.at(axes, a), Enum.at(axes, b)) == 0
         end),
       do:
         throw(
           {:unsupported,
            "only signed orthogonal coordinate wheel axes are independently checked"}
         )

    require!(
      is_map(c["unload_modes"]) and map_size(c["unload_modes"]) <= 16 and
        Enum.all?(c["max_unload_torque_body_nm"], &(&1 >= 0)),
      "wheel_configuration",
      "bounded external unload modes required"
    )

    for {_, mode} <- c["unload_modes"] do
      require!(
        is_map(mode) and vector?(mode["external_torque_body_nm"]) and
          Enum.zip_with(
            mode["external_torque_body_nm"],
            c["max_unload_torque_body_nm"],
            &(abs(&1) <= &2)
          )
          |> Enum.all?(),
        "wheel_configuration",
        "unload torque exceeds declared external capacity"
      )
    end
  end

  defp stationary!(i, r, asset, c) do
    policy = get_in(i, ["study", "attitude", "assets", asset])
    initial = policy["initial"]
    terminal = get_in(i, ["study", "horizon", "terminals", asset])

    unless is_map(initial) and zero?(initial["angular_velocity_inertial_deg_s"]) and
             is_map(terminal) and
             (terminal["strategy"] == "fixed_inertial" or
                (terminal["strategy"] in ["activity_boundary", "execution_boundary"] and
                   zero?(terminal["angular_velocity_inertial_deg_s"]))) and
             same_q?(initial["quaternion_wxyz"], terminal["quaternion_wxyz"]),
           do:
             throw(
               {:unsupported,
                "constant known initial/terminal attitude and zero body rate required"}
             )

    require!(
      initial["frame"] == "eci_j2000" and initial["time_scale"] == "utc" and
        initial["epoch_s"] == get_in(i, ["study", "horizon", "starts_at_s"]) and
        terminal["frame"] == "eci_j2000",
      "wheel_initial_frame",
      "explicit stationary J2000/UTC state at horizon start required"
    )

    require!(
      get_in(policy, ["rigid_body", "principal_moments_kg_m2"]) == c["principal_moments_kg_m2"],
      "wheel_configuration",
      "rigid body and wheel inertia must agree"
    )

    requests = Map.new(i["mission"]["requests"], &{&1["id"], &1})

    for a <- r["activities"], a["asset_id"] == asset do
      request = requests[a["request_id"]]

      unless request["model"] == "fixed_attitude" and
               same_q?(
                 initial["quaternion_wxyz"],
                 get_in(request, ["parameters", "quaternion_wxyz"])
               ),
             do:
               throw(
                 {:unsupported,
                  "only fixed-attitude activities matching the initial attitude are independently checked"}
               )

      require!(
        is_list(a["attitude_profile"]) and
          Enum.all?(a["attitude_profile"], fn p ->
            same_q?(initial["quaternion_wxyz"], p["quaternion_wxyz"]) and
              zero?(p["angular_velocity_inertial_deg_s"]) and
              zero?(p["angular_acceleration_inertial_deg_s2"])
          end),
        "wheel_stationary_profile",
        "reported activity profile contradicts stationary inputs"
      )
    end

    transitions =
      Enum.filter(
        get_in(r, ["attitude_planning", "transitions"]) || [],
        &(&1["asset_id"] == asset)
      )

    terminal_motion =
      get_in(r, ["attitude_planning", "horizon_coverage", "assets", asset, "terminal_motion"])

    for transition <- transitions ++ if(is_map(terminal_motion), do: [terminal_motion], else: []) do
      require!(
        Enum.all?(transition["phases"] || [], fn p ->
          same_q?(initial["quaternion_wxyz"], p["quaternion_wxyz"]) and
            zero?(p["angular_velocity_inertial_deg_s"]) and
            zero?(p["angular_acceleration_inertial_deg_s2"])
        end),
        "wheel_stationary_profile",
        "reported transition contradicts stationary inputs"
      )
    end

    path = get_in(i, ["study", "path_constraints", "assets", asset])

    boundary =
      terminal["strategy"] in ["activity_boundary", "execution_boundary"] and
        Enum.any?(r["activities"], fn a ->
          a["asset_id"] == asset and
            a["ends_at_s"] == get_in(i, ["study", "horizon", "ends_at_s"]) and
            get_in(path, ["activity_modes", a["request_id"]]) == terminal["mode"]
        end)

    require!(
      is_map(path) and not Map.has_key?(c["unload_modes"], path["transition_mode"]) and
        (not Map.has_key?(c["unload_modes"], terminal["mode"]) or boundary),
      "wheel_unload_mode",
      "external unloading cannot be applied by idle or terminal modes"
    )
  end

  defp momentum(initial, segments, t),
    do:
      Enum.reduce(segments, initial, fn s, h ->
        Enum.zip_with(h, s.motor, &(&1 + &2 * max(0, min(t, s.b) - s.a)))
      end)

  defp dot(a, b), do: Enum.zip_with(a, b, &(&1 * &2)) |> Enum.sum()
  defp vector?(v), do: is_list(v) and length(v) == 3 and Enum.all?(v, &is_number/1)

  defp vector_near?(a, b),
    do: vector?(a) and vector?(b) and Enum.zip_with(a, b, &C.near?/2) |> Enum.all?()

  defp zero?(v), do: vector?(v) and Enum.all?(v, &(&1 == 0))
  defp state_near?(s, v), do: is_map(s) and vector_near?(Enum.map(@keys, &s[&1]), v)

  defp same_q?(a, b) do
    if is_list(a) and is_list(b) and length(a) == 4 and length(b) == 4 and
         Enum.all?(a ++ b, &is_number/1) and dot(a, a) > 0 and dot(b, b) > 0 do
      a = Enum.map(a, &(&1 / :math.sqrt(dot(a, a))))
      b = Enum.map(b, &(&1 / :math.sqrt(dot(b, b))))

      min(
        dot(Enum.zip_with(a, b, &(&1 - &2)), Enum.zip_with(a, b, &(&1 - &2))),
        dot(Enum.zip_with(a, b, &(&1 + &2)), Enum.zip_with(a, b, &(&1 + &2)))
      ) <= 1.0e-24
    else
      false
    end
  end

  defp require!(true, _, _), do: :ok
  defp require!(false, code, why), do: throw({:wheel, code, why})
end
