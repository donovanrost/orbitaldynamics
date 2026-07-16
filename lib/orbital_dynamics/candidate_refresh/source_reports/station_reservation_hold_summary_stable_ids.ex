defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryStableIds do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false
end
