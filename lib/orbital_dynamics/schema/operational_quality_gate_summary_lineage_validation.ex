defmodule OrbitalDynamics.Schema.OperationalQualityGateSummaryLineageValidation do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.SourceIdentity

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [expect_field_equals: 6]

  def validate(issues, path, summary) do
    case {summary["source_artifact_type"], summary["source_artifact_id"]} do
      {source_artifact_type, source_artifact_id}
      when is_binary(source_artifact_type) and source_artifact_type != "" and
             is_binary(source_artifact_id) and source_artifact_id != "" ->
        issues
        |> expect_field_equals(
          path,
          summary,
          "source_quality_gate_report_id",
          SourceIdentity.quality_gate_report_id(source_artifact_type, source_artifact_id),
          "must match source artifact identity"
        )
        |> expect_field_equals(
          path,
          summary,
          "source_readiness_report_id",
          SourceIdentity.readiness_report_id(source_artifact_type, source_artifact_id),
          "must match source artifact identity"
        )

      _source_identity ->
        issues
    end
  end
end
