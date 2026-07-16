defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields do
  @moduledoc false

  alias __MODULE__.BaseFields
  alias __MODULE__.ContactFields
  alias __MODULE__.ReviewFields

  def fields(reports) do
    reports
    |> BaseFields.fields()
    |> Map.merge(ContactFields.fields(reports))
    |> Map.merge(ReviewFields.fields(reports))
  end
end
