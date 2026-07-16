defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryDirectReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryReportFields

  def report_from_summary(%{} = summary) do
    summary = QualityGateSummaryEncoding.stringify_keys(summary)

    summary
    |> QualityGateSummaryReportFields.fields()
    |> maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
