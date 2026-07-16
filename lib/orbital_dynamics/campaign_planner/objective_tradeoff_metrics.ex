defmodule OrbitalDynamics.CampaignPlanner.ObjectiveTradeoffMetrics do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ObjectiveContactIdentifiers
  alias OrbitalDynamics.CampaignPlanner.ObjectivePressureContexts
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ScoreTermValues

  @downlink_gap_fields [
    "downlink_shortfall_mb",
    "selected_downlink_shortfall_mb",
    "missing_downlink_mb",
    "downlink_completion_gap_mb",
    "required_downlink_gap_mb"
  ]

  @contact_gap_fields [
    "contact_count_gap",
    "downlink_contact_gap",
    "missing_contact_count",
    "downlink_contact_shortfall_count"
  ]

  def required_downlink_mb(row), do: required_downlink_mb(row, callbacks())

  def required_downlink_mb(row, callbacks) do
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
        row["missing_downlink_mb"],
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
            "min_downlink_mb",
            "missing_downlink_mb"
          ],
          callbacks
        )
      ]
      |> Enum.map(&numeric_or_nil(&1, callbacks))
      |> Enum.find(&is_number/1)

    explicit || required_downlink_mb_from_score_terms(row, callbacks)
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

  def required_contacts(row), do: required_contacts(row, callbacks())

  def required_contacts(row, callbacks) do
    explicit =
      [
        row["required_contacts"],
        row["required_contact_count"],
        row["expected_contact_count"]
      ]
      |> Enum.map(&numeric_or_nil(&1, callbacks))
      |> Enum.find(&is_number/1)

    explicit ||
      contact_count(
        row,
        [
          "required_contact_ids",
          "required_contact_id",
          "required_contacts",
          "required_contact",
          "required_downlink_contact_ids",
          "required_downlink_contact_id",
          "required_downlink_contacts",
          "required_downlink_contact",
          "candidate_contact_ids",
          "candidate_contact_id",
          "candidate_contacts",
          "candidate_contact"
        ],
        callbacks
      ) ||
      required_contacts_from_score_terms(row, callbacks)
  end

  def planned_contacts(row), do: planned_contacts(row, callbacks())

  def planned_contacts(row, callbacks) do
    [
      row["planned_contacts"],
      row["selected_contact_count"],
      row["satisfied_contact_count"],
      row["planned_contact_count"]
    ]
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) ->
        value

      _value ->
        contact_count(
          row,
          [
            "planned_contact_ids",
            "planned_contact_id",
            "planned_contacts",
            "planned_contact",
            "selected_contact_ids",
            "selected_contact_id",
            "selected_contacts",
            "selected_contact",
            "satisfied_contact_ids",
            "satisfied_contact_id",
            "satisfied_contacts",
            "satisfied_contact"
          ],
          callbacks
        ) || 0
    end
  end

  def downlink_objective?(row) do
    row["objective"] in ["downlink_completion", "collection_latency"] or
      row["objective_type"] in ["downlink_completion", "collection_latency"]
  end

  def collection_latency_objective?(row),
    do: row["objective"] == "collection_latency" or row["objective_type"] == "collection_latency"

  def collection_latency_gap?(row), do: collection_latency_gap?(row, callbacks())

  def collection_latency_gap?(row, callbacks) do
    collection_latency_objective?(row) and
      case {max_latency_s(row, callbacks), planned_latency_s(row, callbacks)} do
        {max_latency_s, planned_latency_s}
        when is_number(max_latency_s) and is_number(planned_latency_s) ->
          planned_latency_s > max_latency_s

        {max_latency_s, nil} when is_number(max_latency_s) ->
          true

        _latency ->
          false
      end
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
        row["collection_end_s"] ||
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
          row["delivery_deadline_s"] || row["latency_deadline_s"] ||
          observation_context_number(
            row,
            [
              "deadline_s",
              "delivery_deadline_s",
              "latency_deadline_s"
            ],
            callbacks
          ),
        callbacks
      )

    start_s = latency_window_start_s(row, callbacks)
    max_latency_s = max_latency_s(row, callbacks)

    cond do
      is_number(explicit_end) ->
        explicit_end

      collection_latency_objective?(row) and is_number(start_s) and is_number(max_latency_s) ->
        start_s + max_latency_s

      true ->
        nil
    end
  end

  def downlink_reasons(row, contact_gap?, volume_gap?, latency_gap?),
    do: downlink_reasons(row, contact_gap?, volume_gap?, latency_gap?, callbacks())

  def downlink_reasons(row, contact_gap?, volume_gap?, latency_gap?, callbacks) do
    []
    |> maybe_append_reason(true, "objective_tradeoff_downlink_gap")
    |> maybe_append_reason(latency_gap?, "collection_latency_gap")
    |> maybe_append_reason(latency_gap?, "objective_tradeoff_latency_gap")
    |> maybe_append_reason(contact_gap?, "objective_tradeoff_contact_count_gap")
    |> maybe_append_reason(volume_gap?, "objective_tradeoff_downlink_volume_gap")
    |> maybe_append_reason(
      score_term_downlink_gap?(row, callbacks),
      "objective_tradeoff_score_term_downlink_gap"
    )
    |> maybe_append_reason(
      score_term_contact_gap?(row, callbacks),
      "objective_tradeoff_score_term_contact_gap"
    )
    |> maybe_append_reason(row["selected"] == false, "objective_tradeoff_unselected")
    |> Enum.reverse()
  end

  def trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  def score_term_downlink_gap?(row), do: score_term_downlink_gap?(row, callbacks())

  def score_term_downlink_gap?(row, callbacks),
    do: positive_number?(score_term_downlink_gap(row, callbacks))

  def score_term_contact_gap?(row), do: score_term_contact_gap?(row, callbacks())

  def score_term_contact_gap?(row, callbacks),
    do: positive_number?(score_term_contact_gap(row, callbacks))

  def score_term_downlink_gap(row), do: score_term_downlink_gap(row, callbacks())

  def score_term_downlink_gap(row, callbacks) do
    score_term_number(row, @downlink_gap_fields, callbacks)
  end

  def score_term_contact_gap(row), do: score_term_contact_gap(row, callbacks())

  def score_term_contact_gap(row, callbacks) do
    score_term_number(row, @contact_gap_fields, callbacks)
  end

  defp required_downlink_mb_from_score_terms(row, callbacks) do
    case score_term_downlink_gap(row, callbacks) do
      gap when is_number(gap) and gap > 0.0 ->
        planned_downlink_mb(row, callbacks) + gap

      _gap ->
        nil
    end
  end

  defp required_contacts_from_score_terms(row, callbacks) do
    case score_term_contact_gap(row, callbacks) do
      gap when is_number(gap) and gap > 0.0 ->
        planned_contacts(row, callbacks) + gap

      _gap ->
        nil
    end
  end

  defp callbacks do
    [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      observation_context_number: &ObjectivePressureContexts.observation_context_number/2,
      contact_count: &ObjectiveContactIdentifiers.contact_count/2,
      score_term_number: &ScoreTermValues.number/2
    ]
  end

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp numeric_or_nil(value, callbacks), do: callback(callbacks, :numeric_or_nil, [value])

  defp observation_context_number(row, fields, callbacks),
    do: callback(callbacks, :observation_context_number, [row, fields])

  defp contact_count(row, fields, callbacks),
    do: callback(callbacks, :contact_count, [row, fields])

  defp score_term_number(row, keys, callbacks),
    do: callback(callbacks, :score_term_number, [row, keys])

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp maybe_append_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_reason(reasons, false, _reason), do: reasons
end
