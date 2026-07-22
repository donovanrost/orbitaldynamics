defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationPressureReviewCorrelation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.OutcomeIdentityCorrelation

  @count_field "station_pressure_review_contact_count"
  @ids_field "station_pressure_review_contact_ids"

  def fields, do: [@count_field, @ids_field]

  def fields(%{} = summary) do
    supplied_ids = Map.get(summary, @ids_field)
    contact_ids = OutcomeIdentityCorrelation.contact_ids(supplied_ids)

    count =
      if is_list(supplied_ids) do
        contact_ids |> List.wrap() |> length()
      else
        non_negative_integer(Map.get(summary, @count_field))
      end

    summary
    |> put_or_delete(@count_field, count)
    |> put_or_delete(@ids_field, contact_ids)
  end

  defp non_negative_integer(count) when is_integer(count) and count >= 0, do: count
  defp non_negative_integer(_count), do: nil

  defp put_or_delete(map, field, nil), do: Map.delete(map, field)
  defp put_or_delete(map, field, value), do: Map.put(map, field, value)
end
