defmodule OrbitalDynamics.Schema.GroundNetworkPropertyRouter do
  @moduledoc false

  alias OrbitalDynamics.Schema.TimelineContextJsonSchema

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, "command_window_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.command_window(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :command_window_report_model_limits, []) end,
       fn -> provider(context, :command_window_row_json_schema, []) end}
    )
  end

  def property(field, "station_calendar_precedence_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.calendar_precedence(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      fn -> provider(context, :station_calendar_report_model_limits, []) end
    )
  end

  def property(field, "station_reservation_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.reservation(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      {&OrbitalDynamics.Schema.StationReservationReportJsonSchema.models/0,
       fn -> provider(context, :station_reservation_contact_json_schema, []) end,
       fn -> provider(context, :station_reservation_provider_contention_group_json_schema, []) end}
    )
  end

  def property(field, "station_calendar_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.calendar(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :station_calendar_contact_json_schema, []) end,
       fn -> provider(context, :station_calendar_report_model, []) end,
       fn -> provider(context, :station_calendar_provider_contention_group_json_schema, []) end,
       fn -> provider(context, :station_calendar_provider_entry_json_schema, []) end,
       &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
       fn -> provider(context, :station_calendar_report_model_limits, []) end}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "station_reservation_review_summary.v1",
             "station_reservation_hold_summary.v1",
             "station_reservation_hold_import_readiness_summary.v1"
           ] do
    OrbitalDynamics.Schema.StationReservationSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        review_summary: "station_reservation_review_summary.v1",
        hold_summary: "station_reservation_hold_summary.v1",
        hold_import_readiness_summary: "station_reservation_hold_import_readiness_summary.v1"
      },
      review_row_schema: fn ->
        provider(context, :station_reservation_review_summary_row_json_schema, [])
      end,
      import_readiness_row_schema: fn ->
        provider(context, :station_reservation_hold_import_readiness_row_json_schema, [])
      end,
      model_limits: fn -> provider(context, :station_calendar_report_model_limits, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "station_calendar_provider.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch.station_calendar_provider(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      provider(context, :station_calendar_provider_entry_json_schema, [])
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["link_capacity_report.v1", "link_capacity_summary.v1"] do
    OrbitalDynamics.Schema.LinkCapacityPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{report: "link_capacity_report.v1", summary: "link_capacity_summary.v1"},
      row_schema: fn -> provider(context, :link_capacity_row_json_schema, []) end,
      model_limits: &OrbitalDynamics.Schema.LinkCapacitySummaryContracts.model_limits/0,
      report_assumptions_schema: fn ->
        provider(context, :link_capacity_assumptions_json_schema, [[]])
      end,
      summary_assumptions_schema: fn ->
        provider(context, :link_capacity_assumptions_json_schema, [
          ["execution_boundary", "source", "operator_authority"]
        ])
      end,
      stable_id_array_schema: fn -> provider(context, :stable_id_array_schema, []) end,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      count_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      actual_data_rate_throughput_derivations_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivations/0,
      numeric_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
      stable_id_array_map_schema: fn -> provider(context, :stable_id_array_map_schema, []) end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "relay_data_path_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch.relay_data_path(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {&OrbitalDynamics.Schema.RelayDataPathSummaryContracts.model_limits/0,
       &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.assumptions/0,
       fn -> provider(context, :relay_data_path_row_json_schema, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end}
    )
  end

  def property(field, "contact_allocation_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch.contact_allocation(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :contact_allocation_row_json_schema, []) end,
       fn -> provider(context, :contact_allocation_capacity_pack_group_json_schema, []) end,
       fn -> provider(context, :contact_allocation_model_limits, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :nested_stable_id_array_map_json_schema, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
       &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
       fn -> provider(context, :contact_allocation_capabilities, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.enum_count_map/1,
       &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
       &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map/0}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "contact_allocation_summary.v1",
             "contact_allocation_reservation_conflict_summary.v1",
             "contact_allocation_station_pressure_summary.v1",
             "contact_allocation_capacity_pack_summary.v1",
             "contact_allocation_provider_reservation_request_summary.v1"
           ] do
    OrbitalDynamics.Schema.ContactAllocationSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        summary: "contact_allocation_summary.v1",
        reservation_conflict_summary: "contact_allocation_reservation_conflict_summary.v1",
        station_pressure_summary: "contact_allocation_station_pressure_summary.v1",
        capacity_pack_summary: "contact_allocation_capacity_pack_summary.v1",
        provider_reservation_request_summary:
          "contact_allocation_provider_reservation_request_summary.v1"
      },
      assumptions: %{
        summary: fn ->
          provider(context, :contact_allocation_summary_assumptions_json_schema, [])
        end,
        reservation_conflict_summary: fn ->
          provider(
            context,
            :contact_allocation_reservation_conflict_summary_assumptions_json_schema,
            []
          )
        end,
        station_pressure_summary: fn ->
          provider(
            context,
            :contact_allocation_station_pressure_summary_assumptions_json_schema,
            []
          )
        end,
        capacity_pack_summary: fn ->
          provider(context, :contact_allocation_capacity_pack_summary_assumptions_json_schema, [])
        end,
        provider_reservation_request_summary: fn ->
          provider(
            context,
            :contact_allocation_provider_reservation_request_summary_assumptions_json_schema,
            []
          )
        end
      },
      stable_id_pattern: context_value(context, :stable_id_pattern),
      model_limits: fn -> provider(context, :contact_allocation_model_limits, []) end,
      row_schema: fn -> provider(context, :contact_allocation_row_json_schema, []) end,
      capacity_pack_group_schema: fn ->
        provider(context, :contact_allocation_capacity_pack_group_json_schema, [])
      end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end
end
