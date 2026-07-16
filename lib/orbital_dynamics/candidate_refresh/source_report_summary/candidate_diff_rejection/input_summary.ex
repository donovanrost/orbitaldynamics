defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.{
    CandidateDiffFields,
    CandidateRejectionFields,
    SourceFields
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def candidate_diff_report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.candidate_diff_fields(sources, reports)
    |> Map.merge(CandidateDiffFields.fields(reports))
    |> compact_map()
  end

  def candidate_rejection_report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.candidate_rejection_fields(sources, reports)
    |> Map.merge(CandidateRejectionFields.fields(reports))
    |> compact_map()
  end
end
