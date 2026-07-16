defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationReservationSummary.ExpirationFields.Aggregates.NumericValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def normalize(nil), do: nil

  def normalize(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&NumericValue.value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> non_empty()
  end

  def normalize(value), do: normalize([value])

  defp non_empty([]), do: nil
  defp non_empty(numbers), do: numbers
end
