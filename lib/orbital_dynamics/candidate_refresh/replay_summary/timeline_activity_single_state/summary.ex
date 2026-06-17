defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.Summary do
  @moduledoc false

  alias __MODULE__.Pressure
  alias __MODULE__.StateFields

  def summary(
        state_summary,
        family,
        summary_source,
        replay_scope,
        application_boundary,
        authority_boundary
      ) do
    row_count = summary_integer(state_summary, "row_count")
    review_required_count = summary_integer(state_summary, "review_required_count")
    invalid_activity_input_count = summary_integer(state_summary, "invalid_activity_input_count")

    state_fields = StateFields.fields(state_summary)

    pressure_fields =
      Pressure.fields(family, state_fields, %{
        row_count: row_count,
        review_required_count: review_required_count,
        invalid_activity_input_count: invalid_activity_input_count
      })

    %{
      "model" => "artifact_only_candidate_refresh_#{family}_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(state_summary, nil),
      "source_report_count" => summary_integer(state_summary, "count"),
      "source_report_row_count" => row_count,
      "source_report_paths" => Map.get(state_summary, "paths", []),
      "review_required_count" => review_required_count,
      "invalid_activity_input_count" => invalid_activity_input_count,
      "trust_boundary_status" => Map.get(state_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(state_summary, "trust_boundaries", []),
      "branch_local_#{family}_pressure" =>
        Map.get(pressure_fields, "branch_local_#{family}_pressure"),
      "branch_local_#{family}_review_pressure" =>
        Map.get(pressure_fields, "branch_local_#{family}_review_pressure"),
      "branch_local_#{family}_action_pressure" =>
        Map.get(pressure_fields, "branch_local_#{family}_action_pressure"),
      "branch_local_#{family}_routing_pressure" =>
        Map.get(pressure_fields, "branch_local_#{family}_routing_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => authority_boundary,
        "timeline_mutation" => "not_performed_by_summary",
        application_boundary => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => authority_boundary,
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(state_fields)
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
