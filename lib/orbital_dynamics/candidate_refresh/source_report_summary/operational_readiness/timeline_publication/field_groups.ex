defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.TimelinePublication.FieldGroups do
  @moduledoc false

  alias __MODULE__.ArtifactFields
  alias __MODULE__.DependencyImpactFields
  alias __MODULE__.TimelineDiffFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence

  def artifact_fields(reports) do
    ArtifactFields.values(reports)
  end

  def timeline_diff_fields(reports) do
    TimelineDiffFields.values(reports)
  end

  def dependency_impact_fields(reports) do
    DependencyImpactFields.values(reports)
  end

  def publication_fields(reports) do
    %{
      "publication_status_counts" =>
        Evidence.count_map_merge(reports, "publication_status_counts"),
      "dependency_impact_status_counts" =>
        Evidence.count_map_merge(reports, "dependency_impact_status_counts"),
      "publication_authority_counts" =>
        Evidence.count_map_merge(reports, "publication_authority_counts"),
      "source_artifact_type_counts" =>
        Evidence.count_map_merge(reports, "source_artifact_type_counts"),
      "timeline_publication_source_artifact_type_counts" =>
        Evidence.count_map_merge(reports, "source_artifact_type_counts")
    }
  end
end
