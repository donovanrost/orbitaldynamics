defmodule OrbitalDynamics.CampaignPlanner.ScoreTermPressureMetrics do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ObjectivePressureContexts
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ScoreTermValues
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  @latency_gap_fields [
    "collection_latency_gap_s",
    "latency_gap_s",
    "delivery_latency_gap_s",
    "collection_latency_shortfall_s",
    "late_delivery_s"
  ]

  def downlink_gap(row), do: downlink_gap(row, callbacks())

  def downlink_gap(row, callbacks) do
    gap_value(
      row,
      [
        "downlink_shortfall_mb",
        "selected_downlink_shortfall_mb",
        "missing_downlink_mb",
        "downlink_completion_gap_mb",
        "required_downlink_gap_mb"
      ],
      callbacks
    )
  end

  def contact_gap(row), do: contact_gap(row, callbacks())

  def contact_gap(row, callbacks) do
    gap_value(
      row,
      [
        "contact_count_gap",
        "downlink_contact_gap",
        "missing_contact_count",
        "downlink_contact_shortfall_count"
      ],
      callbacks
    )
  end

  def target_gap(row), do: target_gap(row, callbacks())

  def target_gap(row, callbacks) do
    gap_value(
      row,
      [
        "observation_count_gap",
        "missing_observation_count",
        "target_observation_gap_count",
        "missed_target_count",
        "target_gap_count",
        "target_coverage_gap_count",
        "coverage_gap_count",
        "observation_shortfall_count",
        "revisit_gap_count",
        "missing_revisit_count",
        "target_revisit_gap_count",
        "revisit_shortfall_count",
        "coverage_shortfall_count"
      ],
      callbacks
    )
  end

  def latency_gap(row), do: latency_gap(row, callbacks())

  def latency_gap(row, callbacks) do
    gap_value(row, @latency_gap_fields, callbacks)
  end

  def collection_latency_objective?(row), do: collection_latency_objective?(row, callbacks())

  def collection_latency_objective?(row, callbacks) do
    row["objective"] == "collection_latency" or row["objective_type"] == "collection_latency" or
      row["term_key"] in @latency_gap_fields or
      is_number(number(row, @latency_gap_fields, callbacks))
  end

  def planned_downlink_mb(row), do: planned_downlink_mb(row, callbacks())

  def planned_downlink_mb(row, callbacks) do
    [
      row["planned_downlink_mb"],
      row["selected_downlink_mb"],
      row["actual_downlink_mb"],
      row["planned_data_volume_mb"],
      row["selected_data_volume_mb"],
      row["actual_data_volume_mb"],
      row["delivered_data_volume_mb"],
      row["received_data_volume_mb"],
      row["planned_volume_mb"],
      row["selected_volume_mb"],
      row["actual_volume_mb"],
      observation_context_number(
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
    ]
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) -> value
      _value -> 0.0
    end
  end

  def required_downlink_mb(row, downlink_gap),
    do: required_downlink_mb(row, downlink_gap, callbacks())

  def required_downlink_mb(row, downlink_gap, callbacks) do
    explicit =
      [
        row["required_downlink_mb"],
        row["target_downlink_mb"],
        row["downlink_requirement_mb"],
        row["required_volume_mb"],
        row["required_data_volume_mb"],
        row["target_volume_mb"],
        row["target_data_volume_mb"],
        row["min_downlink_mb"],
        observation_context_number(
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
      ]
      |> Enum.map(&numeric_or_nil(&1, callbacks))
      |> Enum.find(&is_number/1)

    cond do
      is_number(explicit) ->
        explicit

      positive_number?(downlink_gap, callbacks) ->
        planned_downlink_mb(row, callbacks) + downlink_gap

      true ->
        nil
    end
  end

  def planned_contacts(row), do: planned_contacts(row, callbacks())

  def planned_contacts(row, callbacks) do
    [
      row["planned_contacts"],
      row["selected_contact_count"],
      row["planned_contact_count"]
    ]
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) -> value
      _value -> 0
    end
  end

  def required_contacts(row, contact_gap), do: required_contacts(row, contact_gap, callbacks())

  def required_contacts(row, contact_gap, callbacks) do
    explicit =
      [
        row["required_contacts"],
        row["required_contact_count"],
        row["expected_contact_count"]
      ]
      |> Enum.map(&numeric_or_nil(&1, callbacks))
      |> Enum.find(&is_number/1)

    cond do
      is_number(explicit) -> explicit
      positive_number?(contact_gap, callbacks) -> planned_contacts(row, callbacks) + contact_gap
      true -> 1
    end
  end

  def planned_observations(row), do: planned_observations(row, callbacks())

  def planned_observations(row, callbacks) do
    [
      row["planned_observations"],
      row["selected_observation_count"],
      row["planned_observation_count"],
      row["selected_count"],
      row["planned_revisits"],
      row["selected_revisits"],
      row["satisfied_revisits"],
      row["planned_revisit_count"],
      row["selected_revisit_count"],
      row["satisfied_revisit_count"],
      row["target_planned_revisit_count"],
      row["planned_coverage_count"],
      row["selected_coverage_count"],
      row["satisfied_coverage_count"],
      row["target_planned_coverage_count"]
    ]
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) -> value
      _value -> 0
    end
  end

  def required_observations(row, target_gap),
    do: required_observations(row, target_gap, callbacks())

  def required_observations(row, target_gap, callbacks) do
    explicit =
      [
        row["required_observations"],
        row["required_observation_count"],
        row["required_count"],
        row["required_revisits"],
        row["required_revisit_count"],
        row["target_required_revisit_count"],
        row["required_coverage_count"],
        row["target_required_coverage_count"]
      ]
      |> Enum.map(&numeric_or_nil(&1, callbacks))
      |> Enum.find(&is_number/1)

    cond do
      is_number(explicit) ->
        max(ceil_count(explicit, callbacks), 1)

      positive_number?(target_gap, callbacks) ->
        max(ceil_count(planned_observations(row, callbacks) + target_gap, callbacks), 1)

      true ->
        1
    end
  end

  def window_start_s(row), do: window_start_s(row, callbacks())

  def window_start_s(row, callbacks) do
    numeric_or_nil(
      row["starts_at_s"] || row["start_s"] || row["window_starts_at_s"] ||
        observation_context_number(
          row,
          ["starts_at_s", "start_s", "window_starts_at_s"],
          callbacks
        ),
      callbacks
    )
  end

  def window_end_s(row), do: window_end_s(row, callbacks())

  def window_end_s(row, callbacks) do
    numeric_or_nil(
      row["ends_at_s"] || row["end_s"] || row["window_ends_at_s"] ||
        observation_context_number(row, ["ends_at_s", "end_s", "window_ends_at_s"], callbacks),
      callbacks
    )
  end

  def max_latency_s(row), do: max_latency_s(row, callbacks())

  def max_latency_s(row, callbacks) do
    numeric_or_nil(
      row["max_latency_s"] || row["required_latency_s"] || row["target_latency_s"] ||
        row["latency_limit_s"] || row["max_delivery_latency_s"] ||
        row["required_delivery_latency_s"] ||
        observation_context_number(
          row,
          [
            "max_latency_s",
            "required_latency_s",
            "target_latency_s",
            "latency_limit_s",
            "max_delivery_latency_s",
            "required_delivery_latency_s"
          ],
          callbacks
        ),
      callbacks
    )
  end

  def planned_latency_s(row), do: planned_latency_s(row, callbacks())

  def planned_latency_s(row, callbacks) do
    numeric_or_nil(
      row["planned_latency_s"] || row["actual_latency_s"] || row["delivery_latency_s"] ||
        row["planned_delivery_latency_s"] || row["actual_delivery_latency_s"] ||
        observation_context_number(
          row,
          [
            "planned_latency_s",
            "actual_latency_s",
            "delivery_latency_s",
            "planned_delivery_latency_s",
            "actual_delivery_latency_s"
          ],
          callbacks
        ),
      callbacks
    )
  end

  def latency_window_start_s(row), do: latency_window_start_s(row, callbacks())

  def latency_window_start_s(row, callbacks) do
    numeric_or_nil(
      row["starts_at_s"] || row["window_starts_at_s"] || row["source_activity_ends_at_s"] ||
        row["observation_ends_at_s"] || row["collection_ends_at_s"] ||
        row["collection_end_s"] || row["start_s"] ||
        observation_context_number(
          row,
          [
            "source_activity_ends_at_s",
            "observation_ends_at_s",
            "collection_ends_at_s",
            "collection_end_s",
            "ends_at_s",
            "end_s"
          ],
          callbacks
        ),
      callbacks
    )
  end

  def latency_window_end_s(row), do: latency_window_end_s(row, callbacks())

  def latency_window_end_s(row, callbacks) do
    explicit_end =
      numeric_or_nil(
        row["ends_at_s"] || row["window_ends_at_s"] || row["deadline_s"] ||
          row["delivery_deadline_s"] || row["latency_deadline_s"] || row["end_s"] ||
          observation_context_number(
            row,
            ["deadline_s", "delivery_deadline_s", "latency_deadline_s"],
            callbacks
          ),
        callbacks
      )

    start_s = latency_window_start_s(row, callbacks)
    max_latency_s = max_latency_s(row, callbacks)

    cond do
      is_number(explicit_end) -> explicit_end
      is_number(start_s) and is_number(max_latency_s) -> start_s + max_latency_s
      true -> nil
    end
  end

  def target_priority(row, target_spec), do: target_priority(row, target_spec, callbacks())

  def target_priority(row, target_spec, callbacks) do
    [
      target_spec["priority"],
      target_spec["target_priority"],
      row["priority"],
      row["target_priority"],
      number(row, ["target_value"], callbacks),
      row["timeline_score"]
    ]
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
  end

  def target_number(row, target_spec, field),
    do: target_number(row, target_spec, field, callbacks())

  def target_number(row, target_spec, field, callbacks) do
    numeric_or_nil(Map.get(target_spec, field) || Map.get(row, field), callbacks)
  end

  def downlink_source(row), do: downlink_source(row, callbacks())

  def downlink_source(row, callbacks) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)

    [
      "score_term",
      row["id"] || row["scenario_id"] || row["term_key"] || "row",
      row["term_key"] || "gap"
    ]
    |> Enum.map(&branch_id_fragment.(&1))
    |> Enum.join(":")
  end

  def downlink_reasons(row, contact_gap, downlink_gap),
    do: downlink_reasons(row, contact_gap, downlink_gap, callbacks())

  def downlink_reasons(row, contact_gap, downlink_gap, callbacks) do
    []
    |> append_reason(positive_number?(downlink_gap, callbacks), "score_term_downlink_volume_gap")
    |> append_reason(positive_number?(contact_gap, callbacks), "score_term_contact_count_gap")
    |> append_reason(row["term_key"] not in [nil, ""], "score_term_#{row["term_key"]}")
    |> Enum.reverse()
    |> Enum.uniq()
  end

  def target_reasons(row) do
    []
    |> append_reason(true, "score_term_target_gap")
    |> append_reason(row["term_key"] not in [nil, ""], "score_term_#{row["term_key"]}")
    |> Enum.reverse()
    |> Enum.uniq()
  end

  def latency_reasons(row, latency_gap), do: latency_reasons(row, latency_gap, callbacks())

  def latency_reasons(row, latency_gap, callbacks) do
    []
    |> append_reason(true, "collection_latency_gap")
    |> append_reason(true, "score_term_collection_latency_gap")
    |> append_reason(positive_number?(latency_gap, callbacks), "score_term_latency_gap")
    |> append_reason(row["term_key"] not in [nil, ""], "score_term_#{row["term_key"]}")
    |> Enum.reverse()
    |> Enum.uniq()
  end

  def trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp callbacks do
    [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      positive_number?: &ScalarValues.positive_number?/1,
      ceil_count: &ScalarValues.ceil_count/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      observation_context_number: &observation_context_number/2
    ]
  end

  defp objective_pressure_context_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1
    ]
  end

  defp observation_context_number(row, fields) do
    ObjectivePressureContexts.observation_context_number(
      row,
      fields,
      objective_pressure_context_callbacks()
    )
  end

  defp gap_value(row, keys, callbacks) do
    cond do
      row["term_key"] in keys ->
        value(row, callbacks)

      is_map(row["score_terms"]) ->
        number(row, keys, callbacks)

      true ->
        nil
    end
  end

  defp value(row, callbacks) do
    ScoreTermValues.value(row, score_term_value_callbacks(callbacks))
  end

  defp number(row, keys, callbacks) do
    ScoreTermValues.number(row, keys, score_term_value_callbacks(callbacks))
  end

  defp score_term_value_callbacks(callbacks) do
    [numeric_or_nil: Keyword.fetch!(callbacks, :numeric_or_nil)]
  end

  defp observation_context_number(row, fields, callbacks) do
    callbacks
    |> Keyword.fetch!(:observation_context_number)
    |> then(& &1.(row, fields))
  end

  defp numeric_or_nil(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:numeric_or_nil)
    |> then(& &1.(value))
  end

  defp positive_number?(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:positive_number?)
    |> then(& &1.(value))
  end

  defp ceil_count(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:ceil_count)
    |> then(& &1.(value))
  end

  defp append_reason(reasons, true, reason), do: [reason | reasons]
  defp append_reason(reasons, false, _reason), do: reasons
end
