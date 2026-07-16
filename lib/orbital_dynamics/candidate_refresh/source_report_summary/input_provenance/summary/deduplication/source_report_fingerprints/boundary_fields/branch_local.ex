defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.Deduplication.SourceReportFingerprints.BoundaryFields.BranchLocal do
  @moduledoc false

  def boundary?(report) do
    report
    |> boundary_values()
    |> Enum.any?(&branch_local_boundary?/1)
  end

  defp boundary_values(report) do
    [
      report["trust_boundary"],
      get_in(report, ["provenance", "trust_boundary"]),
      get_in(report, ["metadata", "trust_boundary"]),
      report["_source_report_trust_boundary"]
    ]
  end

  defp branch_local_boundary?("branch_" <> _rest), do: true
  defp branch_local_boundary?("live_branch_" <> _rest), do: true
  defp branch_local_boundary?(_boundary), do: false
end
