defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContention.Summary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.{
    Correlation,
    RouteMap
  }

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.InvalidInputs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps.GroundStations

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps.RequiredOperatorActions

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps.ResourceScopes

  def summary(contention_summary, summary_source, replay_scope) do
    conflict_group_count = summary_integer(contention_summary, "conflict_group_count")

    invalid_contact_input_count =
      summary_integer(contention_summary, "invalid_contact_input_count")

    invalid_contact_input_ids =
      InvalidInputs.correlated_ids(
        invalid_contact_input_count,
        Map.get(contention_summary, "invalid_contact_input_ids")
      )

    resource_scope_counts =
      ResourceScopes.correlated_counts(
        conflict_group_count,
        Map.get(contention_summary, "resource_scope_counts")
      ) || %{}

    ground_station_counts =
      GroundStations.correlated_counts(
        resource_scope_counts,
        Map.get(contention_summary, "contact_contention_ground_station_counts")
      ) || %{}

    raw_contact_id_counts =
      contention_summary
      |> Map.get("contact_contention_contact_id_counts")
      |> Correlation.map_or_empty()

    required_action_counts =
      RequiredOperatorActions.correlated_counts(
        conflict_group_count,
        invalid_contact_input_count,
        Map.get(contention_summary, "required_operator_action_counts")
      ) || %{}

    direction_counts =
      contention_summary |> Map.get("direction_counts") |> Correlation.map_or_empty()

    raw_contact_ids_by_direction = Map.get(contention_summary, "contact_ids_by_direction")

    contact_id_counts =
      Correlation.contact_id_counts(
        direction_counts,
        raw_contact_ids_by_direction,
        raw_contact_id_counts
      ) || %{}

    contact_ids_by_direction =
      Correlation.contact_ids_by_direction(
        direction_counts,
        raw_contact_ids_by_direction,
        contact_id_counts
      ) || %{}

    direction_routing =
      RouteMap.field(Correlation.positive_counts(direction_counts), contact_ids_by_direction) ||
        %{}

    %{
      "model" => "artifact_only_candidate_refresh_contact_contention_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(contention_summary, "contact_contention_report.v1"),
      "source_report_count" => summary_integer(contention_summary, "count"),
      "source_report_row_count" => summary_integer(contention_summary, "row_count"),
      "source_report_paths" => Map.get(contention_summary, "paths", []),
      "conflict_group_count" => conflict_group_count,
      "invalid_contact_input_count" => invalid_contact_input_count,
      "invalid_contact_input_ids" => invalid_contact_input_ids,
      "resource_scope_counts" => resource_scope_counts,
      "contact_contention_ground_station_counts" => ground_station_counts,
      "contact_contention_contact_id_counts" => contact_id_counts,
      "required_operator_action_counts" => required_action_counts,
      "direction_counts" => direction_counts,
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" => direction_routing,
      "trust_boundary_status" => Map.get(contention_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(contention_summary, "trust_boundaries", []),
      "branch_local_contact_contention_pressure" =>
        conflict_group_count + invalid_contact_input_count > 0 or
          invalid_contact_input_ids not in [nil, []] or
          map_size(resource_scope_counts) > 0 or map_size(ground_station_counts) > 0 or
          map_size(contact_id_counts) > 0 or map_size(required_action_counts) > 0 or
          map_size(direction_counts) > 0 or map_size(contact_ids_by_direction) > 0 or
          map_size(direction_routing) > 0,
      "branch_local_contact_contention_conflict_pressure" => conflict_group_count > 0,
      "branch_local_invalid_contact_input_pressure" =>
        invalid_contact_input_count > 0 or invalid_contact_input_ids not in [nil, []],
      "branch_local_contact_contention_review_pressure" => map_size(required_action_counts) > 0,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_contact_contention_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_contention_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
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
