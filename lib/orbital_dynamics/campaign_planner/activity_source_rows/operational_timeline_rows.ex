defmodule OrbitalDynamics.CampaignPlanner.ActivitySourceRows.OperationalTimelineRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.SourceReportArtifacts

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

  def prior_plan_planned_activity_rows_with_source(prior_plan, opts, stringify_keys)
      when is_list(opts) and is_function(stringify_keys, 1) do
    rows_with_source(
      prior_plan,
      "prior_plan",
      @planned_activity_source_keys,
      stringify_keys,
      opts
    )
  end

  def mission_state_planned_activity_rows_with_source(mission_state, opts, stringify_keys)
      when is_list(opts) and is_function(stringify_keys, 1) do
    rows_with_source(
      mission_state,
      "mission_state",
      @planned_activity_source_keys,
      stringify_keys,
      opts
    )
  end

  def prior_plan_proposed_contact_rows_with_source(prior_plan, opts, stringify_keys)
      when is_list(opts) and is_function(stringify_keys, 1) do
    rows_with_source(
      prior_plan,
      "prior_plan",
      @proposed_contact_source_keys,
      stringify_keys,
      opts
    )
  end

  def mission_state_proposed_contact_rows_with_source(mission_state, opts, stringify_keys)
      when is_list(opts) and is_function(stringify_keys, 1) do
    rows_with_source(
      mission_state,
      "mission_state",
      @proposed_contact_source_keys,
      stringify_keys,
      opts
    )
  end

  defp rows_with_source(container, source_prefix, source_keys, stringify_keys, opts) do
    container = stringify_keys.(container || %{})

    direct_rows =
      container_rows_with_source(container, source_prefix, source_keys, stringify_keys)

    direct_rows ++
      result_artifact_rows_with_source(container, source_keys, stringify_keys, opts)
  end

  defp container_rows_with_source(container, source_prefix, source_keys, stringify_keys) do
    container = stringify_keys.(container || %{})

    source_keys
    |> Enum.flat_map(fn key ->
      source_rows(Map.get(container, key), "#{source_prefix}.#{key}", source_keys, stringify_keys)
    end)
  end

  defp source_rows(%{} = row, source_path, source_keys, stringify_keys) do
    row
    |> stringify_keys.()
    |> row_with_source(source_path, source_keys, stringify_keys)
    |> List.wrap()
  end

  defp source_rows(rows, source_path, source_keys, stringify_keys) when is_list(rows) do
    rows
    |> Enum.flat_map(&source_rows(&1, source_path, source_keys, stringify_keys))
  end

  defp source_rows(_rows, _source_path, _source_keys, _stringify_keys), do: []

  defp row_with_source(row, source_path, @planned_activity_source_keys, _stringify_keys) do
    if planned_activity_row?(row) do
      {row, source_path}
    end
  end

  defp row_with_source(row, source_path, @proposed_contact_source_keys, stringify_keys) do
    if standalone_proposed_contact_row?(row, stringify_keys) do
      {row, source_path}
    end
  end

  defp planned_activity_row?(%{"schema_contract" => "planned_activity.v1"}), do: true
  defp planned_activity_row?(_row), do: false

  defp standalone_proposed_contact_row?(
         %{"schema_contract" => "proposed_contact.v1"},
         _stringify_keys
       ),
       do: true

  defp standalone_proposed_contact_row?(
         %{"cadence_import" => %{} = cadence_import},
         stringify_keys
       ) do
    stringify_keys.(cadence_import)["schema_contract"] == "proposed_contact.v1"
  end

  defp standalone_proposed_contact_row?(_row, _stringify_keys), do: false

  defp result_artifact_rows_with_source(container, source_keys, stringify_keys, opts) do
    SourceReportArtifacts.inherited_result_artifact_entries(
      container,
      opts,
      stringify_keys,
      fn artifact, source_path ->
        container_rows_with_source(artifact, source_path, source_keys, stringify_keys)
      end
    )
  end
end
