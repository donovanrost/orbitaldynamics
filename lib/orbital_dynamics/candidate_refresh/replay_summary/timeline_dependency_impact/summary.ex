defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact.Summary do
  @moduledoc false

  def summary(impact_summary, summary_source, replay_scope) do
    row_count = summary_integer(impact_summary, "row_count")
    source_activity_count = summary_integer(impact_summary, "source_activity_count")
    replacement_activity_count = summary_integer(impact_summary, "replacement_activity_count")

    changed_source_activity_count =
      summary_integer(impact_summary, "changed_source_activity_count")

    changed_source_timeline_count =
      summary_integer(impact_summary, "changed_source_timeline_count")

    dependent_activity_count = summary_integer(impact_summary, "dependent_activity_count")

    source_dependent_activity_count =
      summary_integer(impact_summary, "source_dependent_activity_count")

    replacement_dependent_activity_count =
      summary_integer(impact_summary, "replacement_dependent_activity_count")

    status_counts = Map.get(impact_summary, "dependency_impact_status_counts", %{})
    scope_counts = Map.get(impact_summary, "dependency_impact_scope_counts", %{})
    required_action_counts = Map.get(impact_summary, "required_operator_action_counts", %{})

    impacted_source_activity_id_counts =
      Map.get(impact_summary, "impacted_source_activity_id_counts", %{})

    impacted_source_timeline_id_counts =
      Map.get(impact_summary, "impacted_source_timeline_id_counts", %{})

    impacted_dependency_activity_id_counts =
      Map.get(impact_summary, "impacted_dependency_activity_id_counts", %{})

    impacted_dependency_timeline_id_counts =
      Map.get(impact_summary, "impacted_dependency_timeline_id_counts", %{})

    impacted_exclusive_activity_id_counts =
      Map.get(impact_summary, "impacted_exclusive_activity_id_counts", %{})

    impacted_exclusive_timeline_id_counts =
      Map.get(impact_summary, "impacted_exclusive_timeline_id_counts", %{})

    dependent_activity_id_counts = Map.get(impact_summary, "dependent_activity_id_counts", %{})
    dependent_timeline_id_counts = Map.get(impact_summary, "dependent_timeline_id_counts", %{})

    changed_source_pressure =
      changed_source_activity_count + changed_source_timeline_count > 0 or
        map_size(impacted_source_activity_id_counts) > 0 or
        map_size(impacted_source_timeline_id_counts) > 0

    dependency_pressure =
      map_size(impacted_dependency_activity_id_counts) > 0 or
        map_size(impacted_dependency_timeline_id_counts) > 0

    exclusivity_pressure =
      map_size(impacted_exclusive_activity_id_counts) > 0 or
        map_size(impacted_exclusive_timeline_id_counts) > 0

    dependent_activity_pressure =
      dependent_activity_count + source_dependent_activity_count +
        replacement_dependent_activity_count > 0 or map_size(dependent_activity_id_counts) > 0 or
        map_size(dependent_timeline_id_counts) > 0

    review_pressure =
      summary_integer(status_counts, "review_required") > 0 or
        required_action_counts |> Map.delete("none") |> map_size() > 0

    %{
      "model" => "artifact_only_candidate_refresh_timeline_dependency_impact_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(
          impact_summary,
          "timeline_dependency_impact_summary.v1"
        ),
      "source_report_count" => summary_integer(impact_summary, "count"),
      "source_report_row_count" => row_count,
      "source_report_paths" => Map.get(impact_summary, "paths", []),
      "source_activity_count" => source_activity_count,
      "replacement_activity_count" => replacement_activity_count,
      "changed_source_activity_count" => changed_source_activity_count,
      "changed_source_timeline_count" => changed_source_timeline_count,
      "dependent_activity_count" => dependent_activity_count,
      "source_dependent_activity_count" => source_dependent_activity_count,
      "replacement_dependent_activity_count" => replacement_dependent_activity_count,
      "dependency_impact_status_counts" => status_counts,
      "dependency_impact_scope_counts" => scope_counts,
      "required_operator_action_counts" => required_action_counts,
      "impacted_source_activity_id_counts" => impacted_source_activity_id_counts,
      "impacted_source_timeline_id_counts" => impacted_source_timeline_id_counts,
      "impacted_dependency_activity_id_counts" => impacted_dependency_activity_id_counts,
      "impacted_dependency_timeline_id_counts" => impacted_dependency_timeline_id_counts,
      "impacted_exclusive_activity_id_counts" => impacted_exclusive_activity_id_counts,
      "impacted_exclusive_timeline_id_counts" => impacted_exclusive_timeline_id_counts,
      "dependent_activity_id_counts" => dependent_activity_id_counts,
      "dependent_timeline_id_counts" => dependent_timeline_id_counts,
      "trust_boundary_status" => Map.get(impact_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(impact_summary, "trust_boundaries", []),
      "branch_local_timeline_dependency_impact_pressure" =>
        row_count > 0 or changed_source_pressure or dependency_pressure or
          exclusivity_pressure or dependent_activity_pressure or review_pressure or
          source_activity_count + replacement_activity_count > 0 or map_size(status_counts) > 0 or
          map_size(scope_counts) > 0,
      "branch_local_changed_source_pressure" => changed_source_pressure,
      "branch_local_dependency_pressure" => dependency_pressure,
      "branch_local_exclusivity_pressure" => exclusivity_pressure,
      "branch_local_dependent_activity_pressure" => dependent_activity_pressure,
      "branch_local_operator_review_pressure" => review_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_timeline_dependency_impact_replay_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_dependency_impact_replay_summary",
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
