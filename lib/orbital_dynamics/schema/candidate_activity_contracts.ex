defmodule OrbitalDynamics.Schema.CandidateActivityContracts do
  @moduledoc false

  def validate(issues, path, activity, callbacks) when is_list(callbacks) do
    issues
    |> validate_activity(callbacks, path, activity)
    |> validate_optional_schema_contract(callbacks, path, activity, "candidate_activity.v1")
    |> validate_stable_ids(callbacks, path, activity, [
      "spacecraft_id",
      "source_target_id",
      "collection_id",
      "payload_id",
      "instrument_id"
    ])
    |> validate_optional_stable_id_list(callbacks, path, activity, "product_ids")
    |> require_fields(callbacks, path, activity, [
      "duration_s",
      "score",
      "score_terms",
      "source_window_id"
    ])
    |> expect_number(callbacks, path, activity, "duration_s")
    |> expect_number(callbacks, path, activity, "score")
    |> expect_type(callbacks, path, activity, "score_terms", :map)
    |> expect_type(callbacks, path, activity, "source_window", :map)
    |> expect_optional_number(callbacks, path, activity, "target_priority")
    |> expect_optional_type(callbacks, path, activity, "target_priority_source", :binary)
    |> expect_optional_type(callbacks, path, activity, "target_priority_objective_type", :binary)
    |> expect_optional_type(callbacks, path, activity, "target_priority_objective_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      activity,
      "target_priority_objective_ids"
    )
    |> expect_optional_type(callbacks, path, activity, "source_target", :map)
    |> expect_optional_number(callbacks, path, activity, "target_latitude_deg")
    |> expect_optional_number(callbacks, path, activity, "target_longitude_deg")
    |> expect_optional_number(callbacks, path, activity, "target_minimum_elevation_deg")
    |> expect_optional_integer(callbacks, path, activity, "observation_objective_count")
    |> expect_optional_type(callbacks, path, activity, "observation_objective_source", :binary)
    |> expect_optional_type(callbacks, path, activity, "observation_objective_types", :list)
    |> validate_string_list_items(callbacks, path, activity, "observation_objective_types")
    |> expect_optional_type(callbacks, path, activity, "observation_objective_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, activity, "observation_objective_ids")
    |> expect_optional_integer(callbacks, path, activity, "collection_latency_objective_count")
    |> expect_optional_type(
      callbacks,
      path,
      activity,
      "collection_latency_objective_source",
      :binary
    )
    |> expect_optional_type(
      callbacks,
      path,
      activity,
      "collection_latency_objective_types",
      :list
    )
    |> validate_string_list_items(callbacks, path, activity, "collection_latency_objective_types")
    |> expect_optional_type(callbacks, path, activity, "collection_latency_objective_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      activity,
      "collection_latency_objective_ids"
    )
    |> expect_optional_number(callbacks, path, activity, "required_downlink_mb")
    |> expect_optional_number(callbacks, path, activity, "required_observations")
    |> expect_optional_number(callbacks, path, activity, "max_latency_s")
    |> expect_optional_probability(callbacks, path, activity, "eclipse_overlap_fraction")
    |> expect_optional_number_or_string(callbacks, path, activity, "lighting_confidence")
    |> expect_optional_probability(callbacks, path, activity, "cloud_cover_fraction")
    |> expect_optional_probability(callbacks, path, activity, "blur_score")
    |> expect_field_at_least(callbacks, path, activity, "observation_objective_count", 0)
    |> expect_field_at_least(callbacks, path, activity, "collection_latency_objective_count", 0)
    |> expect_field_at_least(callbacks, path, activity, "required_downlink_mb", 0)
    |> expect_field_at_least(callbacks, path, activity, "required_observations", 0)
    |> expect_field_at_least(callbacks, path, activity, "max_latency_s", 0)
    |> validate_score(callbacks, path, activity)
    |> validate_source_window_identity(callbacks, path, activity)
  end

  defp validate_score(issues, callbacks, path, %{"score" => score, "score_terms" => terms})
       when is_number(score) and is_map(terms) do
    numeric_terms = Enum.filter(Map.values(terms), &is_number/1)

    if length(numeric_terms) == map_size(terms) do
      expected_score = Enum.sum(numeric_terms)

      if abs(score - expected_score) <= 1.0e-9 do
        issues
      else
        [error(callbacks, path <> ".score", "must equal numeric score_terms sum") | issues]
      end
    else
      issues
    end
  end

  defp validate_score(issues, _callbacks, _path, _activity), do: issues

  defp validate_source_window_identity(
         issues,
         callbacks,
         path,
         %{
           "source_window" => %{} = source_window
         } = activity
       ) do
    expect_field_equals(
      issues,
      callbacks,
      path,
      activity,
      "source_window_id",
      Map.get(source_window, "id"),
      "must match source_window.id"
    )
  end

  defp validate_source_window_identity(issues, _callbacks, _path, _activity), do: issues

  defp validate_activity(issues, callbacks, path, activity),
    do: apply(Keyword.fetch!(callbacks, :validate_activity), [issues, path, activity])

  defp validate_optional_schema_contract(issues, callbacks, path, map, expected) do
    apply(Keyword.fetch!(callbacks, :validate_optional_schema_contract), [
      issues,
      path,
      map,
      expected
    ])
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_probability), [issues, path, map, field])

  defp expect_optional_number_or_string(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_optional_number_or_string), [
      issues,
      path,
      map,
      field
    ])
  end

  defp expect_field_at_least(issues, callbacks, path, map, field, minimum),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_at_least), [issues, path, map, field, minimum])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
