Code.require_file("local_search_support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.V1LocalSearchSelectionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.CampaignPlanner.{BuildOrchestration, LocalSearchSelection}
  alias OrbitalDynamics.CampaignPlanner.LocalSearchSupport, as: Support
  alias OrbitalDynamics.Optimizer.SourceEvidenceRegistry
  alias OrbitalDynamics.Schema

  test "selects the exact feasible V1 plan and excludes the higher-scoring infeasible plan" do
    plan = build()
    trace = plan["optimizer_search_trace"]
    alternatives = trace["search_result"]["alternatives"]
    seed = alternative(alternatives, "campaign_policy:seed")
    increase = alternative(alternatives, "campaign_policy:target_value_weight:increase")

    assert increase["score"] > seed["score"]
    assert increase["candidate_feasibility"]["eligible"] == false
    assert increase["rank"] == nil
    assert "downlink_threshold_not_met" in increase["candidate_feasibility"]["blocker_reasons"]

    assert trace["selected_alternative_id"] == seed["id"]
    assert trace["selected_alternative"] == seed
    assert trace["selected_timeline_score"] == seed["score"]
    assert trace["selected_scoring_policy"] == plan["optimizer_contract"]["scoring_policy"]
    assert plan["optimizer_contract"]["optimizer"] == "per_spacecraft_greedy_non_overlapping"
    assert trace["selection_contract"] == LocalSearchSelection.selection_contract()

    assert trace["search_result"]["objective"] ==
             "maximize first ranked timeline aggregate score"

    assert OrbitalDynamics.campaign_plan_with_local_search(
             Support.result_set(),
             build_opts()
           ) == plan

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(plan)
  end

  test "returns a typed trace and constructs no campaign or handoff artifact when all alternatives fail" do
    search =
      Support.local_search(%{
        "hard_feasibility" => Support.hard_feasibility(all_infeasible?: true)
      })

    assert {:no_selected_plan, trace} = build(search)
    assert trace["schema_contract"] == "campaign_plan_search_trace.v1"
    assert trace["status"] == "no_selected_plan"
    assert trace["selected_alternative_id"] == nil
    assert trace["selected_alternative"] == nil
    assert trace["selected_scoring_policy"] == nil
    assert trace["selected_timeline_scenario_id"] == nil
    assert trace["selected_timeline_score"] == nil
    assert trace["selected_activity_ids"] == []
    assert trace["selected_activity_count"] == 0
    assert trace["search_result"]["eligible_count"] == 0
    assert trace["search_result"]["infeasible_count"] == 3
    assert Enum.all?(trace["search_result"]["alternatives"], &is_nil(&1["rank"]))

    refute Map.has_key?(trace, "operator_review_package")
    refute Map.has_key?(trace, "cadence_import_manifest")
    refute Map.has_key?(trace, "operational_readiness_report")
    refute Map.has_key?(trace, "quality_gate_report")

    assert {:ok, %{"schema_contract" => "campaign_plan_search_trace.v1"}} =
             Schema.validate_artifact(trace)
  end

  test "binds a feasible improved alternative back to its exact unchanged V1 build" do
    search =
      Support.local_search(%{
        "hard_feasibility" => Support.hard_feasibility(higher_score_infeasible?: false)
      })

    plan = build(search)
    trace = plan["optimizer_search_trace"]

    assert trace["selected_alternative_id"] ==
             "campaign_policy:target_value_weight:increase"

    assert trace["selected_scoring_policy"]["target_value_weight"] == 2.0
    assert trace["selected_timeline_score"] == 200.0

    effective_campaign =
      Map.put(Support.campaign(), "scoring_policy", trace["selected_scoring_policy"])

    direct_v1 =
      CampaignPlanner.build(
        Support.result_set(),
        campaign: effective_campaign,
        generated_at: Support.generated_at()
      )

    derived_keys = [
      "optimizer_search_trace",
      "operator_review_package",
      "cadence_import_manifest",
      "operational_readiness_report",
      "quality_gate_report"
    ]

    assert Map.drop(plan, derived_keys) == Map.drop(direct_v1, derived_keys)
    assert {:ok, _report} = Schema.validate_artifact(plan)
  end

  test "retains bounded generation, rejected moves, budget, and deterministic order in the trace" do
    alternatives = Support.alternatives(max_alternatives: 2)

    search =
      Support.local_search(%{
        "max_alternatives" => 2,
        "hard_feasibility" => Support.hard_feasibility(alternatives: alternatives)
      })

    plan = build(search)
    result = plan["optimizer_search_trace"]["search_result"]

    assert result["neighborhood"]["max_alternatives"] == 2
    assert result["neighborhood"]["alternative_count"] == 2
    assert result["neighborhood"]["truncated_move_count"] == 1

    assert result["neighborhood"]["bounds"] == %{
             "target_value_weight" => %{"minimum" => 0.0, "maximum" => 2.0}
           }

    assert Enum.map(result["alternatives"], & &1["id"]) == [
             "campaign_policy:seed",
             "campaign_policy:target_value_weight:decrease"
           ]

    assert [%{"reason" => "alternative_limit"}] = result["rejected_moves"]

    bounded_alternatives = Support.alternatives(bounds: %{"target_value_weight" => {1.0, 2.0}})

    bounded_search =
      Support.local_search(%{
        "bounds" => %{"target_value_weight" => [1.0, 2.0]},
        "hard_feasibility" => Support.hard_feasibility(alternatives: bounded_alternatives)
      })

    bounded_result = build(bounded_search)["optimizer_search_trace"]["search_result"]

    assert bounded_result["neighborhood"]["alternative_count"] == 2
    assert bounded_result["neighborhood"]["rejected_move_count"] == 1
    assert [%{"reason" => "below_minimum_bound"}] = bounded_result["rejected_moves"]
  end

  test "is deterministic for permuted result and evidence input order" do
    search = Support.local_search()
    first = build(search, :forward)

    hard = search["hard_feasibility"]

    permuted_hard = %{
      hard
      | "candidates" => Enum.reverse(hard["candidates"]),
        "evidence_registry" =>
          hard["evidence_registry"]["entries"]
          |> Enum.reverse()
          |> Map.new()
          |> SourceEvidenceRegistry.build()
    }

    second = build(%{search | "hard_feasibility" => permuted_hard}, :reverse)
    assert second == first
  end

  test "rejects objective injection, unsupported policy dimensions, collisions, and unsafe containers" do
    assert_raise ArgumentError, ~r/unsupported local-search campaign option :objective/, fn ->
      CampaignPlanner.build_with_local_search(
        Support.result_set(),
        Keyword.put(build_opts(), :objective, fn _ -> 1 end)
      )
    end

    assert_raise ArgumentError, ~r/unsupported V1 scoring key rank_limit/, fn ->
      build(Support.local_search(%{"steps" => %{"rank_limit" => 1}}))
    end

    assert_raise ArgumentError, ~r/unsupported field constraints/, fn ->
      build(Support.local_search(%{"constraints" => %{}}))
    end

    assert_raise ArgumentError, ~r/unsupported field seed_parameters/, fn ->
      build(Support.local_search(%{"seed_parameters" => %{"target_value_weight" => 2.0}}))
    end

    assert_raise ArgumentError, ~r/duplicate atom\/string keys/, fn ->
      build(%{
        "steps" => %{"target_value_weight" => 1.0},
        "hard_feasibility" => Support.hard_feasibility(),
        :steps => %{target_value_weight: 1.0}
      })
    end

    assert_raise ArgumentError, ~r/unsupported PID content/, fn ->
      build(Support.local_search(%{"id_prefix" => self()}))
    end

    assert_raise ArgumentError, ~r/unsupported tuple content/, fn ->
      build(Support.local_search(%{"bounds" => %{"target_value_weight" => {0.0, 2.0}}}))
    end

    assert_raise ArgumentError, fn ->
      build(
        Support.local_search(%{
          "bounds" => %{"target_value_weight" => [0.0 | 2.0]}
        })
      )
    end
  end

  test "fails source binding closed for missing, stale, cross-alternative, revision, and spacecraft evidence" do
    increase_id = "campaign_policy:target_value_weight:increase"

    missing =
      Support.hard_feasibility(higher_score_infeasible?: false)
      |> Support.rebuild_registry(&Map.delete(&1, increase_id))

    assert_increase_infeasible(missing, "missing_source_evidence_registry_entry")

    stale_parameters =
      Support.hard_feasibility(higher_score_infeasible?: false)
      |> Support.rebuild_registry(fn entries ->
        put_in(
          entries,
          [increase_id, "parameter_content_identity"],
          SourceEvidenceRegistry.parameter_content_identity(%{"target_value_weight" => 99.0})
        )
      end)

    assert_increase_infeasible(stale_parameters, "parameter_content_identity_registry_mismatch")

    base = Support.hard_feasibility(higher_score_infeasible?: false)

    seed_trace_id =
      get_in(base, [
        "evidence_registry",
        "entries",
        "campaign_policy:seed",
        "resource_state_trace_id"
      ])

    cross_alternative =
      Support.rebuild_registry(base, fn entries ->
        put_in(entries, [increase_id, "resource_state_trace_id"], seed_trace_id)
      end)

    assert_increase_infeasible(
      cross_alternative,
      "resource_state_trace_registry_identity_mismatch"
    )

    malformed_revision =
      base
      |> Support.update_candidate(increase_id, fn candidate ->
        put_in(
          candidate,
          ["resource_state_trace", "provenance", "caller", "resource_state_trace_revision"],
          "not a stable revision"
        )
      end)

    assert_increase_infeasible(malformed_revision, [
      "resource_state_trace_revision_missing_or_malformed",
      "malformed_resource_state_trace"
    ])

    spacecraft_mismatch =
      base
      |> Support.update_candidate(increase_id, fn candidate ->
        put_in(candidate, ["downlink_link_budget", "contact_binding", "spacecraft_id"], "sc_2")
      end)

    assert_increase_infeasible(spacecraft_mismatch, [
      "candidate_evidence_spacecraft_mismatch",
      "malformed_downlink_link_budget"
    ])

    tampered_registry = put_in(base, ["evidence_registry", "id"], "tampered-registry")

    assert_raise ArgumentError, ~r/source evidence registry content identity mismatch/, fn ->
      build(Support.local_search(%{"hard_feasibility" => tampered_registry}))
    end
  end

  test "default V1 builder, public facade, and orchestration remain exactly compatible" do
    opts = [campaign: Support.campaign(), generated_at: Support.generated_at()]
    expected = CampaignPlanner.build(Support.result_set(), opts)

    assert OrbitalDynamics.campaign_plan(Support.result_set(), opts) == expected

    assert BuildOrchestration.build(
             Support.result_set(),
             Support.campaign(),
             Support.generated_at()
           ) == expected

    refute Map.has_key?(expected, "optimizer_search_trace")

    refute Enum.any?(expected["operator_review_package"]["rows"], fn row ->
             row["review_type"] == "local_search_review"
           end)

    refute Enum.any?(expected["cadence_import_manifest"]["rows"], fn row ->
             row["import_action"] == "review_local_search"
           end)
  end

  defp build(search \\ Support.local_search(), order \\ :forward) do
    CampaignPlanner.build_with_local_search(
      Support.result_set(order),
      build_opts(search)
    )
  end

  defp build_opts(search \\ Support.local_search()) do
    [campaign: Support.campaign(), generated_at: Support.generated_at(), local_search: search]
  end

  defp alternative(alternatives, id), do: Enum.find(alternatives, &(&1["id"] == id))

  defp assert_increase_infeasible(hard_feasibility, reason_or_reasons) do
    plan = build(Support.local_search(%{"hard_feasibility" => hard_feasibility}))
    result = plan["optimizer_search_trace"]["search_result"]
    increase = alternative(result["alternatives"], "campaign_policy:target_value_weight:increase")
    reasons = List.wrap(reason_or_reasons)

    assert increase["candidate_feasibility"]["eligible"] == false
    assert increase["rank"] == nil
    assert Enum.any?(reasons, &(&1 in increase["candidate_feasibility"]["blocker_reasons"]))
    assert result["selected_id"] == "campaign_policy:seed"
  end
end
