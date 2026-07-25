defmodule OrbitalDynamics.SchemaExportTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "declares schema export compatibility policy" do
    policy = Schema.compatibility_policy()

    assert policy["policy_version"] == 1
    assert "add_optional_fields" in policy["compatible_changes"]
    assert "remove_required_fields" in policy["breaking_changes"]

    bundle = Schema.json_schema_bundle()

    assert bundle["compatibility_policy"] == policy
    assert bundle["identity_policy"] == Schema.identity_policy()

    expected_generated_id_scopes = [
      "candidate_refresh.v1.refreshed_windows.generated_window_id",
      "contact_contention_report.v1.conflict_groups.generated_group_id",
      "contact_contention_resolution_report.v1.recommendations.generated_group_id",
      "relay_data_path_summary.v1.rows.generated_route_id"
    ]

    assert expected_generated_id_scopes --
             Enum.map(bundle["identity_policy"]["generated_id_scopes"], & &1["scope"]) == []

    assert bundle["schemas"]["campaign_plan.v1"]["x-orbital-dynamics"][
             "compatibility_policy_version"
           ] == policy["policy_version"]

    assert bundle["schemas"]["campaign_plan.v1"]["x-orbital-dynamics"][
             "identity_policy_version"
           ] == Schema.identity_policy()["policy_version"]
  end

  test "exports deterministic JSON Schema bundles" do
    bundle = Schema.json_schema_bundle()

    assert bundle["schema_contract"] == "orbital_dynamics.schema_bundle.v1"
    assert bundle["schema_count"] == map_size(Schema.contracts())
    assert Map.has_key?(bundle["schemas"], "candidate_refresh.v1")
    assert Map.has_key?(bundle["schemas"], "policy_decision.v1")
    assert Map.has_key?(bundle["schemas"], "strategy_recommendation.v1")
    assert Map.has_key?(bundle["schemas"], "maneuver_recommendation.v1")
    assert Map.has_key?(bundle["schemas"], "maneuver_review_report.v1")
    assert Map.has_key?(bundle["schemas"], "execution_report.v1")
    assert Map.has_key?(bundle["schemas"], "monte_carlo_reproducibility_report.v1")
    assert Map.has_key?(bundle["schemas"], "objective_tradeoff_report.v1")
    assert Map.has_key?(bundle["schemas"], "objective_satisfaction_report.v1")
    assert Map.has_key?(bundle["schemas"], "ranking_comparison_report.v1")
    assert Map.has_key?(bundle["schemas"], "pareto_frontier_report.v1")
    assert Map.has_key?(bundle["schemas"], "operational_timeline_report.v1")
    assert Map.has_key?(bundle["schemas"], "candidate_rejection_report.v1")
    assert Map.has_key?(bundle["schemas"], "provider_counteroffer_report.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_diff_report.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_diff_summary.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_integrity_report.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_dependency_impact_summary.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_activity_state.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_activity_precondition_summary.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_activity_status_state.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_activity_approval_state.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_activity_lifecycle_state.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_lifecycle_state_summary.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_transition_application_report.v1")
    assert Map.has_key?(bundle["schemas"], "timeline_transition_application_summary.v1")
    assert Map.has_key?(bundle["schemas"], "command_window_report.v1")
    assert Map.has_key?(bundle["schemas"], "branch_comparison_report.v1")
    assert Map.has_key?(bundle["schemas"], "optimizer_contract.v1")
    assert Map.has_key?(bundle["schemas"], "link_capacity_report.v1")
    assert Map.has_key?(bundle["schemas"], "link_capacity_summary.v1")
    assert Map.has_key?(bundle["schemas"], "relay_data_path_summary.v1")
    assert Map.has_key?(bundle["schemas"], "contact_filter_report.v1")
    assert Map.has_key?(bundle["schemas"], "contact_contention_report.v1")
    assert Map.has_key?(bundle["schemas"], "contact_contention_resolution_report.v1")
    assert Map.has_key?(bundle["schemas"], "contact_contention_resolution_summary.v1")
    assert Map.has_key?(bundle["schemas"], "station_calendar_report.v1")
    assert Map.has_key?(bundle["schemas"], "station_calendar_precedence_summary.v1")

    assert get_in(bundle, [
             "schemas",
             "station_calendar_precedence_summary.v1",
             "properties",
             "source"
           ]) == %{"type" => "string"}

    assert Map.has_key?(bundle["schemas"], "resource_filter_report.v1")
    assert Map.has_key?(bundle["schemas"], "resource_filter_summary.v1")
    assert Map.has_key?(bundle["schemas"], "operational_import_eligibility_summary.v1")
    assert Map.has_key?(bundle["schemas"], "operational_readiness_gate_summary.v1")
    assert Map.has_key?(bundle["schemas"], "operational_execution_boundary_summary.v1")
    assert Map.has_key?(bundle["schemas"], "operational_quality_gate_summary.v1")

    assert Map.has_key?(
             bundle["schemas"],
             "operational_quality_gate_unavailable_resource_summary.v1"
           )

    assert Map.has_key?(
             bundle["schemas"],
             "operational_quality_gate_operator_training_summary.v1"
           )

    assert Map.has_key?(
             bundle["schemas"],
             "operational_quality_gate_schema_validation_summary.v1"
           )

    assert Map.has_key?(
             bundle["schemas"],
             "operational_quality_gate_import_readiness_summary.v1"
           )

    assert Map.has_key?(bundle["schemas"], "schema_validation_report.v1")
    assert Map.has_key?(bundle["schemas"], "validation_reference_fixture_report.v1")
    assert Map.has_key?(bundle["schemas"], "result_artifact.v1")
    assert Map.has_key?(bundle["schemas"], "validation_tolerance_policy.v1")
    assert Map.has_key?(bundle["schemas"], "backend_acceptance_policy.v1")
    assert Map.has_key?(bundle["schemas"], "model_acceptance_report.v1")
    assert Map.has_key?(bundle["schemas"], "validation_safety_case_summary.v1")
  end

  test "checked-in JSON Schema exports match the executable registry" do
    bundle = Schema.json_schema_bundle()

    Enum.each(Schema.contracts(), fn {contract_name, _contract} ->
      path = "schemas/#{contract_name}.schema.json"
      assert File.exists?(path), "missing checked-in schema export #{path}"

      expected_schema = Map.fetch!(bundle["schemas"], contract_name)
      assert read_json!(path) == expected_schema
    end)

    assert read_json!("schemas/orbital_dynamics.schema_bundle.v1.json") == bundle
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
