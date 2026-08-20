Code.require_file("../campaign_planner/local_search_support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignPlanSearchContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.CampaignPlanner.LocalSearchSupport, as: Support
  alias OrbitalDynamics.Schema

  test "exports the standalone trace and optional nested campaign-plan property" do
    assert {:ok, trace_schema} = Schema.json_schema("campaign_plan_search_trace.v1")
    assert trace_schema["type"] == "object"

    assert trace_schema["properties"]["schema_contract"]["const"] ==
             "campaign_plan_search_trace.v1"

    assert get_in(trace_schema, ["properties", "selection_contract", "const"]) ==
             "v1_outer_local_search_inner_greedy"

    assert {:ok, plan_schema} = Schema.json_schema("campaign_plan.v1")
    assert get_in(plan_schema, ["properties", "optimizer_search_trace", "type"]) == "object"
    assert get_in(plan_schema, ["$defs", "campaign_plan_search_trace.v1", "type"]) == "object"

    assert "campaign_plan_search_trace.v1" in get_in(plan_schema, [
             "x-orbital-dynamics",
             "nested_contracts"
           ])
  end

  test "rejects tampered selected policy, timeline, activity, and selected-alternative bindings" do
    plan = valid_plan()
    trace = plan["optimizer_search_trace"]

    assert_invalid(
      put_trace(
        plan,
        Map.put(trace, "selected_scoring_policy", %{"target_value_weight" => 99.0})
      ),
      "selected_scoring_policy"
    )

    assert_invalid(
      put_trace(plan, Map.update!(trace, "selected_timeline_score", &(&1 + 1.0))),
      "selected_timeline_score"
    )

    assert_invalid(
      put_trace(plan, Map.put(trace, "selected_activity_ids", ["activity:other"])),
      "selected_activity_ids"
    )

    other =
      Enum.find(trace["search_result"]["alternatives"], fn alternative ->
        alternative["id"] != trace["selected_alternative_id"]
      end)

    assert_invalid(
      put_trace(plan, Map.put(trace, "selected_alternative", other)),
      "selected_alternative"
    )
  end

  test "rejects tampered registry, alternative, evidence IDs, and revisions in the retained search result" do
    plan = valid_plan()
    trace = plan["optimizer_search_trace"]
    result = trace["search_result"]
    selected_id = trace["selected_alternative_id"]

    assert_invalid(
      put_search_result(
        plan,
        Map.put(result, "source_evidence_registry", %{
          result["source_evidence_registry"]
          | "id" => "local_search_source_evidence_registry:tampered"
        })
      ),
      "candidate_feasibility_evaluations"
    )

    assert_invalid(
      update_selected_evaluation(plan, selected_id, fn evaluation ->
        Map.put(evaluation, "alternative_id", "campaign_policy:cross-alternative")
      end),
      "candidate_feasibility_evaluations"
    )

    assert_invalid(
      update_selected_evaluation(plan, selected_id, fn evaluation ->
        put_in(
          evaluation,
          ["evidence_bindings", "resource_state_trace", "id"],
          "resource_state_trace:cross-alternative"
        )
      end),
      "candidate_feasibility_evaluations"
    )

    assert_invalid(
      update_selected_evaluation(plan, selected_id, fn evaluation ->
        put_in(
          evaluation,
          ["evidence_bindings", "downlink_link_budget", "revision"],
          "not a stable revision"
        )
      end),
      "candidate_feasibility_evaluations"
    )

    assert_invalid(
      update_selected_evaluation(plan, selected_id, &Map.put(&1, "spacecraft_id", "sc_2")),
      "alternatives"
    )
  end

  test "requires exact review and Cadence copies and rejects stale handoffs without a trace" do
    plan = valid_plan()

    stale_review =
      update_in(plan, ["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "local_search_review"} = row ->
            Map.put(row, "selected_activity_count", row["selected_activity_count"] + 1)

          row ->
            row
        end)
      end)

    assert_invalid(stale_review, "operator_review_package.rows")

    stale_cadence =
      update_in(plan, ["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn
          %{"import_action" => "review_local_search"} = row ->
            put_in(row, ["source_review_row", "selected_timeline_score"], -1.0)

          row ->
            row
        end)
      end)

    assert_invalid(stale_cadence, "cadence_import_manifest.rows")

    stale_without_trace = Map.delete(plan, "optimizer_search_trace")
    assert_invalid(stale_without_trace, "operator_review_package.rows")
    assert_invalid(stale_without_trace, "cadence_import_manifest.rows")
  end

  defp valid_plan do
    plan =
      CampaignPlanner.build_with_local_search(
        Support.result_set(),
        campaign: Support.campaign(),
        generated_at: Support.generated_at(),
        local_search: Support.local_search()
      )

    assert {:ok, _report} = Schema.validate_artifact(plan)
    plan
  end

  defp put_trace(plan, trace), do: Map.put(plan, "optimizer_search_trace", trace)

  defp put_search_result(plan, result) do
    trace = Map.put(plan["optimizer_search_trace"], "search_result", result)
    put_trace(plan, trace)
  end

  defp update_selected_evaluation(plan, selected_id, update) do
    result = plan["optimizer_search_trace"]["search_result"]

    evaluations =
      Enum.map(result["candidate_feasibility_evaluations"], fn evaluation ->
        if evaluation["alternative_id"] == selected_id, do: update.(evaluation), else: evaluation
      end)

    put_search_result(plan, Map.put(result, "candidate_feasibility_evaluations", evaluations))
  end

  defp assert_invalid(artifact, path_fragment) do
    assert {:error, report} = Schema.validate_artifact(artifact)

    assert Enum.any?(report["errors"], fn error ->
             String.contains?(error["path"], path_fragment)
           end),
           "expected an error containing #{inspect(path_fragment)}, got: #{inspect(report["errors"])}"
  end
end
