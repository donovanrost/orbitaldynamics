Code.require_file("../campaign_planner/local_search_support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignPlanSearchContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.CampaignPlanner.BuildArtifact
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

  test "public trace and enclosing plan validation return path errors for malformed recursive terms" do
    plan = valid_plan()
    trace = plan["optimizer_search_trace"]
    first_alternative = hd(trace["search_result"]["alternatives"])

    mutations = [
      {"$.search_result.alternatives",
       fn value ->
         put_in(value, ["search_result", "alternatives"], [first_alternative | :improper])
       end},
      {"$.search_result.alternatives",
       fn value ->
         put_in(value, ["search_result", "alternatives"], %{})
       end},
      {"$.search_result.alternatives[0].score",
       fn value ->
         update_alternative(value, 0, &Map.put(&1, "score", self()))
       end},
      {"$.search_result.alternatives[0].score_terms",
       fn value ->
         update_alternative(value, 0, &Map.put(&1, "score_terms", fn -> :unsafe end))
       end},
      {"$.search_result.alternatives[0].move",
       fn value ->
         update_alternative(value, 0, &Map.put(&1, "move", {:unsafe, :tuple}))
       end},
      {"$.search_result.assumptions.unsafe_struct",
       fn value ->
         put_in(value, ["search_result", "assumptions", "unsafe_struct"], Support.generated_at())
       end},
      {"$.search_result.assumptions.unsafe_bits",
       fn value ->
         put_in(value, ["search_result", "assumptions", "unsafe_bits"], <<1::1>>)
       end},
      {"$.base_scoring_policy",
       fn value ->
         put_in(value, ["base_scoring_policy"], Map.put(value["base_scoring_policy"], 7, 1.0))
       end},
      {"$.objective", fn value -> Map.put(value, "objective", <<255>>) end},
      {"$", fn value -> Map.put(value, :search_result, value["search_result"]) end},
      {"$.selected_activity_ids",
       fn value ->
         Map.put(value, "selected_activity_ids", ["activity:one" | :improper])
       end},
      {"$.search_result.alternatives[0].score",
       fn value ->
         update_alternative(value, 0, &Map.put(&1, "score", "not-a-number"))
       end},
      {"$.selected_activity_count",
       fn value ->
         Map.put(value, "selected_activity_count", -1)
       end}
    ]

    Enum.each(mutations, fn {trace_path, mutate} ->
      malformed_trace = mutate.(trace)
      assert_error_path(malformed_trace, trace_path)

      plan_path =
        if trace_path == "$",
          do: "$.optimizer_search_trace",
          else: String.replace_prefix(trace_path, "$", "$.optimizer_search_trace")

      assert_error_path(Map.put(plan, "optimizer_search_trace", malformed_trace), plan_path)
    end)
  end

  test "immutable root rejects a coordinated registry and feasibility-copy rebase" do
    plan = valid_plan()
    trace = plan["optimizer_search_trace"]
    forged_id = "local_search_source_evidence_registry:" <> String.duplicate("a", 64)

    forged_result =
      trace["search_result"]
      |> put_in(["source_evidence_registry", "id"], forged_id)
      |> Map.update!("candidate_feasibility_evaluations", fn evaluations ->
        Enum.map(evaluations, &Map.put(&1, "source_evidence_registry_id", forged_id))
      end)
      |> Map.update!("alternatives", fn alternatives ->
        Enum.map(alternatives, fn alternative ->
          update_in(alternative, ["candidate_feasibility"], fn evaluation ->
            Map.put(evaluation, "source_evidence_registry_id", forged_id)
          end)
        end)
      end)

    selected =
      Enum.find(forged_result["alternatives"], &(&1["id"] == forged_result["selected_id"]))

    forged_trace =
      trace
      |> Map.put("search_result", forged_result)
      |> Map.put("selected_alternative", selected)

    assert_error_path(forged_trace, "$.search_root.source_candidate_evidence")

    assert_error_path(
      put_in(trace, ["search_result", "source_evidence_registry", "id"], forged_id),
      "$.search_root.source_evidence_registry"
    )

    forged_plan = BuildArtifact.attach_optimizer_search_trace(plan, forged_trace)

    assert_error_path(
      forged_plan,
      "$.optimizer_search_trace.search_root.source_candidate_evidence"
    )
  end

  test "trace authority rejects coherently rebased approved and ready handoff summaries" do
    plan = valid_plan()
    package = plan["operator_review_package"]
    manifest = plan["cadence_import_manifest"]

    {forged_review_rows, forged_review_row} =
      replace_row(package["rows"], "review_type", "local_search_review", fn row ->
        row
        |> Map.put("approval_status", "approved")
        |> Map.put(
          "review_queue_key",
          "local_search_review|review_local_search|approved"
        )
      end)

    forged_package =
      package
      |> Map.put("rows", forged_review_rows)
      |> Map.update!("approval_status_counts", fn counts ->
        counts
        |> Map.update!("operator_review_required", &(&1 - 1))
        |> Map.put("approved", 1)
      end)
      |> Map.update!("review_queue_counts", fn counts ->
        counts
        |> Map.delete("local_search_review|review_local_search|operator_review_required")
        |> Map.put("local_search_review|review_local_search|approved", 1)
      end)

    {forged_cadence_rows, _forged_cadence_row} =
      replace_row(manifest["rows"], "import_action", "review_local_search", fn row ->
        row
        |> Map.put("approval_status", "approved")
        |> Map.put("import_status", "ready_for_import")
        |> Map.put("source_review_row", forged_review_row)
      end)

    forged_manifest =
      manifest
      |> Map.put("rows", forged_cadence_rows)
      |> Map.update!("ready_count", &(&1 + 1))
      |> Map.update!("review_required_count", &(&1 - 1))
      |> Map.update!("import_status_counts", fn counts ->
        counts
        |> Map.update!("ready_for_import", &(&1 + 1))
        |> Map.update!("review_required_before_import", &(&1 - 1))
      end)

    forged_plan =
      plan
      |> Map.put("operator_review_package", forged_package)
      |> Map.put("cadence_import_manifest", forged_manifest)

    assert_invalid(forged_plan, "operator_review_package")
    assert_invalid(forged_plan, "cadence_import_manifest")
  end

  test "deletion, duplication, and reordering of local-search handoffs fail closed" do
    plan = valid_plan()
    rows = plan["operator_review_package"]["rows"]
    local_row = Enum.find(rows, &(&1["review_type"] == "local_search_review"))
    without_local = Enum.reject(rows, &(&1["review_type"] == "local_search_review"))

    assert_invalid(
      put_in(plan, ["operator_review_package", "rows"], without_local),
      "operator_review_package"
    )

    assert_invalid(
      put_in(plan, ["operator_review_package", "rows"], rows ++ [local_row]),
      "operator_review_package"
    )

    reordered =
      rows
      |> List.delete(local_row)
      |> List.insert_at(0, local_row)

    assert_invalid(
      put_in(plan, ["operator_review_package", "rows"], reordered),
      "operator_review_package"
    )

    cadence_rows = plan["cadence_import_manifest"]["rows"]
    local_import = Enum.find(cadence_rows, &(&1["import_action"] == "review_local_search"))

    without_local_import =
      Enum.reject(cadence_rows, &(&1["import_action"] == "review_local_search"))

    assert_invalid(
      put_in(plan, ["cadence_import_manifest", "rows"], without_local_import),
      "cadence_import_manifest"
    )

    assert_invalid(
      put_in(plan, ["cadence_import_manifest", "rows"], cadence_rows ++ [local_import]),
      "cadence_import_manifest"
    )

    reordered_import =
      cadence_rows
      |> List.delete(local_import)
      |> List.insert_at(0, local_import)

    assert_invalid(
      put_in(plan, ["cadence_import_manifest", "rows"], reordered_import),
      "cadence_import_manifest"
    )
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

  defp update_alternative(trace, index, update) do
    update_in(trace, ["search_result", "alternatives"], fn alternatives ->
      List.update_at(alternatives, index, update)
    end)
  end

  defp replace_row(rows, field, value, update) do
    forged = Enum.find(rows, &(&1[field] == value)) |> update.()
    {Enum.map(rows, &if(&1[field] == value, do: forged, else: &1)), forged}
  end

  defp assert_error_path(artifact, expected_path) do
    assert {:error, report} = Schema.validate_artifact(artifact)

    assert Enum.any?(report["errors"], &(&1["path"] == expected_path)),
           "expected exact path #{inspect(expected_path)}, got: #{inspect(report["errors"])}"
  end

  defp assert_invalid(artifact, path_fragment) do
    assert {:error, report} = Schema.validate_artifact(artifact)

    assert Enum.any?(report["errors"], fn error ->
             String.contains?(error["path"], path_fragment)
           end),
           "expected an error containing #{inspect(path_fragment)}, got: #{inspect(report["errors"])}"
  end
end
