defmodule OrbitalDynamics.Timeline.ActivityInputPolicy do
  @moduledoc false

  def issue(
        activity,
        activity_statuses,
        approval_statuses,
        unit_interval_activity_field_aliases,
        activity_stable_identity_paths,
        activity_status,
        activity_approval_status,
        numeric_value,
        stable_activity_id?
      ) do
    activity_id_issue(activity["id"], stable_activity_id?) ||
      activity_type_issue(activity["type"]) ||
      activity_status_issue(activity, activity_statuses, activity_status) ||
      activity_approval_status_issue(
        activity,
        approval_statuses,
        activity_approval_status
      ) ||
      activity_nested_shape_issue(activity) ||
      activity_unit_interval_issue(
        activity,
        unit_interval_activity_field_aliases,
        numeric_value
      ) ||
      activity_identity_issue(activity, activity_stable_identity_paths, stable_activity_id?)
  end

  defp activity_type_issue(type) do
    if valid_activity_type?(type), do: nil, else: "missing_activity_type"
  end

  defp activity_status_issue(activity, activity_statuses, activity_status) do
    status = activity_status.(activity)

    if status in activity_statuses,
      do: nil,
      else: "unsupported_activity_status"
  end

  defp activity_approval_status_issue(activity, approval_statuses, activity_approval_status) do
    approval_status = activity_approval_status.(activity)

    if approval_status in approval_statuses,
      do: nil,
      else: "unsupported_approval_status"
  end

  defp activity_nested_shape_issue(activity) do
    cond do
      malformed_nested_map?(activity, "metadata") ->
        "invalid_activity_metadata"

      malformed_nested_map?(activity, "source_window") ->
        "invalid_source_window"

      true ->
        nil
    end
  end

  defp activity_unit_interval_issue(activity, unit_interval_activity_field_aliases, numeric_value) do
    Enum.find_value(unit_interval_activity_field_aliases, fn {field, aliases} ->
      if invalid_unit_interval_declared?(activity, aliases, numeric_value),
        do: "invalid_#{field}"
    end)
  end

  defp invalid_unit_interval_declared?(activity, aliases, numeric_value) do
    Enum.any?(aliases, fn field_alias ->
      activity
      |> unit_interval_candidate_values(field_alias)
      |> Enum.any?(&invalid_unit_interval_value?(&1, numeric_value))
    end)
  end

  defp unit_interval_candidate_values(activity, field) do
    [
      Map.get(activity, field),
      get_in(activity, ["metadata", field])
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp invalid_unit_interval_value?(value, numeric_value) do
    case numeric_value.(value) do
      value when is_number(value) -> value < 0.0 or value > 1.0
      _value -> false
    end
  end

  defp malformed_nested_map?(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, nil} -> false
      {:ok, value} -> not is_map(value)
      :error -> false
    end
  end

  defp activity_identity_issue(activity, activity_stable_identity_paths, stable_activity_id?) do
    Enum.find_value(activity_stable_identity_paths, fn {field, path} ->
      case activity_path_value(activity, path) do
        :missing ->
          nil

        value when value in [nil, ""] ->
          nil

        value when is_binary(value) ->
          if stable_activity_id?.(value), do: nil, else: "invalid_#{field}"

        _value ->
          "invalid_#{field}"
      end
    end)
  end

  defp activity_path_value(%{} = activity, [field]) do
    case Map.fetch(activity, field) do
      {:ok, value} -> value
      :error -> :missing
    end
  end

  defp activity_path_value(%{} = activity, [field | rest]) do
    case Map.fetch(activity, field) do
      {:ok, nil} -> :missing
      {:ok, %{} = nested} -> activity_path_value(nested, rest)
      {:ok, _value} -> :missing
      :error -> :missing
    end
  end

  defp activity_path_value(_activity, _path), do: :missing

  defp activity_id_issue(id, _stable_activity_id?) when id in [nil, ""],
    do: "missing_activity_id"

  defp activity_id_issue(id, stable_activity_id?) when is_binary(id),
    do: if(stable_activity_id?.(id), do: nil, else: "invalid_activity_id")

  defp activity_id_issue(_id, _stable_activity_id?), do: "invalid_activity_id"

  defp valid_activity_type?(type) when is_binary(type), do: type != ""
  defp valid_activity_type?(_type), do: false
end
