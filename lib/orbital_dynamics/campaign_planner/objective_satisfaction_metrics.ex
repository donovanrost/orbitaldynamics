defmodule OrbitalDynamics.CampaignPlanner.ObjectiveSatisfactionMetrics do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ObjectiveContactIdentifiers
  alias OrbitalDynamics.CampaignPlanner.FeedbackNumericValues
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

  @observation_success_factor_fields [
    "observation_success_factor",
    "observation_success_rate",
    "observation_success",
    "success_factor",
    "success_rate",
    "realized_success_factor",
    "planned_success_factor",
    ["quality", "observation_success_factor"],
    ["metadata", "observation_success_factor"]
  ]

  def observation_success_factor(row), do: observation_success_factor(row, callbacks())

  def observation_success_factor(row, callbacks) do
    FeedbackNumericValues.first_unit_interval_activity_value(
      row,
      @observation_success_factor_fields,
      callbacks
    )
  end

  def observation_quality_reasons(
        row,
        explicit_factor,
        image_quality_score,
        image_quality_status,
        cloud_cover_fraction,
        blur_score
      ) do
    []
    |> maybe_append_reason(is_number(explicit_factor), "objective_satisfaction_success_factor")
    |> maybe_append_reason(is_number(image_quality_score), "objective_satisfaction_image_quality")
    |> maybe_append_reason(
      image_quality_status not in [nil, ""],
      "objective_satisfaction_image_quality_status"
    )
    |> maybe_append_reason(is_number(cloud_cover_fraction), "objective_satisfaction_cloud_cover")
    |> maybe_append_reason(is_number(blur_score), "objective_satisfaction_blur")
    |> maybe_append_reason(row["status"] not in [nil, ""], "objective_status_#{row["status"]}")
    |> Enum.reverse()
  end

  def quality_feedback_source(source) when is_binary(source) do
    String.replace_prefix(source, "operational_feedback.", "objective_satisfaction.")
  end

  def quality_feedback_source(_source), do: nil

  def required_collection_latency_contacts(row),
    do: required_collection_latency_contacts(row, callbacks())

  def required_collection_latency_contacts(row, callbacks) do
    row
    |> required_contacts(callbacks)
    |> case do
      value when is_number(value) -> max(ceil_count(value), 1)
      _value -> 1
    end
  end

  def required_contacts(row), do: required_contacts(row, callbacks())

  def required_contacts(row, callbacks) do
    explicit =
      [
        row["required_contacts"],
        row["required_count"],
        row["required_contact_count"]
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
      row["selected_count"],
      row["satisfied_count"],
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

  def planned_downlink_mb(row), do: planned_downlink_mb(row, callbacks())

  def planned_downlink_mb(row, callbacks) do
    [
      row["planned_downlink_mb"],
      row["selected_downlink_mb"],
      row["satisfied_downlink_mb"],
      row["planned_data_volume_mb"],
      row["selected_data_volume_mb"],
      row["satisfied_data_volume_mb"],
      row["actual_data_volume_mb"],
      row["delivered_data_volume_mb"],
      row["received_data_volume_mb"],
      row["planned_volume_mb"],
      row["selected_volume_mb"],
      row["satisfied_volume_mb"],
      row["actual_volume_mb"],
      observation_context_number(
        row,
        [
          "planned_downlink_mb",
          "selected_downlink_mb",
          "satisfied_downlink_mb",
          "planned_data_volume_mb",
          "selected_data_volume_mb",
          "satisfied_data_volume_mb",
          "actual_data_volume_mb",
          "delivered_data_volume_mb",
          "received_data_volume_mb",
          "planned_volume_mb",
          "selected_volume_mb",
          "satisfied_volume_mb",
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

  def source_contact_ids(row), do: source_contact_ids(row, callbacks())

  def source_contact_ids(row, callbacks), do: callback(callbacks, :source_contact_ids, [row])

  def contact_count(row, fields), do: contact_count(row, fields, callbacks())

  def contact_count(row, fields, callbacks),
    do: callback(callbacks, :contact_count, [row, fields])

  def pressure_reasons(row, contact_gap?, volume_gap?),
    do: pressure_reasons(row, contact_gap?, volume_gap?, callbacks())

  def pressure_reasons(row, contact_gap?, volume_gap?, callbacks) do
    []
    |> maybe_append_reason(contact_gap?, "objective_satisfaction_contact_gap")
    |> maybe_append_reason(volume_gap?, "objective_satisfaction_downlink_volume_gap")
    |> maybe_append_reason(
      score_term_downlink_gap?(row, callbacks),
      "objective_satisfaction_score_term_downlink_gap"
    )
    |> maybe_append_reason(
      score_term_contact_gap?(row, callbacks),
      "objective_satisfaction_score_term_contact_gap"
    )
    |> maybe_append_reason(row["status"] not in [nil, ""], "objective_status_#{row["status"]}")
    |> Enum.reverse()
  end

  def collection_latency_reasons(row), do: collection_latency_reasons(row, callbacks())

  def collection_latency_reasons(row, callbacks) do
    required_downlink_mb = required_downlink_mb(row, callbacks)
    planned_downlink_mb = planned_downlink_mb(row, callbacks)
    planned_latency_s = planned_latency_s(row, callbacks)
    max_latency_s = max_latency_s(row, callbacks)

    []
    |> maybe_append_reason(true, "collection_latency_gap")
    |> maybe_append_reason(row["status"] not in [nil, ""], "objective_status_#{row["status"]}")
    |> maybe_append_reason(
      is_number(max_latency_s) and
        (is_nil(planned_latency_s) or planned_latency_s > max_latency_s),
      "objective_satisfaction_latency_gap"
    )
    |> maybe_append_reason(
      is_number(required_downlink_mb) and required_downlink_mb > planned_downlink_mb,
      "objective_satisfaction_downlink_volume_gap"
    )
    |> maybe_append_reason(
      score_term_downlink_gap?(row, callbacks),
      "objective_satisfaction_score_term_downlink_gap"
    )
    |> maybe_append_reason(
      score_term_contact_gap?(row, callbacks),
      "objective_satisfaction_score_term_contact_gap"
    )
    |> maybe_append_reason(
      row["realized_status"] not in [nil, ""],
      "realized_downlink_#{row["realized_status"]}"
    )
    |> maybe_append_reason(
      row["contact_result"] not in [nil, ""],
      "realized_downlink_contact_result_#{row["contact_result"]}"
    )
    |> Enum.reverse()
  end

  def latency_window_start_s(row), do: latency_window_start_s(row, callbacks())

  def latency_window_start_s(row, callbacks) do
    numeric_or_nil(
      window_start_s(row, callbacks) || row["source_activity_ends_at_s"] ||
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
        window_end_s(row, callbacks) || row["deadline_s"] ||
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

      is_number(start_s) and is_number(max_latency_s) ->
        start_s + max_latency_s

      true ->
        nil
    end
  end

  def window_start_s(row), do: window_start_s(row, callbacks())

  def window_start_s(row, callbacks) do
    numeric_or_nil(row["starts_at_s"] || row["start_s"] || row["window_starts_at_s"], callbacks)
  end

  def window_end_s(row), do: window_end_s(row, callbacks())

  def window_end_s(row, callbacks) do
    numeric_or_nil(row["ends_at_s"] || row["end_s"] || row["window_ends_at_s"], callbacks)
  end

  def trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
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

  defp callbacks do
    [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      feedback_value_missing?: &feedback_value_missing?/1,
      observation_context_number: &ObjectivePressureContexts.observation_context_number/2,
      contact_count: &ObjectiveContactIdentifiers.contact_count/2,
      source_contact_ids: &ObjectiveContactIdentifiers.source_contact_ids/1,
      score_term_downlink_gap: &score_term_downlink_gap/1,
      score_term_downlink_gap?: &score_term_downlink_gap?/1,
      score_term_contact_gap: &score_term_contact_gap/1,
      score_term_contact_gap?: &score_term_contact_gap?/1
    ]
  end

  defp score_term_downlink_gap(row), do: ScoreTermValues.number(row, @downlink_gap_fields)
  defp score_term_contact_gap(row), do: ScoreTermValues.number(row, @contact_gap_fields)

  defp score_term_downlink_gap?(row),
    do: ScalarValues.positive_number?(score_term_downlink_gap(row))

  defp score_term_contact_gap?(row),
    do: ScalarValues.positive_number?(score_term_contact_gap(row))

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

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp numeric_or_nil(value, callbacks), do: callback(callbacks, :numeric_or_nil, [value])

  defp observation_context_number(row, fields, callbacks),
    do: callback(callbacks, :observation_context_number, [row, fields])

  defp score_term_downlink_gap(row, callbacks),
    do: callback(callbacks, :score_term_downlink_gap, [row])

  defp score_term_downlink_gap?(row, callbacks),
    do: callback(callbacks, :score_term_downlink_gap?, [row])

  defp score_term_contact_gap(row, callbacks),
    do: callback(callbacks, :score_term_contact_gap, [row])

  defp score_term_contact_gap?(row, callbacks),
    do: callback(callbacks, :score_term_contact_gap?, [row])

  defp ceil_count(value) when is_integer(value), do: max(value, 0)
  defp ceil_count(value) when is_float(value), do: value |> Float.ceil() |> trunc() |> max(0)

  defp maybe_append_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_reason(reasons, false, _reason), do: reasons

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false
end
