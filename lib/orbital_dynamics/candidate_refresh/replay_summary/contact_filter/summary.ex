defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.Summary do
  @moduledoc false

  alias __MODULE__.FilterFields
  alias __MODULE__.Pressure

  def summary(filter_summary, summary_source, replay_scope) do
    suppressed_candidate_count =
      summary_integer(filter_summary, "suppressed_candidate_count")

    invalid_contact_input_count =
      summary_integer(filter_summary, "invalid_contact_input_count")

    station_suppression_count =
      summary_integer(filter_summary, "station_suppression_count")

    filter_fields = FilterFields.fields(filter_summary)

    pressure_fields =
      Pressure.fields(
        filter_fields,
        suppressed_candidate_count,
        invalid_contact_input_count,
        station_suppression_count
      )

    source_report_paths = Map.get(filter_summary, "paths") || []

    %{
      "model" => "artifact_only_candidate_refresh_contact_filter_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(filter_summary, "contact_filter_report.v1"),
      "source_report_count" => summary_integer(filter_summary, "count"),
      "source_report_row_count" => summary_integer(filter_summary, "row_count"),
      "source_report_paths" => source_report_paths,
      "suppressed_candidate_count" => suppressed_candidate_count,
      "invalid_contact_input_count" => invalid_contact_input_count,
      "station_suppression_count" => station_suppression_count,
      "trust_boundary_status" => Map.get(filter_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(filter_summary, "trust_boundaries", []),
      "branch_local_contact_filter_pressure" =>
        Map.get(pressure_fields, "branch_local_contact_filter_pressure"),
      "branch_local_candidate_suppression_pressure" =>
        Map.get(pressure_fields, "branch_local_candidate_suppression_pressure"),
      "branch_local_invalid_contact_input_pressure" =>
        Map.get(pressure_fields, "branch_local_invalid_contact_input_pressure"),
      "branch_local_station_suppression_pressure" =>
        Map.get(pressure_fields, "branch_local_station_suppression_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_contact_filter_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_filter_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(filter_fields)
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
