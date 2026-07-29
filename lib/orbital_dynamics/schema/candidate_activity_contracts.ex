defmodule OrbitalDynamics.Schema.CandidateActivityContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_field_at_least: 5,
      expect_field_equals: 6,
      expect_number: 4,
      expect_optional_integer: 4,
      expect_optional_number: 4,
      expect_optional_number_or_string: 4,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(issues, path, activity) do
    issues
    |> OrbitalDynamics.Schema.ActivityContracts.validate(path, activity)
    |> OrbitalDynamics.Schema.SchemaContractField.validate_optional(
      path,
      activity,
      "candidate_activity.v1"
    )
    |> validate_stable_ids(path, activity, [
      "spacecraft_id",
      "source_target_id",
      "collection_id",
      "payload_id",
      "instrument_id"
    ])
    |> validate_optional_stable_id_list(path, activity, "product_ids")
    |> require_fields(path, activity, [
      "duration_s",
      "score",
      "score_terms",
      "source_window_id"
    ])
    |> expect_number(path, activity, "duration_s")
    |> expect_number(path, activity, "score")
    |> expect_type(path, activity, "score_terms", :map)
    |> expect_type(path, activity, "source_window", :map)
    |> expect_optional_number(path, activity, "target_priority")
    |> expect_optional_type(path, activity, "target_priority_source", :binary)
    |> expect_optional_type(path, activity, "target_priority_objective_type", :binary)
    |> expect_optional_type(path, activity, "target_priority_objective_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      activity,
      "target_priority_objective_ids"
    )
    |> expect_optional_type(path, activity, "source_target", :map)
    |> expect_optional_number(path, activity, "target_latitude_deg")
    |> expect_optional_number(path, activity, "target_longitude_deg")
    |> expect_optional_number(path, activity, "target_minimum_elevation_deg")
    |> expect_optional_integer(path, activity, "observation_objective_count")
    |> expect_optional_type(path, activity, "observation_objective_source", :binary)
    |> expect_optional_type(path, activity, "observation_objective_types", :list)
    |> validate_string_list_items(path, activity, "observation_objective_types")
    |> expect_optional_type(path, activity, "observation_objective_ids", :list)
    |> validate_optional_stable_id_list(path, activity, "observation_objective_ids")
    |> expect_optional_integer(path, activity, "collection_latency_objective_count")
    |> expect_optional_type(
      path,
      activity,
      "collection_latency_objective_source",
      :binary
    )
    |> expect_optional_type(
      path,
      activity,
      "collection_latency_objective_types",
      :list
    )
    |> validate_string_list_items(path, activity, "collection_latency_objective_types")
    |> expect_optional_type(path, activity, "collection_latency_objective_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      activity,
      "collection_latency_objective_ids"
    )
    |> expect_optional_number(path, activity, "required_downlink_mb")
    |> expect_optional_number(path, activity, "required_observations")
    |> expect_optional_number(path, activity, "max_latency_s")
    |> expect_optional_probability(path, activity, "eclipse_overlap_fraction")
    |> expect_optional_number_or_string(path, activity, "lighting_confidence")
    |> expect_optional_probability(path, activity, "cloud_cover_fraction")
    |> expect_optional_probability(path, activity, "blur_score")
    |> expect_field_at_least(path, activity, "observation_objective_count", 0)
    |> expect_field_at_least(path, activity, "collection_latency_objective_count", 0)
    |> expect_field_at_least(path, activity, "required_downlink_mb", 0)
    |> expect_field_at_least(path, activity, "required_observations", 0)
    |> expect_field_at_least(path, activity, "max_latency_s", 0)
    |> validate_score(path, activity)
    |> validate_source_window_identity(path, activity)
  end

  @doc false
  def validate_score(issues, path, %{"score" => score, "score_terms" => terms})
      when is_number(score) and is_map(terms) do
    numeric_terms = Enum.filter(Map.values(terms), &is_number/1)

    if length(numeric_terms) == map_size(terms) do
      expected_score = Enum.sum(numeric_terms)

      if abs(score - expected_score) <= 1.0e-9 do
        issues
      else
        [error(path <> ".score", "must equal numeric score_terms sum") | issues]
      end
    else
      issues
    end
  end

  def validate_score(issues, _path, _activity), do: issues

  defp validate_source_window_identity(
         issues,
         path,
         %{
           "source_window" => %{} = source_window
         } = activity
       ) do
    expect_field_equals(
      issues,
      path,
      activity,
      "source_window_id",
      Map.get(source_window, "id"),
      "must match source_window.id"
    )
  end

  defp validate_source_window_identity(issues, _path, _activity), do: issues
end
