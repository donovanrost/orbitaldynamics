defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.ManeuverReviewFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias __MODULE__.FeedbackFields
  alias __MODULE__.SourceValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def fields(sources) do
    reports = SourceValues.reports(sources)
    trust_boundaries = OperationalFeedback.source_maneuver_review_trust_boundaries(reports)

    %{
      "paths" => SourceValues.paths(sources),
      "contract" => "maneuver_review_report.v1",
      "count" => length(sources),
      "trust_boundary_status" => SourceValues.trust_boundary_status(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
    |> Map.merge(FeedbackFields.fields(reports))
    |> compact_map()
  end
end
