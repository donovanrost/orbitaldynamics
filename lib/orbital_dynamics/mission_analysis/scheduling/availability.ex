defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Availability do
  @moduledoc "Bounded interval exclusions for activity eligibility. Spacecraft state and idle resource evolution remain modeled."
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  def validate!(nil), do: nil

  def validate!(c) do
    S.fields!(c, ~w(time_scale outages), "availability")

    unless c["time_scale"] in ~w(utc tai tdb) and is_list(c["outages"]) and
             length(c["outages"]) <= 128,
           do: raise(ArgumentError, "availability requires a time scale and at most 128 outages")

    outages =
      Enum.map(c["outages"], fn o ->
        S.fields!(o, ~w(id asset_id starts_at_s ends_at_s scope), "availability outage")
        Input.id!(o["id"])
        Input.id!(o["asset_id"])
        a = Input.number!(o["starts_at_s"], "outage start", -1.0e12, 1.0e12)
        b = Input.number!(o["ends_at_s"], "outage end", -1.0e12, 1.0e12)
        unless b > a, do: raise(ArgumentError, "outage duration must be positive")
        scope = o["scope"]
        unless is_map(scope), do: raise(ArgumentError, "outage scope required")

        case scope["kind"] do
          "all_activities" ->
            S.fields!(scope, ~w(kind), "outage scope")

          kind when kind in ~w(activity_types modes) ->
            S.fields!(scope, ~w(kind ids), "outage scope")

            unless is_list(scope["ids"]) and length(scope["ids"]) in 1..32 and
                     length(Enum.uniq(scope["ids"])) == length(scope["ids"]),
                   do: raise(ArgumentError, "outage scope IDs must be bounded and unique")

            Enum.each(scope["ids"], &Input.id!/1)

          _ ->
            raise ArgumentError, "unknown outage scope"
        end

        o
      end)

    unless length(Enum.uniq_by(outages, & &1["id"])) == length(outages),
      do: raise(ArgumentError, "outage IDs must be unique")

    %{c | "outages" => Enum.sort_by(outages, &{&1["starts_at_s"], &1["asset_id"], &1["id"]})}
  end

  def apply(reports, nil, _, _, _), do: reports

  def apply(reports, c, assets, requests, attitude) do
    scale = if requests == [], do: attitude.horizon.start.scale, else: hd(requests).time_scale

    unless c["time_scale"] == Atom.to_string(scale),
      do: raise(ArgumentError, "availability time scale differs from mission")

    asset_ids = MapSet.new(assets, & &1.id)

    for o <- c["outages"] do
      unless MapSet.member?(asset_ids, o["asset_id"]),
        do: raise(ArgumentError, "outage names an unknown asset")

      if o["scope"]["kind"] == "modes" do
        modes =
          get_in(
            (attitude && attitude.path_constraints && attitude.path_constraints.assets) || %{},
            [o["asset_id"], :modes]
          ) || %{}

        unless Enum.all?(o["scope"]["ids"], &Map.has_key?(modes, &1)),
          do: raise(ArgumentError, "outage names an unknown activity mode")
      end
    end

    rm = Map.new(requests, &{&1.id, &1})

    Enum.map(reports, fn report ->
      id = report["asset_id"]
      request = rm[report["request_id"]]

      mode =
        if attitude && attitude.path_constraints,
          do: get_in(attitude.path_constraints.assets, [id, :activity_modes, request.id]),
          else: nil

      outages = Enum.filter(c["outages"], &matches?(&1, id, request.activity_type, mode))
      original = report["opportunities"]

      clipped =
        Enum.flat_map(original, fn o ->
          applicable = Enum.filter(outages, &overlaps?(&1, o))

          if applicable == [] do
            [o]
          else
            parts =
              Enum.reduce(applicable, [{o["starts_at_s"], o["ends_at_s"]}], fn outage, parts ->
                Enum.flat_map(parts, fn {a, b} ->
                  subtract(a, b, outage["starts_at_s"], outage["ends_at_s"])
                end)
              end)

            parts
            |> Enum.filter(fn {a, b} -> b - a >= request.duration_s end)
            |> Enum.with_index(1)
            |> Enum.map(fn {{a, b}, index} ->
              o
              |> Map.put("id", o["id"] <> ":availability:#{index}")
              |> Map.put("starts_at_s", a)
              |> Map.put("ends_at_s", b)
              |> Map.put("availability_evidence", %{
                "source_opportunity_id" => o["id"],
                "excluded_outage_ids" => Enum.map(applicable, & &1["id"]),
                "sample_count_scope" => "original_physical_opportunity",
                "rule" => "whole_activity_outside_half_open_outages"
              })
            end)
          end
        end)

      if clipped == original,
        do: report,
        else:
          report
          |> Map.put("source_opportunities", original)
          |> Map.put("opportunities", clipped)
          |> Map.put("availability_evidence", %{
            "outage_ids" => Enum.map(outages, & &1["id"]),
            "source_opportunity_count" => length(original),
            "available_opportunity_count" => length(clipped)
          })
          |> then(fn r ->
            if clipped == [] and original != [],
              do: Map.put(r, "status", "no_available_opportunity"),
              else: r
          end)
    end)
  end

  def matches?(o, asset, type, mode) do
    o["asset_id"] == asset and
      case o["scope"]["kind"] do
        "all_activities" -> true
        "activity_types" -> type in o["scope"]["ids"]
        "modes" -> mode in o["scope"]["ids"]
      end
  end

  def overlaps?(a, b), do: a["starts_at_s"] < b["ends_at_s"] and a["ends_at_s"] > b["starts_at_s"]

  defp subtract(a, b, x, y) do
    if x >= b or y <= a,
      do: [{a, b}],
      else: Enum.filter([{a, min(b, x)}, {max(a, y), b}], fn {s, e} -> e > s end)
  end
end
