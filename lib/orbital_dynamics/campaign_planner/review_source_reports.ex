defmodule OrbitalDynamics.CampaignPlanner.ReviewSourceReports do
  @moduledoc false

  def command_window_reports(mission_state, opts) do
    command_window_reports(
      mission_state,
      [
        {"source_command_window_report", "mission_state.source_command_window_report"},
        {"command_window_report", "mission_state.command_window_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_command_window_report", opts) ++
      result_artifact_embedded_reports(mission_state, "command_window_report", opts)
  end

  def source_command_window_reports(mission_state, opts) do
    command_window_reports(
      mission_state,
      [
        {"source_command_window_report", "mission_state.source_command_window_report"}
      ],
      opts
    )
  end

  def canonical_command_window_reports(mission_state, opts) do
    command_window_reports(
      mission_state,
      [
        {"command_window_report", "mission_state.command_window_report"}
      ],
      opts
    )
  end

  def prior_plan_command_window_reports(prior_plan, opts) do
    direct_report_entries(
      prior_plan,
      [
        {"source_command_window_report", "prior_plan.source_command_window_report"},
        {"command_window_report", "prior_plan.command_window_report"}
      ]
    ) ++
      result_artifact_embedded_reports(
        prior_plan,
        ["source_command_window_report", "command_window_report"],
        opts
      )
  end

  def maneuver_review_reports(mission_state, opts) do
    maneuver_review_reports(
      mission_state,
      [
        {"source_maneuver_review_report", "mission_state.source_maneuver_review_report"},
        {"maneuver_review_report", "mission_state.maneuver_review_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_maneuver_review_report", opts) ++
      result_artifact_embedded_reports(mission_state, "maneuver_review_report", opts)
  end

  def source_maneuver_review_reports(mission_state, opts) do
    maneuver_review_reports(
      mission_state,
      [
        {"source_maneuver_review_report", "mission_state.source_maneuver_review_report"}
      ],
      opts
    )
  end

  def canonical_maneuver_review_reports(mission_state, opts) do
    maneuver_review_reports(
      mission_state,
      [
        {"maneuver_review_report", "mission_state.maneuver_review_report"}
      ],
      opts
    )
  end

  def prior_plan_maneuver_review_reports(prior_plan, opts) do
    prior_plan_maneuver_review_direct_reports(prior_plan) ++
      result_artifact_embedded_reports(
        prior_plan,
        ["source_maneuver_review_report", "maneuver_review_report"],
        opts
      )
  end

  def prior_plan_maneuver_review_direct_reports(prior_plan) do
    direct_report_entries(
      prior_plan,
      [
        {"source_maneuver_review_report", "prior_plan.source_maneuver_review_report"},
        {"maneuver_review_report", "prior_plan.maneuver_review_report"}
      ]
    )
  end

  def prior_plan_timeline_feedback_reports(prior_plan, opts) do
    direct_report_entries(
      prior_plan,
      [
        {"source_timeline_feedback_report", "prior_plan.source_timeline_feedback_report"},
        {"timeline_feedback_report", "prior_plan.timeline_feedback_report"}
      ]
    ) ++
      result_artifact_embedded_reports(
        prior_plan,
        ["source_timeline_feedback_report", "timeline_feedback_report"],
        opts
      )
  end

  def prior_plan_operational_timeline_reports(prior_plan, opts) do
    direct_report_entries(
      prior_plan,
      [
        {"source_operational_timeline_report", "prior_plan.source_operational_timeline_report"},
        {"operational_timeline_report", "prior_plan.operational_timeline_report"}
      ]
    ) ++
      result_artifact_embedded_reports(
        prior_plan,
        ["source_operational_timeline_report", "operational_timeline_report"],
        opts
      )
  end

  def operational_timeline_reports(mission_state, opts) do
    source_report_entries(
      mission_state,
      [
        {"source_operational_timeline_report",
         "mission_state.source_operational_timeline_report"},
        {"operational_timeline_report", "mission_state.operational_timeline_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(
        mission_state,
        "source_operational_timeline_report",
        opts
      ) ++
      result_artifact_embedded_reports(mission_state, "operational_timeline_report", opts)
  end

  def timeline_feedback_reports(mission_state, opts) do
    source_report_entries(
      mission_state,
      [
        {"source_timeline_feedback_report", "mission_state.source_timeline_feedback_report"},
        {"timeline_feedback_report", "mission_state.timeline_feedback_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_timeline_feedback_report", opts) ++
      result_artifact_embedded_reports(mission_state, "timeline_feedback_report", opts)
  end

  def command_window_source_metadata(reports_with_sources, feedback_rows, opts) do
    callbacks = command_window_metadata_callbacks!(opts)
    {reports, source_paths} = reports_and_source_paths(reports_with_sources)

    feedback_source_metadata(
      "command_window_report.v1",
      reports,
      source_paths,
      report_row_count(reports),
      feedback_rows,
      callbacks
    )
  end

  def maneuver_review_source_metadata(
        reports_with_sources,
        feedback_rows,
        source_rows,
        extra_metadata,
        opts
      ) do
    callbacks = maneuver_review_metadata_callbacks!(opts)
    {reports, source_paths} = reports_and_source_paths(reports_with_sources)

    extra_metadata =
      %{
        "source_execution_uncertainty_declared_count" =>
          callbacks.execution_uncertainty_status_count.(source_rows, "declared"),
        "source_execution_uncertainty_missing_count" =>
          callbacks.execution_uncertainty_status_count.(source_rows, "missing")
      }
      |> Map.merge(extra_metadata || %{})

    feedback_source_metadata(
      "maneuver_review_report.v1",
      reports,
      source_paths,
      report_row_count(reports),
      feedback_rows,
      callbacks,
      include_trust_boundaries?: false,
      extra_metadata: extra_metadata
    )
  end

  def operational_timeline_source_metadata(reports_with_sources, feedback_rows, opts) do
    callbacks = operational_timeline_metadata_callbacks!(opts)
    {reports, source_paths} = reports_and_source_paths(reports_with_sources)

    feedback_source_metadata(
      "operational_timeline_report.v1",
      reports,
      source_paths,
      length(feedback_rows),
      feedback_rows,
      callbacks
    )
  end

  defp feedback_source_metadata(
         contract,
         reports,
         source_paths,
         source_report_row_count,
         feedback_rows,
         callbacks,
         opts \\ []
       ) do
    weighted_feedback_row_count = callbacks.weighted_feedback_row_count.(feedback_rows)
    feedback_weight_sources = callbacks.feedback_weight_sources.(feedback_rows)

    %{
      "source_report_contract" => contract,
      "source_report_count" => length(reports),
      "source_report_paths" => if(source_paths == [], do: nil, else: source_paths),
      "source_report_row_count" => source_report_row_count,
      "weighted_feedback_row_count" =>
        if(weighted_feedback_row_count > 0, do: weighted_feedback_row_count),
      "feedback_weight_sources" =>
        if(feedback_weight_sources == [], do: nil, else: feedback_weight_sources)
    }
    |> maybe_put_source_report_trust_boundaries(
      reports,
      Keyword.get(opts, :include_trust_boundaries?, true)
    )
    |> maybe_put_feedback_trust_boundaries(
      feedback_rows,
      callbacks,
      Keyword.get(opts, :include_trust_boundaries?, true)
    )
    |> Map.merge(Keyword.get(opts, :extra_metadata, %{}))
    |> compact_map()
  end

  def timeline_feedback_source_metadata(reports_with_sources, opts) do
    callbacks = timeline_feedback_metadata_callbacks!(opts)
    {reports, source_paths} = reports_and_source_paths(reports_with_sources)

    case reports do
      [] ->
        %{}

      [report] ->
        report
        |> source_report_metadata(callbacks)
        |> put_if_present("source_report_paths", source_paths)
        |> put_if_absent(
          "trust_boundary_status",
          timeline_feedback_report_trust_boundary_status(reports, callbacks)
        )
        |> put_if_absent(
          "trust_boundaries",
          timeline_feedback_report_trust_boundaries(reports, callbacks)
        )
        |> put_if_absent(
          "feedback_trust_boundaries",
          timeline_feedback_reports_feedback_trust_boundaries(reports, callbacks)
        )

      _reports ->
        %{
          "source_report_contract" => "timeline_feedback_report.v1",
          "source_report_count" => length(reports),
          "source_report_paths" => source_paths,
          "source_report_row_count" =>
            reports
            |> Enum.map(&timeline_feedback_report_row_count/1)
            |> Enum.sum(),
          "source_report_status_counts" =>
            merge_report_count_maps(reports, "status_counts", callbacks),
          "source_feedback_kind_counts" =>
            merge_report_count_maps(reports, "feedback_kind_counts", callbacks),
          "source_match_strategy_counts" =>
            merge_report_count_maps(reports, "match_strategy_counts", callbacks),
          "source_cadence_import_status_counts" =>
            merge_report_count_maps(reports, "cadence_import_status_counts", callbacks),
          "source_planned_protection_decision_counts" =>
            merge_report_count_maps(reports, "planned_protection_decision_counts", callbacks),
          "trust_boundary_status" =>
            timeline_feedback_report_trust_boundary_status(reports, callbacks),
          "trust_boundaries" => timeline_feedback_report_trust_boundaries(reports, callbacks),
          "feedback_trust_boundaries" =>
            timeline_feedback_reports_feedback_trust_boundaries(reports, callbacks)
        }
        |> compact_map()
    end
  end

  def timeline_feedback_report_row_count(report) do
    Map.get(report, "row_count") || length(Map.get(report, "rows", []))
  end

  defp command_window_reports(mission_state, fields, opts) do
    source_report_entries(mission_state, fields, opts)
  end

  defp maneuver_review_reports(mission_state, fields, opts) do
    source_report_entries(mission_state, fields, opts)
  end

  defp direct_report_entries(source, fields) do
    fields
    |> Enum.flat_map(fn {field, source_path} ->
      case Map.get(source, field) do
        %{} = report -> [{stringify_keys(report), source_path}]
        _report -> []
      end
    end)
  end

  defp source_report_entries(mission_state, fields, opts) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp result_artifact_embedded_reports(source, report_keys, opts) when is_list(report_keys) do
    callbacks = result_artifact_callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(source, report_keys)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    callbacks = result_artifact_callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(mission_state, report_key)
  end

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp result_artifact_callbacks!(opts) do
    %{
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp command_window_metadata_callbacks!(opts) do
    %{
      weighted_feedback_row_count: Keyword.fetch!(opts, :weighted_feedback_row_count),
      feedback_weight_sources: Keyword.fetch!(opts, :feedback_weight_sources),
      feedback_trust_boundaries: Keyword.fetch!(opts, :feedback_trust_boundaries)
    }
  end

  defp maneuver_review_metadata_callbacks!(opts) do
    %{
      weighted_feedback_row_count: Keyword.fetch!(opts, :weighted_feedback_row_count),
      feedback_weight_sources: Keyword.fetch!(opts, :feedback_weight_sources),
      execution_uncertainty_status_count:
        Keyword.fetch!(opts, :execution_uncertainty_status_count)
    }
  end

  defp operational_timeline_metadata_callbacks!(opts) do
    %{
      weighted_feedback_row_count: Keyword.fetch!(opts, :weighted_feedback_row_count),
      feedback_weight_sources: Keyword.fetch!(opts, :feedback_weight_sources),
      feedback_trust_boundaries: Keyword.fetch!(opts, :feedback_trust_boundaries)
    }
  end

  defp timeline_feedback_metadata_callbacks!(opts) do
    %{
      operational_feedback_provenance_trust_boundaries:
        Keyword.fetch!(opts, :operational_feedback_provenance_trust_boundaries),
      numeric_or_nil: Keyword.fetch!(opts, :numeric_or_nil),
      merge_feedback_trust_boundary_maps:
        Keyword.fetch!(opts, :merge_feedback_trust_boundary_maps),
      normalize_operational_feedback: Keyword.fetch!(opts, :normalize_operational_feedback),
      operational_feedback_value_present:
        Keyword.fetch!(opts, :operational_feedback_value_present),
      put_feedback_trust_boundary: Keyword.fetch!(opts, :put_feedback_trust_boundary)
    }
  end

  defp reports_and_source_paths(reports_with_sources) do
    reports = Enum.map(reports_with_sources, fn {report, _source_path} -> report end)
    source_paths = Enum.map(reports_with_sources, fn {_report, source_path} -> source_path end)

    {reports, source_paths}
  end

  defp maybe_put_source_report_trust_boundaries(metadata, _reports, false), do: metadata

  defp maybe_put_source_report_trust_boundaries(metadata, reports, _include?) do
    trust_boundaries = report_trust_boundaries(reports)

    metadata
    |> Map.put(
      "trust_boundary_status",
      if(trust_boundaries in [nil, []], do: nil, else: "declared")
    )
    |> Map.put("trust_boundaries", trust_boundaries)
  end

  defp maybe_put_feedback_trust_boundaries(metadata, _feedback_rows, _callbacks, false),
    do: metadata

  defp maybe_put_feedback_trust_boundaries(metadata, feedback_rows, callbacks, _include?) do
    Map.put(
      metadata,
      "feedback_trust_boundaries",
      callbacks.feedback_trust_boundaries.(feedback_rows)
    )
  end

  defp report_trust_boundaries(reports) do
    reports
    |> Enum.flat_map(fn report ->
      [
        Map.get(report, "trust_boundary"),
        get_in(report, ["provenance", "trust_boundary"])
      ]
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp report_row_count(reports) do
    reports
    |> Enum.flat_map(&(Map.get(&1, "rows", []) || []))
    |> length()
  end

  defp merge_report_count_maps(reports, field, callbacks) do
    reports
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn counts, merged ->
      counts
      |> stringify_keys()
      |> Enum.reduce(merged, fn {key, value}, merged ->
        case callbacks.numeric_or_nil.(value) do
          number when is_number(number) ->
            Map.update(merged, key, number, &(&1 + number))

          _value ->
            merged
        end
      end)
    end)
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp source_report_metadata(%{} = report, callbacks) when map_size(report) > 0 do
    compact_map(%{
      "source_report_contract" => Map.get(report, "schema_contract"),
      "source_report_count" => 1,
      "source_report_row_count" =>
        Map.get(report, "row_count") || length(Map.get(report, "rows", [])),
      "source_report_status_counts" => Map.get(report, "status_counts"),
      "source_feedback_kind_counts" => Map.get(report, "feedback_kind_counts"),
      "source_match_strategy_counts" => Map.get(report, "match_strategy_counts"),
      "source_cadence_import_status_counts" => Map.get(report, "cadence_import_status_counts"),
      "source_planned_protection_decision_counts" =>
        Map.get(report, "planned_protection_decision_counts"),
      "source_operational_feedback_provenance" =>
        source_report_operational_feedback_provenance(report),
      "trust_boundary_status" =>
        source_report_operational_feedback_trust_status(report, callbacks),
      "trust_boundaries" => source_report_operational_feedback_trust_boundaries(report, callbacks)
    })
  end

  defp source_report_metadata(_report, _callbacks), do: %{}

  defp source_report_operational_feedback_provenance(%{
         "operational_feedback_provenance" => %{} = provenance
       }),
       do: provenance

  defp source_report_operational_feedback_provenance(_report), do: nil

  defp source_report_operational_feedback_trust_status(report, callbacks) do
    case source_report_operational_feedback_trust_boundaries(report, callbacks) do
      boundaries when is_list(boundaries) and boundaries != [] -> "declared"
      _boundaries -> nil
    end
  end

  defp source_report_operational_feedback_trust_boundaries(report, callbacks) do
    case source_report_operational_feedback_provenance(report) do
      %{} = provenance ->
        case callbacks.operational_feedback_provenance_trust_boundaries.(provenance) do
          [] -> nil
          boundaries -> boundaries
        end

      _provenance ->
        nil
    end
  end

  defp timeline_feedback_report_trust_boundary_status(reports, callbacks) do
    case timeline_feedback_report_trust_boundaries(reports, callbacks) do
      boundaries when is_list(boundaries) and boundaries != [] -> "declared"
      _boundaries -> nil
    end
  end

  defp timeline_feedback_report_trust_boundaries(reports, callbacks) do
    reports
    |> Enum.flat_map(fn report ->
      [
        Map.get(report, "trust_boundary"),
        get_in(report, ["provenance", "trust_boundary"]),
        source_report_operational_feedback_trust_boundaries(report, callbacks)
      ]
    end)
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp timeline_feedback_reports_feedback_trust_boundaries(reports, callbacks) do
    reports
    |> Enum.reduce(%{}, fn report, boundaries ->
      report_boundaries =
        case source_report_operational_feedback_trust_boundaries(report, callbacks) do
          values when is_list(values) and values != [] ->
            %{
              "source_operational_feedback_provenance" =>
                source_report_operational_feedback_provenance(report)
            }
            |> source_feedback_trust_boundaries()
            |> callbacks.merge_feedback_trust_boundary_maps.()

          _values ->
            timeline_feedback_report_feedback_trust_boundaries(report, callbacks)
        end

      callbacks.merge_feedback_trust_boundary_maps.([boundaries, report_boundaries])
    end)
    |> case do
      boundaries when boundaries == %{} -> nil
      boundaries -> boundaries
    end
  end

  defp timeline_feedback_report_feedback_trust_boundaries(report, callbacks) do
    trust_boundary =
      Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

    if trust_boundary in [nil, ""] do
      %{}
    else
      report
      |> Map.get("operational_feedback", %{})
      |> callbacks.normalize_operational_feedback.()
      |> Enum.reduce(%{}, fn {field, values}, boundaries ->
        values
        |> Enum.reduce(boundaries, fn {key, value}, boundaries ->
          if callbacks.operational_feedback_value_present.(%{key => value}) do
            callbacks.put_feedback_trust_boundary.(boundaries, field, key, [trust_boundary])
          else
            boundaries
          end
        end)
      end)
    end
  end

  defp source_feedback_trust_boundaries(source) do
    direct =
      case Map.get(source, "feedback_trust_boundaries") do
        %{} = boundaries -> [boundaries]
        _boundaries -> []
      end

    provenance =
      source |> Map.get("source_operational_feedback_provenance", %{}) |> stringify_keys()

    provenance_direct =
      case Map.get(provenance, "feedback_trust_boundaries") do
        %{} = boundaries -> [boundaries]
        _boundaries -> []
      end

    nested =
      provenance
      |> Map.get("sources", [])
      |> Enum.flat_map(fn nested_source ->
        case nested_source |> stringify_keys() |> Map.get("feedback_trust_boundaries") do
          %{} = boundaries -> [boundaries]
          _boundaries -> []
        end
      end)

    direct ++ provenance_direct ++ nested
  end

  defp compact_map(map) do
    Map.reject(map, fn {_key, value} -> is_nil(value) end)
  end

  defp put_if_present(map, _key, value) when value in [nil, []], do: map

  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp put_if_absent(map, key, value) do
    if Map.has_key?(map, key) do
      map
    else
      put_if_present(map, key, value)
    end
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
