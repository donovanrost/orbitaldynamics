defmodule OrbitalDynamics.IndependentPlanFixture do
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission}
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  def build do
    m = ReferenceMission.load!("studies/rolling_state_reference.json")
    s = ReferenceMission.load!("studies/rolling_state_planning.json")
    policy = %{"strategy" => "greedy", "max_trials" => 1}

    advance = fn id, t ->
      %{
        "id" => id,
        "kind" => "advance",
        "expected_status" => "ready_for_review",
        "as_of_s" => t,
        "not_executed_request_ids" => [],
        "energy_losses_wh" => %{},
        "protect_request_ids" => [],
        "scheduling" => policy
      }
    end

    script = %{
      "scenario_id" => "independent_validation_fixture",
      "mission_manifest" => "rolling_state_reference.json",
      "planning_study" => "rolling_state_planning.json",
      "steps" => [
        %{
          "id" => "commit",
          "kind" => "revise",
          "expected_status" => "ready_for_review",
          "change" => %{
            "revision_id" => "commit",
            "protect_request_ids" => ["early-3"],
            "add_requests" => [],
            "unavailable_asset_ids" => [],
            "scheduling" => policy
          }
        },
        advance.("execute_first", 820_497_800),
        advance.("close_remaining", 820_498_190)
      ]
    }

    Process.put(:independent_artifacts, %{})

    report =
      Scenario.run!(m, s, script, fn name, value ->
        Process.put(
          :independent_artifacts,
          Map.put(Process.get(:independent_artifacts), name, value)
        )
      end)

    unless report["verification_status"] == "passed", do: raise("fixture scenario failed")
    %{operations: report, snapshots: Process.get(:independent_artifacts)}
  end

  def rehash(s) do
    hash = Snapshot.digest(s["payload"])

    s
    |> Map.put("content_sha256", hash)
    |> Map.put("snapshot_id", "mission_plan_snapshot:" <> hash)
  end

  def bind(s) do
    s
    |> put_in(["payload", "report", "baseline_configuration"], s["payload"]["inputs"]["mission"])
    |> put_in(
      ["payload", "report", "attitude_study_configuration"],
      s["payload"]["inputs"]["study"]
    )
    |> rehash()
  end

  def replace_final(ctx, child) do
    last = List.last(ctx.operations["steps"])

    row =
      last
      |> Map.put("accepted_snapshot_id", child["snapshot_id"])
      |> put_in(["review", "revised_snapshot_id"], child["snapshot_id"])

    report =
      ctx.operations
      |> Map.put("final_snapshot_id", child["snapshot_id"])
      |> Map.put("final_plan_bound_execution_history", child["payload"]["inputs"]["execution"])
      |> Map.update!("steps", &List.replace_at(&1, -1, row))

    %{
      ctx
      | operations: report,
        snapshots: Map.put(ctx.snapshots, "step-03-revised_snapshot.json", child)
    }
  end

  def load(snapshots),
    do: fn name ->
      case Map.fetch(snapshots, name) do
        {:ok, s} -> {:ok, s}
        :error -> {:error, "missing test artifact"}
      end
    end
end
