defmodule OrbitalDynamics.CampaignPlanner.ActivitySourceRows.RealizedRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.SourceReportArtifacts

  @realized_activity_source_keys [
    "source_realized_activity",
    "realized_activity",
    "source_realized_activities",
    "realized_activities"
  ]

  @mission_state_realized_activity_source_keys [
    "source_realized_activity",
    "realized_activity",
    "source_realized_activities"
  ]

  @realized_state_snapshot_source_keys [
    "source_realized_state_snapshot",
    "realized_state_snapshot",
    "source_realized_state",
    "realized_state"
  ]

  @mission_state_realized_state_snapshot_source_keys [
    "source_realized_state_snapshot",
    "realized_state_snapshot",
    "source_realized_state"
  ]

  def prior_plan_realized_activity_rows_with_source(prior_plan, opts, stringify_keys)
      when is_list(opts) and is_function(stringify_keys, 1) do
    prior_plan = stringify_keys.(prior_plan || %{})

    rows_with_sources =
      prior_plan
      |> realized_activity_container_rows_with_source(
        "prior_plan",
        @realized_activity_source_keys,
        @realized_state_snapshot_source_keys,
        stringify_keys
      )
      |> Kernel.++(
        result_artifact_realized_activity_rows_with_source(prior_plan, opts, stringify_keys)
      )

    enrich_realized_rows_with_source(rows_with_sources, prior_plan, opts)
  end

  def mission_state_realized_activity_rows_with_source(
        mission_state,
        prior_plan,
        opts,
        stringify_keys
      )
      when is_list(opts) and is_function(stringify_keys, 1) do
    mission_state = stringify_keys.(mission_state || %{})

    rows_with_sources =
      mission_state
      |> realized_activity_container_rows_with_source(
        "mission_state",
        @mission_state_realized_activity_source_keys,
        @mission_state_realized_state_snapshot_source_keys,
        stringify_keys
      )
      |> Kernel.++(
        result_artifact_realized_activity_rows_with_source(mission_state, opts, stringify_keys)
      )

    enrich_realized_rows_with_source(rows_with_sources, prior_plan, opts)
  end

  defp realized_activity_source_rows(%{} = row, source_path, stringify_keys) do
    row
    |> stringify_keys.()
    |> realized_activity_row_with_source(source_path)
    |> List.wrap()
  end

  defp realized_activity_source_rows(rows, source_path, stringify_keys) when is_list(rows) do
    rows
    |> Enum.flat_map(&realized_activity_source_rows(&1, source_path, stringify_keys))
  end

  defp realized_activity_source_rows(_rows, _source_path, _stringify_keys), do: []

  defp realized_activity_row_with_source(row, source_path) do
    if realized_activity_row?(row) do
      {row, source_path}
    end
  end

  defp realized_activity_row?(%{"schema_contract" => "realized_activity.v1"}), do: true
  defp realized_activity_row?(_row), do: false

  defp realized_state_snapshot_activity_source_rows(%{} = snapshot, source_path, stringify_keys) do
    snapshot = stringify_keys.(snapshot)

    if realized_state_snapshot_row?(snapshot) do
      trust_boundary =
        Map.get(snapshot, "trust_boundary") || get_in(snapshot, ["provenance", "trust_boundary"])

      snapshot
      |> realized_state_snapshot_activities()
      |> Enum.flat_map(fn activity ->
        activity
        |> stringify_keys.()
        |> put_if_absent("trust_boundary", trust_boundary)
        |> Map.put("_source_report_trust_boundary", trust_boundary)
        |> realized_activity_source_rows("#{source_path}.activities", stringify_keys)
      end)
    else
      []
    end
  end

  defp realized_state_snapshot_activity_source_rows(_snapshot, _source_path, _stringify_keys),
    do: []

  defp realized_state_snapshot_row?(%{"schema_contract" => "realized_state_snapshot.v1"}),
    do: true

  defp realized_state_snapshot_row?(_snapshot), do: false

  defp realized_state_snapshot_activities(snapshot) do
    Map.get(snapshot, "activities") || Map.get(snapshot, "realized_activities") || []
  end

  defp realized_activity_container_rows_with_source(
         container,
         source_prefix,
         activity_keys,
         snapshot_keys,
         stringify_keys
       ) do
    container = stringify_keys.(container || %{})

    activity_rows =
      activity_keys
      |> Enum.flat_map(fn key ->
        realized_activity_source_rows(
          Map.get(container, key),
          "#{source_prefix}.#{key}",
          stringify_keys
        )
      end)

    snapshot_rows =
      snapshot_keys
      |> Enum.flat_map(fn key ->
        realized_state_snapshot_activity_source_rows(
          Map.get(container, key),
          "#{source_prefix}.#{key}",
          stringify_keys
        )
      end)

    activity_rows ++ snapshot_rows
  end

  defp result_artifact_realized_activity_rows_with_source(container, opts, stringify_keys) do
    SourceReportArtifacts.inherited_result_artifact_entries(
      container,
      opts,
      stringify_keys,
      fn artifact, source_path ->
        realized_activity_container_rows_with_source(
          artifact,
          source_path,
          @realized_activity_source_keys,
          @realized_state_snapshot_source_keys,
          stringify_keys
        )
      end
    )
  end

  defp enrich_realized_rows_with_source(rows_with_sources, prior_plan, opts) do
    enrich_realized_activities_with_planned_context =
      Keyword.fetch!(opts, :enrich_realized_activities_with_planned_context)

    rows = Enum.map(rows_with_sources, fn {row, _source_path} -> row end)
    enriched_rows = enrich_realized_activities_with_planned_context.(rows, prior_plan)

    rows_with_sources
    |> Enum.map(fn {_row, source_path} -> source_path end)
    |> then(&Enum.zip(enriched_rows, &1))
  end

  defp put_if_absent(map, _key, nil), do: map
  defp put_if_absent(map, key, value), do: Map.put_new(map, key, value)
end
