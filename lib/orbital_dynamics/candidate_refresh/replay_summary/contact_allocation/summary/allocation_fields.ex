defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.AllocationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CountMapCorrelation
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.RowCountCorrelation

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.Normalization,
    only: [summary_integer: 2]

  def fields(allocation_summary) do
    row_count = summary_integer(allocation_summary, "row_count")

    row_counts =
      RowCountCorrelation.correlated_counts(
        row_count,
        summary_integer(allocation_summary, "blocked_row_count"),
        summary_integer(allocation_summary, "deferred_row_count")
      )

    direction_fields = DirectionRouting.direction_fields_from_summary(allocation_summary)

    %{
      blocked_row_count: Map.fetch!(row_counts, "blocked_row_count"),
      deferred_row_count: Map.fetch!(row_counts, "deferred_row_count"),
      review_contact_ids: Map.get(allocation_summary, "review_contact_ids"),
      allocation_status_counts:
        allocation_summary
        |> Map.get("allocation_status_counts")
        |> CountMapCorrelation.correlated_counts_or_empty(row_count),
      effective_allocation_status_counts:
        allocation_summary
        |> Map.get("effective_allocation_status_counts")
        |> CountMapCorrelation.correlated_counts_or_empty(row_count),
      allocation_reason_counts:
        allocation_summary
        |> Map.get("allocation_reason_counts")
        |> CountMapCorrelation.correlated_counts_or_empty(row_count),
      direction_counts: Map.get(direction_fields, "direction_counts"),
      contact_ids_by_direction: Map.get(direction_fields, "contact_ids_by_direction"),
      direction_routing: Map.get(direction_fields, "direction_routing") || %{},
      allocated_contact_count:
        non_zero_summary_integer(allocation_summary, "allocated_contact_count"),
      allocated_contact_ids: Map.get(allocation_summary, "allocated_contact_ids"),
      allocated_contact_ids_by_station:
        Map.get(allocation_summary, "allocated_contact_ids_by_ground_station"),
      returned_allocated_contact_count:
        non_zero_summary_integer(allocation_summary, "returned_allocated_contact_count"),
      returned_allocated_contact_ids:
        Map.get(allocation_summary, "returned_allocated_contact_ids"),
      returned_allocated_contact_ids_by_station:
        Map.get(allocation_summary, "returned_allocated_contact_ids_by_ground_station"),
      deferred_contact_count:
        non_zero_summary_integer(allocation_summary, "deferred_contact_count"),
      deferred_contact_ids: Map.get(allocation_summary, "deferred_contact_ids"),
      deferred_contact_ids_by_general_station:
        Map.get(allocation_summary, "deferred_contact_ids_by_ground_station"),
      blocked_contact_count:
        non_zero_summary_integer(allocation_summary, "blocked_contact_count"),
      blocked_contact_ids: Map.get(allocation_summary, "blocked_contact_ids"),
      blocked_contact_ids_by_station:
        Map.get(allocation_summary, "blocked_contact_ids_by_ground_station"),
      policy_blocked_allocated_contact_count:
        non_zero_summary_integer(allocation_summary, "policy_blocked_allocated_contact_count"),
      policy_blocked_contact_ids: Map.get(allocation_summary, "policy_blocked_contact_ids"),
      policy_blocked_contact_ids_by_station:
        Map.get(allocation_summary, "policy_blocked_contact_ids_by_ground_station"),
      invalid_contact_input_count:
        non_zero_summary_integer(allocation_summary, "invalid_contact_input_count"),
      duplicate_contact_id_count:
        non_zero_summary_integer(allocation_summary, "duplicate_contact_id_count"),
      invalid_contact_input_ids: Map.get(allocation_summary, "invalid_contact_input_ids"),
      status_blocked_contact_count:
        non_zero_summary_integer(allocation_summary, "status_blocked_contact_count"),
      status_blocked_contact_ids: Map.get(allocation_summary, "status_blocked_contact_ids"),
      resource_blocked_contact_count:
        non_zero_summary_integer(allocation_summary, "resource_blocked_contact_count"),
      resource_blocked_contact_ids: Map.get(allocation_summary, "resource_blocked_contact_ids"),
      resource_blocking_dimension_counts:
        Map.get(allocation_summary, "resource_blocking_dimension_counts"),
      resource_blocked_contact_ids_by_blocking_dimension:
        Map.get(allocation_summary, "resource_blocked_contact_ids_by_blocking_dimension"),
      resource_blocked_contact_ids_by_spacecraft:
        Map.get(allocation_summary, "resource_blocked_contact_ids_by_spacecraft"),
      contact_ids_by_allocation_reason:
        Map.get(allocation_summary, "contact_ids_by_allocation_reason")
    }
  end

  def replay_fields(fields) do
    %{
      "blocked_row_count" => Map.fetch!(fields, :blocked_row_count),
      "deferred_row_count" => Map.fetch!(fields, :deferred_row_count),
      "allocation_status_counts" => Map.fetch!(fields, :allocation_status_counts),
      "effective_allocation_status_counts" =>
        Map.fetch!(fields, :effective_allocation_status_counts),
      "allocation_reason_counts" => Map.fetch!(fields, :allocation_reason_counts),
      "direction_counts" => Map.get(fields, :direction_counts),
      "contact_ids_by_direction" => Map.get(fields, :contact_ids_by_direction),
      "direction_routing" => Map.fetch!(fields, :direction_routing),
      "allocated_contact_count" => Map.get(fields, :allocated_contact_count),
      "allocated_contact_ids" => Map.get(fields, :allocated_contact_ids),
      "allocated_contact_ids_by_ground_station" =>
        Map.get(fields, :allocated_contact_ids_by_station),
      "returned_allocated_contact_count" => Map.get(fields, :returned_allocated_contact_count),
      "returned_allocated_contact_ids" => Map.get(fields, :returned_allocated_contact_ids),
      "returned_allocated_contact_ids_by_ground_station" =>
        Map.get(fields, :returned_allocated_contact_ids_by_station),
      "deferred_contact_count" => Map.get(fields, :deferred_contact_count),
      "deferred_contact_ids" => Map.get(fields, :deferred_contact_ids),
      "deferred_contact_ids_by_ground_station" =>
        Map.get(fields, :deferred_contact_ids_by_general_station),
      "blocked_contact_count" => Map.get(fields, :blocked_contact_count),
      "blocked_contact_ids" => Map.get(fields, :blocked_contact_ids),
      "blocked_contact_ids_by_ground_station" => Map.get(fields, :blocked_contact_ids_by_station),
      "policy_blocked_allocated_contact_count" =>
        Map.get(fields, :policy_blocked_allocated_contact_count),
      "policy_blocked_contact_ids" => Map.get(fields, :policy_blocked_contact_ids),
      "policy_blocked_contact_ids_by_ground_station" =>
        Map.get(fields, :policy_blocked_contact_ids_by_station),
      "invalid_contact_input_count" => Map.get(fields, :invalid_contact_input_count),
      "duplicate_contact_id_count" => Map.get(fields, :duplicate_contact_id_count),
      "invalid_contact_input_ids" => Map.get(fields, :invalid_contact_input_ids),
      "status_blocked_contact_count" => Map.get(fields, :status_blocked_contact_count),
      "status_blocked_contact_ids" => Map.get(fields, :status_blocked_contact_ids),
      "resource_blocked_contact_count" => Map.get(fields, :resource_blocked_contact_count),
      "resource_blocked_contact_ids" => Map.get(fields, :resource_blocked_contact_ids),
      "resource_blocking_dimension_counts" =>
        Map.get(fields, :resource_blocking_dimension_counts),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        Map.get(fields, :resource_blocked_contact_ids_by_blocking_dimension),
      "resource_blocked_contact_ids_by_spacecraft" =>
        Map.get(fields, :resource_blocked_contact_ids_by_spacecraft),
      "contact_ids_by_allocation_reason" => Map.get(fields, :contact_ids_by_allocation_reason),
      "review_contact_ids" => Map.get(fields, :review_contact_ids)
    }
  end

  defp non_zero_summary_integer(summary, field) do
    case summary_integer(summary, field) do
      0 -> nil
      count -> count
    end
  end
end
