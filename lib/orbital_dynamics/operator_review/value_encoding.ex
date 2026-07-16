defmodule OrbitalDynamics.OperatorReview.ValueEncoding do
  @moduledoc false

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
