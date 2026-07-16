defmodule OrbitalDynamics.Schema.ResourceFilterRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "resource_filter_report.v1" => %{
        "schema_contract" => "resource_filter_report.v1",
        "artifact_family" => "resource_filter_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "input_candidate_count",
          "kept_candidate_count",
          "suppressed_candidate_count",
          "suppressed_candidates"
        ],
        "optional_fields" => [
          "policy",
          "model_limits",
          "assumptions",
          "input_resource_summary_count",
          "valid_resource_summary_count",
          "invalid_resource_summary_input_count",
          "invalid_resource_summary_input_ids",
          "invalid_resource_summary_inputs",
          "resource_source_quality_counts",
          "resource_trust_boundary_status_counts",
          "suppressed_resource_source_quality_counts",
          "suppressed_candidate_ids_by_resource_source_quality",
          "suppressed_resource_trust_boundary_status_counts",
          "suppressed_candidate_ids_by_resource_trust_boundary_status",
          "invalid_candidate_input_count",
          "invalid_candidate_input_ids",
          "duplicate_suppressed_candidate_row_count",
          "duplicate_suppressed_candidate_id_count"
        ],
        "nested_contracts" => []
      },
      "resource_filter_summary.v1" => %{
        "schema_contract" => "resource_filter_summary.v1",
        "artifact_family" => "resource_filter_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "input_candidate_count",
          "kept_candidate_count",
          "suppressed_candidate_count",
          "suppression_review_status",
          "suppressed_candidate_ids",
          "suppressed_reason_counts",
          "suppressed_candidate_ids_by_reason",
          "resource_blocking_dimension_counts",
          "suppressed_candidate_ids_by_resource_blocking_dimension",
          "suppressed_candidate_ids_by_spacecraft_id",
          "suppressed_candidate_ids_by_scenario_id",
          "suppressed_resource_source_quality_counts",
          "suppressed_candidate_ids_by_resource_source_quality",
          "suppressed_resource_trust_boundary_status_counts",
          "suppressed_candidate_ids_by_resource_trust_boundary_status",
          "invalid_candidate_input_count",
          "invalid_candidate_input_ids",
          "invalid_resource_summary_input_count",
          "invalid_resource_summary_input_ids",
          "duplicate_suppressed_candidate_id_count",
          "duplicate_suppressed_candidate_row_count",
          "review_rows",
          "invalid_resource_summary_inputs",
          "assumptions"
        ],
        "optional_fields" => ["model_limits"],
        "nested_contracts" => ["resource_filter_report.v1"]
      }
    }
  end
end
