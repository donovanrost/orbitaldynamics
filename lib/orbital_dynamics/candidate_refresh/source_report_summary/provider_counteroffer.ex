defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer do
  @moduledoc false

  alias __MODULE__.RowMetrics
  alias __MODULE__.SourceFields
  alias __MODULE__.SummaryFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(RowMetrics.fields(reports))
    |> Map.merge(SummaryFields.fields(reports))
    |> compact_map()
  end

  def source_provider_counteroffer_report_trust_boundaries(reports),
    do: SourceFields.trust_boundaries(reports)
end
