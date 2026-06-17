defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.Summary do
  @moduledoc false

  alias __MODULE__.Relay
  alias __MODULE__.Routing
  alias __MODULE__.Throughput

  def summary(link_summary, summary_source, replay_scope) do
    throughput_replay = Throughput.fields(link_summary)
    relay_replay = Relay.fields(link_summary)
    routing_replay = Routing.fields(link_summary)

    source_report_paths = Map.get(link_summary, "paths") || []

    capacity_adjusted_throughput_pressure =
      Throughput.capacity_adjusted_pressure?(throughput_replay)

    %{
      "model" => "artifact_only_candidate_refresh_link_capacity_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(link_summary, "link_capacity_report.v1"),
      "source_report_count" => summary_integer(link_summary, "count"),
      "source_report_row_count" => summary_integer(link_summary, "row_count"),
      "source_report_paths" => source_report_paths,
      "trust_boundary_status" => Map.get(link_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(link_summary, "trust_boundaries", []),
      "branch_local_link_capacity_pressure" =>
        Throughput.link_capacity_pressure?(throughput_replay) or
          Routing.pressure?(routing_replay) or Relay.pressure?(relay_replay) or
          capacity_adjusted_throughput_pressure,
      "branch_local_capacity_adjusted_throughput_pressure" =>
        capacity_adjusted_throughput_pressure,
      "branch_local_downlink_shortfall_pressure" =>
        Throughput.shortfall_pressure?(throughput_replay),
      "branch_local_actual_throughput_pressure" => Throughput.actual_pressure?(throughput_replay),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_link_capacity_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_link_capacity_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(routing_replay)
    |> Map.merge(relay_replay)
    |> Map.merge(throughput_replay)
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

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
