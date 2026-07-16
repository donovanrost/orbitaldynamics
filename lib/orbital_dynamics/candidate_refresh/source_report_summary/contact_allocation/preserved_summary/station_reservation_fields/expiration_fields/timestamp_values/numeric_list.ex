defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationReservationFields.ExpirationFields.TimestampValues.NumericList do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def value(nil), do: nil

  def value(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&NumericValue.value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  def value(value), do: value([value])
end
