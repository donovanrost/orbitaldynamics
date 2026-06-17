defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance.SourceReportFields.Flattened do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance.SourceReportFields.Values

  def fields(source_reports) do
    %{
      "source_report_model_acceptance_record_count" =>
        source_report_family_count(source_reports, "record_count"),
      "source_report_model_acceptance_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_model_acceptance_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_model_acceptance_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_model_acceptance_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_model_acceptance_intended_use_counts" =>
        source_report_family_merge_count_maps(source_reports, "intended_use_counts"),
      "source_report_model_acceptance_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "status_counts"),
      "source_report_model_acceptance_model_count" =>
        source_report_family_count(source_reports, "model_count"),
      "source_report_model_acceptance_accepted_count" =>
        source_report_family_count(source_reports, "accepted_count"),
      "source_report_model_acceptance_review_required_count" =>
        source_report_family_count(source_reports, "review_required_count"),
      "source_report_model_acceptance_blocked_count" =>
        source_report_family_count(source_reports, "blocked_count"),
      "source_report_model_acceptance_unknown_model_count" =>
        source_report_family_count(source_reports, "unknown_model_count"),
      "source_report_model_acceptance_validation_level_counts" =>
        source_report_family_merge_count_maps(source_reports, "validation_level_counts"),
      "source_report_model_acceptance_model_ids_by_status" =>
        source_report_family_merge_string_list_maps(source_reports, "model_ids_by_status"),
      "source_report_model_acceptance_model_ids_by_validation_level" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "model_ids_by_validation_level"
        ),
      "source_report_model_acceptance_model_ids_by_intended_use" =>
        source_report_family_merge_string_list_maps(source_reports, "model_ids_by_intended_use")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["model_acceptance_report"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "model_acceptance_report") do
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
    case Map.get(source_reports, "model_acceptance_report") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("model_acceptance_report", %{})
    |> Map.get(field)
  end

  defp source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
  end

  defp source_report_family_merge_string_list_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_string_list_maps()
  end
end
