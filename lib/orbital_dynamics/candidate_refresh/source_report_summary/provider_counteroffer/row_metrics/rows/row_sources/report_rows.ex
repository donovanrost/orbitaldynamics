defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows.RowSources.ReportRows do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def raw(report) do
    Enum.find_value(FieldSpecs.row_fields(), [], fn field ->
      report
      |> Map.get(field, [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> case do
        [] -> nil
        rows -> rows
      end
    end)
  end

  def encoded(report) do
    report
    |> raw()
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end
end
