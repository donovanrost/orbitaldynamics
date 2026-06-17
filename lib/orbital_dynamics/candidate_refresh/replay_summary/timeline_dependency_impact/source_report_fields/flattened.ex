defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact.SourceReportFields.Flattened do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact.SourceReportFields.Values

  def fields(source_reports) do
    %{
      "source_report_timeline_dependency_impact_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_timeline_dependency_impact_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_timeline_dependency_impact_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_timeline_dependency_impact_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_timeline_dependency_impact_source_activity_count" =>
        source_report_family_count(source_reports, "source_activity_count"),
      "source_report_timeline_dependency_impact_replacement_activity_count" =>
        source_report_family_count(source_reports, "replacement_activity_count"),
      "source_report_timeline_dependency_impact_changed_source_activity_count" =>
        source_report_family_count(source_reports, "changed_source_activity_count"),
      "source_report_timeline_dependency_impact_changed_source_timeline_count" =>
        source_report_family_count(source_reports, "changed_source_timeline_count"),
      "source_report_timeline_dependency_impact_dependent_activity_count" =>
        source_report_family_count(source_reports, "dependent_activity_count"),
      "source_report_timeline_dependency_impact_source_dependent_activity_count" =>
        source_report_family_count(source_reports, "source_dependent_activity_count"),
      "source_report_timeline_dependency_impact_replacement_dependent_activity_count" =>
        source_report_family_count(source_reports, "replacement_dependent_activity_count"),
      "source_report_timeline_dependency_impact_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "dependency_impact_status_counts"),
      "source_report_timeline_dependency_impact_scope_counts" =>
        source_report_family_merge_count_maps(source_reports, "dependency_impact_scope_counts"),
      "source_report_timeline_dependency_impact_required_operator_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "required_operator_action_counts"),
      "source_report_timeline_dependency_impact_impacted_source_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "impacted_source_activity_id_counts"
        ),
      "source_report_timeline_dependency_impact_impacted_source_timeline_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "impacted_source_timeline_id_counts"
        ),
      "source_report_timeline_dependency_impact_impacted_dependency_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "impacted_dependency_activity_id_counts"
        ),
      "source_report_timeline_dependency_impact_impacted_dependency_timeline_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "impacted_dependency_timeline_id_counts"
        ),
      "source_report_timeline_dependency_impact_impacted_exclusive_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "impacted_exclusive_activity_id_counts"
        ),
      "source_report_timeline_dependency_impact_impacted_exclusive_timeline_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "impacted_exclusive_timeline_id_counts"
        ),
      "source_report_timeline_dependency_impact_dependent_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "dependent_activity_id_counts"),
      "source_report_timeline_dependency_impact_dependent_timeline_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "dependent_timeline_id_counts")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["timeline_dependency_impact_summary"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "timeline_dependency_impact_summary") do
      source_reports
      |> source_report_family_reports()
      |> Enum.map(&Values.numeric_report_count(&1, field))
      |> Enum.sum()
      |> Values.report_count()
    end
  end

  defp source_report_family_identity_count(source_reports, field) do
    if source_report_family_has_identity_counts?(source_reports) do
      source_report_family_count(source_reports, field)
    end
  end

  defp source_report_family_identity_field(source_reports, field) do
    if source_report_family_has_identity_counts?(source_reports) do
      source_report_family_field(source_reports, field)
    end
  end

  defp source_report_family_has_identity_counts?(source_reports) do
    case Map.get(source_reports, "timeline_dependency_impact_summary") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("timeline_dependency_impact_summary", %{})
    |> Map.get(field)
  end

  defp source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
  end
end
