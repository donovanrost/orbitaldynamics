defmodule OrbitalDynamics.MissionAnalysis.AttitudePathCheck do
  @moduledoc """
  Content-bound independent numerical comparisons for frozen attitude/path cases.

  Library rotations and intersections are physical-input comparisons. Quaternion
  ODE samples take production-exported control phase timings as inputs and do not
  independently establish their optimality. Cap witnesses are finite samples,
  never an exact non-overlap oracle or continuous path validation.
  """
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Trajectory, Vector3}
  alias OrbitalDynamics.MissionAnalysis.{Asset, Request, SphericalScene}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Quaternion, Pointing, Motion, Profile, Policy}
  alias OrbitalDynamics.MissionAnalysis.Path.{Result, Checks.ReflectedBeam}
  alias OrbitalDynamics.MissionAnalysis.Environments.Fixed

  @manifest_sha256 "afd86de6aa39af4fd885ae5a4148a16c5ea882497fffed8600d5136d53ba7584"
  @files ~w(AttitudePathReference.java dependencies.lock make_inputs.py export_phases.exs generate.sh orientation-input.csv motion-input.csv beam-input.csv profile-input.csv phase-input.csv orientation-reference.csv motion-reference.csv motion-samples.csv beam-reference.csv profile-reference.csv mission.json attitude-study.json path-study.json unknown-study.json scenarios.json)
  @tolerances %{
    "orientation_quaternion_norm" => 1.0e-12,
    "orientation_vector_norm" => 1.0e-11,
    "motion_duration_s" => 1.0e-8,
    "motion_quaternion_norm" => 1.0e-10,
    "motion_rate_deg_s" => 1.0e-8,
    "motion_initial_quaternion_norm" => 1.0e-12,
    "motion_initial_rate_deg_s" => 1.0e-10,
    "motion_terminal_quaternion_norm" => 1.0e-10,
    "motion_terminal_rate_deg_s" => 1.0e-8,
    "profile_rate_deg_s" => 1.0e-8,
    "profile_accel_deg_s2" => 1.0e-7,
    "ray_intersection_km" => 1.0e-7,
    "reflected_direction_norm" => 1.0e-12,
    "ground_location_deg" => 1.0e-7,
    "exported_control_values" => 1.0e-10
  }

  defmodule ProfileModel do
    def pointing(state, row, _) do
      t = state.epoch.seconds_since_j2000

      first =
        Quaternion.increment(
          Vector3.scale(
            if(row["law"] == "fixed_axis", do: vector(row, "axis_"), else: {1, 0, 0}),
            num(row, "rate_deg_s") * t + num(row, "accel_deg_s2") * t * t / 2
          )
        )

      moving =
        if row["law"] == "fixed_axis",
          do: first,
          else:
            Quaternion.multiply(
              first,
              Quaternion.increment({0, num(row, "second_rate_deg_s") * t, 0})
            )

      {:ok, Pointing.new!(state.frame, Quaternion.multiply(moving, quaternion(row, "base_")))}
    end

    defp num(r, k), do: elem(Float.parse(r[k]), 0)
    defp vector(r, p), do: {num(r, p <> "x"), num(r, p <> "y"), num(r, p <> "z")}
    defp quaternion(r, p), do: Quaternion.new!(Enum.map(~w(w x y z), &num(r, p <> &1)))
  end

  def bundle_path,
    do: Application.app_dir(:orbital_dynamics, "priv/validation/attitude_path_orekit")

  def verify(directory \\ bundle_path()) do
    try do
      hashes = verify_content!(directory)
      orientation = orientation_checks(directory)
      {motion, plans} = motion_checks(directory)
      ode = ode_checks(directory, plans)
      profile = profile_checks(directory)
      beam = beam_checks(directory)

      groups = %{
        "orientations" => orientation,
        "motion_construction" => motion,
        "phase_ode" => ode,
        "sampled_profile" => profile,
        "beam_geometry" => beam
      }

      expected = %{
        "orientations" => 45,
        "motion_construction" => 18,
        "phase_ode" => 17,
        "sampled_profile" => 12,
        "beam_geometry" => 169
      }

      coverage = Enum.all?(expected, fn {name, count} -> groups[name]["case_count"] == count end)
      passed = coverage and Enum.all?(groups, fn {_, g} -> g["status"] == "pass" end)

      {:ok,
       %{
         "format" => "attitude_path_numerical_check.v1",
         "status" => if(passed, do: "pass", else: "fail"),
         "tool" => "Orekit 13.1.7 / Hipparchus 4.0.3",
         "source_manifest_sha256" => @manifest_sha256,
         "verified_file_sha256" => hashes,
         "tolerances" => @tolerances,
         "groups" => groups,
         "expected_case_coverage_passed" => coverage,
         "limits" => [
           "frozen finite cases, not validation of all missions, hardware, optics or continuous-time safety",
           "phase ODE takes production control timings as inputs; separate Brent solve checks the declared construction duration",
           "cap search uses 16 radial rings and 128 azimuth samples, plus center; no witness is not proof of non-overlap",
           "guard rejections without witnesses are not established false positives",
           "parallel geometric solar inputs, spherical bodies, dummy TAI epoch; no ephemeris or frame-conversion validation",
           "mode expectations are internal semantic fixtures, not independent evidence of hardware blocking behavior"
         ]
       }}
    rescue
      e in [ArgumentError, MatchError, KeyError, File.Error] ->
        {:error, {:attitude_path_check_failed, Exception.message(e)}}
    end
  end

  defp orientation_checks(dir) do
    refs = index(read(dir, "orientation-reference.csv"))
    inputs = read(dir, "orientation-input.csv")
    same_ids!(inputs, refs)

    rows =
      Enum.map(inputs, fn r ->
        ref = refs[r["id"]]

        {:ok, pointing} =
          Pointing.from_direction(
            vector(r, "d_"),
            Frame.new!(:verification, :verification, :inertial),
            %{
              "body_to_payload_quaternion" => quaternion(r, "mount_") |> Tuple.to_list(),
              "roll_reference_inertial" => vector(r, "ref_") |> Tuple.to_list()
            }
          )

        q = pointing.quaternion

        %{
          "id" => r["id"],
          "orientation_quaternion_norm" => q_error(q, quaternion(ref, "q")),
          "orientation_vector_norm" =>
            Vector3.norm(
              Vector3.subtract(Quaternion.rotate(q, vector(r, "v_")), vector(ref, "v"))
            )
        }
      end)

    measured(rows, ~w(orientation_quaternion_norm orientation_vector_norm))
  end

  defp motion_checks(dir) do
    inputs = read(dir, "motion-input.csv")
    refs = index(read(dir, "motion-reference.csv"))
    same_ids!(inputs, refs)

    {rows, plans} =
      Enum.map_reduce(inputs, %{}, fn r, plans ->
        source = pose(r, "source_", 0)
        target = pose(r, "target_", num(r, "gap_s"))

        limits = %{
          max_rate_deg_s: num(r, "max_rate_deg_s"),
          max_accel_deg_s2: num(r, "max_accel_deg_s2"),
          settling_s: num(r, "settling_s")
        }

        {status, plan} = Motion.transition(source, target, limits)
        expected = refs[r["id"]]

        row = %{
          "id" => r["id"],
          "motion_duration_s" => abs(plan["required_s"] - num(expected, "required_s")),
          "feasibility_agrees" => status == :ok == bool(expected, "feasible")
        }

        {row, if(status == :ok, do: Map.put(plans, r["id"], plan), else: plans)}
      end)

    controls = read(dir, "phase-input.csv") |> Enum.group_by(& &1["id"])

    discrepancies =
      Enum.reduce(plans, 0, fn {id, p}, count ->
        exported = Map.get(controls, id, [])

        if length(exported) != length(p["phases"]),
          do: count + 1,
          else:
            count +
              Enum.count(Enum.zip(exported, p["phases"]), fn {row, phase} ->
                values =
                  [
                    num(row, "starts_s") - phase["starts_after_s"],
                    num(row, "ends_s") - phase["ends_after_s"]
                  ] ++
                    Enum.zip_with(
                      {num(row, "ax_deg_s2"), num(row, "ay_deg_s2"), num(row, "az_deg_s2")}
                      |> Tuple.to_list(),
                      phase["angular_acceleration_inertial_deg_s2"],
                      &(&1 - &2)
                    )

                Enum.any?(values, &(abs(&1) > @tolerances["exported_control_values"]))
              end)
      end)

    # All exported controls must correspond to a fresh feasible plan.
    discrepancies = discrepancies + Enum.count(Map.keys(controls), &(not Map.has_key?(plans, &1)))
    result = measured(rows, ["motion_duration_s"])
    mismatch = Enum.count(rows, &(not &1["feasibility_agrees"]))

    {result
     |> Map.put("feasibility_mismatch_count", mismatch)
     |> Map.put("control_input_mismatch_count", discrepancies)
     |> gate(mismatch == 0 and discrepancies == 0), plans}
  end

  defp ode_checks(dir, plans) do
    raw = read(dir, "motion-samples.csv")
    grouped = Enum.group_by(raw, & &1["id"])
    inputs = index(read(dir, "motion-input.csv"))

    independently_feasible =
      read(dir, "motion-reference.csv")
      |> Enum.filter(&bool(&1, "feasible"))
      |> Enum.map(& &1["id"])

    coverage =
      Enum.sort(Map.keys(grouped)) == Enum.sort(independently_feasible) and
        Enum.all?(plans, fn {id, _plan} ->
          samples = Map.get(grouped, id, [])

          samples != [] and num(hd(samples), "elapsed_s") == 0 and
            abs(num(List.last(samples), "elapsed_s") - num(inputs[id], "gap_s")) <= 1.0e-9 and
            samples
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.all?(fn [a, b] -> num(b, "elapsed_s") > num(a, "elapsed_s") end)
        end)

    boundaries =
      Enum.map(grouped, fn {id, samples} ->
        input = inputs[id]
        first = hd(samples)
        last = List.last(samples)

        %{
          "id" => id,
          "motion_initial_quaternion_norm" =>
            q_error(quaternion(first, "q"), quaternion(input, "source_")),
          "motion_initial_rate_deg_s" =>
            Vector3.norm(Vector3.subtract(ode_rate(first), vector(input, "source_rate_"))),
          "motion_terminal_quaternion_norm" =>
            q_error(quaternion(last, "q"), quaternion(input, "target_")),
          "motion_terminal_rate_deg_s" =>
            Vector3.norm(Vector3.subtract(ode_rate(last), vector(input, "target_rate_")))
        }
      end)

    boundary_result =
      measured(
        boundaries,
        ~w(motion_initial_quaternion_norm motion_initial_rate_deg_s motion_terminal_quaternion_norm motion_terminal_rate_deg_s)
      )

    rows =
      Enum.map(raw, fn r ->
        plan = Map.fetch!(plans, r["id"])
        state = Motion.at(plan, num(r, "elapsed_s"))

        %{
          "id" => r["id"],
          "elapsed_s" => num(r, "elapsed_s"),
          "motion_quaternion_norm" => q_error(state.quaternion, quaternion(r, "q")),
          "motion_rate_deg_s" =>
            Vector3.norm(Vector3.subtract(state.angular_velocity_deg_s, ode_rate(r)))
        }
      end)

    measured(rows, ~w(motion_quaternion_norm motion_rate_deg_s))
    |> Map.put("case_count", map_size(plans))
    |> Map.put("sample_count", length(rows))
    |> Map.put("boundary_measurements", boundary_result)
    |> Map.put("sample_epoch_coverage_passed", coverage)
    |> gate(coverage and boundary_result["status"] == "pass")
  end

  defp ode_rate(r), do: {num(r, "wx_deg_s"), num(r, "wy_deg_s"), num(r, "wz_deg_s")}

  defp profile_checks(dir) do
    Code.ensure_loaded!(ProfileModel)
    refs = index(read(dir, "profile-reference.csv"))
    inputs = read(dir, "profile-input.csv")
    same_ids!(inputs, refs)
    frame = Frame.new!(:verification, :verification, :inertial)
    state = fn t -> StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame) end

    asset =
      Asset.new!(
        "verification",
        %Trajectory{
          scenario_id: "profile",
          states: [state.(-100), state.(100)],
          assumptions: %{}
        },
        %{ProfileModel => %{}},
        %{}
      )

    request =
      Request.new!("profile", ProfileModel, :opaque,
        activity_type: "verify",
        starts_at_s: 0,
        ends_at_s: 100,
        duration_s: 1,
        time_scale: :tai,
        value: 1,
        parameters: %{},
        resource_costs: %{}
      )

    limits = %{
      max_rate_deg_s: 100,
      max_accel_deg_s2: 100,
      settling_s: 0,
      initial: :unknown,
      pointing_configurations: %{ProfileModel => %{}}
    }

    rows =
      Enum.map(inputs, fn r ->
        p =
          Policy.new!(%{"verification" => limits},
            profile_step_s: 1,
            derivative_step_s: num(r, "derivative_s"),
            search_step_s: 1,
            max_candidate_starts: 1,
            max_evaluations: 100
          )

        {:ok, sample, _} =
          Profile.sample(
            asset,
            request,
            r,
            num(r, "epoch_s"),
            %{},
            p,
            fn _, t -> {:ok, state.(t)} end,
            %{values: %{}, evaluations: 0}
          )

        ref = refs[r["id"]]

        %{
          "id" => r["id"],
          "law" => r["law"],
          "profile_rate_deg_s" =>
            Vector3.norm(
              Vector3.subtract(
                List.to_tuple(sample["angular_velocity_inertial_deg_s"]),
                vector(ref, "w")
              )
            ),
          "profile_accel_deg_s2" =>
            Vector3.norm(
              Vector3.subtract(
                List.to_tuple(sample["angular_acceleration_inertial_deg_s2"]),
                vector(ref, "a")
              )
            ),
          "rate_estimate_vs_analytic_deg_s" =>
            Vector3.norm(
              Vector3.subtract(
                List.to_tuple(sample["angular_velocity_inertial_deg_s"]),
                vector(ref, "true_w")
              )
            ),
          "accel_estimate_vs_analytic_deg_s2" =>
            Vector3.norm(
              Vector3.subtract(
                List.to_tuple(sample["angular_acceleration_inertial_deg_s2"]),
                vector(ref, "true_a")
              )
            )
        }
      end)

    measured(rows, ~w(profile_rate_deg_s profile_accel_deg_s2))
    |> Map.put(
      "max_rate_estimate_vs_analytic_deg_s",
      max_value(rows, "rate_estimate_vs_analytic_deg_s")
    )
    |> Map.put(
      "max_accel_estimate_vs_analytic_deg_s2",
      max_value(rows, "accel_estimate_vs_analytic_deg_s2")
    )
  end

  defp beam_checks(dir) do
    refs = index(read(dir, "beam-reference.csv"))
    inputs = read(dir, "beam-input.csv")
    same_ids!(inputs, refs)
    rows = Enum.map(inputs, fn r -> beam_case(r, refs[r["id"]]) end)

    geometry =
      measured(rows, ~w(ray_intersection_km reflected_direction_norm ground_location_deg))

    counts = %{
      "ray_hit_mismatch_count" => Enum.count(rows, &(not &1["ray_hit_agrees"])),
      "expected_status_mismatch_count" => Enum.count(rows, &(not &1["expected_status_agrees"])),
      "direct_witness_false_clear_count" => Enum.count(rows, & &1["direct_witness_false_clear"]),
      "modeled_cone_false_clear_count" => Enum.count(rows, & &1["modeled_cone_false_clear"]),
      "guard_rejections_without_sampled_witness" =>
        Enum.count(rows, &(&1["production_status"] == "violated" and &1["cone_witnesses"] == 0)),
      "cases_with_direct_witnesses" => Enum.count(rows, &(&1["direct_solar_witnesses"] > 0)),
      "reflecting_cases_with_direct_witnesses" =>
        Enum.count(
          rows,
          &(&1["optical_behavior"] == "reflecting" and &1["direct_solar_witnesses"] > 0)
        )
    }

    geometry
    |> Map.merge(counts)
    |> gate(
      Enum.all?(
        Map.drop(
          counts,
          ~w(guard_rejections_without_sampled_witness cases_with_direct_witnesses reflecting_cases_with_direct_witnesses)
        ),
        fn {_, n} -> n == 0 end
      )
    )
  end

  defp beam_case(r, ref) do
    radius = num(r, "radius_km")
    position = vector(r, "r_")
    sun = vector(r, "sun_")
    normal = vector(r, "normal_")
    frame = Frame.new!(:verification, :verification, :inertial)
    body = CentralBody.new!(:verification, 1, equatorial_radius_km: radius, j2: 0)

    env =
      Fixed.new!(frame, Epoch.new!(0, :tai),
        sun_direction: sun,
        rotation_angle_rad: num(r, "rotation_rad"),
        rotation_rate_rad_s: 0,
        starts_at_s: -1,
        ends_at_s: 1
      )

    scene = SphericalScene.new!(body, frame, :tai, {Fixed, env})
    state = StateVector.new!(position, {0, 0, 0}, Epoch.new!(0, :tai), frame)

    asset =
      Asset.new!(
        "beam",
        %Trajectory{
          scenario_id: "beam",
          states: [state, %{state | epoch: Epoch.new!(1, :tai)}],
          assumptions: %{}
        },
        %{},
        %{}
      )

    configuration = %{
      "mirror_normal_body" => [0, 0, 1],
      "back_face_behavior" => r["back"],
      "solar_angular_radius_deg" => num(r, "solar_radius_deg"),
      "beam_padding_deg" => num(r, "padding_deg"),
      "exclusion_regions" => [
        %{
          "id" => "region",
          "latitude_deg" => num(r, "region_lat_deg"),
          "longitude_deg" => num(r, "region_lon_deg"),
          "radius_km" => num(r, "region_radius_km")
        }
      ]
    }

    {:ok, session, _} = ReflectedBeam.prepare(asset, scene, configuration)
    reference = if abs(elem(normal, 2)) > 0.95, do: {1, 0, 0}, else: {0, 0, 1}
    {:ok, q} = Quaternion.from_direction(normal, reference)

    behavior =
      case r["mode"] do
        "reflecting" -> "reflecting"
        "blocked_by_assumption" -> "blocked_by_assumption"
        _ -> "unknown"
      end

    {:ok, result} =
      ReflectedBeam.evaluate(
        state,
        Pointing.new!(frame, q),
        %{"name" => r["mode"], "parameters" => %{"optical_behavior" => behavior}},
        session
      )

    result = Result.validate!(result)
    status = Result.status(result)
    hit = ReflectedBeam.ray_hit(position, vector(ref, "d"), radius)
    expected_hit = bool(ref, "hit")

    error =
      if hit != nil and expected_hit,
        do:
          Vector3.norm(
            Vector3.subtract(hit, {num(ref, "hx_km"), num(ref, "hy_km"), num(ref, "hz_km")})
          ),
        else: 0.0

    direction_error =
      case result.metrics["reflected_direction_inertial"] do
        nil -> 0.0
        direction -> Vector3.norm(Vector3.subtract(List.to_tuple(direction), vector(ref, "d")))
      end

    location_error =
      case result.metrics["central_ray_hit"] do
        %{} = location when expected_hit ->
          max(
            abs(location["latitude_deg"] - num(ref, "lat_deg")),
            longitude_error(location["longitude_deg"], num(ref, "lon_deg"))
          )

        _ ->
          0.0
      end

    witnesses = trunc(num(ref, "direct_solar_witnesses"))
    cone = trunc(num(ref, "cone_witnesses"))

    %{
      "id" => r["id"],
      "production_status" => status,
      "optical_behavior" => behavior,
      "minimum_sampled_cap_angle_deg" => num(ref, "min_cap_angle_deg"),
      "cone_half_angle_deg" => num(r, "solar_radius_deg") + num(r, "padding_deg"),
      "reference_visibility" => ref["visibility"],
      "ray_intersection_km" => error,
      "reflected_direction_norm" => direction_error,
      "ground_location_deg" => location_error,
      "ray_hit_agrees" => hit != nil == expected_hit,
      "expected_status_agrees" => r["expected"] == "envelope" or r["expected"] == status,
      "cone_witnesses" => cone,
      "direct_solar_witnesses" => witnesses,
      "cap_sample_count" => trunc(num(ref, "cap_samples")),
      "direct_witness_false_clear" =>
        status == "supported" and behavior == "reflecting" and witnesses > 0,
      "modeled_cone_false_clear" =>
        status == "supported" and behavior == "reflecting" and
          r["back"] == "two_sided_reflecting_by_assumption" and ref["visibility"] != "full" and
          cone > 0
    }
  end

  defp measured(rows, metrics) do
    values =
      Map.new(metrics, fn metric ->
        {metric,
         %{
           "max_error" => max_value(rows, metric),
           "tolerance" => @tolerances[metric],
           "passed" => max_value(rows, metric) <= @tolerances[metric]
         }}
      end)

    %{
      "status" => if(Enum.all?(values, fn {_, m} -> m["passed"] end), do: "pass", else: "fail"),
      "case_count" => length(rows),
      "measurements" => values,
      "cases" => rows
    }
  end

  defp gate(result, true), do: result
  defp gate(result, false), do: Map.put(result, "status", "fail")
  defp max_value(rows, k), do: rows |> Enum.map(& &1[k]) |> Enum.max(fn -> 0.0 end)

  defp pose(r, p, t),
    do: %{
      "epoch_s" => t,
      "quaternion_wxyz" => quaternion(r, p) |> Tuple.to_list(),
      "angular_velocity_inertial_deg_s" => vector(r, p <> "rate_") |> Tuple.to_list()
    }

  defp q_error(a, b) do
    a = Quaternion.new!(a) |> Tuple.to_list()
    b = Quaternion.new!(b) |> Tuple.to_list()

    min(
      :math.sqrt(Enum.zip_with(a, b, fn x, y -> (x - y) * (x - y) end) |> Enum.sum()),
      :math.sqrt(Enum.zip_with(a, b, fn x, y -> (x + y) * (x + y) end) |> Enum.sum())
    )
  end

  defp num(r, k) do
    {x, ""} = Float.parse(Map.fetch!(r, k))
    x
  end

  defp vector(r, p), do: {num(r, p <> "x"), num(r, p <> "y"), num(r, p <> "z")}
  defp quaternion(r, p), do: Quaternion.new!(Enum.map(~w(w x y z), &num(r, p <> &1)))

  defp bool(r, k) do
    case Map.fetch!(r, k) do
      "true" -> true
      "false" -> false
    end
  end

  defp longitude_error(a, b), do: min(abs(a - b), abs(abs(a - b) - 360))

  defp index(rows) do
    indexed = Map.new(rows, &{&1["id"], &1})

    unless map_size(indexed) == length(rows),
      do: raise(ArgumentError, "duplicate independent case IDs")

    indexed
  end

  defp same_ids!(inputs, refs) do
    unless length(inputs) == map_size(refs) and
             Enum.sort(Enum.map(inputs, & &1["id"])) == Enum.sort(Map.keys(refs)),
           do: raise(ArgumentError, "independent reference case identities differ")
  end

  defp read(dir, name) do
    [header | rows] = File.read!(Path.join(dir, name)) |> String.split("\n", trim: true)
    keys = String.split(header, ",")

    Enum.map(rows, fn row ->
      values = String.split(row, ",")
      unless length(values) == length(keys), do: raise(ArgumentError, "reference CSV width")
      Map.new(Enum.zip(keys, values))
    end)
  end

  defp verify_content!(dir) do
    bytes = File.read!(Path.join(dir, "SHA256SUMS"))

    unless sha(bytes) == @manifest_sha256,
      do: raise(ArgumentError, "attitude/path manifest identity mismatch")

    entries =
      String.split(bytes, "\n", trim: true)
      |> Enum.map(fn line ->
        [hash, name] = String.split(line, "  ")
        {name, hash}
      end)

    unless Enum.map(entries, &elem(&1, 0)) == @files,
      do: raise(ArgumentError, "unexpected attitude/path bundle files")

    Enum.each(entries, fn {name, hash} ->
      unless sha(File.read!(Path.join(dir, name))) == hash,
        do: raise(ArgumentError, "attitude/path content mismatch: #{name}")
    end)

    Map.new(entries)
  end

  defp sha(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
