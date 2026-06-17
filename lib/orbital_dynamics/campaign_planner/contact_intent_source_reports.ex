defmodule OrbitalDynamics.CampaignPlanner.ContactIntentSourceReports do
  @moduledoc false

  @contact_intent_source_keys [
    "source_contact_intent",
    "contact_intent",
    "source_contact_intents",
    "contact_intents"
  ]

  @contact_intent_summary_report_keys [
    "source_contact_intent_summary",
    "contact_intent_summary"
  ]

  def prior_plan_rows_with_source(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_rows = container_rows_with_source(prior_plan, "prior_plan")

    direct_rows ++ result_artifact_rows_with_source(prior_plan, opts)
  end

  def mission_state_rows_with_source(mission_state, opts) do
    direct_rows =
      mission_state_direct_rows_with_source(
        mission_state,
        @contact_intent_source_keys
      )

    direct_rows ++ result_artifact_rows_with_source(mission_state, opts)
  end

  def mission_state_source_contact_intent_rows_with_source(mission_state) do
    mission_state_direct_rows_with_source(mission_state, ["source_contact_intent"])
  end

  def mission_state_source_contact_intents_rows_with_source(mission_state) do
    mission_state_direct_rows_with_source(mission_state, ["source_contact_intents"])
  end

  def mission_state_canonical_contact_intent_rows_with_source(mission_state) do
    mission_state_direct_rows_with_source(mission_state, ["contact_intent"])
  end

  def mission_state_canonical_contact_intents_rows_with_source(mission_state) do
    mission_state_direct_rows_with_source(mission_state, ["contact_intents"])
  end

  def mission_state_source_contact_intent_summaries(mission_state, opts) do
    source_report_entries(
      mission_state,
      [{"source_contact_intent_summary", "mission_state.source_contact_intent_summary"}],
      opts
    )
  end

  def mission_state_canonical_contact_intent_summaries(mission_state, opts) do
    source_report_entries(
      mission_state,
      [{"contact_intent_summary", "mission_state.contact_intent_summary"}],
      opts
    )
  end

  def prior_plan_summaries_with_source(prior_plan, opts) do
    source_report_entries(
      prior_plan,
      [
        {"source_contact_intent_summary", "prior_plan.source_contact_intent_summary"},
        {"contact_intent_summary", "prior_plan.contact_intent_summary"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(
        prior_plan,
        @contact_intent_summary_report_keys,
        opts
      )
  end

  def mission_state_summaries_with_source(mission_state, opts) do
    mission_state_source_contact_intent_summaries(mission_state, opts) ++
      mission_state_canonical_contact_intent_summaries(mission_state, opts) ++
      result_artifact_embedded_reports(
        mission_state,
        "source_contact_intent_summary",
        opts
      ) ++
      result_artifact_embedded_reports(mission_state, "contact_intent_summary", opts)
  end

  defp mission_state_direct_rows_with_source(mission_state, source_keys) do
    mission_state = stringify_keys(mission_state || %{})

    container_rows_with_source(mission_state, "mission_state", source_keys)
  end

  defp container_rows_with_source(container, source_prefix) do
    container_rows_with_source(container, source_prefix, @contact_intent_source_keys)
  end

  defp container_rows_with_source(container, source_prefix, source_keys) do
    container = stringify_keys(container || %{})

    source_keys
    |> Enum.flat_map(fn key ->
      source_rows(Map.get(container, key), "#{source_prefix}.#{key}")
    end)
  end

  defp source_rows(%{} = row, source_path) do
    row
    |> stringify_keys()
    |> row_with_source(source_path)
    |> List.wrap()
  end

  defp source_rows(rows, source_path) when is_list(rows) do
    rows
    |> Enum.flat_map(&source_rows(&1, source_path))
  end

  defp source_rows(_rows, _source_path), do: []

  defp row_with_source(row, source_path) do
    if standalone_row?(row) do
      {row, source_path}
    end
  end

  defp standalone_row?(%{"schema_contract" => "contact_intent.v1"}), do: true
  defp standalone_row?(_row), do: false

  defp result_artifact_rows_with_source(container, opts) do
    callbacks = callbacks!(opts)

    container
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      artifact = stringify_keys(artifact || %{})

      artifact
      |> container_rows_with_source(source_path)
      |> Enum.map(fn {row, row_source_path} ->
        row =
          row
          |> callbacks.put_inherited_result_artifact_trust_boundary.(artifact)

        {row, row_source_path}
      end)
    end)
  end

  defp source_report_entries(container, fields, opts) do
    callbacks = callbacks!(opts)
    container = stringify_keys(container || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(container, field), source_path)
    end)
  end

  defp result_artifact_embedded_reports(container, report_keys, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(container, report_keys)
  end

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports),
      put_inherited_result_artifact_trust_boundary:
        Keyword.fetch!(opts, :put_inherited_result_artifact_trust_boundary)
    }
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
