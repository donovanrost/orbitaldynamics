Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyAuthorityContextTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{AuthorityContext, Policy, Schema}

  test "authority_context.v1 is deterministic, schema-valid, and revision-sensitive" do
    attrs = authority_attrs("authority-revision-17")
    left = AuthorityContext.new!(attrs)
    right = AuthorityContext.new!(attrs)
    revised = AuthorityContext.new!(authority_attrs("authority-revision-18"))

    assert left == right
    assert left["authority_context_id"] == AuthorityContext.identity(left)
    assert left["authority_context_id"] != revised["authority_context_id"]

    assert {:ok, ^left} = AuthorityContext.validate(left)

    assert {:ok, %{"schema_contract" => "authority_context.v1", "status" => "pass"}} =
             Schema.validate_artifact(left)

    assert {:ok, schema} = Schema.json_schema("authority_context.v1")
    assert schema["required"] == AuthorityContext.required_fields()
    assert schema["properties"]["evaluation_time"]["format"] == "date-time"

    assert {:ok, decision_schema} = Schema.json_schema("policy_decision.v1")

    assert decision_schema["properties"]["authority_context"]["required"] ==
             AuthorityContext.required_fields()

    assert "reason_code" in decision_schema["properties"]["authority_context_evaluation"][
             "required"
           ]

    tampered = Map.put(left, "source_revision", "authority-revision-18")

    assert {:error, failure} = AuthorityContext.validate(tampered)
    assert failure["reason_code"] == "malformed_authority_context"

    assert Enum.any?(
             failure["validation_errors"],
             &(&1["path"] == "$.authority_context_id")
           )

    assert {:error, extra_field_failure} =
             AuthorityContext.validate(Map.put(left, "ambient_authority", "forbidden"))

    assert extra_field_failure["reason_code"] == "malformed_authority_context"
  end

  test "valid explicit context propagates exactly through decision, recommendation, review, and import" do
    context = AuthorityContext.new!(authority_attrs("authority-revision-17"))
    request = strategy_request(authority_context_mode: :explicit, authority_context: context)

    left = strategy(test_plan(), request)
    right = strategy(test_plan(), request)

    assert left == right
    assert left["eligibility_status"] == "eligible"
    assert left["authority_context"] == context
    assert left["authority_context_evaluation"]["reason_code"] == "authority_context_valid"

    recommended_branch = branch(left, left["recommendation"]["recommended_branch_id"])
    decision = recommended_branch["policy_decision"]
    recommendation = left["recommendation"]
    review = left["operator_review_package"]
    manifest = left["cadence_import_manifest"]
    review_row = strategy_recommendation_review_row(review)
    selected_manifest_row = selected_strategy_manifest_row(manifest)

    assert decision["authority_context"] == context
    assert decision["eligibility_status"] == "eligible"
    assert Enum.all?(left["branches"], &(&1["policy_decision"]["authority_context"] == context))
    assert recommendation["authority_context"] == context
    assert recommendation["eligibility_status"] == "eligible"
    assert review["authority_context"] == context
    assert review_row["authority_context"] == context
    assert manifest["authority_context"] == context
    assert selected_manifest_row["authority_context"] == context

    evaluation = decision["authority_context_evaluation"]
    assert recommendation["authority_context_evaluation"] == evaluation
    assert review["authority_context_evaluation"] == evaluation
    assert review_row["authority_context_evaluation"] == evaluation
    assert manifest["authority_context_evaluation"] == evaluation
    assert selected_manifest_row["authority_context_evaluation"] == evaluation

    assert {:ok, %{"schema_contract" => "policy_decision.v1", "status" => "pass"}} =
             Schema.validate_artifact(decision)

    assert {:ok, %{"schema_contract" => "strategy_recommendation.v1", "status" => "pass"}} =
             Schema.validate_artifact(recommendation)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1", "status" => "pass"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1", "status" => "pass"}} =
             Schema.validate_artifact(manifest)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(left)

    replacement = AuthorityContext.new!(authority_attrs("authority-revision-18"))

    drifted =
      update_in(left, ["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn
          %{"import_action" => "import_strategy_recommendation"} = row ->
            Map.put(row, "authority_context", replacement)

          row ->
            row
        end)
      end)

    assert {:error, drift_report} = Schema.validate_artifact(drifted)

    assert Enum.any?(
             drift_report["errors"],
             &String.ends_with?(&1["path"], ".authority_context")
           )
  end

  test "authority revision changes context and strategy identity without nondeterminism" do
    first_context = AuthorityContext.new!(authority_attrs("authority-revision-17"))
    second_context = AuthorityContext.new!(authority_attrs("authority-revision-18"))

    first =
      strategy(
        test_plan(),
        strategy_request(authority_context_mode: "explicit", authority_context: first_context)
      )

    second =
      strategy(
        test_plan(),
        strategy_request(authority_context_mode: "explicit", authority_context: second_context)
      )

    assert first["authority_context"]["authority_context_id"] !=
             second["authority_context"]["authority_context_id"]

    assert get_in(first, ["strategy_metadata", "strategy_id"]) !=
             get_in(second, ["strategy_metadata", "strategy_id"])

    assert first ==
             strategy(
               test_plan(),
               strategy_request(
                 authority_context_mode: "explicit",
                 authority_context: first_context
               )
             )
  end

  test "explicit missing malformed not-yet-effective and stale contexts fail closed end to end" do
    cases = [
      {"missing_authority_context", nil},
      {"malformed_authority_context", false},
      {"malformed_authority_context", %{"schema_contract" => "authority_context.v1"}},
      {"authority_context_not_yet_effective",
       AuthorityContext.new!(
         authority_attrs("authority-revision-17",
           evaluation_time: "2026-05-13T23:59:59Z"
         )
       )},
      {"stale_authority_context",
       AuthorityContext.new!(
         authority_attrs("authority-revision-17",
           evaluation_time: "2026-05-15T00:00:00Z"
         )
       )},
      {"stale_authority_context",
       AuthorityContext.new!(
         authority_attrs("authority-revision-17",
           evaluation_time: "2026-05-15T00:00:01Z"
         )
       )}
    ]

    for {reason_code, context} <- cases do
      artifact =
        strategy(
          test_plan(),
          strategy_request(authority_context_mode: "explicit", authority_context: context)
        )

      assert Enum.all?(artifact["branches"], &(&1["approval_status"] == "blocked_by_policy"))
      assert artifact["eligibility_status"] == "non_eligible"
      refute Map.has_key?(artifact, "authority_context")

      evaluation = artifact["authority_context_evaluation"]
      assert evaluation["eligibility_status"] == "non_eligible"
      assert evaluation["outcome"] == "blocked_by_policy"
      assert evaluation["reason_code"] == reason_code
      assert evaluation["provenance"]["input_source"] == "caller_supplied"
      assert evaluation["provenance"]["validation"] == "deterministic_no_wall_clock"

      recommendation = artifact["recommendation"]
      review = artifact["operator_review_package"]
      manifest = artifact["cadence_import_manifest"]
      review_row = strategy_recommendation_review_row(review)
      selected_manifest_row = selected_strategy_manifest_row(manifest)

      assert recommendation["approval_status"] == "blocked_by_policy"
      assert recommendation["eligibility_status"] == "non_eligible"
      assert recommendation["authority_context_evaluation"] == evaluation
      assert review["authority_context_evaluation"] == evaluation
      assert review_row["authority_context_evaluation"] == evaluation
      assert manifest["authority_context_evaluation"] == evaluation
      assert selected_manifest_row["authority_context_evaluation"] == evaluation
      assert selected_manifest_row["import_status"] == "review_required_before_import"
      assert manifest["ready_count"] == 0

      assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "legacy policy and strategy paths remain byte and semantically stable when mode is absent" do
    policy_args = {[], [], %{"id" => "baseline"}, %{"activities" => []}, %{}}
    {requirements, risks, branch_input, candidate_plan, policy} = policy_args

    legacy_decision = Policy.decide(requirements, risks, branch_input, candidate_plan, policy)

    assert legacy_decision ==
             Policy.decide(requirements, risks, branch_input, candidate_plan, policy, [])

    context = AuthorityContext.new!(authority_attrs("ignored-without-explicit-mode"))
    legacy = strategy(test_plan(), strategy_request())
    context_without_mode = strategy(test_plan(), strategy_request(authority_context: context))

    assert legacy == context_without_mode
    refute Map.has_key?(legacy, "authority_context")
    refute Map.has_key?(legacy["recommendation"], "authority_context")
    refute Map.has_key?(legacy["operator_review_package"], "authority_context")
    refute Map.has_key?(legacy["cadence_import_manifest"], "authority_context")
  end

  defp authority_attrs(revision, overrides \\ []) do
    %{
      "schema_contract" => "authority_context.v1",
      "authority_source" => "mission-operations-authority-registry",
      "source_revision" => revision,
      "effective_from" => "2026-05-14T00:00:00Z",
      "valid_until" => "2026-05-15T00:00:00Z",
      "evaluation_time" => Keyword.get(overrides, :evaluation_time, "2026-05-14T12:00:00Z")
    }
  end

  defp strategy_request(overrides \\ []) do
    overrides
    |> Map.new()
    |> Map.merge(%{
      branches: [%{id: "baseline"}, %{id: "same_plan", events: []}],
      current_epoch_s: 0.0,
      mission_state: mission_state([])
    })
    |> Map.merge(Map.new(overrides))
  end

  defp test_plan do
    base_plan(%{
      "planning_horizon" => %{"duration_s" => 2_000.0},
      "candidate_activities" => [downlink("dl_1", 100.0, 160.0)]
    })
  end

  defp strategy_recommendation_review_row(review) do
    Enum.find(review["rows"], &(&1["review_type"] == "strategy_recommendation"))
  end

  defp selected_strategy_manifest_row(manifest) do
    Enum.find(manifest["rows"], &(&1["import_action"] == "import_strategy_recommendation"))
  end
end
