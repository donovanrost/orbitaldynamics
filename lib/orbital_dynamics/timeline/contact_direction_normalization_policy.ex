defmodule OrbitalDynamics.Timeline.ContactDirectionNormalizationPolicy do
  @moduledoc false

  def normalize_activity(%{"direction" => direction} = activity, encode_value) do
    case normalize(direction, encode_value) do
      nil -> Map.delete(activity, "direction")
      normalized -> Map.put(activity, "direction", normalized)
    end
  end

  def normalize_activity(activity, _encode_value), do: activity

  def normalize(direction, _encode_value) when direction in [nil, ""], do: nil

  def normalize(direction, encode_value) do
    normalized_direction = normalize_contact_direction_token(direction, encode_value)

    cond do
      normalized_direction in [nil, "", "nil"] ->
        nil

      aliased_direction = Map.get(provider_direction_aliases(), normalized_direction) ->
        aliased_direction

      normalized_direction in contact_direction_values() ->
        normalized_direction

      normalized_direction == "contact" ->
        normalized_direction

      true ->
        normalized_direction
    end
  end

  def provider_direction_aliases do
    OrbitalDynamics.MissionPlan.Activity.capabilities().contact_direction_aliases
    |> Map.new(fn {alias_value, direction} -> {alias_value, Atom.to_string(direction)} end)
  end

  defp normalize_contact_direction_token(direction, encode_value) do
    direction
    |> encode_value.()
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp contact_direction_values do
    OrbitalDynamics.MissionPlan.Activity.capabilities().contact_directions
    |> Enum.map(&Atom.to_string/1)
  end
end
