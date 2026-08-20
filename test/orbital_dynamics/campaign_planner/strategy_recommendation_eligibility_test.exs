Code.require_file("support.exs", __DIR__)
Code.require_file("local_search_support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationEligibilityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.CampaignPlanner.LocalSearchSupport, as: HardSupport
  alias OrbitalDynamics.CampaignPlanner.TestSupport, as: Support
  alias OrbitalDynamics.Optimizer.SourceEvidenceRegistry
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.JsonSafety

  @legacy_digest "430fdc4f9045c83c32d7d5f153868b945f00b67ae66985d33ce290a8bfce326f"

  test "hard mode ranks only eligible branches by score descending then branch_id" do
    branches = [
      %{id: "zulu"},
      %{id: "baseline"},
      %{id: "alpha"}
    ]

    artifact = hard_strategy(branches)
    eligibility = artifact["recommendation_eligibility"]

    assert eligibility["eligible_ranked_branch_ids"] == ["alpha", "baseline", "zulu"]
    assert artifact["recommendation"]["recommended_branch_id"] == "alpha"
    assert artifact["recommendation"]["ranked_branch_ids"] == ["alpha", "baseline", "zulu"]

    assert Enum.map(eligibility["evaluations"], & &1["branch_id"]) == [
             "alpha",
             "baseline",
             "zulu"
           ]

    assert Enum.all?(eligibility["evaluations"], & &1["eligible"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(artifact)

    assert_json_roundtrip(artifact)
  end

  test "a higher-scoring hard-infeasible branch cannot win" do
    branches = [
      %{id: "baseline", probability: 0.5},
      %{id: "blocked:increase", probability: 1.0}
    ]

    artifact = hard_strategy(branches)
    blocked = eligibility_evaluation(artifact, "blocked:increase")
    baseline = eligibility_evaluation(artifact, "baseline")

    assert blocked["score"] > baseline["score"]
    assert blocked["status"] == "infeasible"
    assert blocked["eligible"] == false
    assert "downlink_threshold_not_met" in blocked["blocker_reasons"]
    assert artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert artifact["recommendation"]["ranked_branch_ids"] == ["baseline"]

    selected_import = selected_import_row(artifact)
    assert selected_import["branch_id"] == "baseline"
    refute selected_import["branch_id"] == "blocked:increase"
  end

  test "stale caller-repinned score identity blocks without invalidating typed evidence" do
    prior_plan = Support.base_plan(%{})

    opts = [
      branches: [%{id: "baseline"}, %{id: "alternate"}],
      mission_state: Support.mission_state([]),
      current_epoch_s: 0.0
    ]

    hard_feasibility =
      prior_plan
      |> hard_setting(opts)
      |> HardSupport.rebuild_registry(fn entries ->
        update_in(entries, ["baseline", "parameter_content_identity"], fn _identity ->
          SourceEvidenceRegistry.parameter_content_identity(%{"repinned" => 1.0})
        end)
      end)

    artifact =
      Support.strategy(
        prior_plan,
        Keyword.put(opts, :recommendation_eligibility, hard_feasibility)
      )

    baseline = eligibility_evaluation(artifact, "baseline")

    assert baseline["status"] == "infeasible"
    assert "parameter_content_identity_registry_mismatch" in baseline["blocker_reasons"]

    refute baseline["branch_score_term_identity"] ==
             baseline["hard_feasibility"]["parameter_content_identity"]

    assert {:ok, _report} = Schema.validate_artifact(artifact)
  end

  test "all-blocked hard mode emits null selection and a review-only rejected counterfactual" do
    branches = [
      %{id: "baseline", probability: 0.5},
      %{id: "blocked:increase", probability: 1.0}
    ]

    artifact = hard_strategy(branches, all_infeasible?: true)
    recommendation = artifact["recommendation"]
    eligibility = artifact["recommendation_eligibility"]
    counterfactual = recommendation["counterfactual"]

    assert recommendation["status"] == "no_recommendable_branch"
    assert recommendation["recommended_branch_id"] == :null
    assert recommendation["ranked_branch_ids"] == []
    assert recommendation["approval_status"] == "not_applicable"
    assert eligibility["selected_branch_id"] == :null
    assert eligibility["eligible_ranked_branch_ids"] == []
    assert counterfactual["branch_id"] == "blocked:increase"
    assert counterfactual["review_only"] == true
    assert counterfactual["importable"] == false
    assert "downlink_threshold_not_met" in counterfactual["blocker_reasons"]
    assert counterfactual["hard_feasibility"]["eligible"] == false

    review = artifact["operator_review_package"]
    refute Enum.any?(review["rows"], &(&1["review_type"] == "strategy_recommendation"))
    assert review["recommendation_count"] == 0

    counterfactual_review =
      Enum.find(review["rows"], fn row ->
        get_in(row, ["source_branch_comparison", "recommendation_counterfactual"]) == true
      end)

    assert counterfactual_review["recommendation_counterfactual"] == true
    assert "downlink_threshold_not_met" in counterfactual_review["recommendation_blocker_reasons"]
    assert String.starts_with?(counterfactual_review["reason"], "review-only rejected branch")

    manifest_rows = artifact["cadence_import_manifest"]["rows"]
    refute Enum.any?(manifest_rows, &(&1["import_action"] == "import_strategy_recommendation"))
    refute Enum.any?(manifest_rows, &(&1["source_review_type"] == "strategy_recommendation"))

    counterfactual_imports =
      Enum.filter(manifest_rows, &(&1["recommendation_counterfactual"] == true))

    assert Enum.sort(Enum.map(counterfactual_imports, & &1["source_review_type"])) == [
             "strategy_branch_comparison",
             "strategy_tradeoff"
           ]

    for counterfactual_import <- counterfactual_imports do
      assert counterfactual_import["import_status"] == "not_applicable"
      assert counterfactual_import["cadence_import_status"] == "not_applicable"
      assert counterfactual_import["has_cadence_import"] == false
      assert counterfactual_import["review_only"] == true
      assert counterfactual_import["importable"] == false
      assert counterfactual_import["recommendation_eligibility_status"] == "infeasible"
      refute counterfactual_import["import_status"] == "ready_for_import"
    end

    branch_import =
      Enum.find(
        counterfactual_imports,
        &(&1["source_review_type"] == "strategy_branch_comparison")
      )

    refute Map.has_key?(branch_import, "eligibility_status")
    assert {:ok, _report} = Schema.validate_artifact(artifact)
    assert_json_roundtrip(artifact)
  end

  test "branch policy blockers are applied before score ordering and retain exact decision evidence" do
    prior_plan =
      Support.base_plan(%{
        "activities" => [Support.maneuver("burn_1", 300.0)]
      })

    branches = [
      %{id: "baseline", probability: 0.1},
      %{
        id: "policy_high",
        probability: 1.0,
        events: [
          %{type: "delayed_maneuver", activity_id: "burn_1", actual_starts_at_s: 360.0}
        ]
      }
    ]

    opts = [
      branches: branches,
      mission_state: Support.mission_state([]),
      current_epoch_s: 0.0,
      strategy_policy: %{
        risk_weight: 0.0,
        approval_load_weight: 0.0,
        schedule_stability_weight: 0.0
      },
      approval_policy: %{
        blocked_risk_types: [],
        action_rules: [
          %{
            id: "block_delayed_maneuver",
            event_types: ["delayed_maneuver"],
            classification: "blocked_by_policy",
            reason: "maneuver_timing_change_blocked"
          }
        ]
      }
    ]

    artifact = hard_strategy_from_plan(prior_plan, opts)
    blocked = eligibility_evaluation(artifact, "policy_high")

    assert blocked["score"] > eligibility_evaluation(artifact, "baseline")["score"]
    assert blocked["hard_feasibility"]["eligible"] == true
    assert blocked["status"] == "policy_blocked"
    assert blocked["policy_blocker"] == branch(artifact, "policy_high")["policy_decision"]
    assert "maneuver_timing_change_blocked" in blocked["blocker_reasons"]
    assert artifact["recommendation"]["recommended_branch_id"] == "baseline"
  end

  test "fail-closed authority evaluation blocks hard-feasible branches with bound evidence" do
    branches = [%{id: "baseline"}, %{id: "alternate"}]

    opts = [
      branches: branches,
      mission_state: Support.mission_state([]),
      current_epoch_s: 0.0,
      authority_context_mode: :explicit,
      authority_context: %{"source_revision" => "malformed-only"}
    ]

    artifact = hard_strategy_from_plan(Support.base_plan(%{}), opts)
    recommendation = artifact["recommendation"]

    assert recommendation["status"] == "no_recommendable_branch"
    assert recommendation["recommended_branch_id"] == :null

    for evaluation <- artifact["recommendation_eligibility"]["evaluations"] do
      branch_decision = branch(artifact, evaluation["branch_id"])["policy_decision"]

      assert evaluation["hard_feasibility"]["eligible"] == true
      assert evaluation["status"] == "policy_blocked"
      assert evaluation["policy_blocker"] == branch_decision

      assert evaluation["policy_blocker"]["authority_context_evaluation"]["reason_code"] ==
               "malformed_authority_context"

      assert "malformed_authority_context" in evaluation["blocker_reasons"]
    end

    assert {:ok, _report} = Schema.validate_artifact(artifact)
  end

  test "default V3 behavior and canonical byte shape are unchanged when opt-in is absent" do
    artifact =
      Support.strategy(Support.base_plan(%{}),
        branches: [%{id: "baseline"}, %{id: "alternate", probability: 0.8}],
        mission_state: Support.mission_state([]),
        current_epoch_s: 0.0
      )

    refute Map.has_key?(artifact, "recommendation_eligibility")
    refute Map.has_key?(artifact["recommendation"], "counterfactual")
    assert artifact["recommendation"]["status"] == "pass"
    assert map_size(artifact) == 22
    assert digest(artifact) == @legacy_digest
  end

  test "public hard-mode validation is total for malformed JSON-safe and unsafe settings" do
    request = base_request([%{id: "baseline"}, %{id: "alternate"}])

    for setting <- [
          [],
          :null,
          %{},
          %{"mode" => "soft"},
          %{"mode" => "hard", "evidence_registry" => [], "candidates" => []},
          %{"mode" => "hard", "evidence_registry" => %{}, "candidates" => %{}},
          %{"mode" => "hard", "evidence_registry" => %{}, "candidates" => ["bad"]},
          %{"mode" => "hard", "unsupported" => true},
          %{"mode" => "hard", self() => "unsafe"}
        ] do
      assert_raise ArgumentError, fn ->
        request
        |> Map.put(:recommendation_eligibility, setting)
        |> CampaignPlanner.strategy()
      end
    end

    assert_raise ArgumentError, ~r/must not use both atom and string aliases/, fn ->
      request
      |> Map.put(:recommendation_eligibility, %{"mode" => "hard"})
      |> Map.put("recommendation_eligibility", %{"mode" => "hard"})
      |> CampaignPlanner.strategy()
    end
  end

  test "schema validation rejects reordered eligibility and repinned policy evidence" do
    artifact =
      hard_strategy([
        %{id: "zulu"},
        %{id: "baseline"},
        %{id: "alpha"}
      ])

    reordered =
      update_in(
        artifact,
        ["recommendation_eligibility", "eligible_ranked_branch_ids"],
        &Enum.reverse/1
      )

    assert {:error, reordered_report} = Schema.validate_artifact(reordered)

    assert Enum.any?(
             reordered_report["errors"],
             &(&1["path"] == "$.recommendation_eligibility.eligible_ranked_branch_ids")
           )

    identity_drift =
      put_in(
        artifact,
        [
          "recommendation_eligibility",
          "evaluations",
          Access.at(0),
          "branch_score_term_identity"
        ],
        SourceEvidenceRegistry.parameter_content_identity(%{"repinned" => 1.0})
      )

    assert {:error, identity_report} = Schema.validate_artifact(identity_drift)

    assert Enum.any?(
             identity_report["errors"],
             &String.ends_with?(&1["path"], ".branch_score_term_identity")
           )

    all_blocked =
      hard_strategy(
        [%{id: "baseline"}, %{id: "blocked:increase"}],
        all_infeasible?: true
      )

    repinned =
      put_in(
        all_blocked,
        ["recommendation_eligibility", "evaluations", Access.at(0), "policy_blocker"],
        %{"classification" => "blocked_by_policy", "caller_status" => "trusted"}
      )

    assert {:error, repinned_report} = Schema.validate_artifact(repinned)

    assert Enum.any?(
             repinned_report["errors"],
             &String.ends_with?(&1["path"], ".policy_blocker")
           )
  end

  test "artifact validation returns typed errors for malformed hard-eligibility maps and lists" do
    artifact = hard_strategy([%{id: "baseline"}, %{id: "alternate"}])

    malformed_artifacts = [
      Map.put(artifact, "recommendation_eligibility", []),
      put_in(artifact, ["recommendation_eligibility", "evaluations"], ["malformed"]),
      put_in(artifact, ["recommendation_eligibility", "source_evidence_registry"], []),
      put_in(artifact, ["branches", Access.at(0), "policy_decision"], ["malformed"]),
      Map.put(artifact, "branch_comparison_report", [])
    ]

    for {malformed, index} <- Enum.with_index(malformed_artifacts) do
      result = Schema.validate_artifact(malformed)

      assert match?({:error, %{"status" => "fail", "errors" => [_first | _rest]}}, result),
             "malformed artifact case #{index} unexpectedly validated: #{inspect(result)}"
    end
  end

  test "Schema validation returns typed errors without raising for improper new lists" do
    artifact =
      hard_strategy(
        [%{id: "baseline"}, %{id: "blocked:increase"}],
        all_infeasible?: true
      )

    [first_evaluation | _rest] = artifact["recommendation_eligibility"]["evaluations"]
    [first_blocker | _rest] = first_evaluation["hard_feasibility"]["blockers"]

    malformed_artifacts = [
      put_in(
        artifact,
        ["recommendation_eligibility", "evaluations"],
        [first_evaluation | :improper_tail]
      ),
      put_in(
        artifact,
        [
          "recommendation_eligibility",
          "evaluations",
          Access.at(0),
          "hard_feasibility",
          "blockers"
        ],
        [first_blocker | :improper_tail]
      )
    ]

    for malformed <- malformed_artifacts do
      assert_typed_schema_error(malformed)
    end
  end

  test "procedural hard-eligibility validation is JSON-safe and closed at new boundaries" do
    artifact =
      hard_strategy(
        [%{id: "baseline"}, %{id: "blocked:increase"}],
        all_infeasible?: true
      )

    oversized = String.duplicate("x", JsonSafety.limits()["max_aggregate_bytes"] + 1)

    first_branch_id =
      artifact["recommendation_eligibility"]["evaluations"] |> hd() |> Map.fetch!("branch_id")

    adversarial_artifacts = [
      update_in(artifact, ["recommendation_eligibility"], &Map.put(&1, self(), "unsafe")),
      update_in(artifact, ["recommendation_eligibility"], &Map.put(&1, :mode, "hard")),
      update_in(
        artifact,
        ["recommendation_eligibility"],
        &Map.put(&1, "oversized_unknown", oversized)
      ),
      put_in(
        artifact,
        ["recommendation_eligibility", "evaluations", Access.at(0), "unknown"],
        true
      ),
      put_in(
        artifact,
        [
          "recommendation_eligibility",
          "evaluations",
          Access.at(0),
          "hard_feasibility",
          "unknown"
        ],
        true
      ),
      put_in(
        artifact,
        ["recommendation_eligibility", "source_evidence_registry", "unknown"],
        true
      ),
      put_in(
        artifact,
        [
          "recommendation_eligibility",
          "source_evidence_registry",
          "entries",
          first_branch_id,
          "unknown"
        ],
        true
      ),
      put_in(
        artifact,
        [
          "recommendation_eligibility",
          "evaluations",
          Access.at(0),
          "branch_score_term_identity",
          "unknown"
        ],
        true
      ),
      put_in(
        artifact,
        [
          "recommendation_eligibility",
          "evaluations",
          Access.at(0),
          "hard_feasibility",
          "evidence_bindings",
          "unknown"
        ],
        true
      ),
      put_in(
        artifact,
        [
          "recommendation_eligibility",
          "evaluations",
          Access.at(0),
          "hard_feasibility",
          "evidence_bindings",
          "resource_state_trace",
          "unknown"
        ],
        true
      ),
      put_in(
        artifact,
        [
          "recommendation_eligibility",
          "evaluations",
          Access.at(0),
          "hard_feasibility",
          "threshold_evaluations",
          Access.at(0),
          "unknown"
        ],
        true
      ),
      put_in(
        artifact,
        [
          "recommendation_eligibility",
          "evaluations",
          Access.at(0),
          "hard_feasibility",
          "blockers",
          Access.at(0),
          "unknown"
        ],
        true
      ),
      put_in(
        artifact,
        ["recommendation_eligibility", "counterfactual", "unknown"],
        true
      ),
      put_in(
        artifact,
        ["recommendation_eligibility", "counterfactual", "importable"],
        true
      ),
      update_in(artifact, ["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row["recommendation_counterfactual"] == true,
            do: Map.put(row, "importable", true),
            else: row
        end)
      end)
    ]

    for adversarial <- adversarial_artifacts do
      assert_typed_schema_error(adversarial)
    end
  end

  test "source evidence registry identity is recomputed from canonical bound entries" do
    artifact =
      hard_strategy(
        [%{id: "baseline"}, %{id: "blocked:increase"}],
        all_infeasible?: true
      )

    repinned_id = "local_search_source_evidence_registry:" <> String.duplicate("a", 64)
    repinned = repin_registry_id_copies(artifact, repinned_id)

    assert {:error, report} = Schema.validate_artifact(repinned)

    assert Enum.any?(report["errors"], fn issue ->
             issue["path"] == "$.recommendation_eligibility.source_evidence_registry.id" and
               String.contains?(issue["message"], "recomputable")
           end)

    refute Enum.any?(report["errors"], fn issue ->
             String.contains?(
               issue["message"],
               "must match the declared source evidence registry"
             )
           end)
  end

  test "blocker metric and operator copies retain exported optional string types" do
    artifact = hard_strategy_with_mixed_blockers()

    for field <- ["metric", "operator"] do
      mutated =
        map_hard_feasibility_copies(artifact, fn hard ->
          update_in(hard, ["blockers"], fn blockers ->
            Enum.map(blockers, &Map.put(&1, field, 42))
          end)
        end)

      assert json_occurrences(mutated, "\"schema_contract\":\"candidate_feasibility.v1\"") ==
               22

      assert json_occurrences(mutated, "\"#{field}\":42") == 22
      assert {:error, report} = Schema.validate_artifact(mutated)

      assert Enum.any?(report["errors"], fn issue ->
               String.starts_with?(
                 issue["path"],
                 "$.recommendation_eligibility.evaluations["
               ) and
                 String.ends_with?(
                   issue["path"],
                   ".hard_feasibility.blockers[0].#{field}"
                 ) and issue["message"] == "must be a binary"
             end)
    end
  end

  test "exported hard-eligibility schema is deterministic and closes nested maps" do
    assert {:ok, first_schema} = Schema.json_schema("campaign_strategy.v3")
    assert {:ok, second_schema} = Schema.json_schema("campaign_strategy.v3")
    assert first_schema == second_schema

    eligibility = get_in(first_schema, ["properties", "recommendation_eligibility"])
    evaluation = get_in(eligibility, ["properties", "evaluations", "items"])
    hard = get_in(evaluation, ["properties", "hard_feasibility"])
    registry = get_in(eligibility, ["properties", "source_evidence_registry"])
    registry_entry = get_in(registry, ["properties", "entries", "additionalProperties"])

    assert eligibility["additionalProperties"] == false
    assert evaluation["additionalProperties"] == false
    assert hard["additionalProperties"] == false
    assert registry["additionalProperties"] == false
    assert registry_entry["additionalProperties"] == false

    assert first_schema
           |> :json.encode()
           |> IO.iodata_to_binary()
           |> :json.decode() == first_schema
  end

  defp hard_strategy(branches, hard_opts \\ []) do
    opts = [
      branches: branches,
      mission_state: Support.mission_state([]),
      current_epoch_s: 0.0
    ]

    hard_strategy_from_plan(Support.base_plan(%{}), opts, hard_opts)
  end

  defp hard_strategy_from_plan(prior_plan, opts, hard_opts \\ []) do
    hard_feasibility = hard_setting(prior_plan, opts, hard_opts)

    Support.strategy(prior_plan, Keyword.put(opts, :recommendation_eligibility, hard_feasibility))
  end

  defp hard_strategy_with_mixed_blockers do
    prior_plan = Support.base_plan(%{})

    opts = [
      branches: [%{id: "baseline"}, %{id: "blocked:increase"}],
      mission_state: Support.mission_state([]),
      current_epoch_s: 0.0
    ]

    hard_feasibility =
      prior_plan
      |> hard_setting(opts, all_infeasible?: true)
      |> update_in(["candidates"], fn candidates ->
        Enum.reject(candidates, &(&1["alternative_id"] == "baseline"))
      end)

    Support.strategy(prior_plan, Keyword.put(opts, :recommendation_eligibility, hard_feasibility))
  end

  defp hard_setting(prior_plan, opts, hard_opts \\ []) do
    legacy = Support.strategy(prior_plan, opts)

    alternatives =
      legacy["branches"]
      |> Enum.with_index()
      |> Enum.map(fn {branch, generation_index} ->
        %{
          "id" => branch["branch_id"],
          "generation_index" => generation_index,
          "parameters" => branch["score_terms"]
        }
      end)

    hard_opts
    |> Keyword.put(:alternatives, alternatives)
    |> HardSupport.hard_feasibility()
  end

  defp base_request(branches) do
    %{
      prior_plan: Support.base_plan(%{}),
      branches: branches,
      mission_state: Support.mission_state([]),
      current_epoch_s: 0.0,
      remaining_horizon: %{"starts_at_s" => 0.0, "ends_at_s" => 2_000.0},
      generated_at: ~U[2026-05-14 00:00:00Z]
    }
  end

  defp eligibility_evaluation(artifact, branch_id) do
    Enum.find(
      artifact["recommendation_eligibility"]["evaluations"],
      &(&1["branch_id"] == branch_id)
    )
  end

  defp branch(artifact, branch_id),
    do: Enum.find(artifact["branches"], &(&1["branch_id"] == branch_id))

  defp selected_import_row(artifact) do
    Enum.find(
      artifact["cadence_import_manifest"]["rows"],
      &(&1["import_action"] == "import_strategy_recommendation")
    )
  end

  defp assert_typed_schema_error(artifact) do
    assert {:error, %{"status" => "fail", "errors" => [_first | _rest]}} =
             Schema.validate_artifact(artifact)
  end

  defp repin_registry_id_copies(artifact, registry_id) do
    artifact
    |> put_in(
      ["recommendation_eligibility", "source_evidence_registry", "id"],
      registry_id
    )
    |> map_hard_feasibility_copies(&Map.put(&1, "source_evidence_registry_id", registry_id))
  end

  defp map_hard_feasibility_copies(artifact, hard_fun) do
    artifact
    |> update_in(["recommendation_eligibility"], fn eligibility ->
      eligibility
      |> update_in(
        ["evaluations"],
        &Enum.map(&1, fn row -> map_evaluation_hard(row, hard_fun) end)
      )
      |> update_existing_map("counterfactual", &map_evaluation_hard(&1, hard_fun))
    end)
    |> update_in(["recommendation"], &map_recommendation_hard(&1, hard_fun))
    |> update_in(["branch_comparison_report", "rows"], fn rows ->
      Enum.map(rows, &map_comparison_hard(&1, hard_fun))
    end)
    |> update_in(["operator_review_package", "rows"], fn rows ->
      Enum.map(rows, &map_review_hard(&1, hard_fun))
    end)
    |> update_in(["cadence_import_manifest", "rows"], fn rows ->
      Enum.map(rows, &map_manifest_hard(&1, hard_fun))
    end)
  end

  defp map_evaluation_hard(%{} = evaluation, hard_fun) do
    update_existing_map(evaluation, "hard_feasibility", hard_fun)
  end

  defp map_evaluation_hard(value, _hard_fun), do: value

  defp map_recommendation_hard(recommendation, hard_fun),
    do:
      update_existing_map(
        recommendation,
        "counterfactual",
        &map_evaluation_hard(&1, hard_fun)
      )

  defp map_comparison_hard(row, hard_fun),
    do:
      update_existing_map(
        row,
        "recommendation_hard_feasibility",
        hard_fun
      )

  defp map_review_hard(row, hard_fun) do
    row
    |> update_existing_map("source_tradeoff", &map_comparison_hard(&1, hard_fun))
    |> update_existing_map("source_branch_comparison", &map_comparison_hard(&1, hard_fun))
  end

  defp map_manifest_hard(row, hard_fun) do
    row
    |> update_existing_map("source_tradeoff", &map_comparison_hard(&1, hard_fun))
    |> update_existing_map("source_branch_comparison", &map_comparison_hard(&1, hard_fun))
    |> update_existing_map("source_recommendation", &map_recommendation_hard(&1, hard_fun))
    |> update_existing_map("source_review_row", &map_review_hard(&1, hard_fun))
  end

  defp update_existing_map(map, field, fun) do
    case Map.get(map, field) do
      %{} = value -> Map.put(map, field, fun.(value))
      _value -> map
    end
  end

  defp json_occurrences(value, needle) do
    value
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> :binary.matches(needle)
    |> length()
  end

  defp assert_json_roundtrip(artifact) do
    encoded = artifact |> :json.encode() |> IO.iodata_to_binary()
    decoded = :json.decode(encoded)

    assert decoded["recommendation"] ==
             artifact["recommendation"]
             |> :json.encode()
             |> IO.iodata_to_binary()
             |> :json.decode()

    assert decoded["recommendation_eligibility"] == artifact["recommendation_eligibility"]
    assert {:ok, _report} = Schema.validate_artifact(decoded)
  end

  defp digest(value) do
    value
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
