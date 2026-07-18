defmodule OrbitalDynamics.Timeline.ActivityFieldValuePolicy do
  @moduledoc false

  def first_present_value(activity, keys) do
    Enum.find_value(keys, :error, fn key ->
      metadata = Map.get(activity, "metadata") || Map.get(activity, :metadata) || %{}

      case fetch_key_or_atom(activity, key) do
        {:ok, value} ->
          {:ok, value}

        :error ->
          case fetch_key_or_atom(metadata, key) do
            {:ok, value} -> {:ok, value}
            :error -> false
          end
      end
    end)
  end

  def first_value(activity, keys) do
    Enum.find_value(keys, fn key ->
      metadata = Map.get(activity, "metadata") || Map.get(activity, :metadata) || %{}

      case fetch_key_or_atom(activity, key) do
        {:ok, value} when not is_nil(value) ->
          value

        _value ->
          case fetch_key_or_atom(metadata, key) do
            {:ok, value} -> value
            :error -> nil
          end
      end
    end)
  end

  def first_number(activity, keys, numeric_value) do
    Enum.find_value(keys, fn key ->
      value = first_value(activity, [key])
      numeric_value.(value)
    end)
  end

  def first_number_or_scalar(activity, keys, numeric_value) do
    Enum.find_value(keys, fn key ->
      case first_value(activity, [key]) do
        value when is_number(value) -> value
        value when is_binary(value) and value != "" -> numeric_value.(value) || value
        value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
        _value -> nil
      end
    end)
  end

  def first_scalar_string(activity, keys) do
    Enum.find_value(keys, fn key ->
      case first_value(activity, [key]) do
        value when is_binary(value) and value != "" -> value
        value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
        _value -> nil
      end
    end)
  end

  def first_provider_result_string(activity, keys, provider_result_artifact_value) do
    Enum.find_value(keys, fn key ->
      activity
      |> first_value([key])
      |> provider_result_artifact_value.()
    end)
  end

  def first_stable_identifier(activity, keys, stable_activity_id?) do
    Enum.find_value(keys, fn key ->
      case first_value(activity, [key]) do
        value when is_binary(value) and value != "" ->
          if stable_activity_id?.(value), do: value

        value when is_atom(value) and not is_nil(value) ->
          value = Atom.to_string(value)
          if stable_activity_id?.(value), do: value

        _value ->
          nil
      end
    end)
  end

  defp fetch_key_or_atom(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error when is_binary(key) -> fetch_existing_atom_key(map, key)
      :error -> :error
    end
  end

  defp fetch_key_or_atom(_map, _key), do: :error

  defp fetch_existing_atom_key(map, key) do
    atom_key = String.to_existing_atom(key)
    Map.fetch(map, atom_key)
  rescue
    ArgumentError -> :error
  end
end
