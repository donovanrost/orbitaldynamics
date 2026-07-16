defmodule OrbitalDynamics.Schema.ScopedDownlinkContextContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_optional_number: 4, expect_optional_type: 5, validate_string_list_items: 4]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

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

  def validate(issues, path, row) do
    issues
    |> validate_stable_ids(path, row, @stable_id_fields)
    |> expect_optional_type(path, row, "target_ids", :list)
    |> validate_optional_stable_id_list(path, row, "target_ids")
    |> expect_optional_type(path, row, "collection_ids", :list)
    |> validate_optional_stable_id_list(path, row, "collection_ids")
    |> expect_optional_type(path, row, "product_ids", :list)
    |> validate_optional_stable_id_list(path, row, "product_ids")
    |> expect_optional_type(path, row, "payload_ids", :list)
    |> validate_optional_stable_id_list(path, row, "payload_ids")
    |> expect_optional_type(path, row, "instrument_ids", :list)
    |> validate_optional_stable_id_list(path, row, "instrument_ids")
    |> expect_optional_type(path, row, "objective_ids", :list)
    |> validate_optional_stable_id_list(path, row, "objective_ids")
    |> expect_optional_type(path, row, "objective_type", :binary)
    |> expect_optional_type(path, row, "objective_types", :list)
    |> validate_string_list_items(path, row, "objective_types")
    |> expect_optional_type(path, row, "objective_status", :binary)
    |> expect_optional_type(path, row, "objective_statuses", :list)
    |> validate_string_list_items(path, row, "objective_statuses")
    |> expect_optional_type(path, row, "source_objective_status", :binary)
    |> expect_optional_type(path, row, "source_objective_statuses", :list)
    |> validate_string_list_items(path, row, "source_objective_statuses")
    |> expect_optional_type(path, row, "latency_objective", :boolean)
    |> expect_optional_number(path, row, "max_latency_s")
    |> expect_optional_number(path, row, "planned_latency_s")
    |> expect_optional_number(path, row, "required_contacts")
    |> expect_optional_number(path, row, "planned_contacts")
    |> expect_optional_number(path, row, "required_downlink_mb")
    |> expect_optional_number(path, row, "planned_downlink_mb")
    |> expect_optional_type(path, row, "contact_result", :binary)
    |> expect_optional_type(path, row, "contact_results", :list)
    |> validate_string_list_items(path, row, "contact_results")
    |> expect_optional_type(path, row, "realized_status", :binary)
    |> expect_optional_type(path, row, "realized_statuses", :list)
    |> validate_string_list_items(path, row, "realized_statuses")
    |> expect_optional_type(path, row, "source_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "source_activity_ids")
    |> expect_optional_type(path, row, "missed_downlink_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "missed_downlink_activity_ids")
    |> expect_optional_type(path, row, "feedback_source", :binary)
    |> expect_optional_type(path, row, "feedback_sources", :list)
    |> validate_string_list_items(path, row, "feedback_sources")
    |> expect_optional_type(path, row, "feedback_scope", :binary)
    |> expect_optional_type(path, row, "feedback_scopes", :list)
    |> validate_string_list_items(path, row, "feedback_scopes")
    |> expect_optional_type(path, row, "trust_boundary", :binary)
    |> expect_optional_type(path, row, "trust_boundaries", :list)
    |> validate_string_list_items(path, row, "trust_boundaries")
    |> expect_optional_type(path, row, "derivation_reasons", :list)
    |> validate_string_list_items(path, row, "derivation_reasons")
  end
end
