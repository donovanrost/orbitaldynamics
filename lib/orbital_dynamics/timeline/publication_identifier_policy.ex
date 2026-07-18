defmodule OrbitalDynamics.Timeline.PublicationIdentifierPolicy do
  @moduledoc false

  def publication_source_artifact_id(source_artifact, opts, stable_id_value) do
    [
      Keyword.get(opts, :source_artifact_id),
      source_artifact["id"],
      source_artifact["artifact_id"],
      source_artifact["refresh_id"],
      source_artifact["summary_id"],
      source_artifact["plan_id"]
    ]
    |> Enum.flat_map(stable_id_value)
    |> List.first()
    |> case do
      nil -> "timeline_publication_source"
      value -> value
    end
  end

  def publication_stable_id_list(opts, key, stable_id_value, sorted_uniq) do
    opts
    |> Keyword.get(key, [])
    |> List.wrap()
    |> Enum.flat_map(stable_id_value)
    |> sorted_uniq.()
  end

  def publication_id_list(nil, _stable_id_value, _sorted_uniq), do: nil

  def publication_id_list(values, stable_id_value, sorted_uniq) do
    values
    |> List.wrap()
    |> Enum.flat_map(stable_id_value)
    |> sorted_uniq.()
  end

  def publication_id_array_map(%{} = values, stable_id_value, sorted_uniq) do
    values
    |> Enum.map(fn {key, ids} ->
      {to_string(key), publication_id_list(ids, stable_id_value, sorted_uniq)}
    end)
    |> Enum.reject(fn {key, ids} -> key in ["", "nil"] or ids in [nil, []] end)
    |> Map.new()
  end

  def publication_id_array_map(nil, _stable_id_value, _sorted_uniq), do: nil

  def publication_id_array_map(_values, _stable_id_value, _sorted_uniq), do: %{}
end
