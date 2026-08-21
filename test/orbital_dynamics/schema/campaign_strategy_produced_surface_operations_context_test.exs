Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceOperationsContextTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  test "rejects CampaignStrategy branch comparison operational-event context drift", %{
    strategy: strategy
  } do
    fields = ~w(
      branch_feedback_sources
      branch_feedback_scopes
      branch_contact_results
      branch_contact_allocation_statuses
      branch_contact_allocation_effective_statuses
      branch_contact_allocation_reasons
      branch_contact_allocation_review_statuses
      branch_contact_allocation_approval_statuses
      branch_contact_allocation_policy_classifications
      branch_realized_statuses
      branch_transition_types
      branch_transition_categories
      branch_transition_reasons
      branch_requires_operator_review
      branch_requires_operator_review_count
      branch_source_activity_ids
    )

    transition_fields = ~w(
      branch_transition_types
      branch_transition_categories
      branch_transition_reasons
    )

    for field <- fields do
      current = get_in(strategy, ["branch_comparison_report", "rows", Access.at(1), field])

      replacement =
        cond do
          field == "branch_requires_operator_review" ->
            if is_boolean(current), do: not current, else: true

          field == "branch_requires_operator_review_count" ->
            if is_integer(current), do: current + 1, else: 1

          true ->
            ["invented_operational_event_value"]
        end

      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          replacement
        )

      expected_message =
        cond do
          field in transition_fields ->
            "must match the enclosing branch transition values"

          field == "branch_requires_operator_review" ->
            "must match the enclosing branch operator-review requirement"

          field == "branch_requires_operator_review_count" ->
            "must match the enclosing branch operator-review event count"

          true ->
            "must match the enclosing branch operational-event values"
        end

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}" and
                   &1["message"] == expected_message)
             )
    end
  end

  test "rejects CampaignStrategy branch comparison execution-uncertainty context drift", %{
    strategy: strategy
  } do
    cases = [
      {"branch_missed_downlink_activity_ids",
       "must match the enclosing branch missed-downlink activity IDs"},
      {"branch_maneuver_execution_uncertainty_activity_ids",
       "must match the enclosing branch execution-uncertainty activity_id values"},
      {"branch_maneuver_execution_uncertainty_timeline_ids",
       "must match the enclosing branch execution-uncertainty timeline_id values"},
      {"branch_maneuver_execution_uncertainty_maneuver_ids",
       "must match the enclosing branch execution-uncertainty maneuver_id values"},
      {"branch_maneuver_execution_uncertainty_statuses",
       "must match the enclosing branch execution-uncertainty execution_uncertainty_status values"},
      {"branch_maneuver_execution_uncertainty_sources",
       "must match the enclosing branch execution-uncertainty execution_uncertainty_source values"},
      {"branch_maneuver_execution_uncertainty_max_timing_3sigma_s",
       "must match the enclosing branch execution-uncertainty timing_3sigma_s maximum"},
      {"branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s",
       "must match the enclosing branch execution-uncertainty delta_v_3sigma_magnitude_km_s maximum"}
    ]

    for {field, expected_message} <- cases do
      replacement =
        if String.contains?(field, "_max_") do
          12_345.0
        else
          ["invented_execution_uncertainty_value"]
        end

      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          replacement
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}" and
                   &1["message"] == expected_message)
             )
    end
  end

  test "rejects CampaignStrategy branch comparison operational-readiness context drift", %{
    strategy: strategy
  } do
    fields = ~w(
      branch_operational_readiness_levels
      branch_operational_readiness_import_classifications
      branch_operational_readiness_statuses
      branch_operational_readiness_gate_ids
      branch_operational_readiness_gate_statuses
      branch_operational_readiness_gate_classifications
      branch_operational_readiness_review_required_gate_ids
      branch_operational_readiness_analysis_only_gate_ids
      branch_operational_readiness_blocked_gate_ids
      branch_operational_readiness_non_passed_gate_ids
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["invented_operational_readiness_value"]
        )

      expected_message =
        if field == "branch_operational_readiness_gate_ids" do
          "must match the enclosing branch operational-readiness gate IDs"
        else
          "must match the enclosing branch operational-readiness values"
        end

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}" and
                   &1["message"] == expected_message)
             )
    end
  end

  test "prefers nonempty CampaignStrategy operational-readiness risk values over event values", %{
    strategy: strategy
  } do
    invalid =
      strategy
      |> update_in(["branches", Access.at(1), "events"], fn events ->
        [
          %{
            "type" => "operational_readiness_pressure",
            "readiness_level" => "event_readiness_value"
          }
          | events
        ]
      end)
      |> update_in(["branches", Access.at(1), "risk_indicators"], fn risks ->
        [
          %{
            "type" => "operational_readiness_pressure",
            "readiness_level" => "risk_override_readiness_value"
          }
          | risks
        ]
      end)
      |> put_in(
        ["branch_comparison_report", "rows", Access.at(1), "branch_operational_readiness_levels"],
        ["event_readiness_value"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[1].branch_operational_readiness_levels" and
                 &1["message"] ==
                   "must match the enclosing branch operational-readiness values")
           )
  end

  test "rejects CampaignStrategy branch comparison score evidence drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    score_drift =
      strategy
      |> put_in(
        ["branch_comparison_report", "rows", Access.at(1), "score"],
        row["score"] + 1
      )
      |> put_in(
        ["branch_comparison_report", "rows", Access.at(1), "score_delta_from_recommended"],
        row["score_delta_from_recommended"] + 1
      )

    invalid_cases = [
      {"score", score_drift},
      {"raw_score",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "raw_score"],
         row["raw_score"] + 1
       )},
      {"branch_probability",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "branch_probability"],
         0.5
       )},
      {"expected_score",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "expected_score"],
         row["expected_score"] + 1
       )},
      {"score_terms",
       update_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "score_terms"],
         &Map.update!(&1, "raw_score", fn value -> value + 1 end)
       )}
    ]

    for {field, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison operational evidence drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    invalid_cases = [
      {"approval_status",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "approval_status"],
         "auto_approvable"
       )},
      {"risk_count",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "risk_count"],
         row["risk_count"] + 1
       )},
      {"approval_requirement_count",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "approval_requirement_count"],
         row["approval_requirement_count"] + 1
       )},
      {"candidate_activity_count",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "candidate_activity_count"],
         row["candidate_activity_count"] + 1
       )},
      {"repair_delta_count",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "repair_delta_count"],
         row["repair_delta_count"] + 1
       )}
    ]

    for {field, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison risk classification drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    fields = [
      "risk_types",
      "high_risk_types",
      "feedback_risk_types",
      "resource_risk_types"
    ]

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["schema_valid_drift" | tl(row[field])]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison feedback evidence drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    fields = [
      "feedback_score_adjustment",
      "contact_success_factor",
      "contact_success_factor_source",
      "contact_success_factor_activity_source",
      "observation_success_factor",
      "observation_success_factor_source",
      "observation_success_factor_activity_source",
      "station_throughput_factor",
      "station_throughput_factor_source",
      "station_throughput_factor_activity_source"
    ]

    for field <- fields do
      value = row[field]
      drift = if is_number(value), do: value + 0.01, else: value <> ".schema_valid_drift"

      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison feedback-detail drift", %{
    strategy: strategy
  } do
    feedback_details = %{
      "image_quality_score" => 0.37,
      "image_quality_score_source" => "operator_review.image_quality_score",
      "image_quality_statuses" => ["cloud_limited"],
      "image_quality_sources" => ["provider_imagery_quality"],
      "cloud_cover_fraction" => 0.42,
      "cloud_cover_fraction_source" => "operator_review.cloud_cover_fraction",
      "blur_score" => 0.21,
      "blur_score_source" => "operator_review.blur_score",
      "maneuver_success_factor" => 0.83,
      "maneuver_success_factor_source" => "operator_review.maneuver_success_factor",
      "command_success_factor" => 0.76,
      "command_success_factor_source" => "operator_review.command_success_factor",
      "feedback_weight_sources" => ["operator_sample_size"]
    }

    artifact =
      strategy
      |> update_in(["branches", Access.at(1), "feedback_adjustments"], fn adjustments ->
        Map.merge(adjustments, feedback_details)
      end)
      |> update_in(["branch_comparison_report", "rows", Access.at(1)], fn row ->
        Map.merge(row, feedback_details)
      end)
      |> then(&Map.put(&1, "operator_review_package", OperatorReview.from_strategy_artifact(&1)))
      |> then(&Map.put(&1, "cadence_import_manifest", CadenceImport.from_strategy_artifact(&1)))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(artifact)

    for {field, value} <- feedback_details do
      drift =
        cond do
          is_number(value) -> value + 0.01
          is_binary(value) -> value <> ".schema_valid_drift"
          is_list(value) -> ["schema_valid_drift"]
        end

      invalid =
        put_in(
          artifact,
          ["branch_comparison_report", "rows", Access.at(1), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}" and
                   &1["message"] ==
                     "must match the enclosing branch feedback_adjustments.#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison priority commitment drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    put_row = fn artifact, field, value ->
      put_in(
        artifact,
        ["branch_comparison_report", "rows", Access.at(1), field],
        value
      )
    end

    coherent_required_drift =
      strategy
      |> put_row.(
        "priority_commitment_required_target_ids",
        row["priority_commitment_required_target_ids"] ++ ["target_schema_valid_drift"]
      )
      |> put_row.(
        "priority_commitment_required_target_count",
        row["priority_commitment_required_target_count"] + 1
      )

    coherent_satisfied_drift =
      strategy
      |> put_row.(
        "priority_commitment_satisfied_target_ids",
        row["priority_commitment_satisfied_target_ids"] ++ ["target_schema_valid_drift"]
      )
      |> put_row.(
        "priority_commitment_satisfied_target_count",
        row["priority_commitment_satisfied_target_count"] + 1
      )

    coherent_missed_drift =
      strategy
      |> put_row.("priority_commitment_missed_target_ids", ["target_schema_valid_drift"])
      |> put_row.("priority_commitment_missed_target_count", 1)

    invalid_cases = [
      {[
         "priority_commitment_required_target_count",
         "priority_commitment_required_target_ids"
       ], coherent_required_drift},
      {[
         "priority_commitment_satisfied_target_count",
         "priority_commitment_satisfied_target_ids"
       ], coherent_satisfied_drift},
      {[
         "priority_commitment_missed_target_count",
         "priority_commitment_missed_target_ids"
       ], coherent_missed_drift},
      {["priority_commitment_required_target_ids"],
       put_row.(
         strategy,
         "priority_commitment_required_target_ids",
         ["target_schema_valid_drift"]
       )},
      {["priority_commitment_satisfied_target_ids"],
       put_row.(
         strategy,
         "priority_commitment_satisfied_target_ids",
         ["target_schema_valid_drift"]
       )},
      {["priority_commitment_required_observation_count"],
       put_row.(
         strategy,
         "priority_commitment_required_observation_count",
         row["priority_commitment_required_observation_count"] + 1
       )},
      {["priority_commitment_planned_observation_count"],
       put_row.(
         strategy,
         "priority_commitment_planned_observation_count",
         row["priority_commitment_planned_observation_count"] + 1
       )},
      {["priority_commitment_missing_observation_count"],
       put_row.(
         strategy,
         "priority_commitment_missing_observation_count",
         row["priority_commitment_missing_observation_count"] + 1
       )},
      {["priority_commitment_ratio"], put_row.(strategy, "priority_commitment_ratio", 0.99)}
    ]

    for {expected_fields, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      for field <- expected_fields do
        assert Enum.any?(
                 validation_report["errors"],
                 &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
               )
      end
    end
  end

  test "rejects CampaignStrategy branch comparison downlink completion drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    fields = [
      "downlink_completion_required_contacts",
      "downlink_completion_planned_contacts",
      "downlink_completion_planned_downlink_mb",
      "downlink_completion_ratio"
    ]

    for field <- fields do
      value = row[field]
      drift = if field == "downlink_completion_ratio", do: 0.1, else: value + 1

      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison coverage and revisit drift", %{
    strategy: strategy
  } do
    row = Enum.at(strategy["branch_comparison_report"]["rows"], 1)

    for field <- ["coverage_observed_target_count", "revisit_count"] do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          row[field] + 1
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end
end
