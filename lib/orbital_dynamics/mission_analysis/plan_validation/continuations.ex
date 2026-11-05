defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Continuations do
  @moduledoc "Independent segment identity, reservation and executed-prefix reconstruction. No producer continuation helpers are used."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker, as: C

  def check(i, r, label) do
    try do
      rows = get_in(i, ["study", "continuations"]) || %{}
      ensure!(is_map(rows) and map_size(rows) <= 100, "bounded continuation records required")
      current = Map.new(i["mission"]["requests"], &{&1["id"], &1})
      assets = Enum.map(i["mission"]["assets"], & &1["id"])

      issues =
        Enum.flat_map(rows, fn {id, row} ->
          ensure!(
            is_map(row) and
              Enum.sort(Map.keys(row)) == ~w(baseline_activity kind request source_snapshot_id),
            "invalid continuation record"
          )

          q = current[id]
          origin = row["request"]
          full = row["baseline_activity"]

          ensure!(
            is_map(q) and is_map(origin) and is_map(full),
            "continuation request/placement missing"
          )

          ensure!(
            Enum.sort(Map.keys(origin)) ==
              ~w(activity_type duration_s ends_at_s id model parameters resource_costs starts_at_s target value) and
              Enum.sort(Map.keys(full)) == ~w(asset_id ends_at_s request_id starts_at_s),
            "invalid original request or placement fields"
          )

          ensure!(
            is_binary(row["source_snapshot_id"]) and
              Regex.match?(~r/\Amission_plan_snapshot:[0-9a-f]{64}\z/, row["source_snapshot_id"]),
            "invalid continuation source identity"
          )

          ensure!(
            full["asset_id"] in assets and full["request_id"] == id and origin["id"] == id,
            "continuation identity differs"
          )

          ensure!(
            Enum.all?(~w(starts_at_s ends_at_s duration_s value), &is_number(origin[&1])) and
              is_number(full["starts_at_s"]) and is_number(full["ends_at_s"]) and
              origin["duration_s"] > 0 and
              full["ends_at_s"] == full["starts_at_s"] + origin["duration_s"] and
              full["starts_at_s"] >= origin["starts_at_s"] and
              full["ends_at_s"] <= origin["ends_at_s"],
            "invalid original activity timing"
          )

          same =
            Enum.all?(~w(id model activity_type target parameters), &(q[&1] == origin[&1])) and
              q["starts_at_s"] >= full["starts_at_s"] and q["ends_at_s"] <= full["ends_at_s"] and
              q["duration_s"] == q["ends_at_s"] - q["starts_at_s"]

          legal =
            case row["kind"] do
              "remaining" ->
                q["starts_at_s"] > full["starts_at_s"] and
                  q["starts_at_s"] == get_in(i, ["study", "horizon", "starts_at_s"]) and
                  q["ends_at_s"] == full["ends_at_s"] and q["resource_costs"] == %{} and
                  q["value"] == origin["value"]

              "execution_prefix" ->
                q["ends_at_s"] == get_in(i, ["study", "horizon", "ends_at_s"]) and
                  q["ends_at_s"] < full["ends_at_s"] and q["value"] == 0 and
                  q["resource_costs"] ==
                    if(q["starts_at_s"] == full["starts_at_s"],
                      do: origin["resource_costs"],
                      else: %{}
                    )

              _ ->
                false
            end

          selected = Enum.filter(r["activities"], &(&1["request_id"] == id))

          correct =
            length(selected) == 1 and hd(selected)["asset_id"] == full["asset_id"] and
              hd(selected)["starts_at_s"] == q["starts_at_s"] and
              hd(selected)["ends_at_s"] == q["ends_at_s"]

          descriptor = %{
            "kind" => row["kind"],
            "asset_id" => full["asset_id"],
            "activity_starts_at_s" => full["starts_at_s"],
            "activity_ends_at_s" => full["ends_at_s"],
            "original_duration_s" => origin["duration_s"],
            "original_value" => origin["value"],
            "original_resource_costs" => origin["resource_costs"]
          }

          C.check(
            same and legal,
            "continuation_original_identity",
            label <> "/" <> id,
            "segment changes its original request, costs, credit or bounds"
          ) ++
            C.check(
              correct,
              "continuation_reservation",
              label <> "/" <> id,
              "segment is missing or moved from its original asset and exact slot"
            ) ++
            C.check(
              length(selected) == 1 and hd(selected)["activity_segment"] == descriptor and
                Enum.any?(
                  r["requests"],
                  &(&1["request_id"] == id and &1["activity_segment"] == descriptor)
                ),
              "continuation_report_binding",
              label <> "/" <> id,
              "segment report does not identify its original activity"
            )
        end)

      h = get_in(i, ["study", "horizon", "starts_at_s"])

      joined =
        for {id, row} <- rows,
            current[id]["starts_at_s"] == h and row["baseline_activity"]["starts_at_s"] < h,
            do: id

      declared = get_in(i, ["execution", "last_update", "in_progress_request_ids"]) || []

      issues ++
        C.check(
          is_list(declared) and length(Enum.uniq(declared)) == length(declared) and
            Enum.sort(joined) == Enum.sort(declared),
          "continuation_state_binding",
          label,
          "running segments do not match the raw state declaration"
        )
    rescue
      e in [ArgumentError, KeyError, BadMapError, ArithmeticError, Protocol.UndefinedError] ->
        [C.issue("continuation_schema", label, Exception.message(e))]
    end
  end

  def active(parent, t),
    do:
      Enum.filter(
        parent["payload"]["report"]["activities"],
        &(&1["starts_at_s"] < t and t < &1["ends_at_s"])
      )

  defp original(old, q), do: get_in(old, ["study", "continuations", q["id"], "request"]) || q

  defp original_placement(old, a),
    do:
      get_in(old, ["study", "continuations", a["request_id"], "baseline_activity"]) ||
        C.placement(a)

  defp records(old, parent, active, kind) do
    Map.new(active, fn a ->
      id = a["request_id"]
      old_row = get_in(old, ["study", "continuations", id])

      row =
        if old_row,
          do: Map.take(old_row, ~w(request baseline_activity source_snapshot_id)),
          else: %{
            "request" => Enum.find(old["mission"]["requests"], &(&1["id"] == id)),
            "baseline_activity" => C.placement(a),
            "source_snapshot_id" => parent["snapshot_id"]
          }

      {id, Map.put(row, "kind", kind)}
    end)
  end

  defp slice(q, row, a, b, kind) do
    costs =
      if kind == "execution_prefix" and a == row["baseline_activity"]["starts_at_s"],
        do: row["request"]["resource_costs"],
        else: %{}

    Map.merge(q, %{
      "starts_at_s" => a,
      "ends_at_s" => b,
      "duration_s" => b - a,
      "value" => if(kind == "execution_prefix", do: 0, else: row["request"]["value"]),
      "resource_costs" => costs
    })
  end

  def replay_inputs(old, parent, completed, running, t) do
    partial = Enum.map(running, &(&1 |> Map.put("ends_at_s", t) |> Map.put("value", 0)))
    acts = Enum.sort_by(completed ++ partial, &{&1["starts_at_s"], &1["request_id"]})
    ids = Enum.map(acts, & &1["request_id"])
    rows = records(old, parent, running, "execution_prefix")

    mission =
      Map.update!(old["mission"], "requests", fn qs ->
        qs
        |> Enum.filter(&(&1["id"] in ids))
        |> Enum.map(fn q ->
          if rows[q["id"]],
            do:
              slice(
                q,
                rows[q["id"]],
                Enum.find(running, &(&1["request_id"] == q["id"]))["starts_at_s"],
                t,
                "execution_prefix"
              ),
            else: q
        end)
      end)

    scheduling =
      Map.merge(
        Map.take(old["study"]["scheduling"] || %{}, ["availability", "command_delivery"]),
        %{
          "strategy" => "greedy",
          "max_trials" => 1,
          "protected_activities" => Enum.map(acts, &C.placement/1)
        }
      )

    study =
      old["study"]
      |> put_in(["horizon", "ends_at_s"], t)
      |> Map.put("scheduling", scheduling)
      |> modes(&Map.take(&1, ids))

    all_rows = Map.merge(Map.take(old["study"]["continuations"] || %{}, ids), rows)
    study = put_rows(study, all_rows)

    checkpoints = running ++ Enum.filter(completed, &(&1["ends_at_s"] == t))

    study =
      Enum.reduce(checkpoints, study, fn a, s ->
        p = Enum.find(a["attitude_profile"], &(&1["epoch_s"] == t))
        ensure!(p != nil, "exact execution checkpoint attitude missing")

        mode =
          get_in(old, [
            "study",
            "path_constraints",
            "assets",
            a["asset_id"],
            "activity_modes",
            a["request_id"]
          ])

        put_in(s, ["horizon", "terminals", a["asset_id"]], %{
          "strategy" => "activity_boundary",
          "frame" => "eci_j2000",
          "quaternion_wxyz" => p["quaternion_wxyz"],
          "angular_velocity_inertial_deg_s" => p["angular_velocity_inertial_deg_s"],
          "mode" => mode
        })
      end)

    study =
      if c = get_in(study, ["scheduling", "command_delivery"]) do
        ids = Enum.map(mission["requests"], & &1["id"])

        put_in(
          study,
          ["scheduling", "command_delivery"],
          c
          |> Map.update!("requirements", &Enum.filter(&1, fn r -> r["request_id"] in ids end))
          |> Map.update!("receipts", &Enum.filter(&1, fn r -> r["request_id"] in ids end))
        )
      else
        study
      end

    ended = Enum.filter(parent["payload"]["report"]["activities"], &(&1["ends_at_s"] <= t))

    faithful =
      Enum.sort(Enum.map(ended, & &1["request_id"])) ==
        Enum.sort(Enum.map(completed, & &1["request_id"]))

    study =
      if faithful do
        study =
          Map.put(
            study,
            "saved_motion",
            OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory.replay(
              parent,
              t,
              acts,
              running
            )
          )

        put_in(
          study,
          ["horizon", "terminals"],
          Map.new(old["mission"]["assets"], fn asset ->
            {asset["id"],
             OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory.terminal(
               parent,
               asset["id"],
               t
             )}
          end)
        )
      else
        Map.delete(study, "saved_motion")
      end

    result = %{
      "mission" => mission,
      "study" => study,
      "service_unavailable_asset_ids" => old["service_unavailable_asset_ids"]
    }

    if old["execution"], do: Map.put(result, "execution", old["execution"]), else: result
  end

  def advance_inputs(old, parent, u) do
    t = u["as_of_s"]
    running = active(parent, t)
    active_ids = Enum.map(running, & &1["request_id"])
    rows = records(old, parent, running, "remaining")
    selected = Map.new(parent["payload"]["report"]["activities"], &{&1["request_id"], &1})

    closed =
      for q <- old["mission"]["requests"],
          q["id"] not in active_ids and
            (q["id"] in u["completed_request_ids"] or
               q["ends_at_s"] - q["duration_s"] < t) do
        a = selected[q["id"]]

        %{
          "status" => if(q["id"] in u["completed_request_ids"], do: "completed", else: "expired"),
          "request" => original(old, q),
          "baseline_activity" => if(a, do: original_placement(old, a), else: :null),
          "reported_at_s" => t
        }
      end

    closed_ids = Enum.map(closed, & &1["request"]["id"])

    mission =
      old["mission"]
      |> Map.update!("requests", fn qs ->
        qs
        |> Enum.reject(&(&1["id"] in closed_ids))
        |> Enum.map(fn q ->
          if rows[q["id"]],
            do:
              slice(
                q,
                rows[q["id"]],
                t,
                rows[q["id"]]["baseline_activity"]["ends_at_s"],
                "remaining"
              ),
            else: q
        end)
      end)
      |> Map.update!("assets", fn assets ->
        Enum.map(assets, fn a ->
          Map.put(a, "resource_budgets", u["assets"][a["id"]]["resource_budgets"])
        end)
      end)

    study =
      old["study"]
      |> put_in(["horizon", "starts_at_s"], t)
      |> modes(&Map.drop(&1, closed_ids))
      |> put_rows(rows)

    study =
      Enum.reduce(u["assets"], study, fn {id, a}, s ->
        s =
          put_in(s, ["attitude", "assets", id, "initial"], %{
            "epoch_s" => t,
            "time_scale" => "utc",
            "frame" => "eci_j2000",
            "quaternion_wxyz" => a["quaternion_wxyz"],
            "angular_velocity_inertial_deg_s" => a["angular_velocity_inertial_deg_s"]
          })

        if get_in(s, ["resources", "assets", id]),
          do:
            update_in(s, ["resources", "assets", id], fn models ->
              Enum.map(models, fn m ->
                case m["model"] do
                  "reaction_wheels" ->
                    put_in(
                      m,
                      ["configuration", "initial_momentum_nms"],
                      a["wheel_momentum_nms"][m["id"]]
                    )

                  "thermal" ->
                    put_in(
                      m,
                      ["configuration", "initial_temperature_k"],
                      a["thermal_temperature_k"][m["id"]]
                    )

                  "battery" ->
                    put_in(m, ["configuration", "initial_wh"], a["battery_energy_wh"][m["id"]])
                end
              end)
            end),
          else: s
      end)

    follow = u["motion_source_snapshot_id"] == parent["snapshot_id"]

    motion_pins =
      if follow,
        do: OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory.pins(parent, t),
        else: []

    study =
      if follow,
        do:
          Map.put(
            study,
            "saved_motion",
            OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory.future(parent, t)
          ),
        else: Map.delete(study, "saved_motion")

    inherited =
      (get_in(old, ["study", "scheduling", "protected_activities"]) || [])
      |> Enum.filter(&(&1["starts_at_s"] >= t))

    added = Enum.map(u["protect_request_ids"], &C.placement(selected[&1]))
    ongoing = Enum.map(running, &(&1 |> C.placement() |> Map.put("starts_at_s", t)))

    pins =
      (inherited ++ added ++ ongoing ++ motion_pins)
      |> Enum.uniq_by(& &1["request_id"])
      |> Enum.sort_by(&{&1["starts_at_s"], &1["asset_id"], &1["request_id"]})

    scheduling =
      Map.take(study["scheduling"] || %{}, [
        "maintenance",
        "work_budget",
        "availability",
        "command_delivery"
      ])
      |> Map.merge(u["scheduling"])
      |> Map.put("protected_activities", pins)

    scheduling =
      case scheduling["maintenance"] do
        nil ->
          scheduling

        config ->
          ids = Enum.reject(config["request_ids"], &(&1 in closed_ids))

          if ids == [],
            do: Map.delete(scheduling, "maintenance"),
            else: put_in(scheduling, ["maintenance", "request_ids"], ids)
      end

    scheduling =
      if c = scheduling["command_delivery"] do
        receipts = Map.get(u, "command_receipts", c["receipts"])

        Map.put(
          scheduling,
          "command_delivery",
          c
          |> Map.update!(
            "requirements",
            &Enum.reject(&1, fn r -> r["request_id"] in closed_ids end)
          )
          |> Map.put("receipts", Enum.reject(receipts, &(&1["request_id"] in closed_ids)))
        )
      else
        scheduling
      end

    study = Map.put(study, "scheduling", scheduling)

    ledger = %{
      "format" => "mission_execution_state.v1",
      "as_of_s" => t,
      "time_scale" => "utc",
      "source_id" => u["source_id"],
      "state_update_sha256" => C.digest(u),
      "last_update" => u,
      "closed_requests" => (get_in(old, ["execution", "closed_requests"]) || []) ++ closed
    }

    Map.merge(old, %{"mission" => mission, "study" => study, "execution" => ledger})
  end

  defp put_rows(s, rows),
    do:
      if(rows == %{}, do: Map.delete(s, "continuations"), else: Map.put(s, "continuations", rows))

  defp modes(s, fun),
    do:
      update_in(s, ["path_constraints", "assets"], fn assets ->
        Map.new(assets, fn {id, a} -> {id, Map.update!(a, "activity_modes", fun)} end)
      end)

  defp ensure!(true, _), do: :ok
  defp ensure!(false, message), do: raise(ArgumentError, message)
end
