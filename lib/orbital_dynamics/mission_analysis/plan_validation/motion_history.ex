defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory do
  @moduledoc "Independent parent-derived motion interval reconstruction and checkpoint kinematics. No producer motion/history helpers."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker, as: C

  def records(parent) do
    inputs = parent["payload"]["inputs"]
    report = parent["payload"]["report"]

    Map.new(inputs["mission"]["assets"], fn asset ->
      id = asset["id"]

      acquisitions =
        report["attitude_planning"]["transitions"]
        |> Enum.filter(
          &(&1["asset_id"] == id and &1["destination_epoch_s"] > &1["source_epoch_s"])
        )
        |> Map.new(fn p ->
          a = Enum.find(report["activities"], &(&1["id"] == p["to_activity_id"]))

          {a["request_id"],
           interval(
             p,
             get_in(inputs, ["study", "path_constraints", "assets", id, "transition_mode"]),
             false
           )}
        end)

      p =
        get_in(report, ["attitude_planning", "horizon_coverage", "assets", id, "terminal_motion"])

      tail =
        if is_map(p) and p["destination_epoch_s"] > p["source_epoch_s"],
          do: interval(p, inputs["study"]["horizon"]["terminals"][id]["mode"], false),
          else: :null

      {id, %{"acquisitions" => acquisitions, "terminal" => tail, "committed" => :null}}
    end)
  end

  defp interval(p, mode, strict) do
    p =
      Map.take(p, ~w(source_epoch_s destination_epoch_s status phases))
      |> Map.update!("phases", fn phases ->
        Enum.filter(phases, &(&1["ends_after_s"] > &1["starts_after_s"]))
      end)

    %{
      "source_plan" => p,
      "mode" => mode,
      "starts_at_s" => p["source_epoch_s"],
      "ends_at_s" => p["destination_epoch_s"],
      "strict" => strict
    }
  end

  defp block_stop(row, t) do
    p = row["source_plan"]
    origin = p["source_epoch_s"]

    remaining =
      Enum.filter(
        p["phases"],
        &(origin + &1["ends_after_s"] > t and &1["ends_after_s"] > &1["starts_after_s"])
      )

    case remaining do
      [current | _] ->
        if current["kind"] != "hold" and origin + current["starts_after_s"] <= t and
             row["starts_at_s"] <= t and t < row["ends_at_s"] do
          block = Enum.take_while(remaining, &(&1["kind"] != "hold"))
          min(row["ends_at_s"], origin + List.last(block)["ends_after_s"])
        end

      _ ->
        nil
    end
  end

  def future(parent, t) do
    assets =
      Map.new(records(parent), fn {id, c} ->
        acquisitions =
          Map.new(Enum.filter(c["acquisitions"], fn {_, r} -> r["ends_at_s"] > t end), fn {req, r} ->
            {req,
             Map.merge(r, %{
               "starts_at_s" => max(t, r["starts_at_s"]),
               "strict" => block_stop(r, t) == r["ends_at_s"]
             })}
          end)

        tail =
          if is_map(c["terminal"]) and c["terminal"]["ends_at_s"] > t,
            do: Map.put(c["terminal"], "starts_at_s", max(t, c["terminal"]["starts_at_s"])),
            else: :null

        committed =
          (Map.values(acquisitions) ++ if(is_map(tail), do: [tail], else: []))
          |> Enum.reduce_while(:null, fn row, _ ->
            case block_stop(row, t) do
              nil ->
                {:cont, :null}

              stop ->
                {:halt,
                 Map.merge(row, %{"starts_at_s" => t, "ends_at_s" => stop, "strict" => true})}
            end
          end)

        {id, %{"acquisitions" => acquisitions, "terminal" => tail, "committed" => committed}}
      end)

    %{"source_snapshot_id" => parent["snapshot_id"], "role" => "replanning", "assets" => assets}
  end

  def pins(parent, t) do
    future(parent, t)["assets"]
    |> Enum.flat_map(fn {asset, c} ->
      c["acquisitions"]
      |> Enum.filter(fn {_, r} -> r["strict"] end)
      |> Enum.map(fn {id, _} ->
        parent["payload"]["report"]["activities"]
        |> Enum.find(&(&1["asset_id"] == asset and &1["request_id"] == id))
        |> C.placement()
      end)
    end)
  end

  def replay(parent, t, acts, running) do
    start = parent["payload"]["inputs"]["study"]["horizon"]["starts_at_s"]

    assets =
      Map.new(records(parent), fn {id, c} ->
        list = Enum.filter(acts, &(&1["asset_id"] == id))
        selected = Enum.map(list, & &1["request_id"])

        acquisitions =
          Map.new(Map.take(c["acquisitions"], selected), fn {req, r} ->
            {req, Map.put(r, "strict", true)}
          end)

        from = if list == [], do: start, else: List.last(list)["ends_at_s"]

        tail =
          if from == t or Enum.any?(running, &(&1["asset_id"] == id)) do
            :null
          else
            candidates =
              Map.values(c["acquisitions"]) ++
                if(is_map(c["terminal"]), do: [c["terminal"]], else: [])

            r =
              Enum.find(
                candidates,
                &(&1["starts_at_s"] <= from and from < &1["ends_at_s"] and t <= &1["ends_at_s"])
              ) || raise(ArgumentError, "missing parent motion prefix")

            Map.merge(r, %{"starts_at_s" => from, "ends_at_s" => t, "strict" => true})
          end

        {id, %{"acquisitions" => acquisitions, "terminal" => tail, "committed" => :null}}
      end)

    %{
      "source_snapshot_id" => parent["snapshot_id"],
      "role" => "execution_prefix",
      "assets" => assets
    }
  end

  def terminal(parent, id, t) do
    report = parent["payload"]["report"]
    study = parent["payload"]["inputs"]["study"]

    activity =
      Enum.find(
        report["activities"],
        &(&1["asset_id"] == id and &1["starts_at_s"] < t and t <= &1["ends_at_s"])
      )

    if activity do
      p =
        Enum.find(activity["attitude_profile"], &(&1["epoch_s"] == t)) ||
          raise(ArgumentError, "missing exact activity checkpoint")

      Map.merge(Map.take(p, ~w(quaternion_wxyz angular_velocity_inertial_deg_s)), %{
        "strategy" => "activity_boundary",
        "frame" => "eci_j2000",
        "mode" =>
          study["path_constraints"]["assets"][id]["activity_modes"][activity["request_id"]]
      })
    else
      c = records(parent)[id]

      candidates =
        Map.values(c["acquisitions"]) ++ if(is_map(c["terminal"]), do: [c["terminal"]], else: [])

      row =
        Enum.find(candidates, &(&1["starts_at_s"] <= t and t <= &1["ends_at_s"])) ||
          raise(ArgumentError, "no parent checkpoint motion")

      p = row["source_plan"]

      phase =
        Enum.find(p["phases"], &(t < p["source_epoch_s"] + &1["ends_after_s"])) ||
          List.last(p["phases"])

      {q, w} = kinematics(phase, p["source_epoch_s"], t)

      %{
        "strategy" => "execution_boundary",
        "frame" => "eci_j2000",
        "mode" => Map.get(phase, "mode_name", row["mode"]),
        "quaternion_wxyz" => q,
        "angular_velocity_inertial_deg_s" => w
      }
    end
  end

  # Independently evaluate declared constant-axis Hamilton phases, retaining original clocks.
  defp kinematics(p, origin, t) do
    case p["source_phase"] do
      %{} = clock ->
        t = max(origin + p["starts_after_s"], min(t, origin + p["ends_after_s"]))
        kinematics(clock["phase"], clock["source_epoch_s"], t)

      nil ->
        dt =
          cond do
            t <= origin + p["starts_after_s"] -> 0.0
            t >= origin + p["ends_after_s"] -> p["ends_after_s"] - p["starts_after_s"]
            true -> t - origin - p["starts_after_s"]
          end

        w = p["angular_velocity_inertial_deg_s"]
        alpha = p["angular_acceleration_inertial_deg_s2"]
        rotation = Enum.zip_with(w, alpha, fn w, a -> w * dt + a * dt * dt / 2 end)
        angle = :math.sqrt(Enum.sum(Enum.map(rotation, &(&1 * &1))))

        increment =
          if angle == 0,
            do: [1.0, 0.0, 0.0, 0.0],
            else: [
              :math.cos(angle * :math.pi() / 360)
              | Enum.map(rotation, &(&1 / angle * :math.sin(angle * :math.pi() / 360)))
            ]

        [a, b, c, d] = increment
        [w0, x, y, z] = normalize(p["quaternion_wxyz"])

        q =
          normalize([
            a * w0 - b * x - c * y - d * z,
            a * x + b * w0 + c * z - d * y,
            a * y - b * z + c * w0 + d * x,
            a * z + b * y - c * x + d * w0
          ])

        {q, Enum.zip_with(w, alpha, &(&1 + &2 * dt))}
    end
  end

  @doc "Evaluate a saved Hamilton phase with its original clock, including acceleration."
  def phase_pose(p, origin, t) do
    {q, w} = kinematics(p, origin, t)
    alpha = phase_acceleration(p)

    %{
      "epoch_s" => t,
      "quaternion_wxyz" => q,
      "angular_velocity_inertial_deg_s" => w,
      "angular_acceleration_inertial_deg_s2" => alpha
    }
  end

  defp phase_acceleration(%{"source_phase" => %{"phase" => p}}), do: phase_acceleration(p)
  defp phase_acceleration(p), do: p["angular_acceleration_inertial_deg_s2"]

  defp normalize(q) do
    norm = :math.sqrt(Enum.sum(Enum.map(q, &(&1 * &1))))
    Enum.map(q, &(&1 / norm))
  end

  def same_replay_inputs?(actual, expected) do
    # Float arithmetic is compared only at independently reconstructed boundary states.
    ids = Map.keys(expected["study"]["horizon"]["terminals"])

    valid =
      Enum.all?(ids, fn id ->
        a = actual["study"]["horizon"]["terminals"][id]
        b = expected["study"]["horizon"]["terminals"][id]

        near_vector?(a["quaternion_wxyz"], b["quaternion_wxyz"], 1.0e-12) and
          near_vector?(a["angular_velocity_inertial_deg_s"], b["angular_velocity_inertial_deg_s"])
      end)

    normalized =
      Enum.reduce(ids, expected, fn id, acc ->
        Enum.reduce(~w(quaternion_wxyz angular_velocity_inertial_deg_s), acc, fn key, acc ->
          put_in(
            acc,
            ["study", "horizon", "terminals", id, key],
            actual["study"]["horizon"]["terminals"][id][key]
          )
        end)
      end)

    valid and actual == normalized
  end

  defp near_vector?(a, b, tolerance \\ 1.0e-8),
    do:
      is_list(a) and is_list(b) and length(a) == length(b) and
        Enum.zip_with(a, b, fn x, y ->
          is_number(x) and is_number(y) and abs(x - y) <= tolerance
        end)
        |> Enum.all?()

  def check(i, _r, label) do
    if history = i["study"]["saved_motion"] do
      try do
        ids = Enum.map(i["mission"]["assets"], & &1["id"])

        basic =
          is_map(history) and Enum.sort(Map.keys(history)) == ~w(assets role source_snapshot_id) and
            history["role"] in ~w(replanning execution_prefix) and
            Regex.match?(
              ~r/\Amission_plan_snapshot:[0-9a-f]{64}\z/,
              history["source_snapshot_id"]
            ) and Enum.sort(Map.keys(history["assets"])) == Enum.sort(ids)

        entries =
          Enum.flat_map(history["assets"], fn {asset, c} ->
            unless Enum.sort(Map.keys(c)) == ~w(acquisitions committed terminal),
              do: raise(ArgumentError, "unknown motion contract fields")

            Enum.map(
              Map.values(c["acquisitions"]) ++
                Enum.filter([c["terminal"], c["committed"]], &is_map/1),
              &{asset, &1}
            )
          end)

        records =
          Enum.all?(entries, fn {asset, row} ->
            p = row["source_plan"]

            Enum.sort(Map.keys(row)) == ~w(ends_at_s mode source_plan starts_at_s strict) and
              is_boolean(row["strict"]) and is_number(row["starts_at_s"]) and
              is_number(row["ends_at_s"]) and row["starts_at_s"] < row["ends_at_s"] and
              row["starts_at_s"] >= p["source_epoch_s"] and
              row["ends_at_s"] <= p["destination_epoch_s"] and is_list(p["phases"]) and
              length(p["phases"]) in 1..1024 and
              Map.has_key?(i["study"]["path_constraints"]["assets"][asset]["modes"], row["mode"])
          end)

        pins = get_in(i, ["study", "scheduling", "protected_activities"]) || []

        committed =
          Enum.all?(history["assets"], fn {asset, c} ->
            Enum.all?(c["acquisitions"], fn {req, row} ->
              not row["strict"] or history["role"] == "execution_prefix" or
                Enum.any?(
                  pins,
                  &(&1["request_id"] == req and &1["asset_id"] == asset and
                      &1["starts_at_s"] == row["ends_at_s"])
                )
            end)
          end)

        confirmation =
          history["role"] != "replanning" or
            (get_in(i, ["execution", "last_update", "motion_source_snapshot_id"]) ==
               history["source_snapshot_id"] and
               get_in(i, ["execution", "last_update", "as_of_s"]) ==
                 i["study"]["horizon"]["starts_at_s"])

        C.check(
          basic and records and committed and confirmation,
          "saved_motion_contract",
          label,
          "invalid motion intervals, source identity or committed destination"
        )
      rescue
        _ -> [C.issue("saved_motion_schema", label, "malformed saved motion evidence")]
      end
    else
      []
    end
  end
end
