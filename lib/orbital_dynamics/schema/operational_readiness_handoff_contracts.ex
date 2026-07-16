defmodule OrbitalDynamics.Schema.OperationalReadinessHandoffContracts do
  @moduledoc false

  @source_report_identity_field_pairs [
    {"source_artifact_type", "source_artifact_type"},
    {"source_artifact_id", "source_artifact_id"}
  ]
  @source_report_summary_field_pairs [
    {"subject_id", "report_id"},
    {"readiness_level", "readiness_level"},
    {"import_classification", "import_classification"},
    {"operational_readiness_status", "status"},
    {"gate_count", "gate_count"},
    {"passed_gate_count", "passed_gate_count"},
    {"review_gate_count", "review_gate_count"},
    {"analysis_gate_count", "analysis_gate_count"},
    {"blocked_gate_count", "blocked_gate_count"}
  ]
  @gate_handoff_source_field_pairs [
    {"gate_id", "id"},
    {"readiness_gate_id", "id"},
    {"quality_gate_id", "id"},
    {"status", "status"},
    {"operational_readiness_status", "status"},
    {"readiness_gate_status", "status"},
    {"quality_gate_status", "status"},
    {"classification", "classification"},
    {"readiness_gate_classification", "classification"},
    {"quality_gate_classification", "classification"},
    {"reason", "reason"},
    {"readiness_gate_reason", "reason"},
    {"quality_gate_reason", "reason"},
    {"analysis_mode", "analysis_mode"},
    {"analysis_mode_source", "analysis_mode_source"}
  ]

  def validate_gate_matches_source(
        issues,
        path,
        %{"source_operational_readiness_gate" => %{} = source_gate} = row,
        callbacks
      )
      when is_list(callbacks) do
    validate_nested_source_pairs(
      issues,
      path,
      row,
      source_gate,
      @gate_handoff_source_field_pairs,
      "source_operational_readiness_gate",
      callbacks
    )
  end

  def validate_gate_matches_source(issues, _path, _row, _callbacks), do: issues

  def validate_report_matches_source(
        issues,
        path,
        %{"source_operational_readiness_report" => %{} = source_report} = row,
        callbacks
      )
      when is_list(callbacks) do
    validate_nested_source_pairs(
      issues,
      path,
      row,
      source_report,
      report_field_pairs(row),
      "source_operational_readiness_report",
      callbacks
    )
  end

  def validate_report_matches_source(issues, _path, _row, _callbacks), do: issues

  defp report_field_pairs(row) do
    if Map.has_key?(row, "readiness_gate_id") do
      @source_report_identity_field_pairs
    else
      @source_report_identity_field_pairs ++ @source_report_summary_field_pairs
    end
  end

  defp validate_nested_source_pairs(issues, path, row, source_row, pairs, source_key, callbacks) do
    Enum.reduce(pairs, issues, fn {row_field, source_field}, acc ->
      row_value = Map.get(row, row_field)
      source_value = Map.get(source_row, source_field)

      if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
        [
          error(
            callbacks,
            "#{path}.#{source_key}.#{source_field}",
            "must match #{row_field} on handoff row"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
