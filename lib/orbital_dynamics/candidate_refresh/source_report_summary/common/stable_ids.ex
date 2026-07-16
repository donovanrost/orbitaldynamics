defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  def stable_id?("nil"), do: false
  def stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  def stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  def stable_id?(_value), do: false

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil
end
