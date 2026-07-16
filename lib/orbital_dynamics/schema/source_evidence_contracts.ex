defmodule OrbitalDynamics.Schema.SourceEvidenceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_optional_one_of: 5, expect_optional_probability: 4]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  @fields [
    "source_requirement",
    "source_candidate_diff",
    "source_candidate_rejection",
    "source_contact_intent",
    "source_contact_suppression",
    "source_resource_suppression",
    "source_link_capacity",
    "source_resource_projection",
    "source_resource_projection_flow_summary",
    "source_provider_counteroffer",
    "source_contact_allocation",
    "source_contact_allocation_capacity_pack",
    "source_pareto_frontier",
    "source_ranking_comparison",
    "source_command_window",
    "source_maneuver_review",
    "source_operational_timeline",
    "source_execution_report",
    "source_freshness_report",
    "source_schema_validation_report",
    "source_operational_readiness_report",
    "source_quality_gate_report",
    "source_refresh_budget_report",
    "source_timeline_diff",
    "source_contention_group",
    "source_contention_recommendation",
    "source_recommendation",
    "source_invalid_contact_input",
    "source_station_calendar_review",
    "source_station_calendar_entry",
    "source_station_reservation",
    "source_feedback",
    "source_delta"
  ]
  @list_fields [
    "source_station_calendar_overlaps"
  ]
  @stable_id_list_fields [
    "kept_candidate_ids",
    "dropped_candidate_ids"
  ]
  @probability_fields [
    "contact_success_factor",
    "command_success_factor",
    "observation_success_factor",
    "maneuver_success_factor",
    "cloud_cover_fraction",
    "planned_cloud_cover_fraction",
    "realized_cloud_cover_fraction",
    "blur_score",
    "planned_blur_score",
    "realized_blur_score"
  ]
  @stable_id_fields [
    "id",
    "report_id",
    "activity_id",
    "candidate_id",
    "contact_id",
    "scenario_id",
    "spacecraft_id",
    "ground_station_id",
    "source_window_id",
    "selected_contact_id",
    "station_calendar_entry_id",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id",
    "station_reservation_id",
    "contention_group_id",
    "maneuver_id",
    "rule_id",
    "timeline_id",
    "source_timeline_id",
    "replacement_timeline_id",
    "realized_timeline_id",
    "planned_timeline_id",
    "target_id",
    "resource_id",
    "payload_id",
    "instrument_id",
    "collection_id",
    "product_id"
  ]

  def stable_id_fields, do: @stable_id_fields
  def stable_id_list_fields, do: @stable_id_list_fields
  def probability_fields, do: @probability_fields

  def validate_fields(issues, path, row, battery_fields_validator, battery_own_flow_validator)
      when is_function(battery_fields_validator, 3) and
             is_function(battery_own_flow_validator, 3) do
    issues =
      Enum.reduce(@fields, issues, fn field, acc ->
        case Map.get(row, field) do
          %{} = source ->
            validate_map(
              acc,
              "#{path}.#{field}",
              source,
              battery_fields_validator,
              battery_own_flow_validator
            )

          _source ->
            acc
        end
      end)

    Enum.reduce(@list_fields, issues, fn field, acc ->
      case Map.get(row, field) do
        sources when is_list(sources) ->
          sources
          |> Enum.with_index()
          |> Enum.reduce(acc, fn
            {%{} = source, index}, source_acc ->
              validate_map(
                source_acc,
                "#{path}.#{field}[#{index}]",
                source,
                battery_fields_validator,
                battery_own_flow_validator
              )

            {_source, _index}, source_acc ->
              source_acc
          end)

        _source ->
          acc
      end
    end)
  end

  defp validate_map(
         issues,
         path,
         source,
         battery_fields_validator,
         battery_own_flow_validator
       ) do
    issues
    |> validate_stable_ids(path, source, @stable_id_fields)
    |> validate_stable_id_lists(path, source)
    |> validate_probabilities(path, source)
    |> expect_optional_one_of(path, source, "diff_status", [
      "added",
      "removed",
      "changed",
      "unchanged"
    ])
    |> battery_fields_validator.(path, source)
    |> battery_own_flow_validator.(path, source)
  end

  defp validate_probabilities(issues, path, source) do
    Enum.reduce(@probability_fields, issues, fn field, acc ->
      expect_optional_probability(acc, path, source, field)
    end)
  end

  defp validate_stable_id_lists(issues, path, source) do
    Enum.reduce(@stable_id_list_fields, issues, fn field, acc ->
      validate_optional_stable_id_list(acc, path, source, field)
    end)
  end
end
