defmodule OrbitalDynamics.CandidateRefresh.UnavailableResourceCandidateFilter do
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

  @quality_summary_contract "operational_quality_gate_unavailable_resource_summary.v1"
  @quality_summary_model "artifact_only_quality_gate_unavailable_resource_summary"
  @readiness_contract "operational_readiness_report.v1"

  def apply(candidates, refresh) when is_list(candidates) and is_map(refresh) do
    sources = unavailable_resource_sources(refresh)

    if sources == [] do
      {candidates, [], [], nil}
    else
      spacecraft_by_scenario = ObjectiveMatching.spacecraft_identity_by_scenario(refresh)

      {kept, quality_dropped, readiness_dropped, explained} =
        Enum.reduce(candidates, {[], [], [], []}, fn candidate,
                                                     {kept, quality_dropped, readiness_dropped,
                                                      explained} ->
          case blocking_evidence(candidate, sources, spacecraft_by_scenario) do
            [] ->
              {[candidate | kept], quality_dropped, readiness_dropped, [candidate | explained]}

            evidence ->
              rejected = rejected_candidate(candidate, evidence)

              if Enum.any?(evidence, &(&1["source_family"] == "quality_gate")) do
                {kept, [rejected | quality_dropped], readiness_dropped, [rejected | explained]}
              else
                {kept, quality_dropped, [rejected | readiness_dropped], [rejected | explained]}
              end
          end
        end)

      report =
        explained
        |> Enum.reverse()
        |> Timeline.candidate_rejection_report(source: candidate_rejection_source(sources))

      {
        Enum.reverse(kept),
        Enum.reverse(quality_dropped),
        Enum.reverse(readiness_dropped),
        report
      }
    end
  end

  defp unavailable_resource_sources(refresh) do
    quality_gate_sources(refresh) ++ operational_readiness_sources(refresh)
  end

  defp quality_gate_sources(refresh) do
    refresh
    |> ReadinessQualityGate.quality_gate_reports(
      &ResultArtifactCollection.reports/1,
      &ResultArtifactTrustBoundary.inherit_quality_gate/2
    )
    |> Enum.filter(fn {_path, report} ->
      report["source_summary_schema_contract"] == @quality_summary_contract and
        report["source_summary_model"] == @quality_summary_model
    end)
    |> Enum.map(fn {path, report} ->
      %{
        "source_family" => "quality_gate",
        "source_report_path" => path,
        "source_schema_contract" => @quality_summary_contract,
        "source_artifact_id" => report["source_artifact_id"],
        "source_quality_gate_report_id" => report["source_quality_gate_report_id"],
        "source_readiness_report_id" => report["source_readiness_report_id"],
        "blocked_contact_ids_by_spacecraft_id" => report["blocked_contact_ids_by_spacecraft_id"],
        "trust_boundaries" => report_trust_boundaries(report)
      }
    end)
  end

  defp operational_readiness_sources(refresh) do
    refresh
    |> ReadinessQualityGate.operational_readiness_reports(
      &ResultArtifactCollection.reports/1,
      &ResultArtifactTrustBoundary.inherit/2
    )
    |> Enum.filter(fn {_path, report} ->
      report["schema_contract"] == @readiness_contract and
        blocked_contact_map?(
          get_in(report, ["evidence", "resource_blocked_contact_ids_by_spacecraft_id"])
        )
    end)
    |> Enum.map(fn {path, report} ->
      %{
        "source_family" => "operational_readiness",
        "source_report_path" => path,
        "source_schema_contract" => @readiness_contract,
        "source_artifact_id" => report["source_artifact_id"],
        "source_readiness_report_id" => report["report_id"],
        "blocked_contact_ids_by_spacecraft_id" =>
          get_in(report, ["evidence", "resource_blocked_contact_ids_by_spacecraft_id"]),
        "trust_boundaries" => report_trust_boundaries(report)
      }
    end)
  end

  defp blocking_evidence(candidate, sources, spacecraft_by_scenario) do
    if contact_candidate?(candidate) do
      candidate_id = Map.get(candidate, "id")
      spacecraft_ids = candidate_spacecraft_ids(candidate, spacecraft_by_scenario)

      sources
      |> Enum.flat_map(fn source ->
        source
        |> Map.get("blocked_contact_ids_by_spacecraft_id", %{})
        |> matching_scopes(candidate_id, spacecraft_ids)
        |> Enum.map(&evidence(source, &1))
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

  defp evidence(source, spacecraft_id) do
    source
    |> Map.take([
      "source_family",
      "source_report_path",
      "source_schema_contract",
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id",
      "trust_boundaries"
    ])
    |> Map.put("spacecraft_id", spacecraft_id)
    |> compact_map()
  end

  defp rejected_candidate(candidate, evidence) do
    evidence_by_family = Enum.group_by(evidence, & &1["source_family"])

    candidate
    |> Map.put("quality_gate_status", "blocked")
    |> Map.put("candidate_rejection_reasons", ["quality_gate_failed"])
    |> put_selection_provenance(
      "quality_gate_candidate_filter",
      Map.get(evidence_by_family, "quality_gate", []),
      "source_summary_schema_contract"
    )
    |> put_selection_provenance(
      "operational_readiness_candidate_filter",
      Map.get(evidence_by_family, "operational_readiness", []),
      "source_schema_contract"
    )
  end

  defp put_selection_provenance(candidate, _key, [], _contract_field), do: candidate

  defp put_selection_provenance(candidate, key, evidence, contract_field) do
    selection_provenance =
      %{
        contract_field => evidence |> List.first() |> Map.get("source_schema_contract"),
        "source_report_paths" => evidence_values(evidence, "source_report_path"),
        "source_artifact_ids" => evidence_values(evidence, "source_artifact_id"),
        "source_quality_gate_report_ids" =>
          evidence_values(evidence, "source_quality_gate_report_id"),
        "source_readiness_report_ids" => evidence_values(evidence, "source_readiness_report_id"),
        "blocked_spacecraft_ids" => evidence_values(evidence, "spacecraft_id"),
        "trust_boundaries" =>
          evidence
          |> Enum.flat_map(&list_value(&1["trust_boundaries"]))
          |> stable_values()
      }
      |> compact_map()

    Map.update(candidate, "provenance", %{key => selection_provenance}, fn
      %{} = provenance -> Map.put(provenance, key, selection_provenance)
      _provenance -> %{key => selection_provenance}
    end)
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

  defp candidate_rejection_source(sources) do
    case sources |> Enum.map(& &1["source_family"]) |> Enum.uniq() |> Enum.sort() do
      ["quality_gate"] ->
        "candidate_refresh.operational_quality_gate_unavailable_resource_summary"

      ["operational_readiness"] ->
        "candidate_refresh.operational_readiness_unavailable_resource"

      _families ->
        "candidate_refresh.unavailable_resource_readiness_evidence"
    end
  end

  defp contact_candidate?(%{"type" => type})
       when type in ["contact", "downlink", "planned_contact"],
       do: true

  defp contact_candidate?(%{"direction" => direction})
       when direction in ["downlink", "uplink", "command", "tracking"],
       do: true

  defp contact_candidate?(_candidate), do: false

  defp blocked_contact_map?(%{} = map) do
    Enum.any?(map, fn
      {spacecraft_id, contact_ids} when is_binary(spacecraft_id) and spacecraft_id != "" ->
        Enum.any?(list_value(contact_ids), &(is_binary(&1) and &1 != ""))

      _entry ->
        false
    end)
  end

  defp blocked_contact_map?(_value), do: false

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
