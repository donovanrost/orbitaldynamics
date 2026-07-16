defmodule OrbitalDynamics.Schema.OperationalExecutionBoundarySummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalReadinessClassificationContracts,
    as: ReadinessClassification

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_list: 3, validate_stable_ids: 4]

  def validate_summary(issues, path, summary, model_limits, gate_validator)
      when is_list(model_limits) and is_function(gate_validator, 3) do
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "operational_execution_boundary_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_operational_execution_boundary_summary"
    )
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
    |> expect_type(path, summary, "handoff_only", :boolean)
    |> expect_type(path, summary, "execution_allowed", :boolean)
    |> expect_type(path, summary, "cadence_write_allowed", :boolean)
    |> expect_type(path, summary, "operator_authority_granted", :boolean)
    |> expect_one_of(path, summary, "execution_boundary", [
      "adapter_handoff_only",
      "operator_review_required_before_import",
      "analysis_only_not_for_execution",
      "blocked_not_for_import_or_execution"
    ])
    |> expect_optional_one_of(
      path,
      summary,
      "analysis_mode",
      capability.analysis_modes
    )
    |> expect_optional_type(path, summary, "analysis_mode_source", :binary)
    |> expect_type(path, summary, "operational_mode_gate", :map)
    |> gate_validator.(
      path <> ".operational_mode_gate",
      Map.get(summary, "operational_mode_gate")
    )
    |> expect_non_negative_integer(path, summary, "gate_count")
    |> expect_non_negative_integer(path, summary, "passed_gate_count")
    |> expect_non_negative_integer(path, summary, "review_gate_count")
    |> expect_non_negative_integer(path, summary, "analysis_gate_count")
    |> expect_non_negative_integer(path, summary, "blocked_gate_count")
    |> expect_non_negative_integer(path, summary, "non_passed_gate_count")
    |> expect_type(path, summary, "non_passed_gate_ids", :list)
    |> validate_stable_id_list(
      path <> ".non_passed_gate_ids",
      Map.get(summary, "non_passed_gate_ids")
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match operational execution boundary summary model limits"
    )
    |> validate_assumptions(path, summary)
    |> validate_classification(path, summary)
    |> validate_counts(path, summary)
    |> validate_mode(path, summary)
  end

  defp validate_assumptions(issues, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        [
          {"execution_boundary", "artifact_only_no_cadence_write_no_command_execution"},
          {"source", "operational_readiness_report.v1"},
          {"operator_authority", "not_granted_by_execution_boundary_summary"},
          {"cadence_write", "not_performed_by_summary"},
          {"command_execution", "not_performed_by_summary"}
        ]
        |> Enum.reduce(issues, fn {field, expected}, acc ->
          expect_equal(acc, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_classification(issues, path, summary) do
    import_classification = Map.get(summary, "import_classification")

    issues
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
      "execution_boundary",
      quality_gate_execution_boundary(import_classification),
      "must match import classification"
    )
    |> expect_field_equals(
      path,
      summary,
      "import_eligible",
      import_classification == "importable",
      "must match import classification"
    )
    |> expect_field_equals(path, summary, "handoff_only", true)
    |> expect_field_equals(path, summary, "execution_allowed", false)
    |> expect_field_equals(path, summary, "cadence_write_allowed", false)
    |> expect_field_equals(path, summary, "operator_authority_granted", false)
  end

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
      length(list_or_empty(Map.get(summary, "non_passed_gate_ids"))),
      "must equal non-passed gate ID count"
    )
  end

  defp validate_mode(issues, path, summary) do
    operational_mode_gate = Map.get(summary, "operational_mode_gate")

    issues =
      case operational_mode_gate do
        %{} = gate ->
          issues
          |> expect_equal(
            path <> ".operational_mode_gate",
            gate,
            "id",
            "operational_mode"
          )
          |> expect_field_equals(
            path,
            summary,
            "analysis_mode",
            Map.get(gate, "analysis_mode"),
            "must match operational_mode_gate.analysis_mode"
          )
          |> expect_field_equals(
            path,
            summary,
            "analysis_mode_source",
            Map.get(gate, "analysis_mode_source"),
            "must match operational_mode_gate.analysis_mode_source"
          )

        _gate ->
          issues
      end

    if is_map(operational_mode_gate) and
         is_binary(Map.get(operational_mode_gate, "analysis_mode")) and
         not Map.has_key?(summary, "analysis_mode") do
      [
        error(
          path <> ".analysis_mode",
          "must match operational_mode_gate.analysis_mode"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp quality_gate_execution_boundary("importable"), do: "adapter_handoff_only"

  defp quality_gate_execution_boundary("review_only"),
    do: "operator_review_required_before_import"

  defp quality_gate_execution_boundary("analysis_only"), do: "analysis_only_not_for_execution"
  defp quality_gate_execution_boundary("blocked"), do: "blocked_not_for_import_or_execution"

  defp non_negative_integer_sum(values) do
    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)), do: Enum.sum(values)
  end
end
