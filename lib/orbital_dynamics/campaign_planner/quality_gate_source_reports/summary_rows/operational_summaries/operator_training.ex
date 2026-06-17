defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.OperatorTraining do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.Common

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_operator_training_summary.v1"} = summary
      ) do
    summary = Common.stringify_keys(summary)

    case operator_training_summary_gate_status(summary) do
      nil ->
        []

      gate_status ->
        gate_classification = Common.quality_gate_status_classification(gate_status)

        [
          %{
            "source" => "operational_quality_gate_operator_training_summary",
            "report_id" => summary["source_quality_gate_report_id"],
            "source_artifact_type" => summary["source_artifact_type"],
            "source_artifact_id" => summary["source_artifact_id"],
            "source_readiness_report_id" => summary["source_readiness_report_id"],
            "readiness_level" => Common.quality_gate_status_readiness_level(gate_status),
            "import_classification" => gate_classification,
            "quality_gate_status" => gate_status,
            "gate_count" => summary["operator_training_row_count"],
            "review_gate_count" => length(summary["review_required_quality_gate_row_ids"] || []),
            "analysis_gate_count" =>
              length(get_in(summary, ["quality_gate_row_ids_by_status", "analysis_only"]) || []),
            "blocked_gate_count" => length(summary["blocked_quality_gate_row_ids"] || []),
            "gate_id" => single_operator_training_gate_id(summary["operator_training_gate_ids"]),
            "gate_status" => gate_status,
            "gate_classification" => gate_classification,
            "gate_reason" => operator_training_summary_gate_reason(gate_status),
            "operator_training_requirement_count" =>
              summary["operator_training_requirement_count"],
            "operator_training_requirement_counts" =>
              summary["operator_training_requirement_counts"],
            "required_operator_roles" => summary["required_operator_roles"],
            "required_training_ids" => summary["required_training_ids"],
            "required_certification_ids" => summary["required_certification_ids"],
            "required_qualification_ids" => summary["required_qualification_ids"],
            "assumptions" => summary["assumptions"],
            "source_quality_gate_row" => operator_training_summary_source_row(summary),
            "source_quality_gate_report" => summary
          }
          |> Common.compact_map()
        ]
    end
  end

  defp operator_training_summary_gate_status(summary) do
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

  defp operator_training_summary_gate_reason("blocked"),
    do: "operator training summary blocks import"

  defp operator_training_summary_gate_reason("analysis_only"),
    do: "operator training summary requires analysis"

  defp operator_training_summary_gate_reason(_status),
    do: "operator training summary requires review"

  defp single_operator_training_gate_id([id | _rest]) when id not in [nil, ""], do: id
  defp single_operator_training_gate_id(_ids), do: "operator_training"

  defp operator_training_summary_source_row(summary) do
    %{
      "gate_id" => single_operator_training_gate_id(summary["operator_training_gate_ids"]),
      "quality_gate_row_ids_by_status" => summary["quality_gate_row_ids_by_status"],
      "quality_gate_row_ids_by_classification" =>
        summary["quality_gate_row_ids_by_classification"],
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "quality_gate_ids_by_classification" => summary["quality_gate_ids_by_classification"],
      "review_required_quality_gate_row_ids" => summary["review_required_quality_gate_row_ids"],
      "blocked_quality_gate_row_ids" => summary["blocked_quality_gate_row_ids"],
      "review_only_quality_gate_row_ids" => summary["review_only_quality_gate_row_ids"],
      "operator_training_gate_ids" => summary["operator_training_gate_ids"]
    }
    |> Common.compact_map()
  end
end
