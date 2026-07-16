defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.SourceFields do
  @moduledoc false

  alias __MODULE__.Metadata

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.TrustBoundaries

  def timeline_diff_fields(sources, reports) do
    Metadata.timeline_diff_fields(sources, reports)
  end

  def integrity_fields(sources, reports) do
    sources
    |> Metadata.integrity_fields()
    |> Map.merge(%{
      "trust_boundary_status" => TrustBoundaries.status(reports),
      "trust_boundaries" => TrustBoundaries.values(reports)
    })
  end
end
