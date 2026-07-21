defmodule OrbitalDynamics.CandidateRefresh.QualityGateCandidateFilter do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    ObjectiveMatching,
    ResultArtifactTrustBoundary
  }

  alias OrbitalDynamics.CandidateRefresh.SourceReports.{
    ReadinessQualityGate,
    ResultArtifactCollection
  }

  alias OrbitalDynamics.Timeline

  @source_summary_contract "operational_quality_gate_unavailable_resource_summary.v1"
  @source_summary_model "artifact_only_quality_gate_unavailable_resource_summary"

  def apply(candidates, refresh) when is_list(candidates) and is_map(refresh) do
    reports = unavailable_resource_reports(refresh)

    if reports == [] do
      {candidates, [], nil}
    else
      spacecraft_by_scenario = ObjectiveMatching.spacecraft_identity_by_scenario(refresh)

      {kept, dropped, explained} =
        Enum.reduce(candidates, {[], [], []}, fn candidate, {kept, dropped, explained} ->
          case blocking_evidence(candidate, reports, spacecraft_by_scenario) do
            [] ->
              {[candidate | kept], dropped, [candidate | explained]}

            evidence ->
              rejected = rejected_candidate(candidate, evidence)
              {kept, [rejected | dropped], [rejected | explained]}
          end
        end)

      report =
        explained
        |> Enum.reverse()
        |> Timeline.candidate_rejection_report(
          source: "candidate_refresh.operational_quality_gate_unavailable_resource_summary"
        )

      {Enum.reverse(kept), Enum.reverse(dropped), report}
    end
  end

  defp unavailable_resource_reports(refresh) do
    refresh
    |> ReadinessQualityGate.quality_gate_reports(
      &ResultArtifactCollection.reports/1,
      &ResultArtifactTrustBoundary.inherit_quality_gate/2
    )
    |> Enum.filter(fn {_path, report} ->
      report["source_summary_schema_contract"] == @source_summary_contract and
        report["source_summary_model"] == @source_summary_model
    end)
  end

  defp blocking_evidence(candidate, reports, spacecraft_by_scenario) do
    if contact_candidate?(candidate) do
      candidate_id = Map.get(candidate, "id")
      spacecraft_ids = candidate_spacecraft_ids(candidate, spacecraft_by_scenario)

      reports
      |> Enum.flat_map(fn {path, report} ->
        report
        |> Map.get("blocked_contact_ids_by_spacecraft_id", %{})
        |> matching_scopes(candidate_id, spacecraft_ids)
        |> Enum.map(&evidence(path, report, &1))
      end)
    else
      []
    end
  end

  defp matching_scopes(blocked_by_spacecraft, candidate_id, spacecraft_ids)
       when is_map(blocked_by_spacecraft) and is_binary(candidate_id) do
    Enum.filter(spacecraft_ids, fn spacecraft_id ->
      candidate_id in list_value(Map.get(blocked_by_spacecraft, spacecraft_id))
    end)
  end

  defp matching_scopes(_blocked_by_spacecraft, _candidate_id, _spacecraft_ids), do: []

  defp candidate_spacecraft_ids(candidate, spacecraft_by_scenario) do
    scenario_id = Map.get(candidate, "scenario_id")

    [
      Map.get(candidate, "spacecraft_id"),
      Map.get(spacecraft_by_scenario, scenario_id),
      scenario_id
    ]
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
  end

  defp evidence(path, report, spacecraft_id) do
    %{
      "source_report_path" => path,
      "source_artifact_id" => report["source_artifact_id"],
      "source_quality_gate_report_id" => report["source_quality_gate_report_id"],
      "spacecraft_id" => spacecraft_id,
      "trust_boundaries" => report_trust_boundaries(report)
    }
    |> compact_map()
  end

  defp rejected_candidate(candidate, evidence) do
    selection_provenance =
      %{
        "source_summary_schema_contract" => @source_summary_contract,
        "source_report_paths" => evidence_values(evidence, "source_report_path"),
        "source_artifact_ids" => evidence_values(evidence, "source_artifact_id"),
        "source_quality_gate_report_ids" =>
          evidence_values(evidence, "source_quality_gate_report_id"),
        "blocked_spacecraft_ids" => evidence_values(evidence, "spacecraft_id"),
        "trust_boundaries" =>
          evidence
          |> Enum.flat_map(&list_value(&1["trust_boundaries"]))
          |> stable_values()
      }
      |> compact_map()

    candidate
    |> Map.put("quality_gate_status", "blocked")
    |> Map.put("candidate_rejection_reasons", ["quality_gate_failed"])
    |> Map.update(
      "provenance",
      %{"quality_gate_candidate_filter" => selection_provenance},
      fn
        %{} = provenance ->
          Map.put(provenance, "quality_gate_candidate_filter", selection_provenance)

        _provenance ->
          %{"quality_gate_candidate_filter" => selection_provenance}
      end
    )
  end

  defp evidence_values(evidence, field) do
    evidence
    |> Enum.map(&Map.get(&1, field))
    |> stable_values()
  end

  defp report_trust_boundaries(report) do
    (list_value(report["trust_boundaries"]) ++
       list_value(get_in(report, ["provenance", "trust_boundaries"])) ++
       [get_in(report, ["provenance", "trust_boundary"])])
    |> stable_values()
  end

  defp contact_candidate?(%{"type" => type})
       when type in ["contact", "downlink", "planned_contact"],
       do: true

  defp contact_candidate?(%{"direction" => direction})
       when direction in ["downlink", "uplink", "command", "tracking"],
       do: true

  defp contact_candidate?(_candidate), do: false

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp stable_values(values) do
    values
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
  end
end
