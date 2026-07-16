defmodule OrbitalDynamics.Schema.CandidateRefreshResourceSignalContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [validate_non_negative_integer_count_map: 3]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_list: 3]

  def validate_link_capacity(issues, path, summary) do
    validate_count_maps(issues, path, summary, [
      "ground_station_counts",
      "target_counts",
      "collection_counts",
      "selected_contact_id_counts",
      "actual_throughput_contact_id_counts"
    ])
  end

  def validate_constraint(issues, path, summary) do
    validate_count_maps(issues, path, summary, [
      "constraint_metric_counts",
      "constraint_resource_counts",
      "constraint_spacecraft_counts"
    ])
  end

  def validate_resource_projection(issues, path, summary) do
    validate_count_maps(issues, path, summary, [
      "resource_projection_spacecraft_counts",
      "resource_pressure_type_counts",
      "resource_pressure_activity_id_counts"
    ])
  end

  def validate_resource_filter(issues, path, summary) do
    issues
    |> validate_count_maps(path, summary, [
      "resource_filter_spacecraft_counts",
      "resource_filter_resource_counts",
      "resource_filter_blocking_dimension_counts"
    ])
    |> validate_stable_id_list(
      path <> ".invalid_resource_summary_input_ids",
      Map.get(summary, "invalid_resource_summary_input_ids")
    )
  end

  defp validate_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_non_negative_integer_count_map(acc, path <> ".#{field}", Map.get(summary, field))
    end)
  end
end
