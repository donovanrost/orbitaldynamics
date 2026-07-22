defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.{
    BlockedInputIdentityCorrelation,
    CountMapCorrelation,
    DirectionRouting,
    OutcomeIdentityCorrelation,
    ReasonIdentityCorrelation,
    RowCountCorrelation
  }

  import Aggregation

  def source_report_allocation_fields(source_reports) do
    row_count = source_report_family_identity_count(source_reports, "row_count")
    outcome_fields = primary_outcome_fields(source_reports)
    blocked_input_fields = blocked_input_fields(source_reports)

    reason_fields =
      ReasonIdentityCorrelation.fields(%{
        "allocation_reason_counts" =>
          source_reports
          |> source_report_family_merge_count_maps("allocation_reason_counts")
          |> CountMapCorrelation.correlated_counts(row_count),
        "contact_ids_by_allocation_reason" =>
          source_report_family_merge_string_list_maps(
            source_reports,
            "contact_ids_by_allocation_reason"
          )
      })

    row_counts =
      RowCountCorrelation.correlated_counts_or_nil(
        row_count,
        source_report_family_count(source_reports, "blocked_row_count"),
        source_report_family_count(source_reports, "deferred_row_count")
      ) || %{}

    direction_fields =
      source_reports
      |> Map.get("contact_allocation_report")
      |> DirectionRouting.direction_fields_from_summary()

    %{
      "source_report_contact_allocation_blocked_row_count" =>
        Map.get(row_counts, "blocked_row_count"),
      "source_report_contact_allocation_deferred_row_count" =>
        Map.get(row_counts, "deferred_row_count"),
      "source_report_contact_allocation_allocation_status_counts" =>
        source_reports
        |> source_report_family_merge_count_maps("allocation_status_counts")
        |> CountMapCorrelation.correlated_counts(row_count),
      "source_report_contact_allocation_effective_allocation_status_counts" =>
        source_reports
        |> source_report_family_merge_count_maps("effective_allocation_status_counts")
        |> CountMapCorrelation.correlated_counts(row_count),
      "source_report_contact_allocation_allocation_reason_counts" =>
        Map.get(reason_fields, "allocation_reason_counts"),
      "source_report_contact_allocation_direction_counts" =>
        Map.get(direction_fields, "direction_counts"),
      "source_report_contact_allocation_contact_ids_by_direction" =>
        Map.get(direction_fields, "contact_ids_by_direction"),
      "source_report_contact_allocation_direction_routing" =>
        Map.get(direction_fields, "direction_routing"),
      "source_report_contact_allocation_allocated_contact_count" =>
        Map.get(outcome_fields, "allocated_contact_count"),
      "source_report_contact_allocation_allocated_contact_ids" =>
        Map.get(outcome_fields, "allocated_contact_ids"),
      "source_report_contact_allocation_allocated_contact_ids_by_ground_station" =>
        Map.get(outcome_fields, "allocated_contact_ids_by_ground_station"),
      "source_report_contact_allocation_returned_allocated_contact_count" =>
        Map.get(outcome_fields, "returned_allocated_contact_count"),
      "source_report_contact_allocation_returned_allocated_contact_ids" =>
        Map.get(outcome_fields, "returned_allocated_contact_ids"),
      "source_report_contact_allocation_returned_allocated_contact_ids_by_ground_station" =>
        Map.get(outcome_fields, "returned_allocated_contact_ids_by_ground_station"),
      "source_report_contact_allocation_deferred_contact_count" =>
        Map.get(outcome_fields, "deferred_contact_count"),
      "source_report_contact_allocation_deferred_contact_ids" =>
        Map.get(outcome_fields, "deferred_contact_ids"),
      "source_report_contact_allocation_deferred_contact_ids_by_ground_station" =>
        Map.get(outcome_fields, "deferred_contact_ids_by_ground_station"),
      "source_report_contact_allocation_blocked_contact_count" =>
        Map.get(outcome_fields, "blocked_contact_count"),
      "source_report_contact_allocation_blocked_contact_ids" =>
        Map.get(outcome_fields, "blocked_contact_ids"),
      "source_report_contact_allocation_blocked_contact_ids_by_ground_station" =>
        Map.get(outcome_fields, "blocked_contact_ids_by_ground_station"),
      "source_report_contact_allocation_policy_blocked_allocated_contact_count" =>
        Map.get(outcome_fields, "policy_blocked_allocated_contact_count"),
      "source_report_contact_allocation_policy_blocked_contact_ids" =>
        Map.get(outcome_fields, "policy_blocked_contact_ids"),
      "source_report_contact_allocation_policy_blocked_contact_ids_by_ground_station" =>
        Map.get(outcome_fields, "policy_blocked_contact_ids_by_ground_station"),
      "source_report_contact_allocation_invalid_contact_input_count" =>
        Map.get(blocked_input_fields, "invalid_contact_input_count"),
      "source_report_contact_allocation_duplicate_contact_id_count" =>
        source_report_family_count(source_reports, "duplicate_contact_id_count"),
      "source_report_contact_allocation_invalid_contact_input_ids" =>
        Map.get(blocked_input_fields, "invalid_contact_input_ids"),
      "source_report_contact_allocation_status_blocked_contact_count" =>
        Map.get(blocked_input_fields, "status_blocked_contact_count"),
      "source_report_contact_allocation_status_blocked_contact_ids" =>
        Map.get(blocked_input_fields, "status_blocked_contact_ids"),
      "source_report_contact_allocation_resource_blocked_contact_count" =>
        Map.get(blocked_input_fields, "resource_blocked_contact_count"),
      "source_report_contact_allocation_resource_blocked_contact_ids" =>
        Map.get(blocked_input_fields, "resource_blocked_contact_ids"),
      "source_report_contact_allocation_resource_blocking_dimension_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "resource_blocking_dimension_counts"
        ),
      "source_report_contact_allocation_resource_blocked_contact_ids_by_blocking_dimension" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_blocked_contact_ids_by_blocking_dimension"
        ),
      "source_report_contact_allocation_resource_blocked_contact_ids_by_spacecraft" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_blocked_contact_ids_by_spacecraft"
        ),
      "source_report_contact_allocation_contact_ids_by_allocation_reason" =>
        Map.get(reason_fields, "contact_ids_by_allocation_reason"),
      "source_report_contact_allocation_review_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "review_contact_ids")
    }
  end

  defp primary_outcome_fields(source_reports) do
    OutcomeIdentityCorrelation.field_specs()
    |> Enum.reduce(%{}, fn {count_field, ids_field, routes_field}, fields ->
      fields
      |> Map.put(count_field, source_report_family_count(source_reports, count_field))
      |> Map.put(ids_field, source_report_family_merge_string_lists(source_reports, ids_field))
      |> Map.put(
        routes_field,
        source_report_family_merge_string_list_maps(source_reports, routes_field)
      )
    end)
    |> OutcomeIdentityCorrelation.fields()
  end

  defp blocked_input_fields(source_reports) do
    BlockedInputIdentityCorrelation.field_pairs()
    |> Enum.reduce(%{}, fn {count_field, ids_field}, fields ->
      fields
      |> Map.put(count_field, source_report_family_count(source_reports, count_field))
      |> Map.put(ids_field, source_report_family_merge_string_lists(source_reports, ids_field))
    end)
    |> BlockedInputIdentityCorrelation.fields()
  end
end
