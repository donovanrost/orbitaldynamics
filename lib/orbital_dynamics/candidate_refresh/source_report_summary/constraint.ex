defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.{RowFields, SourceFields}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(RowFields.fields(reports))
    |> compact_map()
  end
end
