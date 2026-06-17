defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.SchemaValidation do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.Common

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_schema_validation_summary.v1"} = summary
      ) do
    summary = Common.stringify_keys(summary)

    case schema_validation_summary_gate_status(summary) do
      nil ->
        []

      gate_status ->
        gate_classification = Common.quality_gate_status_classification(gate_status)

        [
          %{
            "source" => "operational_quality_gate_schema_validation_summary",
            "report_id" => summary["source_quality_gate_report_id"],
            "source_artifact_type" => summary["source_artifact_type"],
            "source_artifact_id" => summary["source_artifact_id"],
            "source_readiness_report_id" => summary["source_readiness_report_id"],
            "readiness_level" => Common.quality_gate_status_readiness_level(gate_status),
            "import_classification" => gate_classification,
            "quality_gate_status" => gate_status,
            "gate_count" => summary["schema_validation_row_count"],
            "review_gate_count" => length(summary["review_required_quality_gate_row_ids"] || []),
            "analysis_gate_count" =>
              length(get_in(summary, ["quality_gate_row_ids_by_status", "analysis_only"]) || []),
            "blocked_gate_count" => length(summary["blocked_quality_gate_row_ids"] || []),
            "gate_id" => single_schema_validation_gate_id(summary["schema_validation_gate_ids"]),
            "gate_status" => gate_status,
            "gate_classification" => gate_classification,
            "gate_reason" => schema_validation_summary_gate_reason(gate_status),
            "schema_validation_row_count" => summary["schema_validation_row_count"],
            "schema_validation_pass_count" => summary["schema_validation_pass_count"],
            "schema_validation_fail_count" => summary["schema_validation_fail_count"],
            "schema_validation_error_count" => summary["schema_validation_error_count"],
            "schema_validation_warning_count" => summary["schema_validation_warning_count"],
            "schema_validation_remediation_count" =>
              summary["schema_validation_remediation_count"],
            "schema_validation_status_counts" => summary["schema_validation_status_counts"],
            "schema_validation_status_ids" => summary["schema_validation_status_ids"],
            "schema_validation_import_blocked" => summary["schema_validation_import_blocked"],
            "failed_schema_validation_quality_gate_row_ids" =>
              summary["failed_schema_validation_quality_gate_row_ids"],
            "assumptions" => summary["assumptions"],
            "source_quality_gate_row" => schema_validation_summary_source_row(summary),
            "source_quality_gate_report" => summary
          }
          |> Common.compact_map()
        ]
    end
  end

  defp schema_validation_summary_gate_status(summary) do
    cond do
      length(summary["blocked_quality_gate_row_ids"] || []) > 0 ->
        "blocked"

      length(get_in(summary, ["quality_gate_row_ids_by_status", "analysis_only"]) || []) > 0 ->
        "analysis_only"

      length(summary["review_required_quality_gate_row_ids"] || []) > 0 ->
        "review_required"

      true ->
        nil
    end
  end

  defp schema_validation_summary_gate_reason("blocked"),
    do: "schema validation summary blocks import"

  defp schema_validation_summary_gate_reason("analysis_only"),
    do: "schema validation summary requires analysis"

  defp schema_validation_summary_gate_reason(_status),
    do: "schema validation summary requires review"

  defp single_schema_validation_gate_id([id | _rest]) when id not in [nil, ""], do: id
  defp single_schema_validation_gate_id(_ids), do: "cadence_import"

  defp schema_validation_summary_source_row(summary) do
    %{
      "gate_id" => single_schema_validation_gate_id(summary["schema_validation_gate_ids"]),
      "quality_gate_row_ids_by_status" => summary["quality_gate_row_ids_by_status"],
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "blocked_quality_gate_row_ids" => summary["blocked_quality_gate_row_ids"],
      "review_required_quality_gate_row_ids" => summary["review_required_quality_gate_row_ids"],
      "failed_schema_validation_quality_gate_row_ids" =>
        summary["failed_schema_validation_quality_gate_row_ids"],
      "schema_validation_gate_ids" => summary["schema_validation_gate_ids"]
    }
    |> Common.compact_map()
  end
end
