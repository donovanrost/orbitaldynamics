defmodule OrbitalDynamics.Schema.CandidateRefreshCandidateSelectionContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_list: 3]

  def validate_freshness(issues, path, summary) do
    issues
    |> expect_optional_non_negative_integer(path, summary, "stale_reason_count")
    |> expect_optional_non_negative_integer(path, summary, "unknown_reason_count")
    |> validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(summary, "status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".stale_reason_counts",
      Map.get(summary, "stale_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".unknown_reason_counts",
      Map.get(summary, "unknown_reason_counts")
    )
    |> validate_string_list_items(path, summary, "stale_reasons")
    |> validate_string_list_items(path, summary, "unknown_reasons")
  end

  def validate_refresh_budget(issues, path, summary) do
    issues =
      Enum.reduce(
        [
          "input_candidate_count",
          "kept_candidate_count",
          "dropped_candidate_count",
          "invalid_candidate_limit_policy_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, path, summary, field)
        end
      )

    issues
    |> validate_non_negative_integer_count_map(
      path <> ".invalid_candidate_limit_policy_reason_counts",
      Map.get(summary, "invalid_candidate_limit_policy_reason_counts")
    )
    |> validate_stable_id_list(
      path <> ".kept_candidate_ids",
      Map.get(summary, "kept_candidate_ids")
    )
    |> validate_stable_id_list(
      path <> ".dropped_candidate_ids",
      Map.get(summary, "dropped_candidate_ids")
    )
  end

  def validate_candidate_rejection(issues, path, summary) do
    issues
    |> validate_non_negative_integer_count_map(
      path <> ".candidate_rejection_candidate_id_counts",
      Map.get(summary, "candidate_rejection_candidate_id_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".candidate_rejection_ground_station_counts",
      Map.get(summary, "candidate_rejection_ground_station_counts")
    )
  end
end
