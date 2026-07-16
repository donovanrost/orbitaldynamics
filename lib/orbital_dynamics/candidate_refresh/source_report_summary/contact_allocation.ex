defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation do
  @moduledoc false

  alias __MODULE__.InputSummary
  alias __MODULE__.PreservedSummary
  alias __MODULE__.PreservedSummary.ProviderReservationRequest

  def report_input_summary([]), do: nil

  defdelegate report_input_summary(sources), to: InputSummary

  defdelegate report_from_summary(summary), to: PreservedSummary

  defdelegate report_from_provider_reservation_request_summary(summary),
    to: ProviderReservationRequest,
    as: :report_from_summary
end
