defmodule OrbitalDynamics.Schema.FixtureVisibilityContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "checked-in branch comparison and Cadence import row fields are schema-visible" do
    assert_fixture_row_fields_are_schema_visible(
      "branch_comparison_report.v1",
      "study_results/branch_comparison_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "operator_review_package.v1",
      "study_results/operator_review_package_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "operator_review_package.v1",
      "study_results/operator_review_package_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "operator_review_package.v1",
      "study_results/operator_review_resource_pressure_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "operator_review_package.v1",
      "study_results/operator_review_resource_projection_battery_handoff_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "operator_review_package.v1",
      "study_results/operator_review_resource_projection_battery_handoff_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "operational_timeline_report.v1",
      "study_results/operational_timeline_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "operational_timeline_report.v1",
      "study_results/operational_timeline_report_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "command_window_report.v1",
      "study_results/command_window_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "contact_allocation_report.v1",
      "study_results/contact_allocation_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "contact_allocation_report.v1",
      "study_results/contact_allocation_capacity_pack_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "link_capacity_report.v1",
      "study_results/link_capacity_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "link_capacity_report.v1",
      "study_results/link_capacity_report_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "resource_filter_report.v1",
      "study_results/resource_filter_report_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "resource_filter_report.v1",
      "study_results/resource_filter_report_v1.json",
      ["properties", "suppressed_candidates", "items", "properties"],
      fn artifact -> Map.get(artifact, "suppressed_candidates", []) end
    )

    assert_fixture_fields_are_schema_visible(
      "contact_filter_report.v1",
      "study_results/contact_filter_report_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "contact_filter_report.v1",
      "study_results/contact_filter_report_v1.json",
      ["properties", "suppressed_candidates", "items", "properties"],
      fn artifact -> Map.get(artifact, "suppressed_candidates", []) end
    )

    assert_fixture_fields_are_schema_visible(
      "contact_contention_report.v1",
      "study_results/contact_contention_report_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "contact_contention_report.v1",
      "study_results/contact_contention_report_v1.json",
      ["properties", "conflict_groups", "items", "properties"],
      fn artifact -> Map.get(artifact, "conflict_groups", []) end
    )

    assert_fixture_fields_are_schema_visible(
      "contact_contention_resolution_report.v1",
      "study_results/contact_contention_resolution_report_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "contact_contention_resolution_report.v1",
      "study_results/contact_contention_resolution_report_v1.json",
      ["properties", "recommendations", "items", "properties"],
      fn artifact -> Map.get(artifact, "recommendations", []) end
    )

    assert_fixture_fields_are_schema_visible(
      "candidate_diff_report.v1",
      "study_results/candidate_diff_report_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "resource_projection_report.v1",
      "study_results/resource_projection_report_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "resource_projection_report.v1",
      "study_results/resource_projection_battery_handoff_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "station_calendar_report.v1",
      "study_results/station_calendar_report_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "proposed_contact.v1",
      "study_results/proposed_contact_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "planned_activity.v1",
      "study_results/planned_activity_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "realized_activity.v1",
      "study_results/realized_activity_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "plan_delta.v1",
      "study_results/plan_delta_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "timeline_diff_report.v1",
      "study_results/timeline_diff_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "timeline_diff_report.v1",
      "study_results/timeline_diff_report_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "timeline_diff_summary.v1",
      "study_results/timeline_diff_summary_v1.json",
      ["properties", "review_rows", "items", "properties"],
      fn artifact -> Map.get(artifact, "review_rows", []) end
    )

    assert_fixture_row_fields_are_schema_visible(
      "timeline_integrity_report.v1",
      "study_results/timeline_integrity_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "timeline_transition_application_report.v1",
      "study_results/timeline_transition_application_report_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "objective_satisfaction_report.v1",
      "study_results/objective_satisfaction_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "maneuver_review_report.v1",
      "study_results/maneuver_review_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "maneuver_review_report.v1",
      "study_results/maneuver_review_report_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "approval_requirement.v1",
      "study_results/approval_requirement_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "strategy_recommendation.v1",
      "study_results/strategy_recommendation_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "strategy_recommendation.v1",
      "study_results/strategy_recommendation_v1.json",
      ["properties", "tradeoffs", "items", "properties"],
      fn artifact -> Map.get(artifact, "tradeoffs", []) end
    )

    assert_fixture_row_fields_are_schema_visible(
      "strategy_recommendation.v1",
      "study_results/strategy_recommendation_v1.json",
      ["properties", "explanation", "items", "properties"],
      fn artifact -> Map.get(artifact, "explanation", []) end
    )

    assert_fixture_row_fields_are_schema_visible(
      "strategy_recommendation.v1",
      "study_results/strategy_recommendation_v1.json",
      ["properties", "risks_remaining", "items", "properties"],
      fn artifact -> Map.get(artifact, "risks_remaining", []) end
    )

    assert_fixture_row_fields_are_schema_visible(
      "strategy_recommendation.v1",
      "study_results/strategy_recommendation_v1.json",
      ["properties", "requires_approval", "items", "properties"],
      fn artifact -> Map.get(artifact, "requires_approval", []) end
    )

    assert_fixture_fields_are_schema_visible(
      "strategy_branch.v1",
      "study_results/strategy_branch_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "strategy_branch.v1",
      "study_results/strategy_branch_v1.json",
      ["properties", "events", "items", "properties"],
      fn artifact -> Map.get(artifact, "events", []) end
    )

    assert_fixture_row_fields_are_schema_visible(
      "strategy_branch.v1",
      "study_results/strategy_branch_v1.json",
      ["properties", "risk_indicators", "items", "properties"],
      fn artifact -> Map.get(artifact, "risk_indicators", []) end
    )

    assert_fixture_row_fields_are_schema_visible(
      "strategy_branch.v1",
      "study_results/strategy_branch_v1.json",
      ["properties", "tradeoffs", "items", "properties"],
      fn artifact -> Map.get(artifact, "tradeoffs", []) end
    )

    assert_fixture_row_fields_are_schema_visible(
      "campaign_strategy.v3",
      "study_results/leo_constellation_campaign_strategy_v3.json",
      ["properties", "branches", "items", "properties"],
      fn artifact -> Map.get(artifact, "branches", []) end
    )

    assert_fixture_row_fields_are_schema_visible(
      "timeline_feedback_report.v1",
      "study_results/timeline_feedback_report_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "timeline_feedback_report.v1",
      "study_results/timeline_feedback_report_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "timeline_lifecycle_state_summary.v1",
      "study_results/timeline_lifecycle_state_summary_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "timeline_lifecycle_state_summary.v1",
      "study_results/timeline_lifecycle_state_summary_v1.json",
      ["properties", "review_rows", "items", "properties"],
      fn artifact -> Map.get(artifact, "review_rows", []) end
    )

    assert_fixture_fields_are_schema_visible(
      "candidate_activity.v1",
      "study_results/candidate_activity_v1.json",
      ["properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "candidate_refresh.v1",
      "study_results/candidate_refresh_resource_provenance_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "cadence_import_manifest.v1",
      "study_results/cadence_import_manifest_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_fields_are_schema_visible(
      "cadence_import_manifest.v1",
      "study_results/cadence_import_manifest_v1.json",
      ["properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "cadence_import_manifest.v1",
      "study_results/cadence_import_manifest_v1.json",
      ["properties", "rows", "items", "properties", "source_review_row", "properties"],
      fn artifact ->
        artifact
        |> Map.get("rows", [])
        |> Enum.map(&Map.get(&1, "source_review_row"))
      end
    )

    assert_fixture_row_fields_are_schema_visible(
      "cadence_import_manifest.v1",
      "study_results/cadence_import_resource_projection_battery_handoff_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "cadence_import_manifest.v1",
      "study_results/cadence_import_resource_projection_battery_handoff_v1.json",
      ["properties", "rows", "items", "properties", "source_review_row", "properties"],
      fn artifact ->
        artifact
        |> Map.get("rows", [])
        |> Enum.map(&Map.get(&1, "source_review_row"))
      end
    )

    assert_fixture_row_fields_are_schema_visible(
      "cadence_import_manifest.v1",
      "study_results/cadence_import_resource_pressure_v1.json",
      ["properties", "rows", "items", "properties"]
    )

    assert_fixture_row_fields_are_schema_visible(
      "cadence_import_manifest.v1",
      "study_results/cadence_import_resource_pressure_v1.json",
      ["properties", "rows", "items", "properties", "source_review_row", "properties"],
      fn artifact ->
        artifact
        |> Map.get("rows", [])
        |> Enum.map(&Map.get(&1, "source_review_row"))
      end
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp assert_fixture_row_fields_are_schema_visible(
         contract,
         fixture_path,
         schema_properties_path,
         rows_fun \\ fn artifact -> Map.get(artifact, "rows", []) end
       ) do
    fixture = read_json!(fixture_path)
    assert {:ok, schema} = Schema.json_schema(contract)

    schema_properties = get_in(schema, schema_properties_path) || %{}

    missing_fields =
      fixture
      |> rows_fun.()
      |> Enum.filter(&is_map/1)
      |> Enum.flat_map(&Map.keys/1)
      |> Enum.uniq()
      |> Enum.reject(&Map.has_key?(schema_properties, &1))
      |> Enum.sort()

    assert missing_fields == []
  end

  defp assert_fixture_fields_are_schema_visible(contract, fixture_path, schema_properties_path) do
    fixture = read_json!(fixture_path)
    assert {:ok, schema} = Schema.json_schema(contract)

    schema_properties = get_in(schema, schema_properties_path) || %{}

    missing_fields =
      fixture
      |> Map.keys()
      |> Enum.reject(&Map.has_key?(schema_properties, &1))
      |> Enum.sort()

    assert missing_fields == []
  end
end
