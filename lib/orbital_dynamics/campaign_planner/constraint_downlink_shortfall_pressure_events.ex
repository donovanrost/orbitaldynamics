defmodule OrbitalDynamics.CampaignPlanner.ConstraintDownlinkShortfallPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ConstraintPressureContext
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ScoreTermIdentifiers
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def events(row, source_path), do: events(row, source_path, callbacks())

  def events(row, source_path, callbacks) do
    if shortfall_metric?(row["metric"]) do
      shortfall = shortfall(row, callbacks)
      station_id = ground_station_id(row, callbacks)

      if is_number(shortfall) and shortfall > 0.0 and stable_id_string?(station_id, callbacks) do
        planned_downlink_mb = planned_downlink_mb(row, callbacks)
        downlink_sources = downlink_sources(row, callbacks)

        [
          %{
            "type" => "downlink_completion_gap",
            "required_downlink_mb" => required_downlink_mb(row, shortfall, callbacks),
            "planned_downlink_mb" => planned_downlink_mb,
            "scenario_id" => scenario_id(row, callbacks),
            "ground_station_id" => station_id,
            "starts_at_s" => window_start_s(row, callbacks),
            "ends_at_s" => window_end_s(row, callbacks),
            "required_contacts" => required_contacts(row, callbacks),
            "planned_contacts" => planned_contacts(row, callbacks),
            "source_activity_ids" => source_activity_ids(row, callbacks),
            "downlink_demand_sources" => downlink_sources,
            "downlink_completion_sources" => downlink_sources,
            "constraint_id" => row["constraint_id"],
            "constraint_metric" => row["metric"],
            "constraint_status" => row["status"],
            "violation_severity" => row["violation_severity"],
            "derivation_reasons" => [
              "constraint_report_#{row["status"]}",
              "constraint_downlink_shortfall"
            ],
            "feedback_source" => source_path,
            "feedback_scope" => "constraint_report",
            "trust_boundary" => trust_boundary(row, callbacks)
          }
          |> compact_map(callbacks)
        ]
      else
        []
      end
    else
      []
    end
  end

  defp shortfall_metric?(metric)
       when metric in [
              "selected_downlink_shortfall_mb",
              "max_selected_downlink_shortfall_mb",
              "downlink_shortfall_mb",
              "actual_downlink_shortfall_mb",
              "selected_data_volume_shortfall_mb",
              "max_selected_data_volume_shortfall_mb",
              "data_volume_shortfall_mb",
              "actual_data_volume_shortfall_mb",
              "missing_data_volume_mb",
              "required_data_volume_gap_mb"
            ],
       do: true

  defp shortfall_metric?(_metric), do: false

  defp shortfall(row, callbacks) do
    [
      row["value"],
      row["selected_downlink_shortfall_mb"],
      row["downlink_shortfall_mb"],
      row["actual_downlink_shortfall_mb"],
      row["selected_data_volume_shortfall_mb"],
      row["data_volume_shortfall_mb"],
      row["actual_data_volume_shortfall_mb"],
      row["missing_data_volume_mb"],
      row["required_data_volume_gap_mb"],
      get_in(row, ["throughput_model", "selected_downlink_shortfall_mb"]),
      get_in(row, ["throughput_model", "downlink_shortfall_mb"]),
      get_in(row, ["throughput_model", "actual_downlink_shortfall_mb"]),
      get_in(row, ["throughput_model", "selected_data_volume_shortfall_mb"]),
      get_in(row, ["throughput_model", "data_volume_shortfall_mb"]),
      get_in(row, ["throughput_model", "actual_data_volume_shortfall_mb"]),
      get_in(row, ["throughput_model", "missing_data_volume_mb"]),
      get_in(row, ["throughput_model", "required_data_volume_gap_mb"]),
      get_in(row, ["activity_context", "selected_downlink_shortfall_mb"]),
      get_in(row, ["activity_context", "downlink_shortfall_mb"]),
      get_in(row, ["activity_context", "actual_downlink_shortfall_mb"]),
      get_in(row, ["activity_context", "selected_data_volume_shortfall_mb"]),
      get_in(row, ["activity_context", "data_volume_shortfall_mb"]),
      get_in(row, ["activity_context", "actual_data_volume_shortfall_mb"]),
      get_in(row, ["activity_context", "missing_data_volume_mb"]),
      get_in(row, ["activity_context", "required_data_volume_gap_mb"]),
      get_in(row, ["source_contact", "selected_downlink_shortfall_mb"]),
      get_in(row, ["source_contact", "downlink_shortfall_mb"]),
      get_in(row, ["source_contact", "actual_downlink_shortfall_mb"]),
      get_in(row, ["source_contact", "selected_data_volume_shortfall_mb"]),
      get_in(row, ["source_contact", "data_volume_shortfall_mb"]),
      get_in(row, ["source_contact", "actual_data_volume_shortfall_mb"]),
      get_in(row, ["source_contact", "missing_data_volume_mb"]),
      get_in(row, ["source_contact", "required_data_volume_gap_mb"]),
      get_in(row, ["source_contact", "throughput_model", "selected_downlink_shortfall_mb"]),
      get_in(row, ["source_contact", "throughput_model", "downlink_shortfall_mb"]),
      get_in(row, ["source_contact", "throughput_model", "actual_downlink_shortfall_mb"]),
      get_in(row, ["source_contact", "throughput_model", "selected_data_volume_shortfall_mb"]),
      get_in(row, ["source_contact", "throughput_model", "data_volume_shortfall_mb"]),
      get_in(row, ["source_contact", "throughput_model", "actual_data_volume_shortfall_mb"]),
      get_in(row, ["source_contact", "throughput_model", "missing_data_volume_mb"]),
      get_in(row, ["source_contact", "throughput_model", "required_data_volume_gap_mb"]),
      get_in(row, ["source_contact", "activity_context", "selected_downlink_shortfall_mb"]),
      get_in(row, ["source_contact", "activity_context", "downlink_shortfall_mb"]),
      get_in(row, ["source_contact", "activity_context", "actual_downlink_shortfall_mb"]),
      get_in(row, ["source_contact", "activity_context", "selected_data_volume_shortfall_mb"]),
      get_in(row, ["source_contact", "activity_context", "data_volume_shortfall_mb"]),
      get_in(row, ["source_contact", "activity_context", "actual_data_volume_shortfall_mb"]),
      get_in(row, ["source_contact", "activity_context", "missing_data_volume_mb"]),
      get_in(row, ["source_contact", "activity_context", "required_data_volume_gap_mb"])
    ]
    |> Kernel.++(
      contact_downlink_field_values(
        row,
        [
          "selected_downlink_shortfall_mb",
          "downlink_shortfall_mb",
          "actual_downlink_shortfall_mb",
          "selected_data_volume_shortfall_mb",
          "data_volume_shortfall_mb",
          "actual_data_volume_shortfall_mb",
          "missing_data_volume_mb",
          "required_data_volume_gap_mb"
        ],
        callbacks
      )
    )
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
  end

  defp planned_downlink_mb(row, callbacks) do
    downlink_number(
      row,
      [
        "planned_downlink_mb",
        "selected_downlink_mb",
        "actual_downlink_mb",
        "planned_data_volume_mb",
        "selected_data_volume_mb",
        "actual_data_volume_mb",
        "delivered_data_volume_mb",
        "received_data_volume_mb",
        "planned_volume_mb",
        "selected_volume_mb",
        "actual_volume_mb"
      ],
      callbacks
    )
    |> case do
      value when is_number(value) -> max(value, 0.0)
      _value -> 0.0
    end
  end

  defp required_downlink_mb(row, shortfall, callbacks) do
    downlink_number(
      row,
      [
        "required_downlink_mb",
        "target_downlink_mb",
        "downlink_requirement_mb",
        "required_volume_mb",
        "required_data_volume_mb",
        "target_volume_mb",
        "target_data_volume_mb",
        "min_downlink_mb"
      ],
      callbacks
    )
    |> case do
      value when is_number(value) -> max(value, 0.0)
      _value -> max(planned_downlink_mb(row, callbacks) + shortfall, shortfall)
    end
  end

  defp downlink_number(row, fields, callbacks) do
    fields
    |> Enum.flat_map(fn field ->
      [
        row[field],
        get_in(row, ["throughput_model", field]),
        get_in(row, ["activity_context", field]),
        get_in(row, ["source_contact", field]),
        get_in(row, ["source_contact", "throughput_model", field]),
        get_in(row, ["source_contact", "activity_context", field])
      ]
    end)
    |> Kernel.++(contact_downlink_field_values(row, fields, callbacks))
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
  end

  defp downlink_sources(row, callbacks) do
    fields = [
      "downlink_demand_source",
      "downlink_demand_sources",
      "downlink_completion_source",
      "downlink_completion_sources"
    ]

    fields
    |> Enum.flat_map(fn field ->
      [
        row[field],
        get_in(row, ["throughput_model", field]),
        get_in(row, ["activity_context", field])
      ]
    end)
    |> Kernel.++(contact_downlink_field_values(row, fields, callbacks))
    |> List.flatten()
    |> Enum.map(&encode_value(&1, callbacks))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp ground_station_id(row, callbacks) do
    [
      row["ground_station_id"],
      row["station_id"],
      row["source_ground_station_id"],
      row["selected_ground_station_id"],
      score_term_entity_id(
        row["ground_station"],
        ["ground_station_id", "station_id", "id"],
        callbacks
      ),
      score_term_entity_id(row["station"], ["ground_station_id", "station_id", "id"], callbacks),
      score_term_entity_id(
        row["source_ground_station"],
        ["ground_station_id", "station_id", "id"],
        callbacks
      ),
      score_term_entity_id(
        row["selected_ground_station"],
        ["ground_station_id", "station_id", "id"],
        callbacks
      ),
      contact_downlink_field_values(row, ["ground_station_id", "station_id"], callbacks),
      contact_entity_ids(
        row,
        ["ground_station", "station"],
        [
          "ground_station_id",
          "station_id",
          "id"
        ],
        callbacks
      )
    ]
    |> List.flatten()
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  defp window_start_s(row, callbacks),
    do: first_number(row, ["starts_at_s", "start_s", "window_starts_at_s"], callbacks)

  defp window_end_s(row, callbacks),
    do: first_number(row, ["ends_at_s", "end_s", "window_ends_at_s"], callbacks)

  defp required_contacts(row, callbacks) do
    first_number(
      row,
      ["required_contacts", "required_contact_count", "expected_contact_count"],
      callbacks
    )
  end

  defp planned_contacts(row, callbacks) do
    first_number(
      row,
      ["planned_contacts", "selected_contact_count", "planned_contact_count"],
      callbacks
    )
  end

  defp first_number(row, fields, callbacks) do
    fields
    |> Enum.map(&row[&1])
    |> Kernel.++(contact_downlink_field_values(row, fields, callbacks))
    |> List.flatten()
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
  end

  defp callbacks do
    [
      compact_map: &ValueEncoding.compact_map/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      encode_value: &ValueEncoding.encode_value/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      score_term_entity_id: &ScoreTermIdentifiers.entity_id/2,
      source_activity_ids: &ConstraintPressureContext.source_activity_ids/1,
      scenario_id: &ConstraintPressureContext.scenario_id/1,
      trust_boundary: &ConstraintPressureContext.trust_boundary/1,
      contact_downlink_field_values: &ConstraintPressureContext.contact_downlink_field_values/2,
      contact_entity_ids: &ConstraintPressureContext.contact_entity_ids/3
    ]
  end

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp compact_map(map, callbacks), do: callback(callbacks, :compact_map, [map])
  defp numeric_or_nil(value, callbacks), do: callback(callbacks, :numeric_or_nil, [value])
  defp encode_value(value, callbacks), do: callback(callbacks, :encode_value, [value])

  defp stable_id_string?(value, callbacks),
    do: callback(callbacks, :stable_id_string?, [value])

  defp score_term_entity_id(value, fields, callbacks),
    do: callback(callbacks, :score_term_entity_id, [value, fields])

  defp source_activity_ids(row, callbacks), do: callback(callbacks, :source_activity_ids, [row])
  defp scenario_id(row, callbacks), do: callback(callbacks, :scenario_id, [row])
  defp trust_boundary(row, callbacks), do: callback(callbacks, :trust_boundary, [row])

  defp contact_downlink_field_values(row, fields, callbacks),
    do: callback(callbacks, :contact_downlink_field_values, [row, fields])

  defp contact_entity_ids(row, fields, entity_keys, callbacks),
    do: callback(callbacks, :contact_entity_ids, [row, fields, entity_keys])
end
