defmodule OrbitalDynamics.Schema.CandidateRefreshOperationalTimelineContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  def validate(issues, path, summary) do
    issues
    |> expect_optional_type(path, summary, "input_keys", :list)
    |> validate_string_list_items(path, summary, "input_keys")
    |> expect_optional_non_negative_integer(path, summary, "contact_feedback_count")
    |> expect_optional_non_negative_integer(path, summary, "command_feedback_count")
    |> expect_optional_non_negative_integer(path, summary, "maneuver_feedback_count")
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "observation_feedback_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "station_throughput_feedback_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "timeline_integrity_issue_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "dependency_integrity_issue_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "exclusivity_integrity_issue_count"
    )
    |> validate_count_maps(path, summary)
  end

  defp validate_count_maps(issues, path, summary) do
    Enum.reduce(
      [
        "operational_kind_counts",
        "activity_id_counts",
        "activity_status_counts",
        "approval_status_counts",
        "required_operator_action_counts",
        "cadence_import_status_counts",
        "timeline_integrity_issue_type_counts"
      ],
      issues,
      fn field, acc ->
        acc
        |> expect_optional_type(path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end
    )
  end
end
