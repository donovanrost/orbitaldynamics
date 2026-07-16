defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.InputSummary.ReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.SourceFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def fields(family, contract, sources, family_fields) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(family, contract, sources, reports)
    |> Map.merge(family_fields.fields(reports))
    |> compact_map()
  end
end
