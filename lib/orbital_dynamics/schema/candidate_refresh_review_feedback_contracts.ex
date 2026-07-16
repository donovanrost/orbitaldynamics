defmodule OrbitalDynamics.Schema.CandidateRefreshReviewFeedbackContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  def validate_timeline_feedback(issues, path, summary) do
    issues
    |> expect_optional_type(path, summary, "input_keys", :list)
    |> validate_string_list_items(path, summary, "input_keys")
    |> validate_optional_count_maps(path, summary, [
      "status_counts",
      "feedback_kind_counts",
      "match_strategy_counts",
      "activity_id_counts",
      "cadence_import_status_counts"
    ])
  end

  def validate_maneuver_review(issues, path, summary) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "maneuver_success_feedback_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "execution_uncertainty_declared_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "execution_uncertainty_missing_count"
    )
    |> expect_optional_type(path, summary, "input_keys", :list)
    |> validate_string_list_items(path, summary, "input_keys")
    |> validate_optional_count_maps(path, summary, [
      "maneuver_id_counts",
      "required_operator_action_counts"
    ])
  end

  defp validate_optional_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, summary, field, :map)
      |> validate_non_negative_integer_count_map(
        path <> ".#{field}",
        Map.get(summary, field)
      )
    end)
  end
end
