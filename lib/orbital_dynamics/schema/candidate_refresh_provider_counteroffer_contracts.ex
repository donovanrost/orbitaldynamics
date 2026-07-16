defmodule OrbitalDynamics.Schema.CandidateRefreshProviderCounterofferContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3
    ]

  def validate(issues, path, summary) do
    issues
    |> expect_optional_non_negative_integer(path, summary, "reviewable_count")
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "counteroffer_cost_delta_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "counteroffer_timing_shift_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "counteroffer_start_delta_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "counteroffer_end_delta_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "counteroffer_duration_delta_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "counteroffer_lock_deadline_count"
    )
    |> expect_optional_number(path, summary, "counteroffer_cost_delta_total")
    |> expect_optional_number(path, summary, "earliest_counteroffer_lock_deadline_s")
    |> expect_optional_type(path, summary, "counteroffer_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_status_counts",
      Map.get(summary, "counteroffer_status_counts")
    )
    |> expect_optional_type(path, summary, "required_operator_action_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".required_operator_action_counts",
      Map.get(summary, "required_operator_action_counts")
    )
    |> expect_optional_non_negative_integer(path, summary, "plan_impact_summary_count")
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "import_readiness_summary_count"
    )
    |> validate_non_negative_integer_count_map(
      path <> ".plan_impact_status_counts",
      Map.get(summary, "plan_impact_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".import_readiness_status_counts",
      Map.get(summary, "import_readiness_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".import_classification_counts",
      Map.get(summary, "import_classification_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".provider_counteroffer_import_status_counts",
      Map.get(summary, "provider_counteroffer_import_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_lock_deadline_status_counts",
      Map.get(summary, "counteroffer_lock_deadline_status_counts")
    )
    |> validate_stable_id_array_map(
      path <> ".counteroffer_ids_by_import_status",
      Map.get(summary, "counteroffer_ids_by_import_status")
    )
    |> validate_stable_id_array_map(
      path <> ".counteroffer_ids_by_required_import_action",
      Map.get(summary, "counteroffer_ids_by_required_import_action")
    )
    |> validate_stable_id_array_map(
      path <> ".counteroffer_ids_by_lock_deadline_status",
      Map.get(summary, "counteroffer_ids_by_lock_deadline_status")
    )
    |> validate_stable_id_list(
      path <> ".review_counteroffer_ids",
      Map.get(summary, "review_counteroffer_ids")
    )
    |> validate_stable_id_list(
      path <> ".no_import_required_counteroffer_ids",
      Map.get(summary, "no_import_required_counteroffer_ids")
    )
    |> validate_string_list_items(path, summary, "affected_station_calendar_entry_ids")
    |> validate_string_list_items(path, summary, "affected_provider_entry_ids")
    |> validate_string_list_items(path, summary, "impact_counteroffer_ids")
    |> validate_string_list_items(path, summary, "timing_shift_counteroffer_ids")
    |> validate_string_list_items(path, summary, "cost_delta_counteroffer_ids")
  end
end
