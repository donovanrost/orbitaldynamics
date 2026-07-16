defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts do
  @moduledoc false

  alias __MODULE__.FieldSpecs
  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    Map.new(FieldSpecs.all(), &field_value(reports, &1))
  end

  defp field_value(reports, {:scalar, field, counter}) do
    {field, sum_report_count(reports, counter)}
  end

  defp field_value(reports, {:status, field, status}) do
    {field, sum_report_count(reports, &RowValues.gate_status_count(&1, status))}
  end

  defp field_value(reports, {:count_map, field, counter}) do
    {
      field,
      reports
      |> Enum.map(counter)
      |> merge_count_maps()
    }
  end
end
