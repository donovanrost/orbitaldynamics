defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance.Summary.Counts do
  @moduledoc false

  @model_id_map_fields [
    "model_ids_by_status",
    "model_ids_by_validation_level",
    "model_ids_by_intended_use"
  ]

  def count(summary, field) do
    case model_id_count(summary) do
      {:ok, count} -> count
      :error -> summary_integer(summary, field)
    end
  end

  def status_count(summary, status) do
    case Map.get(summary, "model_ids_by_status") do
      %{} = model_ids_by_status ->
        model_ids_by_status
        |> Map.get(status, [])
        |> list_value()
        |> length()

      _model_ids_by_status ->
        summary_integer(summary, "#{status}_count")
    end
  end

  def validation_level_count(summary, validation_level) do
    case Map.get(summary, "model_ids_by_validation_level") do
      %{} = model_ids_by_validation_level ->
        model_ids_by_validation_level
        |> Map.get(validation_level, [])
        |> list_value()
        |> length()

      _model_ids_by_validation_level ->
        summary_integer(summary, "unknown_model_count")
    end
  end

  def validation_level_counts(summary) do
    case Map.get(summary, "model_ids_by_validation_level") do
      %{} = model_ids_by_validation_level ->
        model_id_count_map(model_ids_by_validation_level)

      _model_ids_by_validation_level ->
        case Map.get(summary, "validation_level_counts") do
          %{} = counts -> counts
          _counts -> %{}
        end
    end
  end

  defp model_id_count(summary) do
    Enum.find_value(@model_id_map_fields, :error, fn field ->
      case Map.get(summary, field) do
        %{} = model_id_map -> {:ok, model_id_map_model_count(model_id_map)}
        _model_id_map -> false
      end
    end)
  end

  defp model_id_count_map(model_id_map) do
    model_id_map
    |> Enum.map(fn {key, values} -> {to_string(key), values |> list_value() |> length()} end)
    |> Enum.reject(fn {_key, count} -> count == 0 end)
    |> Map.new()
  end

  defp model_id_map_model_count(model_id_map) do
    model_id_map
    |> Enum.flat_map(fn {_key, values} -> list_value(values) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0
end
