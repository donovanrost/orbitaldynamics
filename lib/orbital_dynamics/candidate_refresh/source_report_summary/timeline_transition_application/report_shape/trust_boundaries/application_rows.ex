defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape.TrustBoundaries.ApplicationRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def trust_boundaries(applications) do
    Enum.flat_map(applications, &row_trust_boundaries/1)
  end

  defp row_trust_boundaries(application) do
    application = EncodedValue.stringify_keys(application)

    [
      application["trust_boundary"],
      get_in(application, ["provenance", "trust_boundary"]),
      get_in(application, ["source_timeline_diff", "trust_boundary"]),
      get_in(application, ["source_timeline_diff", "provenance", "trust_boundary"]),
      get_in(application, ["selected_activity", "trust_boundary"]),
      get_in(application, ["selected_activity", "provenance", "trust_boundary"])
    ]
  end
end
