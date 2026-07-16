defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.SourceFields do
  @moduledoc false

  alias __MODULE__.TrustBoundaries

  def candidate_diff_fields(sources, reports) do
    %{
      "paths" => paths(sources),
      "contract" => "candidate_diff_report.v1",
      "count" => length(reports),
      "trust_boundary_status" => TrustBoundaries.candidate_diff_status(reports),
      "trust_boundaries" => TrustBoundaries.candidate_diff(reports)
    }
  end

  def candidate_rejection_fields(sources, reports) do
    %{
      "paths" => paths(sources),
      "contract" => "candidate_rejection_report.v1",
      "count" => length(sources),
      "trust_boundary_status" => TrustBoundaries.candidate_rejection_status(reports),
      "trust_boundaries" => TrustBoundaries.candidate_rejection(reports)
    }
  end

  defp paths(sources) do
    Enum.map(sources, fn {path, _report} -> path end)
  end
end
