defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.ExecutionState do
  @moduledoc "Validated common-epoch declared state and a bounded closed-request ledger."
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion
  alias OrbitalDynamics.MissionAnalysis.Scheduling.{Commitments, Reference}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot
  @placement ~w(request_id asset_id starts_at_s ends_at_s)

  def validate_source!(source) do
    OrbitalDynamics.MissionAnalysis.PlanRevision.StateQuality.validate_policy!(
      source["study"]["state_quality_policy"],
      source["mission"],
      source["study"]
    )

    OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation.validate_source!(source)
    OrbitalDynamics.MissionAnalysis.PlanRevision.MotionHistory.validate_source!(source)

    if Map.has_key?(source, "execution_checkpoint_id") do
      id = source["execution_checkpoint_id"]

      unless is_binary(id) and Regex.match?(~r/\Amission_execution_checkpoint:[0-9a-f]{64}\z/, id) and
               is_map(source["execution"]),
             do:
               raise(
                 ArgumentError,
                 "plan execution checkpoint identity requires a bound execution ledger"
               )
    end

    if e = source["execution"] do
      S.fields!(
        e,
        ~w(format as_of_s time_scale source_id state_update_sha256 last_update closed_requests),
        "execution ledger"
      )

      unless e["format"] == "mission_execution_state.v1" and e["time_scale"] == "utc" and
               e["as_of_s"] == source["study"]["horizon"]["starts_at_s"] and
               is_binary(e["state_update_sha256"]) and
               Regex.match?(~r/\A[0-9a-f]{64}\z/, e["state_update_sha256"]),
             do: raise(ArgumentError, "execution ledger does not match the planning boundary")

      Input.id!(e["source_id"])

      unless is_map(e["last_update"]) and
               Snapshot.digest(e["last_update"]) == e["state_update_sha256"] and
               e["last_update"]["as_of_s"] == e["as_of_s"] and
               e["last_update"]["source_id"] == e["source_id"],
             do: raise(ArgumentError, "execution ledger state update identity mismatch")

      quality =
        OrbitalDynamics.MissionAnalysis.PlanRevision.StateQuality.review(e["last_update"], source)

      if quality && quality["status"] != "supported",
        do: raise(ArgumentError, "saved state quality violates declared policy")

      Enum.each(source["mission"]["assets"], fn asset ->
        id = asset["id"]
        a = e["last_update"]["assets"][id]
        initial = source["study"]["attitude"]["assets"][id]["initial"]

        unless is_map(a) and is_map(initial) and initial["epoch_s"] == e["as_of_s"] and
                 initial["time_scale"] == "utc" and initial["frame"] == "eci_j2000" and
                 initial["quaternion_wxyz"] == a["quaternion_wxyz"] and
                 initial["angular_velocity_inertial_deg_s"] ==
                   a["angular_velocity_inertial_deg_s"] and
                 asset["resource_budgets"] == a["resource_budgets"],
               do:
                 raise(
                   ArgumentError,
                   "execution ledger initial state does not match current inputs"
                 )

        for m <- get_in(source, ["study", "resources", "assets", id]) || [] do
          case m["model"] do
            "battery" ->
              unless m["configuration"]["initial_wh"] == a["battery_energy_wh"][m["id"]],
                do: raise(ArgumentError, "execution ledger battery does not match current inputs")

            "thermal" ->
              unless m["configuration"]["initial_temperature_k"] ==
                       a["thermal_temperature_k"][m["id"]],
                     do:
                       raise(
                         ArgumentError,
                         "execution ledger temperature does not match current inputs"
                       )

            "reaction_wheels" ->
              unless m["configuration"]["initial_momentum_nms"] ==
                       a["wheel_momentum_nms"][m["id"]],
                     do:
                       raise(
                         ArgumentError,
                         "execution ledger wheel momentum does not match current inputs"
                       )

            _ ->
              raise ArgumentError, "unsupported state resource model"
          end
        end
      end)

      unless is_list(e["closed_requests"]) and
               length(e["closed_requests"]) + length(source["mission"]["requests"]) <= 100,
             do: raise(ArgumentError, "execution ledger exceeds request bound")

      closed_ids =
        Enum.map(e["closed_requests"], fn row ->
          S.fields!(row, ~w(status request baseline_activity reported_at_s), "closed request")
          r = row["request"]

          S.fields!(
            r,
            ~w(id model activity_type target starts_at_s ends_at_s duration_s value parameters resource_costs),
            "archived request"
          )

          Input.id!(r["id"])
          Input.number!(row["reported_at_s"], "closed request time", -1.0e12, e["as_of_s"])

          unless row["status"] in ~w(completed expired),
            do: raise(ArgumentError, "invalid closed request status")

          duration = Input.positive!(r["duration_s"], "archived request duration")
          start = Input.number!(r["starts_at_s"], "archived request start", -1.0e12, 1.0e12)
          stop = Input.number!(r["ends_at_s"], "archived request end", start, 1.0e12)

          if row["status"] == "expired" and
               stop - duration >=
                 row["reported_at_s"],
             do: raise(ArgumentError, "expired request still has remaining allowed duration")

          if row["status"] == "completed" do
            a = row["baseline_activity"]
            Commitments.normalize!([a])

            unless a["request_id"] == r["id"] and a["ends_at_s"] <= row["reported_at_s"] and
                     a["ends_at_s"] == a["starts_at_s"] + duration and a["starts_at_s"] >= start and
                     a["ends_at_s"] <= stop,
                   do:
                     raise(
                       ArgumentError,
                       "completion must reference a finished baseline activity"
                     )
          end

          r["id"]
        end)

      confirmed =
        MapSet.new(
          Enum.filter(e["closed_requests"], &(&1["status"] == "completed")),
          & &1["request"]["id"]
        )

      unless Enum.all?(e["last_update"]["completed_request_ids"], &MapSet.member?(confirmed, &1)),
        do: raise(ArgumentError, "execution ledger is missing a confirmed completion")

      active_ids = Enum.map(source["mission"]["requests"], & &1["id"])

      unless length(Enum.uniq(active_ids ++ closed_ids)) == length(active_ids ++ closed_ids),
        do: raise(ArgumentError, "closed requests cannot remain active or reuse an identity")
    end

    source
  end

  def validate_update!(u, source, snapshot) do
    u = OrbitalDynamics.Schema.JsonSafety.normalize_input!(u, "state update")

    S.fields!(
      u,
      ~w(revision_id expected_baseline_id source_id as_of_s time_scale frame assets completed_request_ids not_executed_request_ids protect_request_ids scheduling) ++
        Enum.filter(
          ~w(in_progress_request_ids horizon_extension command_receipts motion_source_snapshot_id),
          &Map.has_key?(u, &1)
        ),
      "state update"
    )

    Input.id!(u["revision_id"])
    Input.id!(u["source_id"])

    unless u["expected_baseline_id"] == snapshot["snapshot_id"],
      do: raise(ArgumentError, "state update expected a different baseline")

    if Map.has_key?(u, "motion_source_snapshot_id") and
         u["motion_source_snapshot_id"] != snapshot["snapshot_id"],
       do: raise(ArgumentError, "motion confirmation expected a different parent snapshot")

    h = source["study"]["horizon"]
    t = Input.number!(u["as_of_s"], "state update epoch", h["starts_at_s"], h["ends_at_s"])

    unless t > h["starts_at_s"] and t < h["ends_at_s"] and u["time_scale"] == "utc" and
             u["frame"] == "eci_j2000",
           do:
             raise(
               ArgumentError,
               "state update requires a strictly advancing UTC epoch inside the existing horizon and eci_j2000 axes"
             )

    S.fields!(
      u["scheduling"],
      ~w(strategy max_trials) ++
        Enum.filter(~w(work_budget availability), &Map.has_key?(u["scheduling"], &1)),
      "advance scheduling"
    )

    Reference.policy!(u["scheduling"])

    for key <- ~w(completed_request_ids not_executed_request_ids protect_request_ids),
        do: ids!(u[key])

    selected = Map.new(snapshot["payload"]["report"]["activities"], &{&1["request_id"], &1})
    running = Map.get(u, "in_progress_request_ids", [])
    ids!(running)

    active =
      OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation.active(
        snapshot["payload"]["report"],
        t
      )

    unless Enum.all?(running, fn id -> Enum.any?(active, &(&1["request_id"] == id)) end),
      do: raise(ArgumentError, "in-progress IDs must name currently running baseline activities")

    motion_committed = get_in(source, ["study", "saved_motion", "assets"]) || %{}

    for {_, c} <- motion_committed, {id, r} <- c["acquisitions"], r["strict"] do
      if id in u["not_executed_request_ids"],
        do:
          raise(
            ArgumentError,
            "a committed acquisition cannot be declared not executed without an abort contract"
          )
    end

    if Enum.any?(
         u["not_executed_request_ids"],
         &Map.has_key?(source["study"]["continuations"] || %{}, &1)
       ),
       do: raise(ArgumentError, "a previously started activity cannot be declared not executed")

    completed = u["completed_request_ids"]
    skipped = u["not_executed_request_ids"]

    unless Enum.all?(
             completed ++ skipped,
             &(Map.has_key?(selected, &1) and selected[&1]["ends_at_s"] <= t)
           ) and
             MapSet.disjoint?(MapSet.new(completed), MapSet.new(skipped)),
           do:
             raise(
               ArgumentError,
               "completed/skipped IDs must be distinct ended baseline activities"
             )

    unless Enum.all?(
             u["protect_request_ids"],
             &(Map.has_key?(selected, &1) and selected[&1]["starts_at_s"] >= t)
           ),
           do: raise(ArgumentError, "new commitments must select future baseline activities")

    assets = source["mission"]["assets"]

    unless is_map(u["assets"]) and
             Enum.sort(Map.keys(u["assets"])) == Enum.sort(Enum.map(assets, & &1["id"])),
           do: raise(ArgumentError, "state update must supply every asset exactly once")

    Enum.each(assets, fn asset ->
      id = asset["id"]
      a = u["assets"][id]

      models = get_in(source, ["study", "resources", "assets", id]) || []
      wheels = Enum.filter(models, &(&1["model"] == "reaction_wheels"))
      batteries = Enum.filter(models, &(&1["model"] == "battery"))
      thermals = Enum.filter(models, &(&1["model"] == "thermal"))

      S.fields!(
        a,
        ~w(quaternion_wxyz angular_velocity_inertial_deg_s battery_energy_wh resource_budgets) ++
          if(wheels != [], do: ["wheel_momentum_nms"], else: []) ++
          if(thermals != [], do: ["thermal_temperature_k"], else: []) ++
          if(Map.has_key?(a, "quality"), do: ["quality"], else: []),
        "asset state"
      )

      Quaternion.new!(a["quaternion_wxyz"])
      norm_squared = Enum.sum(Enum.map(a["quaternion_wxyz"], &(&1 * &1)))

      unless abs(norm_squared - 1) <= 1.0e-6,
        do: raise(ArgumentError, "state quaternion must be unit length")

      Input.vector!(a["angular_velocity_inertial_deg_s"], "state angular velocity")
      budgets = Input.budgets!(a["resource_budgets"])

      unless Enum.sort(Map.keys(budgets)) == Enum.sort(Map.keys(asset["resource_budgets"])) and
               Enum.all?(budgets, fn {key, value} ->
                 spent =
                   (completed ++ running)
                   |> Enum.map(&selected[&1])
                   |> Enum.filter(&(&1["asset_id"] == id))
                   |> Enum.map(&Map.get(&1["resource_costs"], key, 0))
                   |> Enum.sum()

                 value <= asset["resource_budgets"][key] - spent
               end),
             do:
               raise(
                 ArgumentError,
                 "state must provide remaining non-replenishing budgets without increasing keys or refunding completed costs"
               )

      models = get_in(source, ["study", "resources", "assets", id]) || []

      unless is_map(a["battery_energy_wh"]) and
               Enum.sort(Map.keys(a["battery_energy_wh"])) ==
                 Enum.sort(Enum.map(batteries, & &1["id"])) and
               Enum.all?(
                 batteries,
                 &(&1["model"] == "battery" and is_number(&1["configuration"]["capacity_wh"]))
               ),
             do:
               raise(
                 ArgumentError,
                 "state requires every configured finite-capacity reference battery"
               )

      unless length(models) == length(batteries) + length(wheels) + length(thermals),
        do: raise(ArgumentError, "unsupported state resource model")

      if thermals != [] do
        values = a["thermal_temperature_k"]

        unless is_map(values) and
                 Enum.sort(Map.keys(values)) == Enum.sort(Enum.map(thermals, & &1["id"])),
               do: raise(ArgumentError, "state requires every thermal node")

        Enum.each(values, fn {_, t} ->
          Input.number!(t, "reported temperature", 0.000001, 1.0e12)
        end)
      end

      if wheels != [] do
        unless is_map(a["wheel_momentum_nms"]) and
                 Enum.sort(Map.keys(a["wheel_momentum_nms"])) ==
                   Enum.sort(Enum.map(wheels, & &1["id"])),
               do: raise(ArgumentError, "state requires every configured wheel array")

        Enum.each(wheels, fn model ->
          Input.vector!(a["wheel_momentum_nms"][model["id"]], "reported wheel momentum")
        end)
      end

      Enum.each(batteries, fn model ->
        Input.number!(
          a["battery_energy_wh"][model["id"]],
          "reported battery energy",
          0,
          model["configuration"]["capacity_wh"]
        )
      end)
    end)

    if receipts = u["command_receipts"] do
      c = get_in(source, ["study", "scheduling", "command_delivery"])
      unless c, do: raise(ArgumentError, "receipts require declared command delivery policy")

      c2 =
        Map.put(c, "receipts", receipts)
        |> OrbitalDynamics.MissionAnalysis.Scheduling.CommandDelivery.validate!()

      for r <- c["receipts"] do
        unless r in receipts,
          do: raise(ArgumentError, "existing command receipts cannot be changed or dropped")
      end

      OrbitalDynamics.MissionAnalysis.Scheduling.CommandDelivery.receipts!(
        c2,
        OrbitalDynamics.MissionAnalysis.Scheduling.CommandDelivery.allocation(c2),
        t
      )
    end

    u
  end

  def prepare(source, snapshot, u) do
    t = u["as_of_s"]
    baseline = snapshot["payload"]["report"]
    completed = MapSet.new(u["completed_request_ids"])
    selected = Map.new(baseline["activities"], &{&1["request_id"], &1})
    active = OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation.active(baseline, t)
    active_ids = MapSet.new(active, & &1["request_id"])

    continuations =
      OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation.records(
        source,
        snapshot,
        active,
        "remaining"
      )

    closed =
      for r <- source["mission"]["requests"],
          not MapSet.member?(active_ids, r["id"]) and
            (MapSet.member?(completed, r["id"]) or
               r["ends_at_s"] - r["duration_s"] < t) do
        %{
          "status" => if(MapSet.member?(completed, r["id"]), do: "completed", else: "expired"),
          "request" =>
            OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation.original_request(source, r),
          "baseline_activity" =>
            if(selected[r["id"]],
              do:
                OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation.original_placement(
                  source,
                  selected[r["id"]]
                ),
              else: :null
            ),
          "reported_at_s" => t
        }
      end

    closed_ids = MapSet.new(closed, & &1["request"]["id"])

    mission =
      source["mission"]
      |> Map.update!(
        "requests",
        &Enum.reject(&1, fn r -> MapSet.member?(closed_ids, r["id"]) end)
      )
      |> Map.update!("requests", fn requests ->
        Enum.map(requests, fn request ->
          if continuations[request["id"]],
            do:
              OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation.slice(
                request,
                continuations[request["id"]],
                t,
                continuations[request["id"]]["baseline_activity"]["ends_at_s"],
                "remaining"
              ),
            else: request
        end)
      end)
      |> Map.update!(
        "assets",
        &Enum.map(&1, fn asset ->
          Map.put(asset, "resource_budgets", u["assets"][asset["id"]]["resource_budgets"])
        end)
      )

    study = put_in(source["study"], ["horizon", "starts_at_s"], t)

    study =
      Enum.reduce(u["assets"], study, fn {id, a}, s ->
        initial = %{
          "epoch_s" => t,
          "time_scale" => "utc",
          "frame" => "eci_j2000",
          "quaternion_wxyz" => a["quaternion_wxyz"],
          "angular_velocity_inertial_deg_s" => a["angular_velocity_inertial_deg_s"]
        }

        s = put_in(s, ["attitude", "assets", id, "initial"], initial)

        s =
          update_in(
            s,
            ["path_constraints", "assets", id, "activity_modes"],
            &Map.drop(&1, MapSet.to_list(closed_ids))
          )

        if get_in(s, ["resources", "assets", id]) do
          update_in(s, ["resources", "assets", id], fn models ->
            Enum.map(models, fn m ->
              case m["model"] do
                "battery" ->
                  put_in(m, ["configuration", "initial_wh"], a["battery_energy_wh"][m["id"]])

                "thermal" ->
                  put_in(
                    m,
                    ["configuration", "initial_temperature_k"],
                    a["thermal_temperature_k"][m["id"]]
                  )

                "reaction_wheels" ->
                  put_in(
                    m,
                    ["configuration", "initial_momentum_nms"],
                    a["wheel_momentum_nms"][m["id"]]
                  )
              end
            end)
          end)
        else
          s
        end
      end)

    study =
      if continuations == %{},
        do: Map.delete(study, "continuations"),
        else: Map.put(study, "continuations", continuations)

    follow = u["motion_source_snapshot_id"] == snapshot["snapshot_id"]

    motion_pins =
      if follow,
        do: OrbitalDynamics.MissionAnalysis.PlanRevision.MotionHistory.pins(snapshot, t),
        else: []

    study =
      if follow,
        do:
          Map.put(
            study,
            "saved_motion",
            OrbitalDynamics.MissionAnalysis.PlanRevision.MotionHistory.future(snapshot, t)
          ),
        else: Map.delete(study, "saved_motion")

    inherited = get_in(source, ["study", "scheduling", "protected_activities"]) || []
    # Completed commitments are archived; future commitments cannot be released.
    protected =
      (Enum.filter(inherited, &(&1["starts_at_s"] >= t)) ++
         motion_pins ++
         Enum.map(u["protect_request_ids"], &Map.take(selected[&1], @placement)) ++
         Enum.map(active, fn a -> a |> Map.take(@placement) |> Map.put("starts_at_s", t) end))
      |> Enum.uniq_by(& &1["request_id"])
      |> Commitments.normalize!()

    scheduling =
      Map.take(study["scheduling"] || %{}, [
        "maintenance",
        "work_budget",
        "availability",
        "command_delivery"
      ])
      |> Map.merge(u["scheduling"])
      |> Map.put("protected_activities", protected)

    scheduling =
      case scheduling["maintenance"] do
        nil ->
          scheduling

        config ->
          ids = Enum.reject(config["request_ids"], &MapSet.member?(closed_ids, &1))

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
          |> Map.put(
            "receipts",
            Enum.reject(receipts, &MapSet.member?(closed_ids, &1["request_id"]))
          )
          |> Map.update!(
            "requirements",
            &Enum.reject(&1, fn r -> MapSet.member?(closed_ids, r["request_id"]) end)
          )
        )
      else
        scheduling
      end

    study = Map.put(study, "scheduling", scheduling)

    execution = %{
      "format" => "mission_execution_state.v1",
      "as_of_s" => t,
      "time_scale" => "utc",
      "source_id" => u["source_id"],
      "state_update_sha256" => Snapshot.digest(u),
      "last_update" => u,
      "closed_requests" => (get_in(source, ["execution", "closed_requests"]) || []) ++ closed
    }

    inputs =
      Map.merge(source, %{"mission" => mission, "study" => study, "execution" => execution})

    future =
      Enum.filter(baseline["activities"], &(&1["starts_at_s"] >= t)) ++
        Enum.map(active, fn a ->
          a |> Map.put("starts_at_s", t) |> Map.put("resource_costs", %{})
        end)

    future_ids = MapSet.new(future, & &1["request_id"])

    comparison =
      baseline
      |> Map.put("activities", future)
      |> Map.update!("requests", fn rs ->
        rs
        |> Enum.reject(&MapSet.member?(closed_ids, &1["request_id"]))
        |> Enum.map(fn r ->
          if MapSet.member?(future_ids, r["request_id"]),
            do: r,
            else:
              r
              |> Map.put("status", "unfulfilled")
              |> Map.put("activity_ids", [])
              |> Map.put("reasons", ["not_selected_in_future_baseline"])
        end)
      end)

    {inputs, comparison, protected, closed}
  end

  defp ids!(ids) do
    unless is_list(ids) and length(ids) <= 100 and length(Enum.uniq(ids)) == length(ids),
      do: raise(ArgumentError, "state request IDs must be bounded and unique")

    Enum.each(ids, &Input.id!/1)
  end
end
