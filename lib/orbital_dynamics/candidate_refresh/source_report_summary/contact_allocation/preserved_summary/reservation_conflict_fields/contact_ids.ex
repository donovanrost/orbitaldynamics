defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ReservationConflictFields.ContactIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent
  alias __MODULE__.CountableValues

  def count(summary) do
    case CountableValues.values(summary) do
      nil ->
        nil

      contact_ids ->
        contact_ids
        |> ContactIntent.count_unique_contact_ids()
    end
  end
end
