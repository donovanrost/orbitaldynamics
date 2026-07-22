defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.BlockedInputIdentityCorrelation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.OutcomeIdentityCorrelation

  @field_pairs [
    {"invalid_contact_input_count", "invalid_contact_input_ids"},
    {"status_blocked_contact_count", "status_blocked_contact_ids"},
    {"resource_blocked_contact_count", "resource_blocked_contact_ids"}
  ]

  def field_pairs, do: @field_pairs

  def fields(%{} = summary) do
    Enum.reduce(@field_pairs, summary, fn {count_field, ids_field}, correlated ->
      contact_ids = OutcomeIdentityCorrelation.contact_ids(Map.get(summary, ids_field))

      correlated
      |> put_or_delete(ids_field, contact_ids)
      |> put_or_delete(
        count_field,
        OutcomeIdentityCorrelation.correlated_count(
          Map.get(summary, count_field),
          contact_ids
        )
      )
    end)
  end

  defp put_or_delete(map, field, nil), do: Map.delete(map, field)
  defp put_or_delete(map, field, value), do: Map.put(map, field, value)
end
