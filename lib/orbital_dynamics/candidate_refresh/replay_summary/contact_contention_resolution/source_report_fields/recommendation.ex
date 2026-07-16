defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Aggregation

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Aggregation.Values

  alias __MODULE__.ContactFields

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.Rows,
    only: [
      count_rows: 2,
      count_values: 1,
      direction_contact_pairs: 1,
      grouped_id_counts: 1,
      grouped_ids: 1,
      map_value_lists: 1,
      normalize_direction_count_map: 1,
      recommendation_required_actions: 1,
      stringify_keys: 1
    ]

  def fields(source_reports) do
    %{
      "source_report_contact_contention_resolution_recommendation_count" =>
        Aggregation.source_report_family_count(source_reports, "recommendation_count"),
      "source_report_contact_contention_resolution_conflict_group_count" =>
        Aggregation.source_report_family_count(source_reports, "conflict_group_count"),
      "source_report_contact_contention_resolution_review_recommendation_count" =>
        Aggregation.source_report_family_count(source_reports, "review_recommendation_count"),
      "source_report_contact_contention_resolution_recommendation_group_ids" =>
        Aggregation.source_report_family_merge_string_lists(
          source_reports,
          "recommendation_group_ids"
        ),
      "source_report_contact_contention_resolution_review_group_ids" =>
        Aggregation.source_report_family_merge_string_lists(source_reports, "review_group_ids"),
      "source_report_contact_contention_resolution_ambiguous_group_ids" =>
        Aggregation.source_report_family_merge_string_lists(
          source_reports,
          "ambiguous_group_ids"
        ),
      "source_report_contact_contention_resolution_ambiguous_duplicate_contact_ids" =>
        Aggregation.source_report_family_merge_string_lists(
          source_reports,
          "ambiguous_duplicate_contact_ids"
        ),
      "source_report_contact_contention_resolution_ambiguous_duplicate_contact_ids_by_group_id" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "ambiguous_duplicate_contact_ids_by_group_id"
        ),
      "source_report_contact_contention_resolution_deferred_contact_count" =>
        Aggregation.source_report_family_count(source_reports, "deferred_contact_count"),
      "source_report_contact_contention_resolution_status_counts" =>
        Aggregation.source_report_family_merge_count_maps(
          source_reports,
          "resolution_status_counts"
        ),
      "source_report_contact_contention_resolution_selection_reason_counts" =>
        Aggregation.source_report_family_merge_count_maps(
          source_reports,
          "selection_reason_counts"
        ),
      "source_report_contact_contention_resolution_selected_contact_ids_by_selection_reason" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "selected_contact_ids_by_selection_reason"
        ),
      "source_report_contact_contention_resolution_selected_contact_ids" =>
        Aggregation.source_report_family_merge_string_lists(
          source_reports,
          "selected_contact_ids"
        ),
      "source_report_contact_contention_resolution_selected_contact_ids_by_group_id" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "selected_contact_ids_by_group_id"
        ),
      "source_report_contact_contention_resolution_deferred_contact_ids" =>
        Aggregation.source_report_family_merge_string_lists(
          source_reports,
          "deferred_contact_ids"
        ),
      "source_report_contact_contention_resolution_deferred_contact_ids_by_group_id" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "deferred_contact_ids_by_group_id"
        ),
      "source_report_contact_contention_resolution_review_contact_ids" =>
        Aggregation.source_report_family_merge_string_lists(source_reports, "review_contact_ids"),
      "source_report_contact_contention_resolution_review_contact_ids_by_group_id" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "review_contact_ids_by_group_id"
        ),
      "source_report_contact_contention_resolution_resource_scope_counts" =>
        Aggregation.source_report_family_merge_count_maps(source_reports, "resource_scope_counts"),
      "source_report_contact_contention_resolution_selected_contact_ids_by_resource_scope" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "selected_contact_ids_by_resource_scope"
        ),
      "source_report_contact_contention_resolution_deferred_contact_ids_by_resource_scope" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "deferred_contact_ids_by_resource_scope"
        ),
      "source_report_contact_contention_resolution_review_contact_ids_by_resource_scope" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "review_contact_ids_by_resource_scope"
        ),
      "source_report_contact_contention_resolution_selected_contact_ids_by_ground_station" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "selected_contact_ids_by_ground_station"
        ),
      "source_report_contact_contention_resolution_deferred_contact_ids_by_ground_station" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "deferred_contact_ids_by_ground_station"
        ),
      "source_report_contact_contention_resolution_direction_counts" =>
        Aggregation.source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_contact_contention_resolution_contact_ids_by_direction" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_direction"
        ),
      "source_report_contact_contention_resolution_direction_routing" =>
        Aggregation.source_report_family_field(source_reports, "direction_routing"),
      "source_report_contact_contention_resolution_required_operator_action_counts" =>
        Aggregation.source_report_family_merge_count_maps(
          source_reports,
          "required_operator_action_counts"
        ),
      "source_report_contact_contention_resolution_review_contact_ids_by_action" =>
        Aggregation.source_report_family_merge_string_list_maps(
          source_reports,
          "review_contact_ids_by_action"
        )
    }
  end

  def row_count(report), do: recommendation_count(report)

  def recommendation_count(report) do
    case Map.get(report, "recommendations", []) do
      [] -> Values.numeric_report_count(report, "recommendation_count")
      recommendations -> length(recommendations)
    end
  end

  def deferred_contact_count(report), do: ContactFields.deferred_contact_count(report)

  def status_counts(report) do
    case Map.get(report, "recommendations", []) do
      [] -> Map.get(report, "resolution_status_counts")
      recommendations -> count_rows(recommendations, "resolution_status")
    end
  end

  def selection_reason_counts(report) do
    case Map.get(report, "recommendations", []) do
      [] -> Map.get(report, "selection_reason_counts")
      recommendations -> count_rows(recommendations, "selection_reason")
    end
  end

  def direction_counts(report) do
    report
    |> direction_contact_pairs()
    |> case do
      [] ->
        report
        |> Map.get("direction_counts")
        |> normalize_direction_count_map()

      pairs ->
        grouped_id_counts(pairs)
    end
  end

  def contact_ids_by_direction(report) do
    report
    |> direction_contact_pairs()
    |> case do
      [] ->
        report
        |> Map.get("contact_ids_by_direction")
        |> map_value_lists()

      pairs ->
        grouped_ids(pairs)
    end
  end

  def selected_contact_ids(report), do: ContactFields.selected_contact_ids(report)

  def deferred_contact_ids(report), do: ContactFields.deferred_contact_ids(report)

  def selected_contact_ids_by_station(report),
    do: ContactFields.selected_contact_ids_by_station(report)

  def deferred_contact_ids_by_station(report),
    do: ContactFields.deferred_contact_ids_by_station(report)

  def required_action_counts(report) do
    case Map.get(report, "recommendations", []) do
      [] ->
        Map.get(report, "required_operator_action_counts") ||
          Map.get(report, "action_counts") ||
          report
          |> Map.get("required_operator_actions", [])
          |> List.wrap()
          |> count_values()

      recommendations ->
        recommendations
        |> Enum.map(&stringify_keys/1)
        |> Enum.flat_map(&recommendation_required_actions/1)
        |> count_values()
    end
  end
end
