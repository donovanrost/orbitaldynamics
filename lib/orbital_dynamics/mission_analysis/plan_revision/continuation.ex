defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation do
  @moduledoc "Original-request identity and exact slices of already started activities. No abort or restart policy is inferred."
  alias OrbitalDynamics.MissionAnalysis.{Input, Request, ReferenceMission}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Commitments
  @placement ~w(request_id asset_id starts_at_s ends_at_s)

  def attach!(mission, study, requests) do
    records = study["continuations"] || %{}

    unless is_map(records) and map_size(records) <= 100,
      do: raise(ArgumentError, "bounded continuation records required")

    ids = MapSet.new(requests, & &1.id)
    assets = MapSet.new(mission["assets"], & &1["id"])

    parsed =
      Map.new(records, fn {id, row} ->
        Input.id!(id)

        unless MapSet.member?(ids, id),
          do: raise(ArgumentError, "continuation references unknown current request")

        S.fields!(row, ~w(request baseline_activity source_snapshot_id kind), "continuation")

        unless is_binary(row["source_snapshot_id"]) and
                 Regex.match?(
                   ~r/\Amission_plan_snapshot:[0-9a-f]{64}\z/,
                   row["source_snapshot_id"]
                 ),
               do: raise(ArgumentError, "continuation requires original source snapshot identity")

        [placement] = Commitments.normalize!([row["baseline_activity"]])

        unless placement["request_id"] == id and MapSet.member?(assets, placement["asset_id"]),
          do: raise(ArgumentError, "continuation asset/request mismatch")

        original = ReferenceMission.request!(row["request"])

        kind =
          case row["kind"] do
            "remaining" -> :remaining
            "execution_prefix" -> :execution_prefix
            _ -> raise ArgumentError, "invalid continuation segment kind"
          end

        {id,
         %{
           request: original,
           starts_at_s: placement["starts_at_s"],
           ends_at_s: placement["ends_at_s"],
           asset_id: placement["asset_id"],
           kind: kind
         }}
      end)

    requests =
      Enum.map(requests, fn r ->
        if parsed[r.id], do: Request.with_segment!(r, parsed[r.id]), else: r
      end)

    for request <- requests, request.segment do
      valid =
        case request.segment.kind do
          :remaining -> request.starts_at_s == study["horizon"]["starts_at_s"]
          :execution_prefix -> request.ends_at_s == study["horizon"]["ends_at_s"]
        end

      unless valid,
        do:
          raise(
            ArgumentError,
            "activity segment must match its declared planning or execution boundary"
          )
    end

    joins =
      for r <- requests,
          r.segment != nil,
          initial = get_in(study, ["attitude", "assets", r.segment.asset_id, "initial"]),
          is_map(initial),
          initial["epoch_s"] == r.starts_at_s and r.segment.starts_at_s < r.starts_at_s,
          do: {r.segment.asset_id, r.id}

    unless length(Enum.uniq_by(joins, &elem(&1, 0))) == length(joins),
      do: raise(ArgumentError, "one initial continuation per asset required")

    {requests, Map.new(joins)}
  end

  def validate_source!(source) do
    records = source["study"]["continuations"] || %{}

    if records != %{} or get_in(source, ["execution", "last_update", "in_progress_request_ids"]) do
      requests = Enum.map(source["mission"]["requests"], &ReferenceMission.request!/1)
      {_, joins} = attach!(source["mission"], source["study"], requests)
      ids = get_in(source, ["execution", "last_update", "in_progress_request_ids"]) || []

      unless is_list(ids) and length(Enum.uniq(ids)) == length(ids) and
               Enum.sort(ids) == Enum.sort(Map.values(joins)),
             do:
               raise(
                 ArgumentError,
                 "continuations must bind the declared running IDs at the saved boundary"
               )
    end

    source
  end

  def active(report, t),
    do: Enum.filter(report["activities"], &(&1["starts_at_s"] < t and t < &1["ends_at_s"]))

  def records(source, snapshot, activities, kind) do
    requests = Map.new(source["mission"]["requests"], &{&1["id"], &1})

    Map.new(activities, fn a ->
      id = a["request_id"]

      row =
        get_in(source, ["study", "continuations", id]) ||
          %{
            "request" => requests[id],
            "baseline_activity" => Map.take(a, @placement),
            "source_snapshot_id" => snapshot["snapshot_id"]
          }

      {id, Map.put(row, "kind", kind)}
    end)
  end

  def slice(request, row, start, stop, kind) do
    original = row["request"]

    request
    |> Map.put("starts_at_s", start)
    |> Map.put("ends_at_s", stop)
    |> Map.put("duration_s", stop - start)
    |> Map.put("value", if(kind == "execution_prefix", do: 0, else: original["value"]))
    |> Map.put(
      "resource_costs",
      if(kind == "execution_prefix" and start == row["baseline_activity"]["starts_at_s"],
        do: original["resource_costs"],
        else: %{}
      )
    )
  end

  def original_request(source, request),
    do: get_in(source, ["study", "continuations", request["id"], "request"]) || request

  def original_placement(source, activity),
    do:
      get_in(source, ["study", "continuations", activity["request_id"], "baseline_activity"]) ||
        Map.take(activity, @placement)
end
