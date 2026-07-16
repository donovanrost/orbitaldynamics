defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  def entries(path, state) do
    EntryFallbacks.entries(path, state, fn entry_path, entry_state ->
      state = stringify_keys(entry_state)

      if lifecycle_state_source?(state) do
        {entry_path, state}
      end
    end)
  end

  def lifecycle_state_source?(%{} = state) do
    schema_contract = Map.get(state, "schema_contract") || Map.get(state, :schema_contract)
    model = Map.get(state, "model") || Map.get(state, :model)

    schema_contract == "timeline_activity_lifecycle_state.v1" or
      model == "artifact_only_timeline_activity_lifecycle_state"
  end

  def lifecycle_state_source?(_state), do: false

  def stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value), do: encode_value(value)

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
