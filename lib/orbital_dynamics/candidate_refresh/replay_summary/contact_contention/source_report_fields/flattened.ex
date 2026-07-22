defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContention.SourceReportFields.Flattened do
  @moduledoc false

  alias __MODULE__.Values

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.{
    Correlation,
    RouteMap
  }

  def source_report_fields(source_reports) do
    direction_counts =
      source_report_family_merge_count_maps(source_reports, "direction_counts")

    contact_id_counts =
      source_report_family_merge_count_maps(
        source_reports,
        "contact_contention_contact_id_counts"
      )

    contact_ids_by_direction =
      Correlation.contact_ids_by_direction(
        direction_counts,
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_direction"),
        contact_id_counts
      )

    %{
      "source_report_contact_contention_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_contact_contention_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_contact_contention_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_contact_contention_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_contact_contention_conflict_group_count" =>
        source_report_family_count(source_reports, "conflict_group_count"),
      "source_report_contact_contention_invalid_contact_input_count" =>
        source_report_family_count(source_reports, "invalid_contact_input_count"),
      "source_report_contact_contention_resource_scope_counts" =>
        source_report_family_merge_count_maps(source_reports, "resource_scope_counts"),
      "source_report_contact_contention_ground_station_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "contact_contention_ground_station_counts"
        ),
      "source_report_contact_contention_contact_id_counts" => contact_id_counts,
      "source_report_contact_contention_direction_counts" => direction_counts,
      "source_report_contact_contention_contact_ids_by_direction" => contact_ids_by_direction,
      "source_report_contact_contention_direction_routing" =>
        RouteMap.field(Correlation.positive_counts(direction_counts), contact_ids_by_direction),
      "source_report_contact_contention_invalid_contact_input_ids" =>
        source_report_family_merge_string_lists(source_reports, "invalid_contact_input_ids"),
      "source_report_contact_contention_required_operator_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "required_operator_action_counts")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["contact_contention_report"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "contact_contention_report") do
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
    case Map.get(source_reports, "contact_contention_report") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("contact_contention_report", %{})
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

  defp source_report_family_merge_string_lists(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_string_lists()
  end
end
