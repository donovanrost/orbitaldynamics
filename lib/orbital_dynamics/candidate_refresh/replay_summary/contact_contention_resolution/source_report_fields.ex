defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary

  alias __MODULE__.CapacityPack
  alias __MODULE__.Pressure
  alias __MODULE__.Recommendation

  import __MODULE__.Aggregation

  def source_report_summary_fields(refresh_or_artifact, source_reports) do
    branch_resolution_summary = source_report_summary_branch_family(refresh_or_artifact)

    resolution_summary =
      branch_resolution_summary ||
        Map.get(source_reports, "contact_contention_resolution_report", %{})

    {summary_source, replay_scope} =
      if branch_resolution_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_resolution_report",
          "contact_contention_resolution_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_contention_resolution_report",
          "contact_contention_resolution_source_report_provenance_only"
        }
      end

    summary =
      Summary.summary(
        resolution_summary,
        summary_source,
        replay_scope
      )

    source_reports
    |> source_report_fields()
    |> Map.merge(Pressure.source_report_fields(summary))
    |> compact_map()
  end

  def source_report_fields(source_reports) do
    %{
      "source_report_contact_contention_resolution_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_contact_contention_resolution_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_contact_contention_resolution_source_artifact_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_artifact_type_counts"),
      "source_report_contact_contention_resolution_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_contact_contention_resolution_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_contact_contention_resolution_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_contact_contention_resolution_paths" =>
        source_report_family_identity_field(source_reports, "paths")
    }
    |> Map.merge(Recommendation.fields(source_reports))
    |> Map.merge(CapacityPack.fields(source_reports))
    |> compact_map()
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "contact_contention_resolution_report",
      &InputProvenance.build/1
    )
  end
end
