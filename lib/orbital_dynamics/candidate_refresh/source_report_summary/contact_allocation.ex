defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      merge_count_maps: 1,
      merge_nested_string_list_maps: 1,
      merge_numeric_maps: 1,
      merge_string_list_maps: 1,
      merge_string_lists: 1,
      sum_report_count: 2
    ]

  @count_sum_fields [
    {"row_count", :contact_allocation_report_row_count},
    {"blocked_row_count", :contact_allocation_report_blocked_row_count},
    {"deferred_row_count", :contact_allocation_report_deferred_row_count},
    {"capacity_pack_contact_count", :contact_allocation_report_capacity_pack_contact_count},
    {"reduced_capacity_pack_group_count",
     :contact_allocation_report_reduced_capacity_pack_group_count},
    {"allocated_contact_count", :contact_allocation_report_allocated_contact_count},
    {"returned_allocated_contact_count",
     :contact_allocation_report_returned_allocated_contact_count},
    {"deferred_contact_count", :contact_allocation_report_deferred_contact_count},
    {"blocked_contact_count", :contact_allocation_report_blocked_contact_count},
    {"policy_blocked_allocated_contact_count",
     :contact_allocation_report_policy_blocked_allocated_contact_count},
    {"invalid_contact_input_count", :contact_allocation_report_invalid_contact_input_count},
    {"duplicate_contact_id_count", :contact_allocation_report_duplicate_contact_id_count},
    {"status_blocked_contact_count", :contact_allocation_report_status_blocked_contact_count},
    {"resource_blocked_contact_count", :contact_allocation_report_resource_blocked_contact_count},
    {"station_pressure_contact_count", :contact_allocation_report_station_pressure_contact_count},
    {"station_pressure_review_contact_count",
     :contact_allocation_report_station_pressure_review_contact_count},
    {"reservation_conflict_contact_count",
     :contact_allocation_report_reservation_conflict_contact_count},
    {"station_reservation_active_contact_count",
     :contact_allocation_report_station_reservation_active_contact_count},
    {"station_reservation_expired_contact_count",
     :contact_allocation_report_station_reservation_expired_contact_count},
    {"station_reservation_declared_expiration_contact_count",
     :contact_allocation_report_station_reservation_declared_expiration_contact_count},
    {"station_reservation_missing_expiration_contact_count",
     :contact_allocation_report_station_reservation_missing_expiration_contact_count},
    {"provider_reservation_candidate_contact_count",
     :contact_allocation_report_provider_reservation_candidate_contact_count},
    {"provider_reservation_request_contact_count",
     :contact_allocation_report_provider_reservation_request_contact_count},
    {"provider_reservation_review_contact_count",
     :contact_allocation_report_provider_reservation_review_contact_count},
    {"provider_reservation_no_request_contact_count",
     :contact_allocation_report_provider_reservation_no_request_contact_count}
  ]

  @count_map_fields [
    {"allocation_status_counts", :contact_allocation_report_status_counts},
    {"effective_allocation_status_counts", :contact_allocation_report_effective_status_counts},
    {"allocation_reason_counts", :contact_allocation_report_reason_counts},
    {"capacity_pack_status_counts", :contact_allocation_report_capacity_pack_status_counts},
    {"capacity_pack_contact_status_counts",
     :contact_allocation_report_capacity_pack_contact_status_counts},
    {"direction_counts", :contact_allocation_report_direction_counts},
    {"reduced_capacity_pack_status_counts",
     :contact_allocation_report_reduced_capacity_pack_status_counts},
    {"required_capacity_fraction_source_counts",
     :contact_allocation_report_required_capacity_source_counts},
    {"resource_blocking_dimension_counts",
     :contact_allocation_report_resource_blocking_dimension_counts},
    {"station_pressure_ground_station_counts",
     :contact_allocation_report_station_pressure_ground_station_counts},
    {"station_pressure_availability_counts",
     :contact_allocation_report_station_pressure_availability_counts},
    {"station_pressure_precedence_availability_counts",
     :contact_allocation_report_station_pressure_precedence_availability_counts},
    {"station_pressure_precedence_rank_counts",
     :contact_allocation_report_station_pressure_precedence_rank_counts},
    {"station_pressure_status_counts", :contact_allocation_report_station_pressure_status_counts},
    {"station_pressure_direction_counts",
     :contact_allocation_report_station_pressure_direction_counts},
    {"reservation_conflict_match_status_counts",
     :contact_allocation_report_reservation_conflict_match_status_counts},
    {"reservation_conflict_direction_counts",
     :contact_allocation_report_reservation_conflict_direction_counts},
    {"station_reservation_match_status_counts",
     :contact_allocation_report_station_reservation_match_status_counts},
    {"station_reservation_status_counts",
     :contact_allocation_report_station_reservation_status_counts},
    {"station_reserved_by_counts", :contact_allocation_report_station_reserved_by_counts},
    {"station_reservation_expiration_status_counts",
     :contact_allocation_report_station_reservation_expiration_status_counts},
    {"provider_reservation_request_status_counts",
     :contact_allocation_report_provider_reservation_request_status_counts}
  ]

  @numeric_sum_fields [
    {"capacity_pack_required_capacity_fraction",
     :contact_allocation_report_capacity_pack_required_fraction},
    {"capacity_pack_selected_required_capacity_fraction",
     :contact_allocation_report_capacity_pack_selected_required_fraction},
    {"capacity_pack_deferred_required_capacity_fraction",
     :contact_allocation_report_capacity_pack_deferred_required_fraction}
  ]

  @numeric_map_fields [
    {"capacity_pack_required_capacity_fraction_by_status",
     :contact_allocation_report_capacity_pack_required_fraction_by_status},
    {"capacity_pack_required_capacity_fraction_by_ground_station",
     :contact_allocation_report_capacity_pack_required_fraction_by_station},
    {"capacity_pack_required_capacity_fraction_by_direction",
     :contact_allocation_report_capacity_pack_required_fraction_by_direction},
    {"capacity_pack_selected_required_capacity_fraction_by_ground_station",
     :contact_allocation_report_capacity_pack_selected_required_fraction_by_station},
    {"capacity_pack_selected_required_capacity_fraction_by_direction",
     :contact_allocation_report_capacity_pack_selected_required_fraction_by_direction},
    {"capacity_pack_deferred_required_capacity_fraction_by_ground_station",
     :contact_allocation_report_capacity_pack_deferred_required_fraction_by_station},
    {"capacity_pack_deferred_required_capacity_fraction_by_direction",
     :contact_allocation_report_capacity_pack_deferred_required_fraction_by_direction}
  ]

  @string_list_fields [
    {"capacity_pack_group_ids", :contact_allocation_report_capacity_pack_group_ids},
    {"reduced_capacity_packed_contact_ids",
     :contact_allocation_report_reduced_capacity_packed_contact_ids},
    {"reduced_capacity_deferred_contact_ids",
     :contact_allocation_report_reduced_capacity_deferred_contact_ids},
    {"allocated_contact_ids", :contact_allocation_report_allocated_contact_ids},
    {"returned_allocated_contact_ids", :contact_allocation_report_returned_allocated_contact_ids},
    {"deferred_contact_ids", :contact_allocation_report_deferred_contact_ids},
    {"blocked_contact_ids", :contact_allocation_report_blocked_contact_ids},
    {"policy_blocked_contact_ids", :contact_allocation_report_policy_blocked_contact_ids},
    {"invalid_contact_input_ids", :contact_allocation_report_invalid_contact_input_ids},
    {"status_blocked_contact_ids", :contact_allocation_report_status_blocked_contact_ids},
    {"resource_blocked_contact_ids", :contact_allocation_report_resource_blocked_contact_ids},
    {"review_contact_ids", :contact_allocation_report_review_contact_ids},
    {"station_pressure_review_contact_ids",
     :contact_allocation_report_station_pressure_review_contact_ids},
    {"reservation_conflict_contact_ids",
     :contact_allocation_report_reservation_conflict_contact_ids},
    {"station_reservation_ids", :contact_allocation_report_station_reservation_ids},
    {"provider_reservation_request_contact_ids",
     :contact_allocation_report_provider_reservation_request_contact_ids},
    {"provider_reservation_review_contact_ids",
     :contact_allocation_report_provider_reservation_review_contact_ids},
    {"provider_reservation_no_request_contact_ids",
     :contact_allocation_report_provider_reservation_no_request_contact_ids}
  ]

  @string_list_map_fields [
    {"capacity_pack_selected_contact_ids_by_ground_station",
     :contact_allocation_report_capacity_pack_selected_contact_ids_by_station},
    {"capacity_pack_selected_contact_ids_by_direction",
     :contact_allocation_report_capacity_pack_selected_contact_ids_by_direction},
    {"capacity_pack_deferred_contact_ids_by_ground_station",
     :contact_allocation_report_capacity_pack_deferred_contact_ids_by_station},
    {"capacity_pack_deferred_contact_ids_by_direction",
     :contact_allocation_report_capacity_pack_deferred_contact_ids_by_direction},
    {"capacity_pack_contact_ids_by_ground_station",
     :contact_allocation_report_capacity_pack_contact_ids_by_station},
    {"capacity_pack_contact_ids_by_direction",
     :contact_allocation_report_capacity_pack_contact_ids_by_direction},
    {"capacity_pack_contact_ids_by_status",
     :contact_allocation_report_capacity_pack_contact_ids_by_status},
    {"contact_ids_by_direction", :contact_allocation_report_contact_ids_by_direction},
    {"capacity_pack_group_ids_by_status",
     :contact_allocation_report_capacity_pack_group_ids_by_status},
    {"required_capacity_fraction_contact_ids_by_source",
     :contact_allocation_report_required_capacity_contact_ids_by_source},
    {"allocated_contact_ids_by_ground_station",
     :contact_allocation_report_allocated_contact_ids_by_station},
    {"returned_allocated_contact_ids_by_ground_station",
     :contact_allocation_report_returned_allocated_contact_ids_by_station},
    {"deferred_contact_ids_by_ground_station",
     :contact_allocation_report_deferred_contact_ids_by_station},
    {"blocked_contact_ids_by_ground_station",
     :contact_allocation_report_blocked_contact_ids_by_station},
    {"policy_blocked_contact_ids_by_ground_station",
     :contact_allocation_report_policy_blocked_contact_ids_by_station},
    {"resource_blocked_contact_ids_by_blocking_dimension",
     :contact_allocation_report_resource_blocked_contact_ids_by_dimension},
    {"resource_blocked_contact_ids_by_spacecraft",
     :contact_allocation_report_resource_blocked_contact_ids_by_spacecraft},
    {"contact_ids_by_allocation_reason",
     :contact_allocation_report_contact_ids_by_allocation_reason},
    {"station_pressure_contact_ids_by_ground_station",
     :contact_allocation_report_station_pressure_contact_ids_by_ground_station},
    {"station_pressure_contact_ids_by_availability",
     :contact_allocation_report_station_pressure_contact_ids_by_availability},
    {"station_pressure_contact_ids_by_precedence_availability",
     :contact_allocation_report_station_pressure_contact_ids_by_precedence_availability},
    {"station_pressure_contact_ids_by_precedence_rank",
     :contact_allocation_report_station_pressure_contact_ids_by_precedence_rank},
    {"station_pressure_contact_ids_by_status",
     :contact_allocation_report_station_pressure_contact_ids_by_status},
    {"station_pressure_contact_ids_by_direction",
     :contact_allocation_report_station_pressure_contact_ids_by_direction},
    {"reservation_conflict_contact_ids_by_match_status",
     :contact_allocation_report_reservation_conflict_contact_ids_by_match_status},
    {"reservation_conflict_reservation_ids_by_match_status",
     :contact_allocation_report_reservation_conflict_reservation_ids_by_match_status},
    {"reservation_conflict_contact_ids_by_direction",
     :contact_allocation_report_reservation_conflict_contact_ids_by_direction},
    {"station_reservation_contact_ids_by_match_status",
     :contact_allocation_report_station_reservation_contact_ids_by_match_status},
    {"station_reservation_ids_by_match_status",
     :contact_allocation_report_station_reservation_ids_by_match_status},
    {"station_reservation_contact_ids_by_status",
     :contact_allocation_report_station_reservation_contact_ids_by_status},
    {"station_reservation_contact_ids_by_reserved_by",
     :contact_allocation_report_station_reservation_contact_ids_by_reserved_by},
    {"station_reservation_ids_by_status",
     :contact_allocation_report_station_reservation_ids_by_status},
    {"station_reservation_ids_by_reserved_by",
     :contact_allocation_report_station_reservation_ids_by_reserved_by},
    {"station_reservation_contact_ids_by_expiration_status",
     :contact_allocation_report_station_reservation_contact_ids_by_expiration_status},
    {"station_reservation_ids_by_expiration_status",
     :contact_allocation_report_station_reservation_ids_by_expiration_status},
    {"provider_reservation_request_contact_ids_by_ground_station",
     :contact_allocation_report_provider_reservation_request_contact_ids_by_station},
    {"provider_reservation_review_contact_ids_by_ground_station",
     :contact_allocation_report_provider_reservation_review_contact_ids_by_station},
    {"provider_reservation_no_request_contact_ids_by_direction",
     :contact_allocation_report_provider_reservation_no_request_contact_ids_by_direction},
    {"provider_reservation_request_contact_ids_by_direction",
     :contact_allocation_report_provider_reservation_request_contact_ids_by_direction},
    {"provider_reservation_review_contact_ids_by_direction",
     :contact_allocation_report_provider_reservation_review_contact_ids_by_direction},
    {"provider_reservation_request_contact_ids_by_match_status",
     :contact_allocation_report_provider_reservation_request_contact_ids_by_match_status},
    {"provider_reservation_review_contact_ids_by_match_status",
     :contact_allocation_report_provider_reservation_review_contact_ids_by_match_status},
    {"provider_reservation_request_ids_by_match_status",
     :contact_allocation_report_provider_reservation_request_ids_by_match_status},
    {"provider_reservation_review_ids_by_match_status",
     :contact_allocation_report_provider_reservation_review_ids_by_match_status}
  ]

  @nested_string_list_map_fields [
    {"station_pressure_contact_ids_by_direction_and_ground_station",
     :contact_allocation_report_station_pressure_contact_ids_by_direction_and_station},
    {"reservation_conflict_contact_ids_by_direction_and_ground_station",
     :contact_allocation_report_reservation_conflict_contact_ids_by_direction_and_station},
    {"provider_reservation_no_request_contact_ids_by_direction_and_ground_station",
     :contact_allocation_report_provider_reservation_no_request_contact_ids_by_direction_and_station},
    {"provider_reservation_request_contact_ids_by_direction_and_ground_station",
     :contact_allocation_report_provider_reservation_request_contact_ids_by_direction_and_station},
    {"provider_reservation_review_contact_ids_by_direction_and_ground_station",
     :contact_allocation_report_provider_reservation_review_contact_ids_by_direction_and_station}
  ]

  @direct_report_fields [
    {"direction_routing", :contact_allocation_direction_routing},
    {"provider_reservation_request_summary_schema_contract",
     :contact_allocation_provider_reservation_request_summary_schema_contract},
    {"contact_allocation_summary_schema_contract", :contact_allocation_summary_schema_contract},
    {"station_pressure_summary_schema_contract",
     :contact_allocation_station_pressure_summary_schema_contract},
    {"reservation_conflict_summary_schema_contract",
     :contact_allocation_reservation_conflict_summary_schema_contract},
    {"capacity_pack_summary_schema_contract",
     :contact_allocation_capacity_pack_summary_schema_contract}
  ]

  @min_fields [
    {"station_reservation_expiration_now_s",
     :contact_allocation_report_station_reservation_expiration_now_s},
    {"earliest_station_reservation_expires_at_s",
     :contact_allocation_report_earliest_station_reservation_expires_at_s}
  ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "contact_allocation_report.v1",
      "count" => length(sources),
      "source_summary_model_counts" => count_report_field_values(reports, "source_summary_model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(reports, "source_summary_schema_contract"),
      "source_artifact_type_counts" => count_report_field_values(reports, "source_artifact_type"),
      "station_reservation_expires_at_s" =>
        numeric_list_merge(
          reports,
          callbacks,
          :contact_allocation_report_station_reservation_expires_at_s
        ),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_contact_allocation_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_contact_allocation_report_trust_boundaries).(reports)
    }
    |> put_fields(reports, callbacks, @count_sum_fields, &count_sum/3)
    |> put_fields(reports, callbacks, @count_map_fields, &count_map_merge/3)
    |> put_fields(reports, callbacks, @numeric_sum_fields, &numeric_sum/3)
    |> put_fields(reports, callbacks, @numeric_map_fields, &numeric_map_merge/3)
    |> put_fields(reports, callbacks, @string_list_fields, &string_list_merge/3)
    |> put_fields(reports, callbacks, @string_list_map_fields, &string_list_map_merge/3)
    |> put_fields(
      reports,
      callbacks,
      @nested_string_list_map_fields,
      &nested_string_list_map_merge/3
    )
    |> put_fields(reports, callbacks, @direct_report_fields, &direct_report_value/3)
    |> put_fields(reports, callbacks, @min_fields, &min_value/3)
    |> compact_map()
  end

  defp put_fields(summary, reports, callbacks, fields, value_fun) do
    Enum.reduce(fields, summary, fn {field, callback_key}, summary ->
      Map.put(summary, field, value_fun.(reports, callbacks, callback_key))
    end)
  end

  defp count_sum(reports, callbacks, key),
    do: sum_report_count(reports, callback!(callbacks, key))

  defp numeric_sum(reports, callbacks, key) do
    callback!(callbacks, :sum_report_numeric_values).(reports, callback!(callbacks, key))
  end

  defp count_map_merge(reports, callbacks, key) do
    reports
    |> Enum.map(callback!(callbacks, key))
    |> merge_count_maps()
  end

  defp numeric_map_merge(reports, callbacks, key) do
    reports
    |> Enum.map(callback!(callbacks, key))
    |> merge_numeric_maps()
  end

  defp string_list_merge(reports, callbacks, key) do
    reports
    |> Enum.map(callback!(callbacks, key))
    |> merge_string_lists()
  end

  defp string_list_map_merge(reports, callbacks, key) do
    reports
    |> Enum.map(callback!(callbacks, key))
    |> merge_string_list_maps()
  end

  defp nested_string_list_map_merge(reports, callbacks, key) do
    reports
    |> Enum.map(callback!(callbacks, key))
    |> merge_nested_string_list_maps()
  end

  defp direct_report_value(reports, callbacks, key), do: callback!(callbacks, key).(reports)

  defp min_value(reports, callbacks, key) do
    reports
    |> Enum.map(callback!(callbacks, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  defp numeric_list_merge(reports, callbacks, key) do
    values =
      reports
      |> Enum.flat_map(&(callback!(callbacks, key).(&1) || []))

    callback!(callbacks, :normalize_number_list).(values)
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
