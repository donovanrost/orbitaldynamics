defmodule OrbitalDynamics.Timeline.ActivityRelationshipPolicy do
  @moduledoc false

  def dependency_activity_ids(activity, first_value, normalize_id_list) do
    activity
    |> first_value.([
      "dependency_activity_ids",
      "depends_on_activity_ids",
      "depends_on",
      "dependencies"
    ])
    |> normalize_id_list.(["activity_id", "id"])
  end

  def duplicate_dependency_activity_ids(activity, first_value, duplicate_id_list) do
    activity
    |> first_value.([
      "dependency_activity_ids",
      "depends_on_activity_ids",
      "depends_on",
      "dependencies"
    ])
    |> duplicate_id_list.(["activity_id", "id"])
  end

  def dependency_timeline_ids(
        activity,
        first_value,
        normalize_map_id_list,
        normalize_id_list
      ) do
    case first_value.(activity, ["dependency_timeline_ids", "depends_on_timeline_ids"]) do
      value when value in [nil, []] ->
        activity
        |> first_value.(["dependencies"])
        |> normalize_map_id_list.(["timeline_id", "persistent_id"])

      values ->
        normalize_id_list.(values, ["timeline_id", "persistent_id"])
    end
  end

  def duplicate_dependency_timeline_ids(
        activity,
        first_value,
        duplicate_map_id_list,
        duplicate_id_list
      ) do
    case first_value.(activity, ["dependency_timeline_ids", "depends_on_timeline_ids"]) do
      value when value in [nil, []] ->
        activity
        |> first_value.(["dependencies"])
        |> duplicate_map_id_list.(["timeline_id", "persistent_id"])

      values ->
        duplicate_id_list.(values, ["timeline_id", "persistent_id"])
    end
  end

  def exclusive_with_activity_ids(activity, first_value, normalize_id_list) do
    explicit =
      activity
      |> first_value.(["exclusive_with_activity_ids"])
      |> normalize_id_list.(["activity_id", "id"])

    case explicit do
      values when is_list(values) and values != [] ->
        values

      _empty ->
        activity
        |> first_value.(["exclusive_with", "exclusions"])
        |> normalize_id_list.(["activity_id", "id"])
    end
  end

  def duplicate_exclusivity_activity_ids(activity, first_value, duplicate_id_list) do
    explicit =
      activity
      |> first_value.(["exclusive_with_activity_ids"])
      |> duplicate_id_list.(["activity_id", "id"])

    case explicit do
      values when is_list(values) and values != [] ->
        values

      _empty ->
        activity
        |> first_value.(["exclusive_with", "exclusions"])
        |> duplicate_id_list.(["activity_id", "id"])
    end
  end

  def exclusive_with_timeline_ids(
        activity,
        first_value,
        normalize_map_id_list,
        normalize_id_list
      ) do
    case first_value.(activity, ["exclusive_with_timeline_ids"]) do
      value when value in [nil, []] ->
        activity
        |> first_value.(["exclusive_with", "exclusions"])
        |> normalize_map_id_list.(["timeline_id", "persistent_id"])

      values ->
        normalize_id_list.(values, ["timeline_id", "persistent_id"])
    end
  end

  def duplicate_exclusivity_timeline_ids(
        activity,
        first_value,
        duplicate_map_id_list,
        duplicate_id_list
      ) do
    case first_value.(activity, ["exclusive_with_timeline_ids"]) do
      value when value in [nil, []] ->
        activity
        |> first_value.(["exclusive_with", "exclusions"])
        |> duplicate_map_id_list.(["timeline_id", "persistent_id"])

      values ->
        duplicate_id_list.(values, ["timeline_id", "persistent_id"])
    end
  end
end
