defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields.Flattened.DirectionRouting do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields.Flattened.Aggregation

  def fields(source_reports) do
    %{
      "source_report_contact_intent_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_ground_station"
        ),
      "source_report_contact_intent_contact_ids_by_direction_and_ground_station" =>
        source_report_family_merge_nested_string_list_maps(
          source_reports,
          "contact_ids_by_direction_and_ground_station"
        ),
      "source_report_contact_intent_directions" =>
        source_report_family_field(source_reports, "directions"),
      "source_report_contact_intent_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_contact_intent_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_direction"),
      "source_report_contact_intent_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing")
    }
  end
end
