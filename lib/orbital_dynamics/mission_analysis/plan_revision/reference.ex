defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.Reference do
  @moduledoc "Same-horizon reference-mission revision workflow with source-bound baseline snapshots."
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference, as: Planner
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Commitments
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Reference, as: Search
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Snapshot, Diff}
  @placement ~w(request_id asset_id starts_at_s ends_at_s)

  def create!(mission, study) do
    require_horizon!(study)
    report = Planner.run!(mission, study)

    unless supported?(report),
      do: raise(ArgumentError, "baseline planning evidence must be supported")

    Snapshot.new!(
      %{"mission" => mission, "study" => study, "service_unavailable_asset_ids" => []},
      report
    )
  end

  def revise!(snapshot, change, planner \\ &plan/3) do
    Snapshot.verify!(snapshot)
    source = source!(snapshot)
    change = validate_change!(change, source, snapshot["snapshot_id"])
    baseline = snapshot["payload"]["report"]
    selected = Map.new(baseline["activities"], &{&1["request_id"], &1})

    unless Enum.all?(change["protect_request_ids"], &Map.has_key?(selected, &1)),
      do: raise(ArgumentError, "only baseline scheduled requests can become commitments")

    existing = get_in(source, ["study", "scheduling", "protected_activities"]) || []

    protected =
      (existing ++
         Enum.map(change["protect_request_ids"], &Map.take(Map.fetch!(selected, &1), @placement)))
      |> Enum.uniq_by(& &1["request_id"])
      |> Commitments.normalize!()

    unless Commitments.intact?(baseline["activities"], protected),
      do: raise(ArgumentError, "baseline commitments do not match selected activities")

    unavailable = change["unavailable_asset_ids"]

    conflicts =
      for p <- protected, p["asset_id"] in unavailable do
        %{
          "kind" => "protected_service_unavailable",
          "placement" => p,
          "reason" => "asset service unavailable throughout the unchanged planning horizon"
        }
      end

    {mission, study} = updated_inputs(source, change, protected)

    review = %{
      "format" => "mission_plan_revision.v1",
      "revision_id" => change["revision_id"],
      "baseline_snapshot_id" => snapshot["snapshot_id"],
      "change_sha256" => Snapshot.digest(change),
      "changes" => change,
      "protected_activities" => protected,
      "horizon" => study["horizon"],
      "initial_state_policy" => "recompute_from_same_declared_initial_state",
      "service_availability_changes" => %{
        "newly_unavailable" => unavailable -- source["service_unavailable_asset_ids"],
        "restored" => source["service_unavailable_asset_ids"] -- unavailable
      },
      "execution_boundary" => "analysis_only_no_approval_or_command_execution"
    }

    if conflicts != [] do
      result(review, "commitment_conflict", conflicts, :null, :null, :null)
    else
      inputs =
        Map.merge(source, %{
          "mission" => mission,
          "study" => study,
          "service_unavailable_asset_ids" => unavailable
        })

      evaluate_revision!(snapshot, baseline, inputs, review, protected, planner)
    end
  end

  @doc false
  def evaluate_revision!(snapshot, baseline, inputs, review, protected, planner \\ &plan/3) do
    outages = get_in(inputs, ["study", "scheduling", "availability", "outages"]) || []
    requests = Map.new(inputs["mission"]["requests"], &{&1["id"], &1})

    conflicts =
      for pin <- protected,
          outage <- outages,
          mode =
            get_in(inputs, [
              "study",
              "path_constraints",
              "assets",
              pin["asset_id"],
              "activity_modes",
              pin["request_id"]
            ]),
          OrbitalDynamics.MissionAnalysis.Scheduling.Availability.matches?(
            outage,
            pin["asset_id"],
            requests[pin["request_id"]]["activity_type"],
            mode
          ),
          OrbitalDynamics.MissionAnalysis.Scheduling.Availability.overlaps?(outage, pin),
          do: %{
            "kind" => "protected_activity_unavailable",
            "placement" => pin,
            "outage_id" => outage["id"]
          }

    if conflicts == [],
      do: evaluate_revision_core!(snapshot, baseline, inputs, review, protected, planner),
      else: result(review, "commitment_conflict", conflicts, :null, :null, :null)
  end

  defp evaluate_revision_core!(snapshot, baseline, inputs, review, protected, planner) do
    mission = inputs["mission"]
    study = inputs["study"]
    unavailable = inputs["service_unavailable_asset_ids"]

    case planner.(mission, study, unavailable) do
      {:ok, report, timings} ->
        bind_report!(report, %{
          "mission" => mission,
          "study" => study,
          "service_unavailable_asset_ids" => unavailable
        })

        cond do
          not Commitments.intact?(report["activities"], protected) ->
            conflicts =
              for p <- protected,
                  not Commitments.intact?(report["activities"], [p]),
                  do: %{"kind" => "protected_placement_not_preserved", "placement" => p}

            result(
              Map.put(review, "planner_timings", timings),
              "commitment_conflict",
              conflicts,
              report,
              :null,
              :null
            )

          not supported?(report) ->
            result(
              Map.put(review, "planner_timings", timings),
              "unsupported_revision",
              [],
              report,
              :null,
              :null
            )

          true ->
            updated = Snapshot.new!(inputs, report, snapshot["snapshot_id"])
            diff = Diff.compare!(baseline, report, protected)

            result(
              Map.put(review, "planner_timings", timings),
              "ready_for_review",
              [],
              report,
              updated,
              diff
            )
        end

      {:error, reason} ->
        category = OrbitalDynamics.MissionAnalysis.Scheduling.Explanation.failure_category(reason)

        conflicts =
          if category == "evaluation_budget_exhausted",
            do: [],
            else: protected_conflicts(reason, protected)

        unknown =
          match?({:protected_activity_unknown, _, _}, reason) or
            match?({:protected_resources_unknown, _, _}, reason)

        work =
          case reason do
            {:planning_work_budget_exhausted, evidence} when is_map(evidence) -> evidence
            _ -> nil
          end

        review = if work, do: Map.put(review, "planning_work", work), else: review

        result(
          review
          |> Map.put("planning_error", error_summary(reason))
          |> Map.put(
            "planning_failure_category",
            cond do
              unknown -> "unknown_feasibility"
              conflicts != [] -> "commitment_constraint_violation"
              true -> category
            end
          ),
          cond do
            unknown -> "unsupported_revision"
            conflicts != [] -> "commitment_conflict"
            true -> "planning_failed"
          end,
          conflicts,
          :null,
          :null,
          :null
        )
    end
  end

  defp error_summary({:protected_resources_unsupported, asset_id, evidence})
       when is_map(evidence),
       do: "protected resource replay violated for #{asset_id}; see conflict resource_evidence"

  defp error_summary(reason), do: inspect(reason, limit: 20, printable_limit: 512)

  defp protected_conflicts(
         {:protected_activity_unsupported, request_id,
          {:rigid_body_torque_exceeds_limit, scope, assessment}},
         protected
       ) do
    for p <- protected,
        p["request_id"] == request_id,
        do: %{
          "kind" => "protected_torque_capacity_exceeded",
          "placement" => p,
          "scope" => scope,
          "torque_evidence" => assessment,
          "reason" => "constructed motion exceeds declared body torque capacity"
        }
  end

  defp protected_conflicts(
         {:protected_activity_unsupported, request_id,
          {:tracking_torque_exceeds_limit, epoch, assessment}},
         protected
       ) do
    for p <- protected,
        p["request_id"] == request_id,
        do: %{
          "kind" => "protected_torque_capacity_exceeded",
          "placement" => p,
          "scope" => "tracking",
          "epoch_s" => epoch,
          "torque_evidence" => assessment,
          "reason" => "sampled tracking exceeds declared body torque capacity"
        }
  end

  defp protected_conflicts({:protected_activity_unsupported, request_id, reason}, protected) do
    for p <- protected,
        p["request_id"] == request_id,
        do: %{
          "kind" => "protected_activity_unsupported_from_initial_state",
          "placement" => p,
          "reason" => inspect(reason)
        }
  end

  defp protected_conflicts({:protected_resources_unsupported, asset_id, reason}, protected) do
    for p <- protected,
        p["asset_id"] == asset_id,
        do: %{
          "kind" => "protected_resource_replay_failed",
          "placement" => p,
          "reason" =>
            if(is_map(reason), do: "protected resource replay violated", else: inspect(reason)),
          "resource_evidence" => if(is_map(reason), do: reason, else: :null)
        }
  end

  defp protected_conflicts(_, _), do: []

  @doc false
  def rejected(review, status, conflicts),
    do: result(review, status, conflicts, :null, :null, :null)

  defp result(review, status, conflicts, candidate, snapshot, diff) do
    review =
      Map.merge(review, %{
        "status" => status,
        "conflicts" => conflicts,
        "diff" => diff,
        "revised_snapshot_id" => if(snapshot == :null, do: :null, else: snapshot["snapshot_id"])
      })

    %{review: review, candidate_report: candidate, revised_snapshot: snapshot}
  end

  defp plan(m, s, unavailable) do
    Planner.run_profiled(m, s, service_unavailable_asset_ids: unavailable)
  rescue
    e in [ArgumentError, KeyError, MatchError] ->
      {:error, {:invalid_reference_planning_input, Exception.message(e)}}
  end

  def source!(snapshot) do
    source = snapshot["payload"]["inputs"]

    SurfaceSupport.fields!(
      source,
      ~w(mission study service_unavailable_asset_ids) ++
        Enum.filter(~w(execution execution_checkpoint_id), &Map.has_key?(source, &1)),
      "reference snapshot inputs"
    )

    require_horizon!(source["study"])
    bind_report!(snapshot["payload"]["report"], source)

    unless supported?(snapshot["payload"]["report"]),
      do: raise(ArgumentError, "baseline snapshot must contain supported planning evidence")

    OrbitalDynamics.MissionAnalysis.PlanRevision.ExecutionState.validate_source!(source)
    source
  end

  defp bind_report!(report, source) do
    Snapshot.validate_report!(report)

    unless report["baseline_configuration"] === source["mission"] and
             report["attitude_study_configuration"] === source["study"] and
             report["time_system"]["scale"] == "utc" and
             Enum.sort(Enum.map(report["requests"], & &1["request_id"])) ==
               Enum.sort(Enum.map(source["mission"]["requests"], & &1["id"])) and
             Enum.sort(get_in(report, ["service_unavailability", "asset_ids"]) || []) ==
               Enum.sort(source["service_unavailable_asset_ids"]),
           do:
             raise(
               ArgumentError,
               "snapshot/candidate report is not bound to its reference inputs"
             )
  end

  defp require_horizon!(study) do
    unless is_map(study["horizon"]) and study["horizon"]["time_scale"] == "utc" and
             is_map(study["path_constraints"]) and is_map(study["attitude"]),
           do:
             raise(
               ArgumentError,
               "reference revisions require an explicit UTC horizon, attitude and path policy"
             )
  end

  defp supported?(report),
    do: get_in(report, ["attitude_planning", "planning_status"]) == "supported"

  def validate_change!(c, source, baseline_id) do
    SurfaceSupport.fields!(
      c,
      ~w(revision_id protect_request_ids add_requests unavailable_asset_ids scheduling) ++
        if(Map.has_key?(c, "expected_baseline_id"), do: ["expected_baseline_id"], else: []),
      "revision change"
    )

    Input.id!(c["revision_id"])

    if Map.has_key?(c, "expected_baseline_id") and c["expected_baseline_id"] != baseline_id,
      do: raise(ArgumentError, "change expected a different baseline snapshot")

    ids = Enum.map(source["mission"]["assets"], & &1["id"])

    for {key, max} <- [{"protect_request_ids", 100}, {"unavailable_asset_ids", 20}] do
      values = c[key]

      unless is_list(values) and length(values) <= max and Enum.all?(values, &is_binary/1) and
               length(Enum.uniq(values)) == length(values),
             do: raise(ArgumentError, "#{key} must contain bounded unique IDs")

      Enum.each(values, &Input.id!/1)
    end

    unless Enum.all?(c["unavailable_asset_ids"], &(&1 in ids)),
      do: raise(ArgumentError, "unavailability names an unknown asset")

    # Select commitments only from the saved baseline, never by inventing positions.
    # report binding is already checked before this validation.
    unless is_list(c["add_requests"]) and
             length(c["add_requests"]) + length(source["mission"]["requests"]) +
               length(get_in(source, ["execution", "closed_requests"]) || []) <= 100,
           do: raise(ArgumentError, "revised mission exceeds 100 requests")

    SurfaceSupport.fields!(
      c["scheduling"],
      ~w(strategy max_trials) ++
        Enum.filter(~w(work_budget availability), &Map.has_key?(c["scheduling"], &1)),
      "revision scheduling"
    )

    Search.policy!(c["scheduling"])
    # The snapshot report is recovered through its source configuration in revise!;
    # actual selected-ID validation occurs before extracting placements there.
    existing =
      Enum.map(source["mission"]["requests"], & &1["id"]) ++
        Enum.map(get_in(source, ["execution", "closed_requests"]) || [], & &1["request"]["id"])

    added =
      Enum.map(c["add_requests"], fn addition ->
        SurfaceSupport.fields!(addition, ~w(request activity_modes), "added request")
        r = addition["request"]

        SurfaceSupport.fields!(
          r,
          ~w(id model activity_type target starts_at_s ends_at_s duration_s value parameters resource_costs),
          "added reference request"
        )

        Input.id!(r["id"])

        unless is_map(addition["activity_modes"]) and
                 Enum.sort(Map.keys(addition["activity_modes"])) == Enum.sort(ids),
               do:
                 raise(
                   ArgumentError,
                   "added request must declare an existing activity mode for every asset"
                 )

        for {id, mode} <- addition["activity_modes"] do
          unless is_binary(mode) and
                   Map.has_key?(
                     get_in(source, ["study", "path_constraints", "assets", id, "modes"]) || %{},
                     mode
                   ),
                 do: raise(ArgumentError, "added request names an unknown activity mode")
        end

        r["id"]
      end)

    unless length(Enum.uniq(existing ++ added)) == length(existing ++ added),
      do: raise(ArgumentError, "added request ID already exists or is duplicated")

    c
  end

  def updated_inputs(source, c, protected) do
    mission =
      Map.update!(
        source["mission"],
        "requests",
        &(&1 ++ Enum.map(c["add_requests"], fn a -> a["request"] end))
      )

    study =
      Enum.reduce(c["add_requests"], source["study"], fn a, s ->
        Enum.reduce(a["activity_modes"], s, fn {id, mode}, s ->
          put_in(
            s,
            ["path_constraints", "assets", id, "activity_modes", a["request"]["id"]],
            mode
          )
        end)
      end)

    study =
      Map.put(
        study,
        "scheduling",
        Map.take(study["scheduling"] || %{}, [
          "maintenance",
          "work_budget",
          "availability",
          "command_delivery"
        ])
        |> Map.merge(c["scheduling"])
        |> Map.put("protected_activities", protected)
      )

    {mission, study}
  end
end
