defmodule OrbitalDynamics.Schema.OperationalReadinessReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_type: 5,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  alias OrbitalDynamics.Schema.OperationalReadinessClassificationContracts
  alias OrbitalDynamics.Schema.OperationalReadinessEvidenceContracts
  alias OrbitalDynamics.OperationalReadiness.SourceIdentity

  def validate(issues, path, report, model_limits, gate_validator, evidence_validator) do
    gates = Map.get(report, "gates", [])
    evidence = Map.get(report, "evidence", %{})
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(path, report, "schema_contract", "operational_readiness_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "artifact_only_operational_readiness_classifier"
    )
    |> validate_stable_ids(path, report, ["report_id", "source_artifact_id"])
    |> validate_report_identity(path, report)
    |> expect_one_of(path, report, "readiness_level", capability.readiness_levels)
    |> expect_one_of(
      path,
      report,
      "import_classification",
      capability.import_classifications
    )
    |> expect_one_of(path, report, "status", capability.gate_statuses)
    |> expect_non_negative_integer(path, report, "gate_count")
    |> expect_non_negative_integer(path, report, "passed_gate_count")
    |> expect_non_negative_integer(path, report, "review_gate_count")
    |> expect_non_negative_integer(path, report, "analysis_gate_count")
    |> expect_non_negative_integer(path, report, "blocked_gate_count")
    |> expect_type(path, report, "gates", :list)
    |> validate_rows(path <> ".gates", gates, gate_validator)
    |> expect_type(path, report, "evidence", :map)
    |> evidence_validator.(path <> ".evidence", evidence)
    |> expect_type(path, report, "assumptions", :list)
    |> validate_string_list_items(path, report, "assumptions")
    |> expect_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      model_limits,
      "must match operational readiness model limits"
    )
    |> OperationalReadinessClassificationContracts.validate_assumptions(path, report)
    |> OperationalReadinessClassificationContracts.validate_classification(path, report, gates)
    |> OperationalReadinessEvidenceContracts.validate_gate_counts(
      path <> ".evidence",
      evidence,
      gates
    )
    |> expect_field_equals(
      path,
      report,
      "gate_count",
      if(is_list(gates), do: length(gates))
    )
    |> expect_field_equals(
      path,
      report,
      "passed_gate_count",
      gate_status_count(gates, "passed")
    )
    |> expect_field_equals(
      path,
      report,
      "review_gate_count",
      gate_status_count(gates, "review_required")
    )
    |> expect_field_equals(
      path,
      report,
      "analysis_gate_count",
      gate_status_count(gates, "analysis_only")
    )
    |> expect_field_equals(
      path,
      report,
      "blocked_gate_count",
      gate_status_count(gates, "blocked")
    )
  end

  def gate_status_count(gates, status) when is_list(gates) do
    gates
    |> Enum.filter(&is_map/1)
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  def gate_status_count(_gates, _status), do: nil

  defp validate_report_identity(issues, path, report) do
    case {report["source_artifact_type"], report["source_artifact_id"]} do
      {source_artifact_type, source_artifact_id}
      when is_binary(source_artifact_type) and source_artifact_type != "" and
             is_binary(source_artifact_id) and source_artifact_id != "" ->
        expect_field_equals(
          issues,
          path,
          report,
          "report_id",
          SourceIdentity.readiness_report_id(source_artifact_type, source_artifact_id),
          "must match source artifact identity"
        )

      _source_identity ->
        issues
    end
  end

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
