defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot do
  @moduledoc "Versioned content-bound analysis inputs/report; content identity is not authentication or approval."
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.Schema.JsonSafety
  @format "mission_analysis_plan_snapshot.v1"
  @canonicalization "sorted_json_keys.v1"
  @max_bytes 64 * 1024 * 1024

  def new!(inputs, report, parent \\ :null) do
    inputs = JsonSafety.normalize_input!(inputs, "snapshot inputs")

    payload = %{
      "format" => @format,
      "canonicalization" => @canonicalization,
      "inputs" => inputs,
      "report" => report,
      "parent_snapshot_id" => parent
    }

    encoded = :json.encode(payload)

    if IO.iodata_length(encoded) > @max_bytes - 1024,
      do: raise(ArgumentError, "snapshot exceeds 64 MiB")

    decoded = encoded |> IO.iodata_to_binary() |> :json.decode()

    unless decoded === payload,
      do: raise(ArgumentError, "snapshot must contain only exact JSON values")

    validate_payload!(payload)
    hash = digest(payload)

    %{
      "snapshot_id" => "mission_plan_snapshot:#{hash}",
      "content_sha256" => hash,
      "payload" => payload
    }
  end

  def verify!(snapshot) do
    unless is_map(snapshot) and
             Enum.sort(Map.keys(snapshot)) == ~w(content_sha256 payload snapshot_id),
           do: raise(ArgumentError, "invalid snapshot envelope")

    if IO.iodata_length(:json.encode(snapshot)) > @max_bytes,
      do: raise(ArgumentError, "snapshot exceeds 64 MiB")

    payload = snapshot["payload"]
    validate_payload!(payload)
    hash = digest(payload)

    unless snapshot["content_sha256"] == hash and
             snapshot["snapshot_id"] == "mission_plan_snapshot:#{hash}",
           do: raise(ArgumentError, "snapshot content identity mismatch")

    snapshot
  end

  def read!(path) do
    if File.stat!(path).size > @max_bytes, do: raise(ArgumentError, "snapshot exceeds 64 MiB")
    bytes = File.read!(path)
    if byte_size(bytes) > @max_bytes, do: raise(ArgumentError, "snapshot exceeds 64 MiB")

    decoder = %{
      object_start: fn _ -> %{} end,
      object_push: fn k, v, m ->
        if Map.has_key?(m, k), do: raise(ArgumentError, "duplicate snapshot JSON key")
        Map.put(m, k, v)
      end,
      object_finish: fn object, old -> {object, old} end
    }

    case :json.decode(bytes, :root, decoder) do
      {%{} = snapshot, :root, <<>>} -> verify!(snapshot)
      _ -> raise ArgumentError, "expected one snapshot object"
    end
  end

  def digest(value),
    do:
      value |> canonical_json() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

  defp canonical_json(%{} = m) do
    [
      ?{,
      m
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {k, v} -> [:json.encode(k), ?:, canonical_json(v)] end)
      |> Enum.intersperse(?,),
      ?}
    ]
  end

  defp canonical_json(list) when is_list(list),
    do: [?[, Enum.map(list, &canonical_json/1) |> Enum.intersperse(?,), ?]]

  defp canonical_json(v), do: :json.encode(v)

  def validate_report!(r) do
    unless is_map(r) and r["format"] == "mission_analysis.v1" and
             r["time_system"]["epoch_origin"] == "J2000" and
             r["time_system"]["scale"] in ~w(utc tai tdb) and
             is_list(r["activities"]) and length(r["activities"]) <= 100 and
             is_list(r["requests"]) and length(r["requests"]) <= 100,
           do: raise(ArgumentError, "invalid mission analysis report in snapshot/diff")

    ids = Enum.map(r["requests"], &Input.id!(&1["request_id"]))

    unless length(Enum.uniq(ids)) == length(ids),
      do: raise(ArgumentError, "duplicate request identity")

    Enum.each(r["requests"], fn request ->
      Input.number!(request["value"], "request value", 0, 1.0e15)

      unless request["status"] in ["scheduled", "unfulfilled"] and is_list(request["reasons"]) and
               Enum.all?(request["reasons"], &is_binary/1),
             do: raise(ArgumentError, "invalid request status/reasons")
    end)

    activity_ids =
      Enum.map(r["activities"], fn a ->
        Input.id!(a["asset_id"])
        Input.id!(a["request_id"])
        start = Input.number!(a["starts_at_s"], "activity start", -1.0e12, 1.0e12)
        stop = Input.number!(a["ends_at_s"], "activity end", -1.0e12, 1.0e12)
        Input.number!(a["value"], "activity value", 0, 1.0e15)

        unless stop > start and a["request_id"] in ids,
          do: raise(ArgumentError, "invalid activity identity or interval")

        a["request_id"]
      end)

    unless length(Enum.uniq(activity_ids)) == length(activity_ids),
      do: raise(ArgumentError, "duplicate scheduled request identity")

    for request <- r["requests"] do
      unless request["request_id"] in activity_ids == (request["status"] == "scheduled"),
        do: raise(ArgumentError, "request status does not match selected activities")
    end

    r
  end

  defp validate_payload!(p) do
    unless is_map(p) and
             Enum.sort(Map.keys(p)) ==
               ~w(canonicalization format inputs parent_snapshot_id report) and
             p["format"] == @format and p["canonicalization"] == @canonicalization and
             is_map(p["inputs"]),
           do: raise(ArgumentError, "invalid snapshot payload/version")

    parent = p["parent_snapshot_id"]

    unless parent == :null or
             (is_binary(parent) and
                Regex.match?(~r/\Amission_plan_snapshot:[0-9a-f]{64}\z/, parent)),
           do: raise(ArgumentError, "invalid parent snapshot identity")

    JsonSafety.normalize_input!(p["inputs"], "snapshot inputs")
    validate_report!(p["report"])
  end
end
