defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness.Summary.ReadinessFields do
  @moduledoc false

  def fields(readiness_summary) do
    %{
      "readiness_level_counts" => Map.get(readiness_summary, "readiness_level_counts", %{}),
      "import_classification_counts" =>
        Map.get(readiness_summary, "import_classification_counts", %{}),
      "status_counts" => Map.get(readiness_summary, "status_counts", %{}),
      "execution_boundary_counts" => Map.get(readiness_summary, "execution_boundary_counts", %{}),
      "analysis_mode_source_counts" =>
        Map.get(readiness_summary, "analysis_mode_source_counts", %{}),
      "analysis_mode_counts" => Map.get(readiness_summary, "analysis_mode_counts", %{}),
      "gate_status_counts" => Map.get(readiness_summary, "gate_status_counts"),
      "gate_classification_counts" => Map.get(readiness_summary, "gate_classification_counts"),
      "gate_ids_by_status" => Map.get(readiness_summary, "gate_ids_by_status"),
      "gate_ids_by_classification" => Map.get(readiness_summary, "gate_ids_by_classification"),
      "passed_gate_ids" => Map.get(readiness_summary, "passed_gate_ids"),
      "review_required_gate_ids" => Map.get(readiness_summary, "review_required_gate_ids"),
      "analysis_only_gate_ids" => Map.get(readiness_summary, "analysis_only_gate_ids"),
      "blocked_gate_ids" => Map.get(readiness_summary, "blocked_gate_ids"),
      "non_passed_gate_ids" => Map.get(readiness_summary, "non_passed_gate_ids"),
      "freshness_status_counts" => Map.get(readiness_summary, "freshness_status_counts", %{}),
      "schema_validation_status_counts" =>
        Map.get(readiness_summary, "schema_validation_status_counts", %{}),
      "import_status_counts" => Map.get(readiness_summary, "import_status_counts", %{}),
      "cadence_import_status_counts" =>
        Map.get(readiness_summary, "cadence_import_status_counts", %{}),
      "adapter_boundary_status_counts" =>
        Map.get(readiness_summary, "adapter_boundary_status_counts", %{}),
      "resource_availability_reason_counts" =>
        Map.get(readiness_summary, "resource_availability_reason_counts", %{}),
      "resource_availability_reason_ids" =>
        Map.get(readiness_summary, "resource_availability_reason_ids", []),
      "station_availability_reason_ids" =>
        Map.get(readiness_summary, "station_availability_reason_ids", []),
      "station_availability_reason_counts" =>
        Map.get(readiness_summary, "station_availability_reason_counts", %{}),
      "unavailable_resource_reason_ids" =>
        Map.get(readiness_summary, "unavailable_resource_reason_ids", []),
      "resource_blocking_dimension_counts" =>
        Map.get(readiness_summary, "resource_blocking_dimension_counts", %{}),
      "review_type_counts" => Map.get(readiness_summary, "review_type_counts", %{}),
      "import_action_counts" => Map.get(readiness_summary, "import_action_counts", %{}),
      "source_review_type_counts" => Map.get(readiness_summary, "source_review_type_counts", %{})
    }
  end
end
