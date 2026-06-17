defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.ImportReadiness do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.Common
  alias __MODULE__.StatusRows

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_import_readiness_summary.v1"} = summary
      ) do
    summary = Common.stringify_keys(summary)

    case StatusRows.gate_status(summary) do
      nil ->
        []

      gate_status ->
        gate_classification = Common.quality_gate_status_classification(gate_status)

        review_required_quality_gate_row_ids =
          StatusRows.quality_gate_status_row_ids(summary, "review_required")

        analysis_only_quality_gate_row_ids =
          StatusRows.quality_gate_status_row_ids(summary, "analysis_only")

        blocked_quality_gate_row_ids = StatusRows.quality_gate_status_row_ids(summary, "blocked")

        stale_or_unknown_freshness_quality_gate_row_ids =
          StatusRows.quality_gate_status_scoped_row_ids(
            summary,
            "stale_or_unknown_freshness_quality_gate_row_ids",
            ["review_required", "blocked"]
          )

        import_preparation_quality_gate_row_ids =
          StatusRows.quality_gate_status_scoped_row_ids(
            summary,
            "import_preparation_quality_gate_row_ids",
            ["review_required"]
          )

        blocked_import_quality_gate_row_ids =
          StatusRows.quality_gate_status_scoped_row_ids(
            summary,
            "blocked_import_quality_gate_row_ids",
            ["blocked"]
          )

        [
          %{
            "source" => "operational_quality_gate_import_readiness_summary",
            "report_id" => summary["source_quality_gate_report_id"],
            "source_artifact_type" => summary["source_artifact_type"],
            "source_artifact_id" => summary["source_artifact_id"],
            "source_readiness_report_id" => summary["source_readiness_report_id"],
            "readiness_level" => Common.quality_gate_status_readiness_level(gate_status),
            "import_classification" => gate_classification,
            "quality_gate_status" => gate_status,
            "gate_count" => summary["import_readiness_row_count"],
            "review_gate_count" => length(review_required_quality_gate_row_ids),
            "analysis_gate_count" => length(analysis_only_quality_gate_row_ids),
            "blocked_gate_count" => length(blocked_quality_gate_row_ids),
            "gate_id" => StatusRows.single_gate_id(summary["import_readiness_gate_ids"]),
            "gate_status" => gate_status,
            "gate_classification" => gate_classification,
            "gate_reason" => StatusRows.gate_reason(gate_status),
            "import_readiness_row_count" => summary["import_readiness_row_count"],
            "ready_for_import_count" => summary["ready_for_import_count"],
            "manifest_review_required_count" => summary["manifest_review_required_count"],
            "blocked_import_count" => summary["blocked_import_count"],
            "missing_import_count" => summary["missing_import_count"],
            "invalid_cadence_import_count" => summary["invalid_cadence_import_count"],
            "current_freshness_count" => summary["current_freshness_count"],
            "stale_freshness_count" => summary["stale_freshness_count"],
            "unknown_freshness_count" => summary["unknown_freshness_count"],
            "freshness_status_counts" => summary["freshness_status_counts"],
            "freshness_status_ids" => summary["freshness_status_ids"],
            "import_status_counts" => summary["import_status_counts"],
            "import_status_ids" => summary["import_status_ids"],
            "cadence_import_status_counts" => summary["cadence_import_status_counts"],
            "cadence_import_status_ids" => summary["cadence_import_status_ids"],
            "freshness_review_required" =>
              StatusRows.summary_flag(
                summary,
                "freshness_review_required",
                stale_or_unknown_freshness_quality_gate_row_ids
              ),
            "import_preparation_required" =>
              StatusRows.summary_flag(
                summary,
                "import_preparation_required",
                import_preparation_quality_gate_row_ids
              ),
            "import_blocked" =>
              StatusRows.summary_flag(
                summary,
                "import_blocked",
                blocked_import_quality_gate_row_ids
              ),
            "stale_or_unknown_freshness_quality_gate_row_ids" =>
              stale_or_unknown_freshness_quality_gate_row_ids,
            "import_preparation_quality_gate_row_ids" => import_preparation_quality_gate_row_ids,
            "blocked_import_quality_gate_row_ids" => blocked_import_quality_gate_row_ids,
            "assumptions" => summary["assumptions"],
            "source_quality_gate_row" =>
              StatusRows.source_row(
                summary,
                review_required_quality_gate_row_ids,
                analysis_only_quality_gate_row_ids,
                blocked_quality_gate_row_ids,
                stale_or_unknown_freshness_quality_gate_row_ids,
                import_preparation_quality_gate_row_ids,
                blocked_import_quality_gate_row_ids
              ),
            "source_quality_gate_report" => summary
          }
          |> Common.compact_map()
        ]
    end
  end
end
