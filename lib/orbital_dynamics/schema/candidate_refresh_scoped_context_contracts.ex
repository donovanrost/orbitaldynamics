defmodule OrbitalDynamics.Schema.CandidateRefreshScopedContextContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_at_least: 5,
      expect_optional_integer: 4,
      expect_optional_number: 4,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4]

  def validate(issues, path, row) do
    issues
    |> OrbitalDynamics.Schema.ScopedDownlinkContextContracts.validate(path, row)
    |> expect_optional_integer(path, row, "collection_latency_objective_count")
    |> expect_field_at_least(path, row, "collection_latency_objective_count", 0)
    |> expect_optional_type(path, row, "collection_latency_objective_source", :binary)
    |> expect_optional_type(path, row, "collection_latency_objective_types", :list)
    |> validate_string_list_items(path, row, "collection_latency_objective_types")
    |> expect_optional_type(path, row, "collection_latency_objective_ids", :list)
    |> validate_optional_stable_id_list(path, row, "collection_latency_objective_ids")
    |> expect_optional_number(path, row, "candidate_downlink_mb")
    |> expect_optional_probability(path, row, "downlink_completion_ratio")
    |> expect_optional_number(path, row, "selected_downlink_shortfall_mb")
    |> expect_optional_type(path, row, "downlink_requirement_status", :binary)
    |> expect_optional_type(path, row, "downlink_completion_source", :binary)
    |> expect_optional_type(path, row, "downlink_completion_sources", :list)
    |> validate_string_list_items(path, row, "downlink_completion_sources")
    |> expect_field_at_least(path, row, "candidate_downlink_mb", 0)
    |> expect_field_at_least(path, row, "selected_downlink_shortfall_mb", 0)
  end
end
