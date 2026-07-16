defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewReportRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewReportRowValues

  def from_rows(path, source, rows, artifact) do
    ManeuverReviewReportRowValues.from_rows(path, source, rows, artifact)
  end
end
