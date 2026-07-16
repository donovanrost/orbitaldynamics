defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ContactFields.ContactMaps do
  @moduledoc false

  alias __MODULE__.MapFields
  alias __MODULE__.StationMaps

  def fields(reports) do
    reports
    |> MapFields.fields()
    |> Map.merge(StationMaps.fields(reports))
  end
end
