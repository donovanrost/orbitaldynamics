defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.ReasonIds.Values.UnavailableReasons do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.ReasonIds.Values.ReportReasonIds

  @unavailable_reasons ~w(
    antenna_unavailable
    payload_unavailable
    spacecraft_degraded_payload_unavailable
    spacecraft_unavailable
  )

  def values(report) do
    report
    |> ReportReasonIds.values("unavailable_resource_reason_ids")
    |> filter_reason_ids()
  end

  defp filter_reason_ids(values) do
    values
    |> Enum.map(&NormalizedToken.value/1)
    |> Enum.filter(&(&1 in @unavailable_reasons))
  end
end
