defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.StatusFields.Aggregates do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.StatusValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  def gate_status_id_fields(reports, specs) do
    Map.new(specs, fn {field, status, fallback_field} ->
      {field, status_gate_ids(reports, status, fallback_field)}
    end)
  end

  def row_status_id_fields(reports, specs) do
    Map.new(specs, fn {field, status, fallback_field} ->
      {field, status_row_ids(reports, status, fallback_field)}
    end)
  end

  defp status_gate_ids(reports, status, fallback_field) do
    reports
    |> Enum.flat_map(&StatusValues.gate_ids(&1, status, fallback_field))
    |> sorted_string_values()
  end

  defp status_row_ids(reports, status, fallback_field) do
    reports
    |> Enum.flat_map(&StatusValues.row_ids(&1, status, fallback_field))
    |> sorted_string_values()
  end
end
