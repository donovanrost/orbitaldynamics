defmodule OrbitalDynamics.Schema.CandidateRefreshQualityGateContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_array_map: 3, validate_stable_id_list: 3]

  def validate(issues, path, summary) do
    issues =
      Enum.reduce(
        [
          "gate_count",
          "passed_gate_count",
          "review_gate_count",
          "analysis_gate_count",
          "blocked_gate_count",
          "non_passed_gate_count",
          "source_readiness_report_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, path, summary, field)
        end
      )

    issues =
      Enum.reduce(
        [
          "readiness_level_counts",
          "import_classification_counts",
          "status_counts",
          "gate_status_counts",
          "gate_classification_counts"
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

    issues =
      Enum.reduce(
        [
          "quality_gate_row_ids_by_status",
          "quality_gate_ids_by_status",
          "quality_gate_row_ids_by_classification",
          "quality_gate_ids_by_classification"
        ],
        issues,
        fn field, acc ->
          validate_optional_stable_id_array_map(acc, path, summary, field)
        end
      )

    Enum.reduce(
      [
        "review_required_quality_gate_row_ids",
        "blocked_quality_gate_row_ids",
        "ready_quality_gate_row_ids",
        "analysis_only_quality_gate_row_ids",
        "passed_gate_ids",
        "review_required_gate_ids",
        "analysis_only_gate_ids",
        "blocked_gate_ids",
        "non_passed_gate_ids",
        "non_passed_quality_gate_row_ids",
        "stale_or_unknown_freshness_quality_gate_row_ids",
        "import_preparation_quality_gate_row_ids",
        "blocked_import_quality_gate_row_ids",
        "import_readiness_gate_ids"
      ],
      issues,
      fn field, acc ->
        validate_stable_id_list(acc, path <> ".#{field}", Map.get(summary, field))
      end
    )
    |> validate_string_list_items(path, summary, "schema_validation_status_ids")
    |> validate_string_list_items(path, summary, "freshness_status_ids")
    |> validate_string_list_items(path, summary, "import_status_ids")
    |> validate_string_list_items(path, summary, "cadence_import_status_ids")
  end

  defp validate_optional_stable_id_array_map(issues, path, map, field) do
    issues
    |> expect_optional_type(path, map, field, :map)
    |> validate_stable_id_array_map("#{path}.#{field}", Map.get(map, field))
  end
end
