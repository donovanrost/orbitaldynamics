defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.TimelinePublication do
  @moduledoc false

  alias __MODULE__.FieldGroups

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common, only: [compact_map: 1]

  def fields(reports) do
    reports
    |> FieldGroups.publication_fields()
    |> Map.merge(FieldGroups.artifact_fields(reports))
    |> Map.merge(FieldGroups.timeline_diff_fields(reports))
    |> Map.merge(FieldGroups.dependency_impact_fields(reports))
    |> compact_map()
  end
end
