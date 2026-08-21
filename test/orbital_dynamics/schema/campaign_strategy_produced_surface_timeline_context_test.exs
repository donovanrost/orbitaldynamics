Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceTimelineContextTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase, async: true

  alias OrbitalDynamics.Schema

  test "rejects CampaignStrategy branch comparison timeline-integrity event context drift", %{
    strategy: strategy
  } do
    fields = ~w(
      branch_timeline_integrity_activity_ids
      branch_timeline_integrity_timeline_ids
      branch_missing_dependency_activity_ids
      branch_missing_dependency_timeline_ids
      branch_dependency_cycle_activity_ids
      branch_dependency_cycle_timeline_ids
      branch_dependency_order_violation_activity_ids
      branch_dependency_order_violation_timeline_ids
      branch_exclusivity_violation_activity_ids
      branch_exclusivity_violation_timeline_ids
      branch_exclusivity_violation_groups
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["invented_timeline_integrity_value"]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison timeline-dependency-impact context drift", %{
    strategy: strategy
  } do
    fields = ~w(
      branch_timeline_dependency_impact_activity_ids
      branch_timeline_dependency_impact_timeline_ids
      branch_timeline_dependency_impact_scopes
      branch_impacted_dependency_activity_ids
      branch_impacted_dependency_timeline_ids
      branch_impacted_exclusive_with_activity_ids
      branch_impacted_exclusive_with_timeline_ids
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["invented_timeline_dependency_impact_value"]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison timeline-publication context drift", %{
    strategy: strategy
  } do
    fields = ~w(
      branch_timeline_publication_ids
      branch_timeline_publication_statuses
      branch_timeline_publication_source_artifact_ids
      branch_timeline_publication_source_artifact_types
      branch_timeline_publication_downstream_invalidation_statuses
      branch_timeline_publication_invalidated_downstream_product_ids
      branch_timeline_publication_downstream_invalidation_reasons
      branch_timeline_publication_dependency_impact_statuses
      branch_timeline_publication_impacted_source_activity_ids
      branch_timeline_publication_impacted_source_timeline_ids
      branch_timeline_publication_dependent_activity_ids
      branch_timeline_publication_dependent_timeline_ids
      branch_timeline_publication_changed_fields
      branch_timeline_publication_changed_timeline_ids
      branch_timeline_publication_review_timeline_ids
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["invented_timeline_publication_value"]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison timeline lifecycle-state context drift", %{
    strategy: strategy
  } do
    fields = ~w(
      branch_timeline_lifecycle_state_statuses
      branch_timeline_lifecycle_state_review_timeline_ids
      branch_timeline_lifecycle_state_review_activity_ids
      branch_timeline_lifecycle_state_invalid_activity_input_ids
      branch_timeline_lifecycle_state_required_operator_actions
      branch_timeline_lifecycle_state_import_actions
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["invented_timeline_lifecycle_state_value"]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison timeline activity lifecycle-state context drift",
       %{strategy: strategy} do
    fields = ~w(
      branch_timeline_activity_lifecycle_state_activity_ids
      branch_timeline_activity_lifecycle_state_timeline_ids
      branch_timeline_activity_lifecycle_state_transition_decisions
      branch_timeline_activity_lifecycle_state_required_operator_actions
      branch_timeline_activity_lifecycle_state_import_actions
      branch_timeline_activity_lifecycle_state_invalid_activity_input_reasons
      branch_timeline_activity_lifecycle_state_status_transition_categories
      branch_timeline_activity_lifecycle_state_approval_transition_categories
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["invented_timeline_activity_lifecycle_state_value"]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison timeline activity-precondition context drift",
       %{strategy: strategy} do
    fields = ~w(
      branch_timeline_activity_precondition_activity_ids
      branch_timeline_activity_precondition_timeline_ids
      branch_timeline_activity_precondition_statuses
      branch_timeline_activity_precondition_blocked_types
      branch_timeline_activity_precondition_review_types
      branch_timeline_activity_precondition_dependency_activity_ids
      branch_timeline_activity_precondition_dependency_timeline_ids
      branch_timeline_activity_precondition_exclusive_with_activity_ids
      branch_timeline_activity_precondition_exclusive_with_timeline_ids
      branch_timeline_activity_precondition_duplicate_dependency_activity_ids
      branch_timeline_activity_precondition_duplicate_dependency_timeline_ids
      branch_timeline_activity_precondition_duplicate_exclusivity_activity_ids
      branch_timeline_activity_precondition_duplicate_exclusivity_timeline_ids
      branch_timeline_activity_precondition_invalid_activity_input_reasons
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["invented_timeline_activity_precondition_value"]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison timeline-preservation context drift", %{
    strategy: strategy
  } do
    fields = ~w(
      branch_timeline_preservation_activity_ids
      branch_timeline_preservation_timeline_ids
      branch_timeline_preservation_statuses
      branch_timeline_preservation_protection_decisions
      branch_timeline_preservation_protection_categories
      branch_timeline_preservation_protection_reasons
      branch_timeline_preservation_preserve_activity_ids
      branch_timeline_preservation_preserve_timeline_ids
      branch_timeline_preservation_review_change_activity_ids
      branch_timeline_preservation_review_change_timeline_ids
      branch_timeline_preservation_invalid_activity_input_reasons
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["invented_timeline_preservation_value"]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison mission identity context drift", %{
    strategy: strategy
  } do
    fields = ~w(
      branch_scenario_ids
      branch_target_ids
      branch_collection_ids
      branch_product_ids
      branch_payload_ids
      branch_instrument_ids
      branch_objective_ids
      branch_objective_types
      branch_objective_statuses
      branch_source_objective_statuses
    )

    for field <- fields do
      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "rows", Access.at(1), field],
          ["invented_branch_mission_identity_value"]
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}")
             )
    end
  end

  test "rejects CampaignStrategy branch comparison source-window context drift", %{
    strategy: strategy
  } do
    fields = ~w(
      branch_source_window_ids
      branch_source_window_count
      branch_source_window_bounds
      branch_source_window_bound_count
      branch_untimed_source_window_ids
      branch_untimed_source_window_count
      branch_partially_timed_source_window_ids
      branch_partially_timed_source_window_count
      branch_source_window_timing_coverage_status
    )

    complete_context = %{
      "branch_source_window_ids" => ["invented_complete_window"],
      "branch_source_window_count" => 1,
      "branch_source_window_bounds" => [
        %{
          "source_window_id" => "invented_complete_window",
          "earliest_starts_at_s" => 1.0,
          "latest_ends_at_s" => 2.0
        }
      ],
      "branch_source_window_bound_count" => 1,
      "branch_untimed_source_window_ids" => [],
      "branch_untimed_source_window_count" => 0,
      "branch_partially_timed_source_window_ids" => [],
      "branch_partially_timed_source_window_count" => 0,
      "branch_source_window_timing_coverage_status" => "complete"
    }

    partial_context = %{
      "branch_source_window_ids" => [
        "invented_partially_timed_window",
        "invented_untimed_window_a",
        "invented_untimed_window_b"
      ],
      "branch_source_window_count" => 3,
      "branch_source_window_bounds" => [
        %{
          "source_window_id" => "invented_partially_timed_window",
          "earliest_starts_at_s" => 1.0
        }
      ],
      "branch_source_window_bound_count" => 1,
      "branch_untimed_source_window_ids" => [
        "invented_untimed_window_a",
        "invented_untimed_window_b"
      ],
      "branch_untimed_source_window_count" => 2,
      "branch_partially_timed_source_window_ids" => [
        "invented_partially_timed_window"
      ],
      "branch_partially_timed_source_window_count" => 1,
      "branch_source_window_timing_coverage_status" => "partial"
    }

    reports =
      for context <- [complete_context, partial_context] do
        row =
          strategy["branch_comparison_report"]["rows"]
          |> Enum.at(1)
          |> Map.drop(fields)
          |> Map.merge(context)

        invalid =
          put_in(strategy, ["branch_comparison_report", "rows", Access.at(1)], row)

        assert {:error, validation_report} = Schema.validate_artifact(invalid)
        validation_report
      end

    errors = Enum.flat_map(reports, & &1["errors"])

    for field <- fields do
      assert Enum.any?(
               errors,
               &(&1["path"] == "$.branch_comparison_report.rows[1].#{field}" and
                   &1["message"] == "must match the enclosing branch source-window context")
             )
    end
  end
end
