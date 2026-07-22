defmodule OrbitalDynamics.CandidateRefresh.UnavailableResourceCandidateFilter do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    ObjectiveMatching,
    ResultArtifactTrustBoundary
  }

  alias OrbitalDynamics.CandidateRefresh.SourceReports.{
    ContactReviewCollection,
    ReadinessQualityGate,
    ResultArtifactCollection
  }

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows,
    as: ContactAllocationRows

  alias OrbitalDynamics.{Schema, Timeline}

  @quality_summary_contract "operational_quality_gate_unavailable_resource_summary.v1"
  @quality_summary_model "artifact_only_quality_gate_unavailable_resource_summary"
  @quality_gate_contract "quality_gate_report.v1"
  @planned_activity_contract "planned_activity.v1"
  @readiness_contract "operational_readiness_report.v1"

  def apply(candidates, refresh) when is_list(candidates) and is_map(refresh) do
    sources = unavailable_resource_sources(refresh)

    if sources == [] do
      {candidates, [], [], [], [], [], nil}
    else
      spacecraft_by_scenario = ObjectiveMatching.spacecraft_identity_by_scenario(refresh)

      {kept, quality_dropped, candidate_quality_dropped, readiness_dropped,
       candidate_readiness_dropped, contact_allocation_dropped, explained} =
        Enum.reduce(candidates, {[], [], [], [], [], [], []}, fn candidate,
                                                                 {kept, quality_dropped,
                                                                  candidate_quality_dropped,
                                                                  readiness_dropped,
                                                                  candidate_readiness_dropped,
                                                                  contact_allocation_dropped,
                                                                  explained} ->
          case blocking_evidence(candidate, sources, spacecraft_by_scenario) do
            [] ->
              {
                [candidate | kept],
                quality_dropped,
                candidate_quality_dropped,
                readiness_dropped,
                candidate_readiness_dropped,
                contact_allocation_dropped,
                [candidate | explained]
              }

            evidence ->
              rejected = rejected_candidate(candidate, evidence)

              cond do
                Enum.any?(
                  evidence,
                  &(&1["selection_scope"] == "candidate_artifact" and
                        &1["source_family"] == "quality_gate")
                ) ->
                  {
                    kept,
                    quality_dropped,
                    [rejected | candidate_quality_dropped],
                    readiness_dropped,
                    candidate_readiness_dropped,
                    contact_allocation_dropped,
                    [rejected | explained]
                  }

                Enum.any?(
                  evidence,
                  &(&1["selection_scope"] == "candidate_artifact" and
                        &1["source_family"] == "operational_readiness")
                ) ->
                  {
                    kept,
                    quality_dropped,
                    candidate_quality_dropped,
                    readiness_dropped,
                    [rejected | candidate_readiness_dropped],
                    contact_allocation_dropped,
                    [rejected | explained]
                  }

                Enum.any?(evidence, &(&1["source_family"] == "quality_gate")) ->
                  {
                    kept,
                    [rejected | quality_dropped],
                    candidate_quality_dropped,
                    readiness_dropped,
                    candidate_readiness_dropped,
                    contact_allocation_dropped,
                    [rejected | explained]
                  }

                Enum.any?(evidence, &(&1["source_family"] == "operational_readiness")) ->
                  {
                    kept,
                    quality_dropped,
                    candidate_quality_dropped,
                    [rejected | readiness_dropped],
                    candidate_readiness_dropped,
                    contact_allocation_dropped,
                    [rejected | explained]
                  }

                true ->
                  {
                    kept,
                    quality_dropped,
                    candidate_quality_dropped,
                    readiness_dropped,
                    candidate_readiness_dropped,
                    [rejected | contact_allocation_dropped],
                    [rejected | explained]
                  }
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
        Enum.reverse(candidate_quality_dropped),
        Enum.reverse(readiness_dropped),
        Enum.reverse(candidate_readiness_dropped),
        Enum.reverse(contact_allocation_dropped),
        report
      }
    end
  end

  defp unavailable_resource_sources(refresh) do
    quality_gate_sources(refresh) ++
      operational_readiness_sources(refresh) ++ contact_allocation_sources(refresh)
  end

  defp quality_gate_sources(refresh) do
    reports =
      ReadinessQualityGate.quality_gate_reports(
        refresh,
        &ResultArtifactCollection.reports/1,
        &ResultArtifactTrustBoundary.inherit_quality_gate/2
      )

    unavailable_resource_quality_gate_sources(reports) ++
      candidate_scoped_quality_gate_sources(reports)
  end

  defp unavailable_resource_quality_gate_sources(reports) do
    reports
    |> Enum.filter(fn {_path, report} ->
      report["source_summary_schema_contract"] == @quality_summary_contract and
        report["source_summary_model"] == @quality_summary_model and
        report["source_summary_validation_status"] == "pass"
    end)
    |> Enum.map(fn {path, report} ->
      %{
        "source_family" => "quality_gate",
        "selection_scope" => "unavailable_resource",
        "source_report_path" => path,
        "source_summary_schema_contract" => @quality_summary_contract,
        "source_artifact_id" => report["source_artifact_id"],
        "source_quality_gate_report_id" => report["source_quality_gate_report_id"],
        "source_readiness_report_id" => report["source_readiness_report_id"],
        "blocked_contact_ids_by_spacecraft_id" => report["blocked_contact_ids_by_spacecraft_id"],
        "trust_boundaries" => report_trust_boundaries(report)
      }
    end)
  end

  defp candidate_scoped_quality_gate_sources(reports) do
    reports
    |> Enum.filter(fn {_path, report} ->
      report["schema_contract"] == @quality_gate_contract and
        report["source_artifact_type"] == @planned_activity_contract and
        report["status"] == "blocked" and
        not is_nil(stable_string(report["source_artifact_id"])) and
        valid_quality_gate_report?(report)
    end)
    |> Enum.map(fn {path, report} ->
      %{
        "source_family" => "quality_gate",
        "selection_scope" => "candidate_artifact",
        "source_report_path" => path,
        "source_schema_contract" => @quality_gate_contract,
        "source_summary_schema_contract" => report["source_summary_schema_contract"],
        "source_artifact_type" => @planned_activity_contract,
        "source_artifact_id" => report["source_artifact_id"],
        "source_quality_gate_report_id" =>
          report["report_id"] || report["source_quality_gate_report_id"],
        "source_readiness_report_id" => report["source_readiness_report_id"],
        "blocked_candidate_id" => report["source_artifact_id"],
        "quality_gate_status" => "blocked",
        "trust_boundaries" => report_trust_boundaries(report)
      }
    end)
  end

  defp operational_readiness_sources(refresh) do
    reports =
      ReadinessQualityGate.operational_readiness_reports(
        refresh,
        &ResultArtifactCollection.reports/1,
        &ResultArtifactTrustBoundary.inherit/2
      )

    unavailable_resource_operational_readiness_sources(reports) ++
      candidate_scoped_operational_readiness_sources(reports)
  end

  defp unavailable_resource_operational_readiness_sources(reports) do
    reports
    |> Enum.filter(fn {_path, report} ->
      report["schema_contract"] == @readiness_contract and
        blocked_contact_map?(
          get_in(report, ["evidence", "resource_blocked_contact_ids_by_spacecraft_id"])
        ) and valid_operational_readiness_report?(report)
    end)
    |> Enum.map(fn {path, report} ->
      %{
        "source_family" => "operational_readiness",
        "selection_scope" => "unavailable_resource",
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

  defp candidate_scoped_operational_readiness_sources(reports) do
    reports
    |> Enum.filter(fn {_path, report} ->
      report["schema_contract"] == @readiness_contract and
        report["source_artifact_type"] == @planned_activity_contract and
        report["status"] == "blocked" and
        not is_nil(stable_string(report["source_artifact_id"])) and
        valid_operational_readiness_report?(report)
    end)
    |> Enum.map(fn {path, report} ->
      %{
        "source_family" => "operational_readiness",
        "selection_scope" => "candidate_artifact",
        "source_report_path" => path,
        "source_schema_contract" => @readiness_contract,
        "source_summary_schema_contract" => report["source_summary_schema_contract"],
        "source_artifact_type" => @planned_activity_contract,
        "source_artifact_id" => report["source_artifact_id"],
        "source_readiness_report_id" => report["report_id"],
        "blocked_candidate_id" => report["source_artifact_id"],
        "operational_readiness_status" => "blocked",
        "trust_boundaries" => report_trust_boundaries(report)
      }
    end)
  end

  defp contact_allocation_sources(refresh) do
    refresh
    |> ContactReviewCollection.contact_allocation_reports(
      &ResultArtifactCollection.reports/1,
      &ResultArtifactTrustBoundary.inherit/2
    )
    |> Enum.flat_map(fn {path, report} ->
      if report["schema_contract"] == "contact_allocation_report.v1" do
        report
        |> ContactAllocationRows.resource_blocked_rows()
        |> Enum.flat_map(&contact_allocation_row_source(path, report, &1))
      else
        []
      end
    end)
  end

  defp contact_allocation_row_source(path, report, row) do
    contact_id = ContactAllocationRows.summary_contact_id(row)
    spacecraft_id = stable_string(row["spacecraft_id"])
    resource_suppression = row["source_resource_suppression"]

    resource_blocking_dimension =
      stable_string(
        row["resource_blocking_dimension"] ||
          get_in(row, ["source_resource_suppression", "resource_blocking_dimension"])
      )

    if contact_id && spacecraft_id && resource_blocking_dimension &&
         ContactAllocationRows.effective_status(row) == "blocked" &&
         is_map(resource_suppression) && map_size(resource_suppression) > 0 do
      [
        %{
          "source_family" => "contact_allocation",
          "selection_scope" => "unavailable_resource",
          "source_report_path" => path,
          "source_schema_contract" => "contact_allocation_report.v1",
          "source_artifact_id" => report["source_artifact_id"],
          "source_contact_allocation_report_id" => report["report_id"] || report["id"],
          "source_report_source" => report["source"],
          "blocked_contact_ids_by_spacecraft_id" => %{spacecraft_id => [contact_id]},
          "resource_blocking_dimension" => resource_blocking_dimension,
          "trust_boundaries" =>
            (report_trust_boundaries(report) ++ contact_allocation_row_trust_boundaries(row))
            |> stable_values()
        }
      ]
    else
      []
    end
  end

  defp blocking_evidence(candidate, sources, spacecraft_by_scenario) do
    candidate_id = Map.get(candidate, "id")
    spacecraft_ids = candidate_spacecraft_ids(candidate, spacecraft_by_scenario)

    Enum.flat_map(sources, fn source ->
      cond do
        source["selection_scope"] == "candidate_artifact" and
            source["blocked_candidate_id"] == candidate_id ->
          [evidence(source, nil)]

        source["selection_scope"] == "unavailable_resource" and
            contact_candidate?(candidate) ->
          source
          |> Map.get("blocked_contact_ids_by_spacecraft_id", %{})
          |> matching_scopes(candidate_id, spacecraft_ids)
          |> Enum.map(&evidence(source, &1))

        true ->
          []
      end
    end)
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
      "selection_scope",
      "source_report_path",
      "source_schema_contract",
      "source_summary_schema_contract",
      "source_artifact_type",
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id",
      "source_contact_allocation_report_id",
      "source_report_source",
      "resource_blocking_dimension",
      "blocked_candidate_id",
      "quality_gate_status",
      "operational_readiness_status",
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
      Map.get(evidence_by_family, "quality_gate", [])
    )
    |> put_selection_provenance(
      "operational_readiness_candidate_filter",
      Map.get(evidence_by_family, "operational_readiness", [])
    )
    |> put_selection_provenance(
      "contact_allocation_candidate_filter",
      Map.get(evidence_by_family, "contact_allocation", [])
    )
  end

  defp put_selection_provenance(candidate, _key, []), do: candidate

  defp put_selection_provenance(candidate, key, evidence) do
    selection_provenance =
      %{
        "source_schema_contract" => first_evidence_value(evidence, "source_schema_contract"),
        "source_summary_schema_contract" =>
          first_evidence_value(evidence, "source_summary_schema_contract"),
        "source_report_paths" => evidence_values(evidence, "source_report_path"),
        "source_artifact_types" => evidence_values(evidence, "source_artifact_type"),
        "source_artifact_ids" => evidence_values(evidence, "source_artifact_id"),
        "source_quality_gate_report_ids" =>
          evidence_values(evidence, "source_quality_gate_report_id"),
        "source_readiness_report_ids" => evidence_values(evidence, "source_readiness_report_id"),
        "source_contact_allocation_report_ids" =>
          evidence_values(evidence, "source_contact_allocation_report_id"),
        "source_report_sources" => evidence_values(evidence, "source_report_source"),
        "resource_blocking_dimensions" =>
          evidence_values(evidence, "resource_blocking_dimension"),
        "blocked_candidate_ids" => evidence_values(evidence, "blocked_candidate_id"),
        "quality_gate_statuses" => evidence_values(evidence, "quality_gate_status"),
        "operational_readiness_statuses" =>
          evidence_values(evidence, "operational_readiness_status"),
        "selection_scopes" => candidate_artifact_selection_scopes(evidence),
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

  defp first_evidence_value(evidence, field) do
    evidence
    |> evidence_values(field)
    |> List.first()
  end

  defp candidate_artifact_selection_scopes(evidence) do
    evidence
    |> Enum.filter(&(&1["selection_scope"] == "candidate_artifact"))
    |> evidence_values("selection_scope")
  end

  defp report_trust_boundaries(report) do
    (list_value(report["trust_boundaries"]) ++
       list_value(get_in(report, ["provenance", "trust_boundaries"])) ++
       [get_in(report, ["provenance", "trust_boundary"])])
    |> stable_values()
  end

  defp contact_allocation_row_trust_boundaries(row) do
    [
      row["trust_boundary"],
      row["resource_trust_boundary"],
      get_in(row, ["provenance", "trust_boundary"]),
      get_in(row, ["resource_provenance", "trust_boundary"]),
      get_in(row, ["source_resource_suppression", "resource_trust_boundary"]),
      get_in(row, ["source_resource_suppression", "resource_provenance", "trust_boundary"])
    ]
    |> stable_values()
  end

  defp candidate_rejection_source(sources) do
    source_families = sources |> Enum.map(& &1["source_family"]) |> Enum.uniq() |> Enum.sort()

    selection_scopes =
      sources
      |> Enum.map(& &1["selection_scope"])
      |> Enum.uniq()
      |> Enum.sort()

    case {source_families, selection_scopes} do
      {["quality_gate"], ["candidate_artifact"]} ->
        "candidate_refresh.candidate_scoped_quality_gate"

      {["operational_readiness"], ["candidate_artifact"]} ->
        "candidate_refresh.candidate_scoped_operational_readiness"

      {["quality_gate"], ["unavailable_resource"]} ->
        "candidate_refresh.operational_quality_gate_unavailable_resource_summary"

      {["operational_readiness"], ["unavailable_resource"]} ->
        "candidate_refresh.operational_readiness_unavailable_resource"

      {["contact_allocation"], ["unavailable_resource"]} ->
        "candidate_refresh.contact_allocation_unavailable_resource"

      {_source_families, ["unavailable_resource"]} ->
        "candidate_refresh.unavailable_resource_readiness_evidence"

      _source_scope ->
        "candidate_refresh.readiness_quality_gate_selection_evidence"
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

  defp stable_string(value) when is_binary(value) and value != "", do: value
  defp stable_string(_value), do: nil

  defp valid_quality_gate_report?(report) do
    match?(
      {:ok, %{"schema_contract" => @quality_gate_contract, "status" => "pass"}},
      Schema.validate_artifact(report)
    )
  end

  defp valid_operational_readiness_report?(report) do
    match?(
      {:ok, %{"schema_contract" => @readiness_contract, "status" => "pass"}},
      Schema.validate_artifact(report)
    )
  end

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
