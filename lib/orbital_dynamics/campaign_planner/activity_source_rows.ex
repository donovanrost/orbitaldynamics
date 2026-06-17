defmodule OrbitalDynamics.CampaignPlanner.ActivitySourceRows do
  @moduledoc false

  @planned_activity_source_keys [
    "source_planned_activity",
    "planned_activity",
    "source_planned_activities",
    "planned_activities"
  ]

  @proposed_contact_source_keys [
    "source_proposed_contact",
    "proposed_contact",
    "source_proposed_contacts",
    "proposed_contacts"
  ]

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

  def prior_plan_planned_activity_rows_with_source(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_rows = planned_activity_container_rows_with_source(prior_plan, "prior_plan")

    direct_rows ++ result_artifact_planned_activity_rows_with_source(prior_plan, opts)
  end

  def mission_state_planned_activity_rows_with_source(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    direct_rows = planned_activity_container_rows_with_source(mission_state, "mission_state")

    direct_rows ++ result_artifact_planned_activity_rows_with_source(mission_state, opts)
  end

  def prior_plan_proposed_contact_rows_with_source(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_rows = proposed_contact_container_rows_with_source(prior_plan, "prior_plan")

    direct_rows ++ result_artifact_proposed_contact_rows_with_source(prior_plan, opts)
  end

  def mission_state_proposed_contact_rows_with_source(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    direct_rows = proposed_contact_container_rows_with_source(mission_state, "mission_state")

    direct_rows ++ result_artifact_proposed_contact_rows_with_source(mission_state, opts)
  end

  def prior_plan_realized_activity_rows_with_source(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    rows_with_sources =
      prior_plan
      |> realized_activity_container_rows_with_source(
        "prior_plan",
        @realized_activity_source_keys,
        @realized_state_snapshot_source_keys
      )
      |> Kernel.++(result_artifact_realized_activity_rows_with_source(prior_plan, opts))

    enrich_realized_rows_with_source(rows_with_sources, prior_plan, opts)
  end

  def mission_state_realized_activity_rows_with_source(mission_state, prior_plan, opts) do
    mission_state = stringify_keys(mission_state || %{})

    rows_with_sources =
      mission_state
      |> realized_activity_container_rows_with_source(
        "mission_state",
        @mission_state_realized_activity_source_keys,
        @mission_state_realized_state_snapshot_source_keys
      )
      |> Kernel.++(result_artifact_realized_activity_rows_with_source(mission_state, opts))

    enrich_realized_rows_with_source(rows_with_sources, prior_plan, opts)
  end

  defp planned_activity_source_rows(%{} = row, source_path) do
    row
    |> stringify_keys()
    |> planned_activity_row_with_source(source_path)
    |> List.wrap()
  end

  defp planned_activity_source_rows(rows, source_path) when is_list(rows) do
    rows
    |> Enum.flat_map(&planned_activity_source_rows(&1, source_path))
  end

  defp planned_activity_source_rows(_rows, _source_path), do: []

  defp planned_activity_row_with_source(row, source_path) do
    if planned_activity_row?(row) do
      {row, source_path}
    end
  end

  defp planned_activity_row?(%{"schema_contract" => "planned_activity.v1"}), do: true
  defp planned_activity_row?(_row), do: false

  defp planned_activity_container_rows_with_source(container, source_prefix) do
    container = stringify_keys(container || %{})

    @planned_activity_source_keys
    |> Enum.flat_map(fn key ->
      planned_activity_source_rows(Map.get(container, key), "#{source_prefix}.#{key}")
    end)
  end

  defp result_artifact_planned_activity_rows_with_source(container, opts) do
    container
    |> result_artifacts_with_source(opts)
    |> Enum.flat_map(fn {artifact, source_path} ->
      artifact = stringify_keys(artifact || %{})

      artifact
      |> planned_activity_container_rows_with_source(source_path)
      |> put_result_artifact_trust_boundary(artifact, opts)
    end)
  end

  defp proposed_contact_source_rows(%{} = row, source_path) do
    row
    |> stringify_keys()
    |> proposed_contact_row_with_source(source_path)
    |> List.wrap()
  end

  defp proposed_contact_source_rows(rows, source_path) when is_list(rows) do
    rows
    |> Enum.flat_map(&proposed_contact_source_rows(&1, source_path))
  end

  defp proposed_contact_source_rows(_rows, _source_path), do: []

  defp proposed_contact_row_with_source(row, source_path) do
    if standalone_proposed_contact_row?(row) do
      {row, source_path}
    end
  end

  defp standalone_proposed_contact_row?(%{"schema_contract" => "proposed_contact.v1"}),
    do: true

  defp standalone_proposed_contact_row?(%{"cadence_import" => %{} = cadence_import}) do
    stringify_keys(cadence_import)["schema_contract"] == "proposed_contact.v1"
  end

  defp standalone_proposed_contact_row?(_row), do: false

  defp proposed_contact_container_rows_with_source(container, source_prefix) do
    container = stringify_keys(container || %{})

    @proposed_contact_source_keys
    |> Enum.flat_map(fn key ->
      proposed_contact_source_rows(Map.get(container, key), "#{source_prefix}.#{key}")
    end)
  end

  defp result_artifact_proposed_contact_rows_with_source(container, opts) do
    container
    |> result_artifacts_with_source(opts)
    |> Enum.flat_map(fn {artifact, source_path} ->
      artifact = stringify_keys(artifact || %{})

      artifact
      |> proposed_contact_container_rows_with_source(source_path)
      |> put_result_artifact_trust_boundary(artifact, opts)
    end)
  end

  defp realized_activity_source_rows(%{} = row, source_path) do
    row
    |> stringify_keys()
    |> realized_activity_row_with_source(source_path)
    |> List.wrap()
  end

  defp realized_activity_source_rows(rows, source_path) when is_list(rows) do
    rows
    |> Enum.flat_map(&realized_activity_source_rows(&1, source_path))
  end

  defp realized_activity_source_rows(_rows, _source_path), do: []

  defp realized_activity_row_with_source(row, source_path) do
    if realized_activity_row?(row) do
      {row, source_path}
    end
  end

  defp realized_activity_row?(%{"schema_contract" => "realized_activity.v1"}), do: true
  defp realized_activity_row?(_row), do: false

  defp realized_state_snapshot_activity_source_rows(%{} = snapshot, source_path) do
    snapshot = stringify_keys(snapshot)

    if realized_state_snapshot_row?(snapshot) do
      trust_boundary =
        Map.get(snapshot, "trust_boundary") || get_in(snapshot, ["provenance", "trust_boundary"])

      snapshot
      |> realized_state_snapshot_activities()
      |> Enum.flat_map(fn activity ->
        activity
        |> stringify_keys()
        |> put_if_absent("trust_boundary", trust_boundary)
        |> Map.put("_source_report_trust_boundary", trust_boundary)
        |> realized_activity_source_rows("#{source_path}.activities")
      end)
    else
      []
    end
  end

  defp realized_state_snapshot_activity_source_rows(_snapshot, _source_path), do: []

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
         snapshot_keys
       ) do
    container = stringify_keys(container || %{})

    activity_rows =
      activity_keys
      |> Enum.flat_map(fn key ->
        realized_activity_source_rows(Map.get(container, key), "#{source_prefix}.#{key}")
      end)

    snapshot_rows =
      snapshot_keys
      |> Enum.flat_map(fn key ->
        realized_state_snapshot_activity_source_rows(
          Map.get(container, key),
          "#{source_prefix}.#{key}"
        )
      end)

    activity_rows ++ snapshot_rows
  end

  defp result_artifact_realized_activity_rows_with_source(container, opts) do
    container
    |> result_artifacts_with_source(opts)
    |> Enum.flat_map(fn {artifact, source_path} ->
      artifact = stringify_keys(artifact || %{})

      artifact
      |> realized_activity_container_rows_with_source(
        source_path,
        @realized_activity_source_keys,
        @realized_state_snapshot_source_keys
      )
      |> put_result_artifact_trust_boundary(artifact, opts)
    end)
  end

  defp enrich_realized_rows_with_source(rows_with_sources, prior_plan, opts) do
    enrich_realized_activities_with_planned_context =
      opts
      |> realized_callbacks!()
      |> Map.fetch!(:enrich_realized_activities_with_planned_context)

    rows = Enum.map(rows_with_sources, fn {row, _source_path} -> row end)
    enriched_rows = enrich_realized_activities_with_planned_context.(rows, prior_plan)

    rows_with_sources
    |> Enum.map(fn {_row, source_path} -> source_path end)
    |> then(&Enum.zip(enriched_rows, &1))
  end

  defp result_artifacts_with_source(container, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifacts_with_source.(container)
  end

  defp put_result_artifact_trust_boundary(rows_with_sources, artifact, opts) do
    put_inherited_result_artifact_trust_boundary =
      opts
      |> callbacks!()
      |> Map.fetch!(:put_inherited_result_artifact_trust_boundary)

    Enum.map(rows_with_sources, fn {row, row_source_path} ->
      row =
        row
        |> put_inherited_result_artifact_trust_boundary.(artifact)

      {row, row_source_path}
    end)
  end

  defp callbacks!(opts) do
    %{
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
      put_inherited_result_artifact_trust_boundary:
        Keyword.fetch!(opts, :put_inherited_result_artifact_trust_boundary)
    }
  end

  defp realized_callbacks!(opts) do
    Map.put(
      callbacks!(opts),
      :enrich_realized_activities_with_planned_context,
      Keyword.fetch!(opts, :enrich_realized_activities_with_planned_context)
    )
  end

  defp put_if_absent(map, _key, nil), do: map

  defp put_if_absent(map, key, value), do: Map.put_new(map, key, value)

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
