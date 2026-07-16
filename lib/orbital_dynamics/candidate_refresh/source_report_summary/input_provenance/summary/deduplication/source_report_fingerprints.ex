defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.Deduplication.SourceReportFingerprints do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias __MODULE__.BoundaryFields

  @branch_local_contracts [
    "candidate_diff_report.v1",
    "candidate_rejection_report.v1"
  ]

  def fingerprint(%{} = report) do
    report
    |> EncodedValue.stringify_keys_with_keyword_maps()
    |> BoundaryFields.drop()
  end

  def fingerprint(report), do: report

  def branch_local?(%{} = report) do
    report = EncodedValue.stringify_keys_with_keyword_maps(report)

    Map.get(report, "schema_contract") in @branch_local_contracts or
      BoundaryFields.branch_local?(report)
  end

  def branch_local?(_report), do: false
end
