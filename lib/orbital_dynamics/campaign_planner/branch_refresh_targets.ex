defmodule OrbitalDynamics.CampaignPlanner.BranchRefreshTargets do
  @moduledoc false

  def build(branch, mission_state, operational_feedback) do
    catalog_targets =
      mission_state
      |> Map.get("targets", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&normalize_target_spec/1)
      |> unique_items_by_id()

    objective_targets =
      mission_state
      |> Map.get("objectives", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(fn objective ->
        objective
        |> Map.take([
          "id",
          "target_id",
          "latitude_deg",
          "longitude_deg",
          "minimum_elevation_deg",
          "priority"
        ])
        |> Map.put_new("id", Map.get(objective, "target_id"))
      end)
      |> Enum.map(&normalize_target_spec/1)
      |> Enum.filter(&target_spec?/1)
      |> unique_items_by_id()

    event_targets =
      branch
      |> Map.get("events", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(fn event ->
        event
        |> Map.take([
          "id",
          "target_id",
          "latitude_deg",
          "longitude_deg",
          "minimum_elevation_deg",
          "priority"
        ])
        |> Map.put_new("id", Map.get(event, "target_id"))
      end)
      |> Enum.map(&normalize_target_spec/1)
      |> Enum.filter(&target_spec?/1)
      |> unique_items_by_id()

    (catalog_targets ++ objective_targets ++ event_targets)
    |> Enum.filter(&target_spec?/1)
    |> Enum.map(fn target ->
      target
      |> Map.put_new("minimum_elevation_deg", 10.0)
      |> Map.put_new("priority", 1.0)
      |> Map.delete("target_id")
    end)
    |> dedupe_by_id()
    |> apply_target_priority_feedback(operational_feedback)
    |> apply_observation_success_feedback(operational_feedback)
    |> apply_observation_quality_feedback(operational_feedback)
  end

  def target_spec?(target) do
    target_id = Map.get(target, "id") || Map.get(target, "target_id")

    target_id not in [nil, ""] and is_number(Map.get(target, "latitude_deg")) and
      is_number(Map.get(target, "longitude_deg"))
  end

  def normalize_target_spec(target) do
    target
    |> Map.put_new("id", Map.get(target, "target_id"))
    |> normalize_target_spec_number("latitude_deg")
    |> normalize_target_spec_number("longitude_deg")
    |> normalize_target_spec_number("minimum_elevation_deg")
    |> normalize_target_spec_number("priority")
  end

  defp normalize_target_spec_number(target, field) do
    case numeric_or_nil(Map.get(target, field)) do
      value when is_number(value) -> Map.put(target, field, value)
      _value -> Map.delete(target, field)
    end
  end

  defp apply_target_priority_feedback(targets, %{"target_priority_overrides" => priorities})
       when is_map(priorities) do
    Enum.map(targets, fn target ->
      target_id = Map.get(target, "id")
      priority = numeric_or_nil(Map.get(priorities, target_id))

      if is_number(priority) do
        target
        |> Map.put("priority", max(priority, 0.0))
        |> Map.put("priority_override_source", "operational_feedback")
      else
        target
      end
    end)
  end

  defp apply_target_priority_feedback(targets, _operational_feedback), do: targets

  defp apply_observation_success_feedback(targets, %{"observation_success_rate" => rates})
       when is_map(rates) do
    Enum.map(targets, fn target ->
      target_id = Map.get(target, "id")
      factor = Map.get(rates, target_id) || Map.get(rates, "default")

      if is_number(factor) do
        priority =
          target
          |> Map.get("priority", 1.0)
          |> numeric_or_nil()
          |> Kernel.||(1.0)
          |> Kernel.*(factor)
          |> max(0.0)

        target
        |> Map.put("priority", priority)
        |> Map.put("observation_success_factor", factor)
      else
        target
      end
    end)
  end

  defp apply_observation_success_feedback(targets, _operational_feedback), do: targets

  defp apply_observation_quality_feedback(targets, %{} = operational_feedback) do
    Enum.map(targets, fn target ->
      target_id = Map.get(target, "id")

      target
      |> put_observation_quality_feedback_value(
        "image_quality_score",
        feedback_target_number(operational_feedback, "image_quality_score", target_id)
      )
      |> put_observation_quality_feedback_value(
        "image_quality_status",
        feedback_target_string(operational_feedback, "image_quality_status", target_id)
      )
      |> put_observation_quality_feedback_value(
        "image_quality_source",
        feedback_target_string(operational_feedback, "image_quality_source", target_id)
      )
      |> put_observation_quality_feedback_value(
        "cloud_cover_fraction",
        feedback_target_number(operational_feedback, "cloud_cover_fraction", target_id)
      )
      |> put_observation_quality_feedback_value(
        "blur_score",
        feedback_target_number(operational_feedback, "blur_score", target_id)
      )
    end)
  end

  defp apply_observation_quality_feedback(targets, _operational_feedback), do: targets

  defp feedback_target_number(feedback, field, target_id) do
    case Map.get(feedback, field) do
      %{} = values ->
        Enum.find_value([target_id, "default"], fn key ->
          case Map.get(values, key) do
            value when is_number(value) -> value
            _value -> nil
          end
        end)

      _values ->
        nil
    end
  end

  defp feedback_target_string(feedback, field, target_id) do
    case Map.get(feedback, field) do
      %{} = values ->
        Enum.find_value([target_id, "default"], fn key ->
          case encode_value(Map.get(values, key)) do
            value when is_binary(value) and value != "" -> value
            _value -> nil
          end
        end)

      _values ->
        nil
    end
  end

  defp put_observation_quality_feedback_value(target, _field, nil), do: target

  defp put_observation_quality_feedback_value(target, field, value),
    do: Map.put(target, field, value)

  defp dedupe_by_id(items) do
    items
    |> Map.new(&{&1["id"], &1})
    |> Map.values()
    |> Enum.sort_by(& &1["id"])
  end

  defp unique_items_by_id(items) do
    items
    |> Enum.group_by(&Map.get(&1, "id"))
    |> Enum.reject(fn {id, _items} -> id in [nil, ""] end)
    |> Enum.flat_map(fn
      {_id, [item]} -> [item]
      {_id, _duplicates} -> []
    end)
    |> Enum.sort_by(& &1["id"])
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

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
