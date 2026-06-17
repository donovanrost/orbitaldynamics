defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationSourceReports do
  @moduledoc false

  @report_fields [
    {"source_contact_allocation_report", "mission_state.source_contact_allocation_report"},
    {"contact_allocation_report", "mission_state.contact_allocation_report"}
  ]

  @prior_report_fields [
    {"source_contact_allocation_report", "prior_plan.source_contact_allocation_report"},
    {"contact_allocation_report", "prior_plan.contact_allocation_report"}
  ]

  @summary_pairs %{
    "source_contact_allocation_summary" => "contact_allocation_summary",
    "source_contact_allocation_station_pressure_summary" =>
      "contact_allocation_station_pressure_summary",
    "source_contact_allocation_reservation_conflict_summary" =>
      "contact_allocation_reservation_conflict_summary",
    "source_contact_allocation_capacity_pack_summary" =>
      "contact_allocation_capacity_pack_summary",
    "source_contact_allocation_provider_reservation_request_summary" =>
      "contact_allocation_provider_reservation_request_summary"
  }

  @pressure_summary_fields [
    "source_contact_allocation_summary",
    "contact_allocation_summary",
    "source_contact_allocation_station_pressure_summary",
    "contact_allocation_station_pressure_summary",
    "source_contact_allocation_reservation_conflict_summary",
    "contact_allocation_reservation_conflict_summary",
    "source_contact_allocation_capacity_pack_summary",
    "contact_allocation_capacity_pack_summary",
    "source_contact_allocation_provider_reservation_request_summary",
    "contact_allocation_provider_reservation_request_summary"
  ]

  def reports(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    source_reports(mission_state, @report_fields, opts) ++
      result_artifact_embedded_reports(mission_state, "source_contact_allocation_report", opts) ++
      result_artifact_embedded_reports(mission_state, "contact_allocation_report", opts)
  end

  def reports(mission_state, "source_contact_allocation_report", opts) do
    source_reports(
      mission_state,
      [
        {"source_contact_allocation_report", "mission_state.source_contact_allocation_report"}
      ],
      opts
    )
  end

  def reports(mission_state, "contact_allocation_report", opts) do
    source_reports(
      mission_state,
      [
        {"contact_allocation_report", "mission_state.contact_allocation_report"}
      ],
      opts
    )
  end

  def prior_plan_reports(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_reports =
      @prior_report_fields
      |> Enum.flat_map(fn {field, source_path} ->
        case Map.get(prior_plan, field) do
          %{} = report -> [{stringify_keys(report), source_path}]
          _report -> []
        end
      end)

    direct_reports ++ prior_plan_result_artifact_reports(prior_plan, opts)
  end

  def summaries(mission_state, source_key, opts) when is_map_key(@summary_pairs, source_key) do
    source_reports_with_result_artifact_reports(
      mission_state,
      {source_key, "mission_state.#{source_key}"},
      [source_key, Map.fetch!(@summary_pairs, source_key)],
      opts
    )
  end

  def summaries(mission_state, canonical_key, opts) do
    source_reports(
      mission_state,
      [
        {canonical_key, "mission_state.#{canonical_key}"}
      ],
      opts
    )
  end

  def pressure_summaries(mission_state, opts) do
    Enum.flat_map(@pressure_summary_fields, &summaries(mission_state, &1, opts))
  end

  def prior_plan_pressure_summaries(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_summaries =
      @pressure_summary_fields
      |> Enum.flat_map(fn field ->
        case Map.get(prior_plan, field) do
          %{} = summary -> [{stringify_keys(summary), "prior_plan.#{field}"}]
          _summary -> []
        end
      end)

    direct_summaries ++ prior_plan_result_artifact_pressure_summaries(prior_plan, opts)
  end

  defp source_reports(mission_state, fields, opts) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp source_reports_with_result_artifact_reports(
         mission_state,
         {field, source_path},
         result_artifact_keys,
         opts
       ) do
    mission_state = stringify_keys(mission_state || %{})

    source_reports(mission_state, [{field, source_path}], opts) ++
      Enum.flat_map(result_artifact_keys, fn key ->
        result_artifact_embedded_reports(mission_state, key, opts)
      end)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(mission_state, report_key)
  end

  defp prior_plan_result_artifact_reports(prior_plan, opts) do
    callbacks = prior_plan_callbacks!(opts)
    report_keys = Enum.map(@report_fields, &elem(&1, 0))
    callbacks.result_artifact_embedded_reports.(prior_plan, report_keys)
  end

  defp prior_plan_result_artifact_pressure_summaries(prior_plan, opts) do
    callbacks = prior_plan_callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(prior_plan, @pressure_summary_fields)
  end

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp prior_plan_callbacks!(opts) do
    %{
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
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
