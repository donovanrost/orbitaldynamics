defmodule OrbitalDynamics.Schema.StationCalendarSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:station_calendar_contact_json_schema, 0} => fn ->
        station_calendar_contact(stable_id_pattern, dependencies)
      end,
      {:station_calendar_provider_contention_group_json_schema, 0} => fn ->
        station_calendar_provider_contention_group(stable_id_pattern, dependencies)
      end,
      {:station_calendar_provider_entry_json_schema, 0} => fn ->
        station_calendar_provider_entry(stable_id_pattern, dependencies)
      end,
      {:station_reservation_contact_json_schema, 0} => fn ->
        station_reservation_contact(stable_id_pattern, dependencies)
      end,
      {:station_reservation_hold_import_readiness_row_json_schema, 0} => fn ->
        station_reservation_hold_import_readiness_row(stable_id_pattern, dependencies)
      end,
      {:station_reservation_provider_contention_group_json_schema, 0} => fn ->
        station_reservation_provider_contention_group(stable_id_pattern, dependencies)
      end,
      {:station_reservation_review_summary_row_json_schema, 0} => fn ->
        station_reservation_review_summary_row(stable_id_pattern, dependencies)
      end
    }
  end

  defp station_calendar_contact(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.contact(
      stable_id_pattern: stable_id_pattern,
      provider_counteroffer_negotiation_states:
        call(dependencies, :provider_counteroffer_negotiation_states),
      source_entry_schema: station_calendar_report_source_entry(stable_id_pattern, dependencies),
      approval_requirement_schema: call(dependencies, :approval_requirement_schema),
      policy_decision_rule_match_schema: call(dependencies, :policy_decision_rule_match_schema),
      policy_decision_schema: call(dependencies, :policy_decision_schema)
    )
  end

  defp station_reservation_contact(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.StationReservationReportJsonSchema.contact(
      stable_id_pattern: stable_id_pattern,
      approval_requirement_schema: call(dependencies, :approval_requirement_schema),
      policy_decision_rule_match_schema: call(dependencies, :policy_decision_rule_match_schema),
      policy_decision_schema: call(dependencies, :policy_decision_schema)
    )
  end

  defp station_reservation_provider_contention_group(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.StationReservationReportJsonSchema.provider_contention_group(
      calendar_group_schema:
        station_calendar_provider_contention_group(stable_id_pattern, dependencies)
    )
  end

  defp station_reservation_review_summary_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.StationReservationReviewSummaryJsonSchema.review_row(
      stable_id_pattern: stable_id_pattern,
      base_schema: station_reservation_contact(stable_id_pattern, dependencies)
    )
  end

  defp station_reservation_hold_import_readiness_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.StationReservationHoldImportReadinessSummaryJsonSchema.import_readiness_row(
      review_row_schema: station_reservation_review_summary_row(stable_id_pattern, dependencies)
    )
  end

  defp station_calendar_report_source_entry(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.source_entry(
      stable_id_pattern: stable_id_pattern,
      provider_counteroffer_negotiation_states:
        call(dependencies, :provider_counteroffer_negotiation_states)
    )
  end

  defp station_calendar_provider_contention_group(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.provider_contention_group(
      stable_id_pattern: stable_id_pattern,
      policy_decision_schema: call(dependencies, :policy_decision_schema),
      provider_contention_pair_schema:
        station_calendar_provider_contention_pair(stable_id_pattern),
      provider_entry_schema: station_calendar_provider_entry(stable_id_pattern, dependencies)
    )
  end

  defp station_calendar_provider_contention_pair(stable_id_pattern) do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.provider_contention_pair(
      stable_id_pattern: stable_id_pattern
    )
  end

  defp station_calendar_provider_entry(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.provider_entry(
      stable_id_pattern: stable_id_pattern,
      provider_counteroffer_negotiation_states:
        call(dependencies, :provider_counteroffer_negotiation_states)
    )
  end

  defp call(dependencies, name), do: dependencies |> Map.fetch!(name) |> apply([])
end
