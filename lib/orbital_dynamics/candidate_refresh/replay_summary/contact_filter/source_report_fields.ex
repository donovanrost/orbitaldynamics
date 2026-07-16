defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter
  alias __MODULE__.Pressure
  alias __MODULE__.StationSuppression

  import __MODULE__.Aggregation

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("contact_filter_report", %{})
      |> ContactFilter.summary(
        "candidate_refresh.source_report_provenance.contact_filter_report",
        "contact_filter_source_report_provenance_only"
      )

    Pressure.source_report_fields(summary)
  end

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_fields()
    |> Map.merge(source_report_identity_fields(source_reports))
    |> Map.merge(source_report_suppression_fields(source_reports))
    |> Map.merge(source_report_direction_fields(source_reports))
    |> Map.merge(StationSuppression.fields(source_reports))
  end

  def source_report_identity_fields(source_reports) do
    %{
      "source_report_contact_filter_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_contact_filter_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_contact_filter_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_contact_filter_paths" =>
        source_report_family_identity_field(source_reports, "paths")
    }
  end

  def source_report_suppression_fields(source_reports) do
    %{
      "source_report_contact_filter_suppressed_candidate_count" =>
        source_report_family_count(source_reports, "suppressed_candidate_count"),
      "source_report_contact_filter_invalid_contact_input_count" =>
        source_report_family_count(source_reports, "invalid_contact_input_count"),
      "source_report_contact_filter_invalid_contact_input_ids" =>
        source_report_family_merge_string_lists(source_reports, "invalid_contact_input_ids"),
      "source_report_contact_filter_suppressed_reason_counts" =>
        source_report_family_merge_count_maps(source_reports, "suppressed_reason_counts"),
      "source_report_contact_filter_contact_ids_by_suppressed_reason" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_suppressed_reason"
        )
    }
  end

  def source_report_direction_fields(source_reports) do
    %{
      "source_report_contact_filter_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_contact_filter_directions" =>
        source_report_family_field(source_reports, "directions"),
      "source_report_contact_filter_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_direction"),
      "source_report_contact_filter_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing")
    }
  end
end
