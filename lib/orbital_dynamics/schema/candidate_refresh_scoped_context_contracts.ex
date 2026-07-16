defmodule OrbitalDynamics.Schema.CandidateRefreshScopedContextContracts do
  @moduledoc false

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> validate_scoped_downlink_context_fields(callbacks, path, row)
    |> expect_optional_integer(callbacks, path, row, "collection_latency_objective_count")
    |> expect_field_at_least(callbacks, path, row, "collection_latency_objective_count", 0)
    |> expect_optional_type(callbacks, path, row, "collection_latency_objective_source", :binary)
    |> expect_optional_type(callbacks, path, row, "collection_latency_objective_types", :list)
    |> validate_string_list_items(callbacks, path, row, "collection_latency_objective_types")
    |> expect_optional_type(callbacks, path, row, "collection_latency_objective_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "collection_latency_objective_ids")
    |> expect_optional_number(callbacks, path, row, "candidate_downlink_mb")
    |> expect_optional_probability(callbacks, path, row, "downlink_completion_ratio")
    |> expect_optional_number(callbacks, path, row, "selected_downlink_shortfall_mb")
    |> expect_optional_type(callbacks, path, row, "downlink_requirement_status", :binary)
    |> expect_optional_type(callbacks, path, row, "downlink_completion_source", :binary)
    |> expect_optional_type(callbacks, path, row, "downlink_completion_sources", :list)
    |> validate_string_list_items(callbacks, path, row, "downlink_completion_sources")
    |> expect_field_at_least(callbacks, path, row, "candidate_downlink_mb", 0)
    |> expect_field_at_least(callbacks, path, row, "selected_downlink_shortfall_mb", 0)
  end

  defp validate_scoped_downlink_context_fields(issues, callbacks, path, row),
    do:
      apply(require_callback(callbacks, :validate_scoped_downlink_context_fields), [
        issues,
        path,
        row
      ])

  defp expect_optional_integer(issues, callbacks, path, row, field),
    do: apply(require_callback(callbacks, :expect_optional_integer), [issues, path, row, field])

  defp expect_field_at_least(issues, callbacks, path, row, field, minimum),
    do:
      apply(require_callback(callbacks, :expect_field_at_least), [
        issues,
        path,
        row,
        field,
        minimum
      ])

  defp expect_optional_type(issues, callbacks, path, row, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        row,
        field,
        type
      ])

  defp validate_string_list_items(issues, callbacks, path, row, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [
        issues,
        path,
        row,
        field
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, row, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        row,
        field
      ])

  defp expect_optional_number(issues, callbacks, path, row, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, row, field])

  defp expect_optional_probability(issues, callbacks, path, row, field),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [
        issues,
        path,
        row,
        field
      ])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
