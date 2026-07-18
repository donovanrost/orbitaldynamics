defmodule OrbitalDynamics.Timeline.ActivityRelationshipContext do
  @moduledoc false

  def build(activity, stable_id_pattern) do
    %{
      "dependency_activity_ids" => dependency_activity_ids(activity, stable_id_pattern),
      "dependency_timeline_ids" => dependency_timeline_ids(activity, stable_id_pattern),
      "exclusive_with_activity_ids" => exclusive_with_activity_ids(activity, stable_id_pattern),
      "exclusive_with_timeline_ids" => exclusive_with_timeline_ids(activity, stable_id_pattern),
      "duplicate_dependency_activity_ids" =>
        duplicate_dependency_activity_ids(activity, stable_id_pattern),
      "duplicate_dependency_timeline_ids" =>
        duplicate_dependency_timeline_ids(activity, stable_id_pattern),
      "duplicate_exclusivity_activity_ids" =>
        duplicate_exclusivity_activity_ids(activity, stable_id_pattern),
      "duplicate_exclusivity_timeline_ids" =>
        duplicate_exclusivity_timeline_ids(activity, stable_id_pattern),
      "allow_overlap" => activity_allow_overlap(activity)
    }
    |> compact_map()
  end

  def dependency_activity_ids(activity, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityRelationshipPolicy.dependency_activity_ids(
      activity,
      &first_value/2,
      fn value, map_keys -> normalize_id_list(value, map_keys, stable_id_pattern) end
    )
  end

  def duplicate_dependency_activity_ids(activity, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityRelationshipPolicy.duplicate_dependency_activity_ids(
      activity,
      &first_value/2,
      fn value, map_keys -> duplicate_id_list(value, map_keys, stable_id_pattern) end
    )
  end

  def dependency_timeline_ids(activity, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityRelationshipPolicy.dependency_timeline_ids(
      activity,
      &first_value/2,
      fn value, map_keys -> normalize_map_id_list(value, map_keys, stable_id_pattern) end,
      fn value, map_keys -> normalize_id_list(value, map_keys, stable_id_pattern) end
    )
  end

  def duplicate_dependency_timeline_ids(activity, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityRelationshipPolicy.duplicate_dependency_timeline_ids(
      activity,
      &first_value/2,
      fn value, map_keys -> duplicate_map_id_list(value, map_keys, stable_id_pattern) end,
      fn value, map_keys -> duplicate_id_list(value, map_keys, stable_id_pattern) end
    )
  end

  def exclusive_with_activity_ids(activity, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityRelationshipPolicy.exclusive_with_activity_ids(
      activity,
      &first_value/2,
      fn value, map_keys -> normalize_id_list(value, map_keys, stable_id_pattern) end
    )
  end

  def duplicate_exclusivity_activity_ids(activity, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityRelationshipPolicy.duplicate_exclusivity_activity_ids(
      activity,
      &first_value/2,
      fn value, map_keys -> duplicate_id_list(value, map_keys, stable_id_pattern) end
    )
  end

  def exclusive_with_timeline_ids(activity, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityRelationshipPolicy.exclusive_with_timeline_ids(
      activity,
      &first_value/2,
      fn value, map_keys -> normalize_map_id_list(value, map_keys, stable_id_pattern) end,
      fn value, map_keys -> normalize_id_list(value, map_keys, stable_id_pattern) end
    )
  end

  def duplicate_exclusivity_timeline_ids(activity, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityRelationshipPolicy.duplicate_exclusivity_timeline_ids(
      activity,
      &first_value/2,
      fn value, map_keys -> duplicate_map_id_list(value, map_keys, stable_id_pattern) end,
      fn value, map_keys -> duplicate_id_list(value, map_keys, stable_id_pattern) end
    )
  end

  defp first_value(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_value(activity, keys)
  end

  defp normalize_id_list(value, map_keys, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityReferenceIdPolicy.normalize(
      value,
      map_keys,
      fn id -> stable_activity_id?(id, stable_id_pattern) end
    )
  end

  defp duplicate_id_list(value, map_keys, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityReferenceIdPolicy.duplicates(
      value,
      map_keys,
      fn id -> stable_activity_id?(id, stable_id_pattern) end
    )
  end

  defp normalize_map_id_list(value, map_keys, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityReferenceIdPolicy.normalize_maps(
      value,
      map_keys,
      fn id -> stable_activity_id?(id, stable_id_pattern) end
    )
  end

  defp duplicate_map_id_list(value, map_keys, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityReferenceIdPolicy.duplicate_maps(
      value,
      map_keys,
      fn id -> stable_activity_id?(id, stable_id_pattern) end
    )
  end

  defp stable_activity_id?(id, stable_id_pattern) do
    OrbitalDynamics.Timeline.StableIdentifierPolicy.valid?(id, stable_id_pattern)
  end

  defp activity_allow_overlap(activity) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.allow_overlap(activity)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
