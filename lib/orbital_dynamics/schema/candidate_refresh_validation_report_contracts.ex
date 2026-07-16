defmodule OrbitalDynamics.Schema.CandidateRefreshValidationReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_string_list_map: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3
    ]

  def validate_schema_validation(issues, path, summary) do
    issues =
      Enum.reduce(
        [
          "error_count",
          "warning_count",
          "remediation_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, path, summary, field)
        end
      )

    Enum.reduce(
      [
        "status_counts",
        "validated_contract_counts",
        "validation_mode_counts",
        "remediation_action_counts",
        "remediation_category_counts",
        "remediation_path_counts"
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

  def validate_model_acceptance(issues, path, summary) do
    issues
    |> expect_optional_non_negative_integer(path, summary, "record_count")
    |> expect_optional_non_negative_integer(path, summary, "model_count")
    |> expect_optional_non_negative_integer(path, summary, "accepted_count")
    |> expect_optional_non_negative_integer(path, summary, "review_required_count")
    |> expect_optional_non_negative_integer(path, summary, "blocked_count")
    |> expect_optional_non_negative_integer(path, summary, "unknown_model_count")
    |> validate_model_acceptance_count_maps(path, summary)
    |> expect_optional_type(path, summary, "model_ids_by_status", :map)
    |> validate_string_list_map(path, summary, "model_ids_by_status")
    |> expect_optional_type(path, summary, "model_ids_by_validation_level", :map)
    |> validate_string_list_map(path, summary, "model_ids_by_validation_level")
    |> expect_optional_type(path, summary, "model_ids_by_intended_use", :map)
    |> validate_string_list_map(path, summary, "model_ids_by_intended_use")
  end

  def validate_safety_case(issues, path, summary, count_fields) do
    issues
    |> expect_optional_non_negative_integer(path, summary, "accepted_evidence_count")
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "review_required_evidence_count"
    )
    |> expect_optional_non_negative_integer(path, summary, "blocked_evidence_count")
    |> expect_optional_type(path, summary, "status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(summary, "status_counts")
    )
    |> expect_optional_type(path, summary, "evidence_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".evidence_status_counts",
      Map.get(summary, "evidence_status_counts")
    )
    |> expect_optional_type(path, summary, "input_contract_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".input_contract_counts",
      Map.get(summary, "input_contract_counts")
    )
    |> expect_optional_type(path, summary, "evidence_refs_by_status", :map)
    |> validate_string_list_map(path, summary, "evidence_refs_by_status")
    |> expect_optional_type(path, summary, "evidence_refs_by_contract", :map)
    |> validate_string_list_map(path, summary, "evidence_refs_by_contract")
    |> validate_safety_case_counts(count_fields, path, summary)
  end

  defp validate_model_acceptance_count_maps(issues, path, summary) do
    Enum.reduce(
      [
        "intended_use_counts",
        "status_counts",
        "validation_level_counts"
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

  defp validate_safety_case_counts(issues, count_fields, path, summary) do
    Enum.reduce(count_fields.(), issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, summary, field)
    end)
  end
end
