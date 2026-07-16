defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryProjectedResourceValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryEncoding

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def nested_entity_id(row, key, fields) when is_map(row) do
    case Map.get(row, key) do
      %{} = entity -> entity_id(entity, fields)
      _entity -> nil
    end
  end

  def positive_number_value?(value), do: is_number(value) and value > 0.0

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil

  def stringify_keys(value), do: ResourceProjectionFlowSummaryEncoding.stringify_keys(value)

  defp entity_id(%{} = entity, fields) do
    entity = stringify_keys(entity)
    Enum.find_value(fields, &Map.get(entity, &1))
  end

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false
end
