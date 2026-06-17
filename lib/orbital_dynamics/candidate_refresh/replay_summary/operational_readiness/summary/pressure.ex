defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness.Summary.Pressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness.Summary.ReadinessFields

  def fields(readiness_summary) do
    fields(readiness_summary, ReadinessFields.fields(readiness_summary))
  end

  def fields(readiness_summary, readiness_fields) do
    review_gate_count = summary_integer(readiness_summary, "review_gate_count")
    blocked_gate_count = summary_integer(readiness_summary, "blocked_gate_count")
    review_required_count = summary_integer(readiness_summary, "review_required_count")
    import_review_count = summary_integer(readiness_summary, "manifest_review_required_count")
    missing_import_count = summary_integer(readiness_summary, "missing_import_count")
    blocked_import_count = summary_integer(readiness_summary, "blocked_import_count")
    invalid_import_count = summary_integer(readiness_summary, "invalid_cadence_import_count")
    import_ineligible_count = summary_integer(readiness_summary, "import_ineligible_count")
    execution_boundary_counts = Map.get(readiness_fields, "execution_boundary_counts", %{})
    analysis_mode_source_counts = Map.get(readiness_fields, "analysis_mode_source_counts", %{})
    handoff_only_count = summary_integer(readiness_summary, "handoff_only_count")
    execution_denied_count = summary_integer(readiness_summary, "execution_denied_count")
    cadence_write_denied_count = summary_integer(readiness_summary, "cadence_write_denied_count")

    operator_authority_denied_count =
      summary_integer(readiness_summary, "operator_authority_denied_count")

    resource_pressure_count =
      summary_integer(readiness_summary, "resource_availability_pressure_count")

    resource_availability_reason_counts =
      Map.get(readiness_fields, "resource_availability_reason_counts", %{})

    resource_availability_reason_ids =
      Map.get(readiness_fields, "resource_availability_reason_ids", [])

    station_availability_reason_ids =
      Map.get(readiness_fields, "station_availability_reason_ids", [])

    station_availability_reason_counts =
      Map.get(readiness_fields, "station_availability_reason_counts", %{})

    unavailable_resource_reason_ids =
      Map.get(readiness_fields, "unavailable_resource_reason_ids", [])

    resource_blocking_dimension_counts =
      Map.get(readiness_fields, "resource_blocking_dimension_counts", %{})

    review_type_counts = Map.get(readiness_fields, "review_type_counts", %{})
    import_action_counts = Map.get(readiness_fields, "import_action_counts", %{})
    source_review_type_counts = Map.get(readiness_fields, "source_review_type_counts", %{})
    gate_status_counts = Map.get(readiness_fields, "gate_status_counts")
    gate_classification_counts = Map.get(readiness_fields, "gate_classification_counts")
    gate_ids_by_status = Map.get(readiness_fields, "gate_ids_by_status")
    gate_ids_by_classification = Map.get(readiness_fields, "gate_ids_by_classification")
    review_required_gate_ids = Map.get(readiness_fields, "review_required_gate_ids")
    blocked_gate_ids = Map.get(readiness_fields, "blocked_gate_ids")
    non_passed_gate_ids = Map.get(readiness_fields, "non_passed_gate_ids")
    non_passed_gate_count = summary_integer(readiness_summary, "non_passed_gate_count")

    resource_pressure =
      resource_pressure_count > 0 or map_size(resource_availability_reason_counts) > 0 or
        resource_availability_reason_ids != [] or station_availability_reason_ids != [] or
        map_size(station_availability_reason_counts) > 0 or
        unavailable_resource_reason_ids != [] or map_size(resource_blocking_dimension_counts) > 0

    review_pressure =
      review_gate_count > 0 or blocked_gate_count > 0 or review_required_count > 0 or
        map_size(review_type_counts) > 0 or map_size(source_review_type_counts) > 0

    import_pressure =
      import_review_count + missing_import_count + blocked_import_count + invalid_import_count +
        import_ineligible_count >
        0 or map_size(import_action_counts) > 0

    execution_boundary_pressure =
      map_size(execution_boundary_counts) > 0 or map_size(analysis_mode_source_counts) > 0 or
        handoff_only_count + execution_denied_count + cadence_write_denied_count +
          operator_authority_denied_count >
          0

    %{
      "branch_local_review_pressure" =>
        review_pressure or map_size(empty_map_if_nil(gate_status_counts)) > 0 or
          map_size(empty_map_if_nil(gate_classification_counts)) > 0 or
          map_size(empty_map_if_nil(gate_ids_by_status)) > 0 or
          map_size(empty_map_if_nil(gate_ids_by_classification)) > 0 or
          List.wrap(review_required_gate_ids) != [] or List.wrap(blocked_gate_ids) != [] or
          List.wrap(non_passed_gate_ids) != [] or non_passed_gate_count > 0,
      "branch_local_import_pressure" => import_pressure,
      "branch_local_execution_boundary_pressure" => execution_boundary_pressure,
      "branch_local_resource_pressure" => resource_pressure
    }
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(value) do
          {parsed, ""} -> parsed
          _other -> 0
        end

      _other ->
        0
    end
  end

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}
end
