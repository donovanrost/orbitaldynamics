defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.RealizedActivitySourceRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  def rows_for_refresh(
        refresh,
        inherit_result_artifact_trust_boundary_fun,
        result_artifact_trust_boundary_fun
      ) do
    rows(
      refresh,
      &ResultArtifactCollectionSourceReports.reports/1,
      inherit_result_artifact_trust_boundary_fun,
      result_artifact_trust_boundary_fun
    )
  end

  def rows(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        result_artifact_trust_boundary_fun
      ) do
    refresh
    |> direct_rows()
    |> Kernel.++(
      result_artifact_rows(
        refresh,
        source_result_artifacts_fun,
        result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      operator_review_rows(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      cadence_import_rows(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        result_artifact_trust_boundary_fun
      )
    )
  end

  defp direct_rows(refresh) do
    [
      {"accepted_planning_state.source_realized_activity",
       get_in(refresh, ["accepted_planning_state", "source_realized_activity"])},
      {"accepted_planning_state.realized_activity",
       get_in(refresh, ["accepted_planning_state", "realized_activity"])},
      {"accepted_planning_state.source_realized_activities",
       get_in(refresh, ["accepted_planning_state", "source_realized_activities"])},
      {"accepted_planning_state.realized_activities",
       get_in(refresh, ["accepted_planning_state", "realized_activities"])},
      {"accepted_planning_state.source_realized_state_snapshot",
       get_in(refresh, ["accepted_planning_state", "source_realized_state_snapshot"])},
      {"accepted_planning_state.realized_state_snapshot",
       get_in(refresh, ["accepted_planning_state", "realized_state_snapshot"])},
      {"accepted_planning_state.source_realized_state",
       get_in(refresh, ["accepted_planning_state", "source_realized_state"])},
      {"accepted_planning_state.realized_state",
       get_in(refresh, ["accepted_planning_state", "realized_state"])},
      {"mission_state.source_realized_activity",
       get_in(refresh, ["mission_state", "source_realized_activity"])},
      {"mission_state.realized_activity",
       get_in(refresh, ["mission_state", "realized_activity"])},
      {"mission_state.source_realized_activities",
       get_in(refresh, ["mission_state", "source_realized_activities"])},
      {"mission_state.realized_activities",
       get_in(refresh, ["mission_state", "realized_activities"])},
      {"mission_state.source_realized_state_snapshot",
       get_in(refresh, ["mission_state", "source_realized_state_snapshot"])},
      {"mission_state.realized_state_snapshot",
       get_in(refresh, ["mission_state", "realized_state_snapshot"])},
      {"mission_state.source_realized_state",
       get_in(refresh, ["mission_state", "source_realized_state"])},
      {"mission_state.realized_state", get_in(refresh, ["mission_state", "realized_state"])},
      {"source_realized_activity", Map.get(refresh, "source_realized_activity")},
      {"realized_activity", Map.get(refresh, "realized_activity")},
      {"source_realized_activities", Map.get(refresh, "source_realized_activities")},
      {"realized_activities", Map.get(refresh, "realized_activities")},
      {"source_realized_state_snapshot", Map.get(refresh, "source_realized_state_snapshot")},
      {"realized_state_snapshot", Map.get(refresh, "realized_state_snapshot")},
      {"source_realized_state", Map.get(refresh, "source_realized_state")},
      {"realized_state", Map.get(refresh, "realized_state")}
    ]
    |> Enum.flat_map(fn {path, row_or_rows} ->
      entries(path, row_or_rows, nil, result_artifact_trust_boundary_fun: nil)
    end)
  end

  defp result_artifact_rows(
         refresh,
         source_result_artifacts_fun,
         result_artifact_trust_boundary_fun
       ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = RowValues.stringify_keys_with_keyword_maps(artifact)

      [
        {"#{path}.source_realized_activity", Map.get(artifact, "source_realized_activity")},
        {"#{path}.realized_activity", Map.get(artifact, "realized_activity")},
        {"#{path}.source_realized_activities", Map.get(artifact, "source_realized_activities")},
        {"#{path}.realized_activities", Map.get(artifact, "realized_activities")},
        {"#{path}.source_realized_state_snapshot",
         Map.get(artifact, "source_realized_state_snapshot")},
        {"#{path}.realized_state_snapshot", Map.get(artifact, "realized_state_snapshot")},
        {"#{path}.source_realized_state", Map.get(artifact, "source_realized_state")},
        {"#{path}.realized_state", Map.get(artifact, "realized_state")}
      ]
      |> Enum.flat_map(fn {entry_path, row_or_rows} ->
        entries(entry_path, row_or_rows, artifact,
          result_artifact_trust_boundary_fun: result_artifact_trust_boundary_fun
        )
      end)
    end)
  end

  defp operator_review_rows(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun,
         result_artifact_trust_boundary_fun
       ) do
    direct =
      [
        {"accepted_planning_state.source_operator_review_package",
         get_in(refresh, ["accepted_planning_state", "source_operator_review_package"])},
        {"accepted_planning_state.operator_review_package",
         get_in(refresh, ["accepted_planning_state", "operator_review_package"])},
        {"mission_state.source_operator_review_package",
         get_in(refresh, ["mission_state", "source_operator_review_package"])},
        {"mission_state.operator_review_package",
         get_in(refresh, ["mission_state", "operator_review_package"])},
        {"source_operator_review_package", Map.get(refresh, "source_operator_review_package")},
        {"operator_review_package", Map.get(refresh, "operator_review_package")}
      ]
      |> Enum.flat_map(fn {path, package_or_packages} ->
        operator_review_entries(
          path,
          package_or_packages,
          nil,
          result_artifact_trust_boundary_fun
        )
      end)

    embedded =
      refresh
      |> source_result_artifacts_fun.()
      |> Enum.flat_map(fn {path, artifact} ->
        artifact = RowValues.stringify_keys_with_keyword_maps(artifact)

        [
          {"#{path}", artifact},
          {"#{path}.operator_review_package", Map.get(artifact, "operator_review_package")}
        ]
        |> Enum.flat_map(fn {entry_path, package} ->
          operator_review_entries(
            entry_path,
            inherit_result_artifact_trust_boundary_fun.(package, artifact),
            artifact,
            result_artifact_trust_boundary_fun
          )
        end)
      end)

    direct ++ embedded
  end

  defp operator_review_entries(path, packages, artifact, result_artifact_trust_boundary_fun)
       when is_list(packages) do
    packages
    |> Enum.with_index()
    |> Enum.flat_map(fn {package, index} ->
      operator_review_entries(
        "#{path}[#{index}]",
        package,
        artifact,
        result_artifact_trust_boundary_fun
      )
    end)
  end

  defp operator_review_entries(path, %{} = package, artifact, result_artifact_trust_boundary_fun) do
    package = RowValues.stringify_keys_with_keyword_maps(package)

    package
    |> Map.get("rows", [])
    |> Enum.map(&RowValues.stringify_keys_with_keyword_maps/1)
    |> Enum.filter(&(&1["review_type"] == "realized_feedback"))
    |> Enum.flat_map(fn row ->
      case row_from_review_or_import_row(
             row,
             package,
             artifact,
             result_artifact_trust_boundary_fun
           ) do
        %{} = realized_row -> [{"#{path}.rows.source_feedback", realized_row}]
        _row -> []
      end
    end)
  end

  defp operator_review_entries(_path, _package, _artifact, _result_artifact_trust_boundary_fun),
    do: []

  defp cadence_import_rows(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun,
         result_artifact_trust_boundary_fun
       ) do
    direct =
      [
        {"accepted_planning_state.source_cadence_import_manifest",
         get_in(refresh, ["accepted_planning_state", "source_cadence_import_manifest"])},
        {"accepted_planning_state.cadence_import_manifest",
         get_in(refresh, ["accepted_planning_state", "cadence_import_manifest"])},
        {"mission_state.source_cadence_import_manifest",
         get_in(refresh, ["mission_state", "source_cadence_import_manifest"])},
        {"mission_state.cadence_import_manifest",
         get_in(refresh, ["mission_state", "cadence_import_manifest"])},
        {"source_cadence_import_manifest", Map.get(refresh, "source_cadence_import_manifest")},
        {"cadence_import_manifest", Map.get(refresh, "cadence_import_manifest")}
      ]
      |> Enum.flat_map(fn {path, manifest_or_manifests} ->
        cadence_import_entries(
          path,
          manifest_or_manifests,
          nil,
          result_artifact_trust_boundary_fun
        )
      end)

    embedded =
      refresh
      |> source_result_artifacts_fun.()
      |> Enum.flat_map(fn {path, artifact} ->
        artifact = RowValues.stringify_keys_with_keyword_maps(artifact)

        [
          {"#{path}", artifact},
          {"#{path}.cadence_import_manifest", Map.get(artifact, "cadence_import_manifest")}
        ]
        |> Enum.flat_map(fn {entry_path, manifest} ->
          cadence_import_entries(
            entry_path,
            inherit_result_artifact_trust_boundary_fun.(manifest, artifact),
            artifact,
            result_artifact_trust_boundary_fun
          )
        end)
      end)

    direct ++ embedded
  end

  defp cadence_import_entries(path, manifests, artifact, result_artifact_trust_boundary_fun)
       when is_list(manifests) do
    manifests
    |> Enum.with_index()
    |> Enum.flat_map(fn {manifest, index} ->
      cadence_import_entries(
        "#{path}[#{index}]",
        manifest,
        artifact,
        result_artifact_trust_boundary_fun
      )
    end)
  end

  defp cadence_import_entries(path, %{} = manifest, artifact, result_artifact_trust_boundary_fun) do
    manifest = RowValues.stringify_keys_with_keyword_maps(manifest)

    manifest
    |> Map.get("rows", [])
    |> Enum.map(&RowValues.stringify_keys_with_keyword_maps/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "realized_feedback" or
        row["import_action"] in ["review_realized_feedback", "record_realized_feedback"]
    end)
    |> Enum.flat_map(fn row ->
      case row_from_review_or_import_row(
             row,
             manifest,
             artifact,
             result_artifact_trust_boundary_fun
           ) do
        %{} = realized_row ->
          row_source_path =
            if is_map(row["source_review_row"]) do
              "#{path}.rows.source_review_row.source_feedback"
            else
              "#{path}.rows.source_feedback"
            end

          [{row_source_path, realized_row}]

        _row ->
          []
      end
    end)
  end

  defp cadence_import_entries(_path, _manifest, _artifact, _result_artifact_trust_boundary_fun),
    do: []

  defp row_from_review_or_import_row(
         %{} = row,
         %{} = source_artifact,
         artifact,
         result_artifact_trust_boundary_fun
       ) do
    row = RowValues.stringify_keys_with_keyword_maps(row)

    source_review_row =
      RowValues.stringify_keys_with_keyword_maps(Map.get(row, "source_review_row", %{}))

    source =
      cond do
        is_map(row["source_feedback"]) -> row["source_feedback"]
        is_map(source_review_row["source_feedback"]) -> source_review_row["source_feedback"]
        map_size(source_review_row) > 0 -> source_review_row
        true -> row
      end
      |> RowValues.stringify_keys_with_keyword_maps()

    fallback = review_fallback(row, source_review_row)
    feedback_status = fallback["feedback_status"] || source["status"]

    realized_status =
      fallback["realized_status"] || source["realized_status"] || fallback["status"]

    source
    |> Map.put("schema_contract", "realized_activity.v1")
    |> maybe_put("feedback_status", feedback_status)
    |> maybe_put("status", realized_status)
    |> put_feedback_fallback(fallback, "activity_id")
    |> put_feedback_fallback(fallback, "id", "activity_id")
    |> put_feedback_fallback(fallback, "timeline_id", "timeline_identity")
    |> put_feedback_fallback(fallback, "scenario_id")
    |> put_feedback_fallback(fallback, "ground_station_id")
    |> put_feedback_fallback(fallback, "ground_station_id", "planned_ground_station_id")
    |> put_feedback_fallback(fallback, "ground_station_id", "realized_ground_station_id")
    |> put_feedback_fallback(fallback, "target_id")
    |> put_feedback_fallback(fallback, "target_id", "planned_target_id")
    |> put_feedback_fallback(fallback, "target_id", "realized_target_id")
    |> put_feedback_fallback(fallback, "contact_success")
    |> put_feedback_fallback(fallback, "contact_success_factor")
    |> put_feedback_fallback(fallback, "contact_result")
    |> put_feedback_fallback(fallback, "observation_success")
    |> put_feedback_fallback(fallback, "observation_success_factor")
    |> put_feedback_fallback(fallback, "observation_result")
    |> put_feedback_fallback(fallback, "image_quality_score")
    |> put_feedback_fallback(fallback, "image_quality_status")
    |> put_feedback_fallback(fallback, "image_quality_source")
    |> put_feedback_fallback(fallback, "cloud_cover_fraction")
    |> put_feedback_fallback(fallback, "blur_score")
    |> put_feedback_fallback(fallback, "command_success")
    |> put_feedback_fallback(fallback, "command_success_factor")
    |> put_feedback_fallback(fallback, "command_result")
    |> put_feedback_fallback(fallback, "maneuver_success")
    |> put_feedback_fallback(fallback, "maneuver_success_factor")
    |> put_feedback_fallback(fallback, "maneuver_result")
    |> put_feedback_fallback(fallback, "execution_uncertainty")
    |> put_feedback_fallback(fallback, "execution_uncertainty_status")
    |> put_feedback_fallback(fallback, "timing_3sigma_s")
    |> put_feedback_fallback(fallback, "delta_v_3sigma_km_s")
    |> put_feedback_fallback(fallback, "delta_v_3sigma_magnitude_km_s")
    |> put_feedback_fallback(fallback, "execution_uncertainty_source")
    |> put_feedback_fallback(fallback, "actual_throughput_mb")
    |> put_feedback_fallback(fallback, "estimated_throughput_mb")
    |> put_feedback_fallback(fallback, "required_downlink_mb")
    |> put_feedback_fallback(fallback, "completed_fraction")
    |> put_feedback_fallback(fallback, "feedback_weight")
    |> put_feedback_fallback(fallback, "feedback_weight_source")
    |> put_feedback_fallback(fallback, "feedback_sample_weight")
    |> put_feedback_fallback(fallback, "feedback_sample_weight_source")
    |> put_feedback_fallback(fallback, "sample_weight")
    |> put_feedback_fallback(fallback, "sample_weight_source")
    |> put_feedback_fallback(fallback, "confidence_weight")
    |> put_feedback_fallback(fallback, "confidence_weight_source")
    |> maybe_put("type", review_type(fallback, source))
    |> maybe_put("_operator_review_feedback_status", feedback_status)
    |> maybe_put(
      "_operator_review_match_strategy",
      fallback["match_strategy"] || source["match_strategy"]
    )
    |> put_row_trust_boundary(
      row,
      source_review_row,
      source_artifact,
      artifact,
      result_artifact_trust_boundary_fun
    )
    |> RowValues.compact_nonempty()
  end

  defp row_from_review_or_import_row(
         _row,
         _source_artifact,
         _artifact,
         _result_artifact_trust_boundary_fun
       ),
       do: nil

  defp review_fallback(row, source_review_row) do
    Map.merge(source_review_row, row, fn _key, review_value, row_value ->
      if row_value in [nil, ""], do: review_value, else: row_value
    end)
  end

  defp review_type(row, source) do
    row["activity_type"] || source["activity_type"] || source["planned_type"] ||
      source["realized_type"] ||
      feedback_kind_activity_type(row["feedback_kind"] || source["feedback_kind"])
  end

  defp feedback_kind_activity_type("observation"), do: "observe"
  defp feedback_kind_activity_type("contact"), do: "contact"
  defp feedback_kind_activity_type("command"), do: "command"
  defp feedback_kind_activity_type("maneuver"), do: "maneuver"
  defp feedback_kind_activity_type(_kind), do: nil

  defp put_feedback_fallback(source, row, field, row_field \\ nil) do
    row_field = row_field || field

    if Map.get(source, field) in [nil, ""] and Map.get(row, row_field) not in [nil, ""] do
      Map.put(source, field, Map.get(row, row_field))
    else
      source
    end
  end

  defp put_row_trust_boundary(
         realized_row,
         row,
         source_review_row,
         source_artifact,
         artifact,
         result_artifact_trust_boundary_fun
       ) do
    trust_boundary =
      Map.get(realized_row, "trust_boundary") ||
        Map.get(row, "trust_boundary") ||
        get_in(row, ["provenance", "trust_boundary"]) ||
        Map.get(source_review_row, "trust_boundary") ||
        get_in(source_review_row, ["provenance", "trust_boundary"]) ||
        result_artifact_trust_boundary(artifact, result_artifact_trust_boundary_fun) ||
        result_artifact_trust_boundary(source_artifact, result_artifact_trust_boundary_fun)

    realized_row
    |> maybe_put("trust_boundary", trust_boundary)
    |> maybe_put("_source_report_trust_boundary", trust_boundary)
  end

  defp entries(path, row_or_rows, artifact, opts)

  defp entries(path, %{} = row, artifact, opts) do
    row = RowValues.stringify_keys_with_keyword_maps(row)
    result_artifact_trust_boundary_fun = Keyword.get(opts, :result_artifact_trust_boundary_fun)

    cond do
      realized_activity_feedback_row?(row) ->
        [{path, put_inherited_trust_boundary(row, artifact, result_artifact_trust_boundary_fun)}]

      realized_state_snapshot_feedback_row?(row) ->
        trust_boundary =
          realized_state_snapshot_trust_boundary(row) ||
            result_artifact_trust_boundary(artifact, result_artifact_trust_boundary_fun)

        row
        |> realized_state_snapshot_feedback_activities()
        |> Enum.flat_map(fn activity ->
          activity =
            activity
            |> RowValues.stringify_keys_with_keyword_maps()
            |> maybe_put("trust_boundary", trust_boundary)
            |> maybe_put("_source_report_trust_boundary", trust_boundary)

          entries("#{path}.activities", activity, artifact,
            result_artifact_trust_boundary_fun: result_artifact_trust_boundary_fun
          )
        end)

      true ->
        []
    end
  end

  defp entries(path, rows, artifact, opts) when is_list(rows) do
    rows
    |> Enum.flat_map(&entries(path, &1, artifact, opts))
  end

  defp entries(_path, _row_or_rows, _artifact, _opts), do: []

  defp realized_activity_feedback_row?(%{"schema_contract" => "realized_activity.v1"}), do: true
  defp realized_activity_feedback_row?(_row), do: false

  defp realized_state_snapshot_feedback_row?(%{
         "schema_contract" => "realized_state_snapshot.v1"
       }),
       do: true

  defp realized_state_snapshot_feedback_row?(_row), do: false

  defp realized_state_snapshot_feedback_activities(snapshot) do
    Map.get(snapshot, "activities") || Map.get(snapshot, "realized_activities") || []
  end

  defp realized_state_snapshot_trust_boundary(snapshot) do
    Map.get(snapshot, "trust_boundary") ||
      get_in(snapshot, ["provenance", "trust_boundary"]) ||
      get_in(snapshot, ["metadata", "trust_boundary"])
  end

  defp put_inherited_trust_boundary(row, %{} = artifact, result_artifact_trust_boundary_fun) do
    case result_artifact_trust_boundary(artifact, result_artifact_trust_boundary_fun) do
      trust_boundary when trust_boundary in [nil, ""] ->
        row

      trust_boundary ->
        row
        |> Map.put_new("trust_boundary", RowValues.encode_value_with_keyword_maps(trust_boundary))
        |> Map.put_new(
          "_source_report_trust_boundary",
          RowValues.encode_value_with_keyword_maps(trust_boundary)
        )
    end
  end

  defp put_inherited_trust_boundary(row, _artifact, _result_artifact_trust_boundary_fun), do: row

  defp result_artifact_trust_boundary(%{} = artifact, result_artifact_trust_boundary_fun)
       when is_function(result_artifact_trust_boundary_fun, 1) do
    result_artifact_trust_boundary_fun.(artifact)
  end

  defp result_artifact_trust_boundary(_artifact, _result_artifact_trust_boundary_fun), do: nil

  defp maybe_put(map, _key, value) when value in [nil, ""], do: map

  defp maybe_put(map, key, value),
    do: Map.put(map, key, RowValues.encode_value_with_keyword_maps(value))
end
