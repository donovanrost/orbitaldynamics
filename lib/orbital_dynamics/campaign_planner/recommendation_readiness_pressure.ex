defmodule OrbitalDynamics.CampaignPlanner.RecommendationReadinessPressure do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def rows(%PlanBranch{} = branch) do
    operational_readiness_rows(branch) ++ quality_gate_rows(branch)
  end

  def rows(_branch), do: []

  defp operational_readiness_rows(%PlanBranch{id: branch_id, events: events}) do
    events
    |> Enum.filter(&(&1["type"] == "operational_readiness_pressure"))
    |> Enum.map(fn event ->
      event
      |> Map.take([
        "report_id",
        "source_artifact_type",
        "source_artifact_id",
        "readiness_level",
        "import_classification",
        "operational_readiness_status",
        "gate_count",
        "passed_gate_count",
        "review_gate_count",
        "analysis_gate_count",
        "blocked_gate_count",
        "readiness_gate_id",
        "readiness_gate_status",
        "readiness_gate_classification",
        "readiness_gate_reason",
        "analysis_mode",
        "analysis_mode_source",
        "required_operator_action",
        "feedback_source",
        "feedback_scope",
        "feedback_key",
        "trust_boundary",
        "operator_training_requirement_count",
        "operator_training_requirement_counts",
        "required_operator_roles",
        "required_training_ids",
        "required_certification_ids",
        "required_qualification_ids"
      ])
      |> Map.put("type", "operational_readiness_pressure")
      |> Map.put("recommended_branch_id", branch_id)
      |> Map.put(
        "reason",
        event["readiness_gate_reason"] ||
          "recommended branch includes operational readiness pressure"
      )
      |> compact_map()
    end)
  end

  defp quality_gate_rows(%PlanBranch{id: branch_id, events: events}) do
    events
    |> Enum.filter(&(&1["type"] == "quality_gate_pressure"))
    |> Enum.map(fn event ->
      event
      |> Map.take([
        "report_id",
        "source_artifact_type",
        "source_artifact_id",
        "source_readiness_report_id",
        "readiness_level",
        "import_classification",
        "quality_gate_status",
        "gate_count",
        "passed_gate_count",
        "review_gate_count",
        "analysis_gate_count",
        "blocked_gate_count",
        "gate_id",
        "gate_status",
        "gate_classification",
        "gate_reason",
        "analysis_mode",
        "analysis_mode_source",
        "required_operator_action",
        "feedback_source",
        "feedback_scope",
        "feedback_key",
        "trust_boundary",
        "operator_training_requirement_count",
        "operator_training_requirement_counts",
        "required_operator_roles",
        "required_training_ids",
        "required_certification_ids",
        "required_qualification_ids",
        "import_readiness_row_count",
        "ready_for_import_count",
        "manifest_review_required_count",
        "blocked_import_count",
        "missing_import_count",
        "invalid_cadence_import_count",
        "current_freshness_count",
        "stale_freshness_count",
        "unknown_freshness_count",
        "freshness_status_counts",
        "freshness_status_ids",
        "import_status_counts",
        "import_status_ids",
        "cadence_import_status_counts",
        "cadence_import_status_ids",
        "freshness_review_required",
        "import_preparation_required",
        "import_blocked",
        "stale_or_unknown_freshness_quality_gate_row_ids",
        "import_preparation_quality_gate_row_ids",
        "blocked_import_quality_gate_row_ids",
        "schema_validation_row_count",
        "schema_validation_pass_count",
        "schema_validation_fail_count",
        "schema_validation_error_count",
        "schema_validation_warning_count",
        "schema_validation_remediation_count",
        "schema_validation_status_counts",
        "schema_validation_status_ids",
        "schema_validation_import_blocked",
        "failed_schema_validation_quality_gate_row_ids",
        "resource_availability_pressure_count",
        "resource_availability_reason_counts",
        "resource_availability_reason_ids",
        "unavailable_resource_reason_counts",
        "unavailable_resource_reason_ids",
        "station_availability_reason_counts",
        "station_availability_reason_ids",
        "resource_blocking_dimension_counts",
        "blocked_contact_ids_by_blocking_dimension",
        "blocked_contact_ids_by_spacecraft_id",
        "blocked_contact_ids_by_status"
      ])
      |> Map.put("type", "quality_gate_pressure")
      |> Map.put("recommended_branch_id", branch_id)
      |> Map.put(
        "reason",
        event["gate_reason"] || "recommended branch includes quality gate pressure"
      )
      |> compact_map()
    end)
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
