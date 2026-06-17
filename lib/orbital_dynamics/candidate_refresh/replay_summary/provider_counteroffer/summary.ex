defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.Summary do
  @moduledoc false

  alias __MODULE__.CounterofferFields
  alias __MODULE__.Pressure

  def summary(counteroffer_summary, summary_source, replay_scope) do
    reviewable_count = summary_integer(counteroffer_summary, "reviewable_count")
    cost_delta_count = summary_integer(counteroffer_summary, "counteroffer_cost_delta_count")
    timing_shift_count = summary_integer(counteroffer_summary, "counteroffer_timing_shift_count")
    start_delta_count = summary_integer(counteroffer_summary, "counteroffer_start_delta_count")
    end_delta_count = summary_integer(counteroffer_summary, "counteroffer_end_delta_count")

    duration_delta_count =
      summary_integer(counteroffer_summary, "counteroffer_duration_delta_count")

    lock_deadline_count =
      summary_integer(counteroffer_summary, "counteroffer_lock_deadline_count")

    plan_impact_summary_count = summary_integer(counteroffer_summary, "plan_impact_summary_count")

    counteroffer_fields = CounterofferFields.fields(counteroffer_summary)

    review_summary_count = summary_integer(counteroffer_summary, "review_summary_count")

    import_readiness_summary_count =
      summary_integer(counteroffer_summary, "import_readiness_summary_count")

    pressure_fields =
      Pressure.fields(counteroffer_fields, %{
        reviewable_count: reviewable_count,
        cost_delta_count: cost_delta_count,
        timing_shift_count: timing_shift_count,
        start_delta_count: start_delta_count,
        end_delta_count: end_delta_count,
        duration_delta_count: duration_delta_count,
        lock_deadline_count: lock_deadline_count,
        earliest_lock_deadline_s:
          Map.get(counteroffer_fields, "earliest_counteroffer_lock_deadline_s"),
        review_summary_count: review_summary_count,
        import_readiness_summary_count: import_readiness_summary_count,
        plan_impact_summary_count: plan_impact_summary_count
      })

    %{
      "model" => "artifact_only_candidate_refresh_provider_counteroffer_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(counteroffer_summary, "provider_counteroffer_report.v1"),
      "source_report_count" => summary_integer(counteroffer_summary, "count"),
      "source_report_row_count" => summary_integer(counteroffer_summary, "row_count"),
      "source_report_paths" => Map.get(counteroffer_summary, "paths", []),
      "reviewable_count" => reviewable_count,
      "counteroffer_cost_delta_count" => cost_delta_count,
      "counteroffer_timing_shift_count" => timing_shift_count,
      "counteroffer_start_delta_count" => start_delta_count,
      "counteroffer_end_delta_count" => end_delta_count,
      "counteroffer_duration_delta_count" => duration_delta_count,
      "counteroffer_lock_deadline_count" => lock_deadline_count,
      "review_summary_count" => review_summary_count,
      "import_readiness_summary_count" => import_readiness_summary_count,
      "plan_impact_summary_count" => plan_impact_summary_count,
      "trust_boundary_status" => Map.get(counteroffer_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(counteroffer_summary, "trust_boundaries", []),
      "branch_local_counteroffer_pressure" =>
        Map.get(pressure_fields, "branch_local_counteroffer_pressure"),
      "branch_local_counteroffer_review_pressure" =>
        Map.get(pressure_fields, "branch_local_counteroffer_review_pressure"),
      "branch_local_counteroffer_cost_pressure" =>
        Map.get(pressure_fields, "branch_local_counteroffer_cost_pressure"),
      "branch_local_counteroffer_timing_pressure" =>
        Map.get(pressure_fields, "branch_local_counteroffer_timing_pressure"),
      "branch_local_counteroffer_lock_pressure" =>
        Map.get(pressure_fields, "branch_local_counteroffer_lock_pressure"),
      "branch_local_counteroffer_import_readiness_pressure" =>
        Map.get(pressure_fields, "branch_local_counteroffer_import_readiness_pressure"),
      "branch_local_plan_impact_pressure" =>
        Map.get(pressure_fields, "branch_local_plan_impact_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_provider_counteroffer_replay_summary",
        "provider_write" => "not_performed_by_summary",
        "schedule_mutation" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_provider_counteroffer_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(counteroffer_fields)
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
