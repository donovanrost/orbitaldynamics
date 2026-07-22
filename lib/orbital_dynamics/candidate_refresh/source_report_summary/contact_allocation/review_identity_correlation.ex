defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ReviewIdentityCorrelation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.OutcomeIdentityCorrelation

  @field "review_contact_ids"

  def field, do: @field

  def fields(%{} = summary) do
    case OutcomeIdentityCorrelation.contact_ids(Map.get(summary, @field)) do
      nil -> Map.delete(summary, @field)
      contact_ids -> Map.put(summary, @field, contact_ids)
    end
  end
end
