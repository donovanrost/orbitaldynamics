defmodule OrbitalDynamics.CampaignPlanner.ProviderCounterofferPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ScalarValues, ValueEncoding}

  def pressure_branch(row, source_path, index),
    do: pressure_branch(row, source_path, index, default_callbacks())

  def pressure_branch(row, source_path, index, opts) when is_list(opts) do
    case pressure_event(row, source_path, opts) do
      nil ->
        []

      event ->
        identity = pressure_identity(row, index, opts)

        [
          %{
            "id" => "derived_provider_counteroffer_pressure_#{identity}",
            "label" => "Derived provider-counteroffer review #{identity}",
            "events" => [event],
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_event(row, source_path), do: pressure_event(row, source_path, default_callbacks())

  def pressure_event(row, source_path, opts) when is_list(opts) do
    stable_id_string? = Keyword.fetch!(opts, :stable_id_string?)
    counteroffer_id = provider_counteroffer_id(row)

    if stable_id_string?.(counteroffer_id) and reviewable?(row) do
      compact_map = Keyword.fetch!(opts, :compact_map)
      operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)

      %{
        "type" => "provider_counteroffer_pressure",
        "provider_counteroffer_id" => counteroffer_id,
        "provider_counteroffer_status" => row["provider_counteroffer_status"],
        "provider_counteroffer_negotiation_state" =>
          row["provider_counteroffer_negotiation_state"],
        "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_lock_deadline_status" =>
          row["provider_counteroffer_lock_deadline_status"],
        "provider_counteroffer_import_status" => row["provider_counteroffer_import_status"],
        "import_readiness_status" => row["import_readiness_status"],
        "import_classification" => row["import_classification"],
        "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
        "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
        "provider_counteroffer_start_delta_s" => row["provider_counteroffer_start_delta_s"],
        "provider_counteroffer_end_delta_s" => row["provider_counteroffer_end_delta_s"],
        "provider_counteroffer_duration_delta_s" => row["provider_counteroffer_duration_delta_s"],
        "plan_impact_status" => row["plan_impact_status"],
        "affected_station_calendar_entry_ids" => row["affected_station_calendar_entry_ids"],
        "affected_provider_entry_ids" => row["affected_provider_entry_ids"],
        "impact_counteroffer_ids" => row["impact_counteroffer_ids"],
        "ground_station_id" => row["ground_station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_availability" => row["station_availability"],
        "required_operator_action" => row["required_operator_action"],
        "derivation_reasons" => pressure_reasons(row, opts),
        "feedback_source" => source_path,
        "feedback_scope" => "provider_counteroffer",
        "feedback_key" => counteroffer_id,
        "trust_boundary" => operator_review_trust_boundary.(row),
        "source_provider_counteroffer" => Map.get(row, "source_provider_counteroffer", row),
        "assumptions" => %{
          "provider_write" => "not_performed_by_strategy_branch",
          "schedule_mutation" => "not_performed_by_strategy_branch",
          "operator_authority" => "not_granted_by_strategy_branch"
        }
      }
      |> compact_map.()
    end
  end

  defp pressure_reasons(row, opts) do
    numeric_or_nil = Keyword.fetch!(opts, :numeric_or_nil)

    [
      "provider_counteroffer_review",
      row["plan_impact_status"] && "provider_counteroffer_plan_impact",
      row["provider_counteroffer_import_status"] &&
        "provider_counteroffer_import_readiness",
      row["import_readiness_status"] && "provider_counteroffer_import_readiness",
      numeric_or_nil.(row["provider_counteroffer_cost_delta"]) &&
        "provider_counteroffer_cost_delta",
      timing_shift?(row, opts) && "provider_counteroffer_timing_shift",
      numeric_or_nil.(row["provider_counteroffer_lock_deadline_s"]) &&
        "provider_counteroffer_lock_deadline"
    ]
    |> Enum.reject(&(&1 in [nil, false, ""]))
    |> Enum.uniq()
  end

  defp timing_shift?(row, opts) do
    numeric_or_nil = Keyword.fetch!(opts, :numeric_or_nil)

    Enum.any?(
      [
        row["provider_counteroffer_start_delta_s"],
        row["provider_counteroffer_end_delta_s"],
        row["provider_counteroffer_duration_delta_s"]
      ],
      fn value ->
        case numeric_or_nil.(value) do
          nil -> false
          number -> number != 0
        end
      end
    )
  end

  defp reviewable?(row) do
    row["reviewable"] == true and
      row["required_operator_action"] == "review_provider_counteroffer"
  end

  defp provider_counteroffer_id(row) do
    row["provider_counteroffer_id"] ||
      get_in(row, ["source_provider_counteroffer", "provider_counteroffer_id"]) ||
      row["id"]
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      provider_counteroffer_id(row),
      row["station_calendar_entry_id"],
      row["station_calendar_provider_entry_id"],
      row["id"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp default_callbacks,
    do: [
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      operator_review_trust_boundary: &operator_review_trust_boundary/1,
      compact_map: &ValueEncoding.compact_map/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1
    ]

  defp operator_review_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
