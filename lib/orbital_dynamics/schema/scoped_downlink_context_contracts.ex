defmodule OrbitalDynamics.Schema.ScopedDownlinkContextContracts do
  @moduledoc false

  @stable_id_fields [
    "target_id",
    "collection_id",
    "product_id",
    "payload_id",
    "instrument_id",
    "objective_id",
    "source_activity_id",
    "missed_downlink_activity_id"
  ]

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, row, @stable_id_fields)
    |> expect_optional_type(callbacks, path, row, "target_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "target_ids")
    |> expect_optional_type(callbacks, path, row, "collection_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "collection_ids")
    |> expect_optional_type(callbacks, path, row, "product_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "product_ids")
    |> expect_optional_type(callbacks, path, row, "payload_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "payload_ids")
    |> expect_optional_type(callbacks, path, row, "instrument_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "instrument_ids")
    |> expect_optional_type(callbacks, path, row, "objective_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "objective_ids")
    |> expect_optional_type(callbacks, path, row, "objective_type", :binary)
    |> expect_optional_type(callbacks, path, row, "objective_types", :list)
    |> validate_string_list_items(callbacks, path, row, "objective_types")
    |> expect_optional_type(callbacks, path, row, "objective_status", :binary)
    |> expect_optional_type(callbacks, path, row, "objective_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "objective_statuses")
    |> expect_optional_type(callbacks, path, row, "source_objective_status", :binary)
    |> expect_optional_type(callbacks, path, row, "source_objective_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "source_objective_statuses")
    |> expect_optional_type(callbacks, path, row, "latency_objective", :boolean)
    |> expect_optional_number(callbacks, path, row, "max_latency_s")
    |> expect_optional_number(callbacks, path, row, "planned_latency_s")
    |> expect_optional_number(callbacks, path, row, "required_contacts")
    |> expect_optional_number(callbacks, path, row, "planned_contacts")
    |> expect_optional_number(callbacks, path, row, "required_downlink_mb")
    |> expect_optional_number(callbacks, path, row, "planned_downlink_mb")
    |> expect_optional_type(callbacks, path, row, "contact_result", :binary)
    |> expect_optional_type(callbacks, path, row, "contact_results", :list)
    |> validate_string_list_items(callbacks, path, row, "contact_results")
    |> expect_optional_type(callbacks, path, row, "realized_status", :binary)
    |> expect_optional_type(callbacks, path, row, "realized_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "realized_statuses")
    |> expect_optional_type(callbacks, path, row, "source_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "source_activity_ids")
    |> expect_optional_type(callbacks, path, row, "missed_downlink_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "missed_downlink_activity_ids")
    |> expect_optional_type(callbacks, path, row, "feedback_source", :binary)
    |> expect_optional_type(callbacks, path, row, "feedback_sources", :list)
    |> validate_string_list_items(callbacks, path, row, "feedback_sources")
    |> expect_optional_type(callbacks, path, row, "feedback_scope", :binary)
    |> expect_optional_type(callbacks, path, row, "feedback_scopes", :list)
    |> validate_string_list_items(callbacks, path, row, "feedback_scopes")
    |> expect_optional_type(callbacks, path, row, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, row, "trust_boundaries", :list)
    |> validate_string_list_items(callbacks, path, row, "trust_boundaries")
    |> expect_optional_type(callbacks, path, row, "derivation_reasons", :list)
    |> validate_string_list_items(callbacks, path, row, "derivation_reasons")
  end

  defp validate_stable_ids(issues, callbacks, path, row, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, row, fields])

  defp expect_optional_type(issues, callbacks, path, row, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        row,
        field,
        type
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, row, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        row,
        field
      ])

  defp validate_string_list_items(issues, callbacks, path, row, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [
        issues,
        path,
        row,
        field
      ])

  defp expect_optional_number(issues, callbacks, path, row, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, row, field])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
