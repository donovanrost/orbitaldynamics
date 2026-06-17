defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.Summary.Pressure do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.Summary.Values,
    only: [summary_integer: 2]

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.Summary.ResourceAvailabilityFields

  def pressure_fields(quality_gate_summary) do
    pressure_fields(quality_gate_summary, ResourceAvailabilityFields.fields(quality_gate_summary))
  end

  def pressure_fields(quality_gate_summary, resource_availability_fields) do
    review_gate_count = summary_integer(quality_gate_summary, "review_gate_count")
    blocked_gate_count = summary_integer(quality_gate_summary, "blocked_gate_count")
    import_review_count = summary_integer(quality_gate_summary, "manifest_review_required_count")
    missing_import_count = summary_integer(quality_gate_summary, "missing_import_count")
    blocked_import_count = summary_integer(quality_gate_summary, "blocked_import_count")
    invalid_import_count = summary_integer(quality_gate_summary, "invalid_cadence_import_count")

    resource_pressure_count =
      summary_integer(resource_availability_fields, "resource_availability_pressure_count")

    resource_availability_reason_counts =
      Map.get(resource_availability_fields, "resource_availability_reason_counts", %{})

    resource_availability_reason_ids =
      Map.get(resource_availability_fields, "resource_availability_reason_ids", [])

    station_availability_reason_ids =
      Map.get(resource_availability_fields, "station_availability_reason_ids", [])

    station_availability_reason_counts =
      Map.get(resource_availability_fields, "station_availability_reason_counts", %{})

    unavailable_resource_reason_ids =
      Map.get(resource_availability_fields, "unavailable_resource_reason_ids", [])

    resource_blocking_dimension_counts =
      Map.get(resource_availability_fields, "resource_blocking_dimension_counts", %{})

    blocked_contact_ids_by_blocking_dimension =
      Map.get(resource_availability_fields, "blocked_contact_ids_by_blocking_dimension", %{})

    blocked_contact_ids_by_spacecraft_id =
      Map.get(resource_availability_fields, "blocked_contact_ids_by_spacecraft_id", %{})

    blocked_contact_ids_by_status =
      Map.get(resource_availability_fields, "blocked_contact_ids_by_status", %{})

    readiness_level_counts = Map.get(quality_gate_summary, "readiness_level_counts", %{})

    import_classification_counts =
      Map.get(quality_gate_summary, "import_classification_counts", %{})

    status_counts = Map.get(quality_gate_summary, "status_counts", %{})
    analysis_mode_counts = Map.get(quality_gate_summary, "analysis_mode_counts", %{})
    gate_status_counts = Map.get(quality_gate_summary, "gate_status_counts", %{})
    gate_classification_counts = Map.get(quality_gate_summary, "gate_classification_counts", %{})
    import_status_counts = Map.get(quality_gate_summary, "import_status_counts", %{})

    cadence_import_status_counts =
      Map.get(quality_gate_summary, "cadence_import_status_counts", %{})

    %{
      "branch_local_review_pressure" =>
        review_gate_count > 0 or blocked_gate_count > 0 or
          map_size(readiness_level_counts) > 0 or
          map_size(import_classification_counts) > 0 or map_size(status_counts) > 0 or
          map_size(analysis_mode_counts) > 0 or map_size(gate_status_counts) > 0 or
          map_size(gate_classification_counts) > 0,
      "branch_local_import_pressure" =>
        import_review_count + missing_import_count + blocked_import_count + invalid_import_count >
          0 or map_size(import_status_counts) > 0 or map_size(cadence_import_status_counts) > 0,
      "branch_local_resource_pressure" =>
        resource_pressure_count > 0 or map_size(resource_availability_reason_counts) > 0 or
          resource_availability_reason_ids != [] or station_availability_reason_ids != [] or
          map_size(station_availability_reason_counts) > 0 or
          unavailable_resource_reason_ids != [] or
          map_size(resource_blocking_dimension_counts) > 0 or
          map_size(blocked_contact_ids_by_blocking_dimension) > 0 or
          map_size(blocked_contact_ids_by_spacecraft_id) > 0 or
          map_size(blocked_contact_ids_by_status) > 0
    }
  end
end
