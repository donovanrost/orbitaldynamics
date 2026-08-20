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

  test "builder and validator reject ambiguous unknown and structurally unsupported inputs" do
    attrs = authority_attrs("authority-revision-17")
    context = AuthorityContext.new!(attrs)

    for {operation, input, expected_reason} <- [
          {:new, Map.put(attrs, :source_revision, "duplicate-revision"), "duplicate"},
          {:validate, Map.put(context, :source_revision, "duplicate-revision"), "duplicate"},
          {:new, Map.put(attrs, {:unsupported, :key}, "value"), "strings or atoms"},
          {:validate, Map.put(context, {:unsupported, :key}, "value"), "strings or atoms"},
          {:new, Map.put(attrs, <<255>>, "value"), "strings or atoms"},
          {:new, Map.put(attrs, "unknown_field", "value"), "is not allowed"},
          {:validate, Map.put(context, "unknown_field", "value"), "is not allowed"},
          {:new, Map.put(attrs, "authority_context_id", "caller-derived"), "is not allowed"},
          {:new, Map.put(attrs, "source_revision", self()), "non-empty UTF-8 string"},
          {:validate, Map.put(context, "source_revision", self()), "non-empty UTF-8 string"},
          {:new, Map.put(attrs, "source_revision", ["revision" | :unsupported]),
           "non-empty UTF-8 string"}
        ] do
      assert {:error, failure} = apply(AuthorityContext, operation, [input])
      assert failure["reason_code"] == "malformed_authority_context"

      assert Enum.any?(
               failure["validation_errors"],
               &String.contains?(&1["reason"], expected_reason)
             )

      if operation == :new do
        assert {:ok, nil, ^failure} = AuthorityContext.recompute_evaluation(failure)
        assert {:ok, _result} = AuthorityContext.validate_evaluation(nil, failure)
      end
    end

    assert {:error, caller_id_failure} = AuthorityContext.new(context)
    assert caller_id_failure["reason_code"] == "malformed_authority_context"
    assert caller_id_failure["provenance"]["operation"] == "constructor"

    assert {:ok, nil, ^caller_id_failure} =
             AuthorityContext.recompute_evaluation(caller_id_failure)

    assert {:ok, _result} = AuthorityContext.validate_evaluation(nil, caller_id_failure)

    assert {:error, _errors} =
             AuthorityContext.validate_evaluation(
               nil,
               Map.put(caller_id_failure, "reason", "tampered constructor failure")
             )

    {:ok, utc, 0} = DateTime.from_iso8601("2026-05-14T00:00:00Z")
    unsupported_zone = %{utc | time_zone: "Mars/Olympus", zone_abbr: "MST"}

    assert {:error, zone_failure} =
             AuthorityContext.new(Map.put(attrs, "effective_from", unsupported_zone))

    assert zone_failure["reason_code"] == "malformed_authority_context"

    assert Enum.any?(
             zone_failure["validation_errors"],
             &(&1["path"] == "$.effective_from" and
                 String.contains?(&1["reason"], "supported ISO 8601"))
           )

    assert {:error, struct_failure} =
             AuthorityContext.new(Map.put(attrs, "evaluation_time", ~N[2026-05-14 12:00:00]))

    assert struct_failure["reason_code"] == "malformed_authority_context"

    pid_input = Map.put(attrs, "source_revision", self())
    assert {:error, pid_evaluation} = AuthorityContext.evaluate("explicit", pid_input)
    assert {:ok, nil, ^pid_evaluation} = AuthorityContext.recompute_evaluation(pid_evaluation)
    assert {:ok, _result} = AuthorityContext.validate_evaluation(nil, pid_evaluation)
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

    for rootless <- [
          Map.drop(left, propagation_fields()),
          Map.drop(review, propagation_fields()),
          Map.drop(manifest, propagation_fields())
        ] do
      assert {:error, rootless_report} = Schema.validate_artifact(rootless)

      assert Enum.any?(
               rootless_report["errors"],
               &String.contains?(
                 to_string(&1["message"] || &1["reason"]),
                 "must match"
               )
             )
    end
  end

  test "valid authority evidence never overrides a preexisting blocked policy decision" do
    context = AuthorityContext.new!(authority_attrs("authority-revision-17"))

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [maneuver("burn_1", 300.0)]
      })

    artifact =
      strategy(
        prior_plan,
        strategy_request(
          authority_context_mode: "explicit",
          authority_context: context,
          approval_policy: %{
            "operator_review_risk_limit" => 10,
            "blocked_risk_types" => [],
            "action_rules" => [
              %{
                "id" => "maneuver_block",
                "event_types" => ["delayed_maneuver"],
                "classification" => "blocked_by_policy",
                "reason" => "maneuver timing change is substantively blocked"
              }
            ]
          },
          branches: [
            %{
              id: "baseline",
              events: [
                %{
                  type: "delayed_maneuver",
                  activity_id: "burn_1",
                  actual_starts_at_s: 360.0
                }
              ]
            },
            %{
              id: "later_maneuver",
              events: [
                %{
                  type: "delayed_maneuver",
                  activity_id: "burn_1",
                  actual_starts_at_s: 420.0
                }
              ]
            }
          ]
        )
      )

    decision = artifact |> branch("baseline") |> Map.fetch!("policy_decision")
    recommendation = artifact["recommendation"]
    review = artifact["operator_review_package"]
    manifest = artifact["cadence_import_manifest"]
    review_row = strategy_recommendation_review_row(review)
    selected_manifest_row = selected_strategy_manifest_row(manifest)

    assert decision["classification"] == "blocked_by_policy"
    assert decision["eligibility_status"] == "non_eligible"
    assert decision["authority_context_evaluation"]["eligibility_status"] == "eligible"
    assert decision["authority_context_evaluation"]["reason_code"] == "authority_context_valid"

    assert recommendation["approval_status"] == "blocked_by_policy"
    assert recommendation["eligibility_status"] == "non_eligible"
    assert artifact["eligibility_status"] == "non_eligible"
    assert review["eligibility_status"] == "non_eligible"
    assert review_row["eligibility_status"] == "non_eligible"
    assert manifest["eligibility_status"] == "non_eligible"
    assert selected_manifest_row["eligibility_status"] == "non_eligible"
    assert selected_manifest_row["import_status"] == "review_required_before_import"
    assert manifest["ready_count"] == 0

    for produced <- [decision, recommendation, review, manifest, artifact] do
      assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(produced)
    end

    assert {:error, _report} =
             review
             |> Map.put("eligibility_status", "eligible")
             |> Schema.validate_artifact()

    assert {:error, _report} =
             review
             |> update_in(["rows"], fn rows ->
               Enum.map(rows, fn
                 %{"review_type" => "strategy_recommendation"} = row ->
                   Map.put(row, "eligibility_status", "eligible")

                 row ->
                   row
               end)
             end)
             |> Schema.validate_artifact()

    assert {:error, _report} =
             manifest
             |> Map.put("eligibility_status", "eligible")
             |> Schema.validate_artifact()

    readiness_tamper =
      manifest
      |> update_in(["rows"], fn rows ->
        Enum.map(rows, fn
          %{"import_action" => "import_strategy_recommendation"} = row ->
            Map.put(row, "import_status", "ready_for_import")

          row ->
            row
        end)
      end)
      |> recompute_import_status_counts()

    assert readiness_tamper["ready_count"] == 1
    assert readiness_tamper["import_status_counts"]["ready_for_import"] == 1
    assert {:error, readiness_report} = Schema.validate_artifact(readiness_tamper)

    assert Enum.any?(
             readiness_report["errors"],
             &String.contains?(
               to_string(&1["message"] || &1["reason"]),
               "authority-eligible"
             )
           )
  end

  test "blocked alternatives retain non-eligibility without contaminating an eligible recommendation" do
    context = AuthorityContext.new!(authority_attrs("authority-revision-17"))

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [maneuver("burn_1", 300.0)]
      })

    artifact =
      strategy(
        prior_plan,
        strategy_request(
          authority_context_mode: "explicit",
          authority_context: context,
          approval_policy: %{
            "operator_review_risk_limit" => 10,
            "blocked_risk_types" => [],
            "action_rules" => [
              %{
                "id" => "maneuver_block",
                "event_types" => ["delayed_maneuver"],
                "classification" => "blocked_by_policy",
                "reason" => "maneuver timing change is substantively blocked"
              }
            ]
          },
          branches: [
            %{id: "baseline"},
            %{
              id: "blocked_maneuver",
              events: [
                %{
                  type: "delayed_maneuver",
                  activity_id: "burn_1",
                  actual_starts_at_s: 360.0
                }
              ]
            }
          ]
        )
      )

    eligible = branch(artifact, "baseline")["policy_decision"]
    blocked = branch(artifact, "blocked_maneuver")["policy_decision"]

    assert eligible["eligibility_status"] == "eligible"
    assert blocked["classification"] == "blocked_by_policy"
    assert blocked["eligibility_status"] == "non_eligible"
    assert blocked["authority_context_evaluation"]["eligibility_status"] == "eligible"
    assert artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert artifact["recommendation"]["eligibility_status"] == "eligible"

    assert artifact["cadence_import_manifest"]
           |> selected_strategy_manifest_row()
           |> Map.fetch!("import_status") == "ready_for_import"

    selected_row = selected_strategy_manifest_row(artifact["cadence_import_manifest"])

    blocked_row =
      Enum.find(artifact["cadence_import_manifest"]["rows"], fn row ->
        row["source_review_type"] == "strategy_branch_comparison" and
          row["branch_id"] == "blocked_maneuver"
      end)

    assert selected_row["eligibility_status"] == "eligible"
    assert blocked_row["approval_status"] == "blocked_by_policy"
    assert blocked_row["eligibility_status"] == "non_eligible"
    assert blocked_row["import_status"] == "not_applicable"

    mixed_tamper =
      update_in(artifact, ["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn
          %{"branch_id" => "blocked_maneuver"} = row ->
            Map.put(row, "eligibility_status", "eligible")

          row ->
            row
        end)
      end)

    assert {:error, _report} = Schema.validate_artifact(mixed_tamper)
    assert {:error, _report} = Schema.validate_artifact(mixed_tamper["cadence_import_manifest"])

    assert artifact["cadence_import_manifest"]["ready_count"] > 0
    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)
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

  test "semantic validators reject revision-evaluation substitution after exact ID recomputation" do
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

    retained_evaluation = first["authority_context_evaluation"]

    tampered =
      second
      |> deep_replace_key("authority_context_evaluation", retained_evaluation)
      |> recompute_enclosing_ids()

    strategy_id = get_in(tampered, ["strategy_metadata", "strategy_id"])
    manifest = tampered["cadence_import_manifest"]

    assert tampered["authority_context"] == second_context
    assert tampered["authority_context_evaluation"] == retained_evaluation
    assert tampered["operator_review_package"]["source_artifact_id"] == strategy_id
    assert manifest["source_artifact_id"] == strategy_id
    assert manifest["provenance"]["source_artifact_id"] == strategy_id
    assert manifest["manifest_id"] == "cadence_import_manifest:#{strategy_id}"

    assert {:error, report} = Schema.validate_artifact(tampered)

    assert Enum.any?(
             report["errors"],
             &String.contains?(
               to_string(&1["message"] || &1["reason"]),
               "recomputed from evaluation provenance"
             )
           )

    for produced <- [
          tampered["recommendation"],
          tampered["operator_review_package"],
          tampered["cadence_import_manifest"]
        ] do
      assert {:error, boundary_report} = Schema.validate_artifact(produced)

      assert Enum.any?(
               boundary_report["errors"],
               &String.contains?(
                 to_string(&1["message"] || &1["reason"]),
                 "recomputed from evaluation provenance"
               )
             )
    end
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
      assert {:ok, nil, ^evaluation} = AuthorityContext.recompute_evaluation(evaluation)
      assert {:ok, _result} = AuthorityContext.validate_evaluation(nil, evaluation)

      assert {:error, _errors} =
               AuthorityContext.validate_evaluation(
                 nil,
                 Map.put(evaluation, "reason", "tampered failure reason")
               )

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

      if reason_code == "missing_authority_context" do
        failed_readiness_tamper =
          manifest
          |> Map.put("eligibility_status", "eligible")
          |> update_in(["rows"], fn rows ->
            Enum.map(rows, fn
              %{"import_action" => "import_strategy_recommendation"} = row ->
                row
                |> Map.put("eligibility_status", "eligible")
                |> Map.put("import_status", "ready_for_import")

              row ->
                row
            end)
          end)
          |> recompute_import_status_counts()

        assert {:error, _report} = Schema.validate_artifact(failed_readiness_tamper)
      end

      assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "only absent mode and context retain byte-identical legacy output" do
    policy_args = {[], [], %{"id" => "baseline"}, %{"activities" => []}, %{}}
    {requirements, risks, branch_input, candidate_plan, policy} = policy_args

    legacy_decision = Policy.decide(requirements, risks, branch_input, candidate_plan, policy)

    assert legacy_decision ==
             Policy.decide(requirements, risks, branch_input, candidate_plan, policy, [])

    context = AuthorityContext.new!(authority_attrs("requires-explicit-mode"))
    legacy = strategy(test_plan(), strategy_request())
    context_without_mode = strategy(test_plan(), strategy_request(authority_context: context))

    assert legacy
           |> :erlang.term_to_binary([:deterministic])
           |> then(&:crypto.hash(:sha256, &1))
           |> Base.encode16(case: :lower) ==
             "a049ad75983465ae54101020a12aa6e6d18c4004cec00166f31ff4cb0c2a986f"

    refute Map.has_key?(legacy, "authority_context")
    refute Map.has_key?(legacy, "authority_context_evaluation")
    refute Map.has_key?(legacy["recommendation"], "authority_context")
    refute Map.has_key?(legacy["operator_review_package"], "authority_context")
    refute Map.has_key?(legacy["cadence_import_manifest"], "authority_context")

    refute legacy == context_without_mode
    assert context_without_mode["eligibility_status"] == "non_eligible"

    assert context_without_mode["authority_context_evaluation"]["reason_code"] ==
             "missing_authority_context_mode"

    for {request, reason_code} <- [
          {strategy_request(authority_context_mode: "explict", authority_context: context),
           "invalid_authority_context_mode"},
          {strategy_request(authority_context_mode: nil, authority_context: context),
           "invalid_authority_context_mode"},
          {strategy_request(authority_context_mode: "explicit"), "missing_authority_context"}
        ] do
      rejected = strategy(test_plan(), request)
      refute rejected == legacy
      assert rejected["eligibility_status"] == "non_eligible"
      assert rejected["authority_context_evaluation"]["reason_code"] == reason_code
      assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(rejected)
    end

    for opts <- [
          [
            authority_context_mode: "explicit",
            authority_context_mode: "explict",
            authority_context: context
          ],
          [
            authority_context_mode: "explicit",
            authority_context: context,
            authority_context: AuthorityContext.new!(authority_attrs("conflicting-context"))
          ]
        ] do
      {_status, _requirements, _matches, duplicate_decision} =
        Policy.decide(requirements, risks, branch_input, candidate_plan, policy, opts)

      assert duplicate_decision["authority_context_evaluation"]["reason_code"] ==
               "ambiguous_authority_context_options"

      duplicate_evaluation = duplicate_decision["authority_context_evaluation"]

      assert {:ok, nil, ^duplicate_evaluation} =
               AuthorityContext.recompute_evaluation(duplicate_evaluation)
    end

    conflicting_context = AuthorityContext.new!(authority_attrs("conflicting-context"))

    for request <- [
          strategy_request(authority_context_mode: "explicit", authority_context: context)
          |> Map.put("authority_context_mode", "explict"),
          strategy_request(authority_context_mode: "explicit", authority_context: context)
          |> Map.put("authority_context", conflicting_context)
        ] do
      rejected = strategy(test_plan(), request)

      assert rejected["authority_context_evaluation"]["reason_code"] ==
               "ambiguous_authority_context_options"

      assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(rejected)
    end

    equivalent_aliases =
      strategy_request(authority_context_mode: :explicit, authority_context: context)
      |> Map.put("authority_context_mode", "explicit")
      |> Map.put("authority_context", context)
      |> then(&strategy(test_plan(), &1))

    assert equivalent_aliases["authority_context_evaluation"]["reason_code"] ==
             "authority_context_valid"

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(equivalent_aliases)
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

  defp propagation_fields,
    do: ~w(eligibility_status authority_context authority_context_evaluation)

  defp recompute_import_status_counts(manifest) do
    rows = manifest["rows"]

    manifest
    |> Map.put("ready_count", Enum.count(rows, &(&1["import_status"] == "ready_for_import")))
    |> Map.put(
      "review_required_count",
      Enum.count(rows, &(&1["import_status"] == "review_required_before_import"))
    )
    |> Map.put(
      "blocked_count",
      Enum.count(rows, &(&1["import_status"] == "blocked_missing_cadence_import"))
    )
    |> Map.put("import_status_counts", frequency_map(rows, "import_status"))
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp deep_replace_key(value, key, replacement) when is_map(value) do
    Map.new(value, fn
      {^key, _value} ->
        {key, replacement}

      {nested_key, nested_value} ->
        {nested_key, deep_replace_key(nested_value, key, replacement)}
    end)
  end

  defp deep_replace_key(values, key, replacement) when is_list(values),
    do: Enum.map(values, &deep_replace_key(&1, key, replacement))

  defp deep_replace_key(value, _key, _replacement), do: value

  defp recompute_enclosing_ids(artifact) do
    old_id = get_in(artifact, ["strategy_metadata", "strategy_id"])
    new_id = exact_strategy_id(artifact)

    artifact
    |> deep_replace_value(old_id, new_id)
    |> put_in(["cadence_import_manifest", "manifest_id"], "cadence_import_manifest:#{new_id}")
  end

  defp deep_replace_value(value, expected, replacement) when value == expected, do: replacement

  defp deep_replace_value(value, expected, replacement) when is_map(value) do
    Map.new(value, fn {key, nested_value} ->
      {key, deep_replace_value(nested_value, expected, replacement)}
    end)
  end

  defp deep_replace_value(values, expected, replacement) when is_list(values),
    do: Enum.map(values, &deep_replace_value(&1, expected, replacement))

  defp deep_replace_value(value, _expected, _replacement), do: value

  defp exact_strategy_id(artifact) do
    stable_input =
      {
        artifact["source_plan_id"],
        strip_snapshot_model_limits(artifact["mission_state_snapshot"]),
        artifact["strategy_policy"],
        artifact["approval_policy"],
        strip_snapshot_model_limits(artifact["branches"])
      }
      |> canonical_hash_term()

    :crypto.hash(:sha256, :erlang.term_to_binary(stable_input))
    |> Base.encode16(case: :lower)
  end

  defp canonical_hash_term(%{} = map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), canonical_hash_term(value)} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  defp canonical_hash_term(values) when is_list(values),
    do: Enum.map(values, &canonical_hash_term/1)

  defp canonical_hash_term(value), do: value

  defp strip_snapshot_model_limits(%{"schema_contract" => "realized_state_snapshot.v1"} = value) do
    value
    |> Map.delete("model_limits")
    |> Map.new(fn {key, nested_value} -> {key, strip_snapshot_model_limits(nested_value)} end)
  end

  defp strip_snapshot_model_limits(value) when is_map(value),
    do:
      Map.new(value, fn {key, nested_value} ->
        {key, strip_snapshot_model_limits(nested_value)}
      end)

  defp strip_snapshot_model_limits(values) when is_list(values),
    do: Enum.map(values, &strip_snapshot_model_limits/1)

  defp strip_snapshot_model_limits(value), do: value
end
