defmodule OrbitalDynamics.CampaignPlanner.BranchRefreshResourceSummaries do
  @moduledoc false

  def build(branch, base_summaries, opts) do
    callbacks = callbacks!(opts)

    branch
    |> Map.get("events", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.reduce(base_summaries, &apply_resource_event_summary(&1, &2, callbacks))
    |> Enum.sort_by(& &1["spacecraft_id"])
  end

  defp callbacks!(opts) do
    %{
      branch_event_spacecraft_id: Keyword.fetch!(opts, :branch_event_spacecraft_id),
      degraded_event_mode: Keyword.fetch!(opts, :degraded_event_mode),
      normalize_incompatible_activity_types:
        Keyword.fetch!(opts, :normalize_incompatible_activity_types)
    }
  end

  defp apply_resource_event_summary(
         %{"type" => "degraded_spacecraft"} = event,
         summaries,
         callbacks
       ) do
    spacecraft_id = callbacks.branch_event_spacecraft_id.(event)

    if spacecraft_id in [nil, ""] do
      summaries
    else
      incompatible_types =
        (Map.get(event, "incompatible_activity_types") ||
           Map.get(event, "suppressed_activity_types") || ["observe"])
        |> callbacks.normalize_incompatible_activity_types.()

      spacecraft_unavailable? =
        event["spacecraft_available"] == false or
          event
          |> Map.get("derivation_reasons", [])
          |> Enum.any?(
            &(&1 in [
                "spacecraft_available_feedback_false",
                "spacecraft_availability_feedback_false"
              ])
          )

      overlay =
        %{
          "spacecraft_id" => spacecraft_id,
          "mode" => callbacks.degraded_event_mode.(event),
          "degraded" => true,
          "spacecraft_available" => if(spacecraft_unavailable?, do: false),
          "payload_available" => not Enum.member?(incompatible_types, "observe"),
          "antenna_available" =>
            not Enum.any?(incompatible_types, &(&1 in ["downlink", "planned_contact"])),
          "assumptions" =>
            %{
              "model" => "strategy_branch_event_resource_overlay",
              "incompatible_activity_types" => incompatible_types,
              "derivation_reasons" => Map.get(event, "derivation_reasons", []),
              "feedback_source" => Map.get(event, "feedback_source")
            }
            |> compact_map(),
          "provenance" =>
            %{
              "source" => "strategy_branch_event",
              "event_type" => "degraded_spacecraft",
              "trust_boundary" => resource_event_trust_boundary(event)
            }
            |> compact_map()
        }

      upsert_resource_summary(summaries, overlay)
    end
  end

  defp apply_resource_event_summary(
         %{"type" => "resource_margin_pressure"} = event,
         summaries,
         callbacks
       ) do
    spacecraft_id = callbacks.branch_event_spacecraft_id.(event)
    field = event["resource_field"]
    value = field && Map.get(event, field)

    if spacecraft_id in [nil, ""] or
         field not in [
           "fuel_margin",
           "power_margin",
           "storage_margin",
           "downlink_margin",
           "thermal_margin_c"
         ] or
         not is_number(value) do
      summaries
    else
      overlay =
        %{
          "spacecraft_id" => spacecraft_id,
          field => value,
          "assumptions" =>
            %{
              "model" => "strategy_branch_event_resource_overlay",
              "resource_field" => field,
              "derivation_reasons" => Map.get(event, "derivation_reasons", []),
              "resource_id" => event["resource_id"],
              "planned_resource_id" => event["planned_resource_id"],
              "realized_resource_id" => event["realized_resource_id"],
              "resource_match_status" => event["resource_match_status"]
            }
            |> compact_map(),
          "provenance" =>
            %{
              "source" => "strategy_branch_event",
              "event_type" => "resource_margin_pressure",
              "trust_boundary" => resource_event_trust_boundary(event)
            }
            |> compact_map()
        }

      upsert_resource_summary(summaries, overlay)
    end
  end

  defp apply_resource_event_summary(
         %{"type" => "resource_availability_constraint"} = event,
         summaries,
         callbacks
       ) do
    spacecraft_id = callbacks.branch_event_spacecraft_id.(event)
    field = event["resource_field"]

    if spacecraft_id in [nil, ""] or
         field not in ["antenna_available", "payload_available", "spacecraft_available"] or
         event["available"] != false do
      summaries
    else
      overlay =
        %{
          "spacecraft_id" => spacecraft_id,
          field => false,
          "assumptions" =>
            %{
              "model" => "strategy_branch_event_resource_overlay",
              "resource_field" => field,
              "derivation_reasons" => Map.get(event, "derivation_reasons", []),
              "resource_id" => event["resource_id"],
              "planned_resource_id" => event["planned_resource_id"],
              "realized_resource_id" => event["realized_resource_id"],
              "resource_match_status" => event["resource_match_status"]
            }
            |> compact_map(),
          "provenance" =>
            %{
              "source" => "strategy_branch_event",
              "event_type" => "resource_availability_constraint",
              "trust_boundary" => resource_event_trust_boundary(event)
            }
            |> compact_map()
        }

      upsert_resource_summary(summaries, overlay)
    end
  end

  defp apply_resource_event_summary(_event, summaries, _callbacks), do: summaries

  defp resource_event_trust_boundary(%{"trust_boundary" => trust_boundary})
       when is_binary(trust_boundary) and trust_boundary != "",
       do: trust_boundary

  defp resource_event_trust_boundary(%{"provenance" => %{"trust_boundary" => trust_boundary}})
       when is_binary(trust_boundary) and trust_boundary != "",
       do: trust_boundary

  defp resource_event_trust_boundary(_event), do: nil

  defp upsert_resource_summary(summaries, overlay) do
    key = overlay["spacecraft_id"]

    {matched, rest} =
      Enum.split_with(summaries, fn summary -> summary["spacecraft_id"] == key end)

    base = List.first(matched, %{"spacecraft_id" => key})

    merged =
      base
      |> Map.merge(overlay)
      |> Map.put(
        "provenance",
        merge_resource_summary_provenance(base["provenance"], overlay["provenance"])
      )

    [merged | rest]
  end

  defp merge_resource_summary_provenance(base, overlay) do
    base =
      case base do
        %{} = provenance -> provenance
        _provenance -> %{}
      end

    overlay =
      case overlay do
        %{} = provenance -> provenance
        _provenance -> %{}
      end

    Map.merge(base, overlay)
    |> compact_map()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
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
