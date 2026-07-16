defmodule OrbitalDynamics.Schema.OperationalImportEligibilitySummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalReadinessClassificationContracts,
    as: ReadinessClassification

  alias OrbitalDynamics.Schema.OperationalReadinessReportContracts,
    as: ReadinessReport

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate_summary(issues, path, summary, model_limits, gate_validator)
      when is_list(model_limits) and is_function(gate_validator, 3) do
    non_passed_gates = Map.get(summary, "non_passed_gates", [])
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "operational_import_eligibility_summary.v1"
    )
    |> expect_equal(path, summary, "model", "artifact_only_import_eligibility_summary")
    |> expect_equal(path, summary, "source", "operational_readiness_report.v1")
    |> expect_type(path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(path, summary, ["source_artifact_id"])
    |> expect_one_of(path, summary, "readiness_level", capability.readiness_levels)
    |> expect_one_of(
      path,
      summary,
      "import_classification",
      capability.import_classifications
    )
    |> expect_one_of(path, summary, "status", capability.gate_statuses)
    |> expect_type(path, summary, "import_eligible", :boolean)
    |> expect_non_negative_integer(path, summary, "gate_count")
    |> expect_non_negative_integer(path, summary, "passed_gate_count")
    |> expect_non_negative_integer(path, summary, "review_gate_count")
    |> expect_non_negative_integer(path, summary, "analysis_gate_count")
    |> expect_non_negative_integer(path, summary, "blocked_gate_count")
    |> expect_non_negative_integer(path, summary, "non_passed_gate_count")
    |> expect_type(path, summary, "non_passed_gates", :list)
    |> validate_rows(
      path <> ".non_passed_gates",
      non_passed_gates,
      gate_validator
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match operational import eligibility summary model limits"
    )
    |> validate_assumptions(path, summary)
    |> validate_classification(path, summary, non_passed_gates)
    |> validate_counts(path, summary)
  end

  defp validate_assumptions(issues, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        [
          {"execution_boundary", "artifact_only_no_cadence_write"},
          {"source", "operational_readiness_report.v1"},
          {"operator_authority", "not_granted_by_summary"}
        ]
        |> Enum.reduce(issues, fn {field, expected}, acc ->
          expect_equal(acc, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_classification(issues, path, summary, non_passed_gates)
       when is_list(non_passed_gates) do
    import_classification = ReadinessClassification.import_classification(non_passed_gates)

    issues
    |> expect_field_equals(
      path,
      summary,
      "import_classification",
      import_classification,
      "must match non-passed gate-derived import classification"
    )
    |> expect_field_equals(
      path,
      summary,
      "readiness_level",
      ReadinessClassification.readiness_level(import_classification),
      "must match import classification"
    )
    |> expect_field_equals(
      path,
      summary,
      "status",
      ReadinessClassification.report_status(import_classification),
      "must match import classification"
    )
    |> expect_field_equals(
      path,
      summary,
      "import_eligible",
      import_classification == "importable",
      "must match import classification"
    )
  end

  defp validate_classification(issues, __path, _summary, _non_passed_gates), do: issues

  defp validate_counts(issues, path, summary) do
    passed_count = Map.get(summary, "passed_gate_count")
    review_count = Map.get(summary, "review_gate_count")
    analysis_count = Map.get(summary, "analysis_gate_count")
    blocked_count = Map.get(summary, "blocked_gate_count")

    total_count =
      non_negative_integer_sum([
        passed_count,
        review_count,
        analysis_count,
        blocked_count
      ])

    non_passed_count =
      non_negative_integer_sum([review_count, analysis_count, blocked_count])

    non_passed_gates =
      case Map.get(summary, "non_passed_gates", []) do
        gates when is_list(gates) -> Enum.filter(gates, &is_map/1)
        _gates -> []
      end

    issues
    |> expect_field_equals(
      path,
      summary,
      "gate_count",
      total_count,
      "must equal gate status counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "non_passed_gate_count",
      non_passed_count,
      "must equal review, analysis, and blocked gate counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "non_passed_gate_count",
      length(non_passed_gates),
      "must equal non-passed gate row count"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_gate_count",
      ReadinessReport.gate_status_count(non_passed_gates, "review_required"),
      "must equal non-passed review gate count"
    )
    |> expect_field_equals(
      path,
      summary,
      "analysis_gate_count",
      ReadinessReport.gate_status_count(non_passed_gates, "analysis_only"),
      "must equal non-passed analysis gate count"
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_gate_count",
      ReadinessReport.gate_status_count(non_passed_gates, "blocked"),
      "must equal non-passed blocked gate count"
    )
  end

  defp non_negative_integer_sum(values) do
    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)), do: Enum.sum(values)
  end
end
