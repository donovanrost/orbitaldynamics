defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.ExecutionCheckpoint do
  @moduledoc "Immutable, source-bound declared execution state. Contains no claim that a replacement plan exists."
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Snapshot, Advance}
  @max_bytes 8 * 1024 * 1024

  def new!(parent, update, inputs) do
    payload = %{
      "format" => "mission_execution_checkpoint.v1",
      "canonicalization" => "sorted_json_keys.v1",
      "parent_snapshot_id" => parent["snapshot_id"],
      "state_update" => update,
      "inputs" => inputs
    }

    payload = OrbitalDynamics.Schema.JsonSafety.normalize_input!(payload, "execution checkpoint")
    hash = Snapshot.digest(payload)

    checkpoint = %{
      "checkpoint_id" => "mission_execution_checkpoint:" <> hash,
      "content_sha256" => hash,
      "payload" => payload
    }

    identity!(checkpoint)
  end

  def identity!(c) do
    unless is_map(c) and Enum.sort(Map.keys(c)) == ~w(checkpoint_id content_sha256 payload),
      do: raise(ArgumentError, "invalid execution checkpoint envelope")

    bytes = :json.encode(c)

    unless IO.iodata_length(bytes) <= @max_bytes and
             :json.decode(IO.iodata_to_binary(bytes)) === c,
           do: raise(ArgumentError, "execution checkpoint requires exact JSON within 8 MiB")

    p = c["payload"]

    unless is_map(p) and
             Enum.sort(Map.keys(p)) ==
               ~w(canonicalization format inputs parent_snapshot_id state_update) and
             p["format"] == "mission_execution_checkpoint.v1" and
             p["canonicalization"] == "sorted_json_keys.v1" and is_map(p["inputs"]) and
             is_map(p["state_update"]),
           do: raise(ArgumentError, "invalid execution checkpoint payload")

    hash = Snapshot.digest(p)

    unless c["content_sha256"] == hash and
             c["checkpoint_id"] == "mission_execution_checkpoint:" <> hash,
           do: raise(ArgumentError, "execution checkpoint content identity mismatch")

    c
  end

  @doc "Checks hashes and reconstructs accepted state from the supplied parent; never invokes planning or execution replay."
  def validate!(c, parent) do
    identity!(c)

    unless c["payload"]["parent_snapshot_id"] == parent["snapshot_id"],
      do: raise(ArgumentError, "execution checkpoint belongs to a different parent plan")

    accepted = Advance.accept!(parent, c["payload"]["state_update"])

    unless accepted.execution_checkpoint === c,
      do: raise(ArgumentError, "execution checkpoint differs from validated parent-derived state")

    accepted
  end

  def verify!(c, parent),
    do:
      (
        validate!(c, parent)
        c
      )

  def read!(path) do
    if File.stat!(path).size > @max_bytes,
      do: raise(ArgumentError, "execution checkpoint exceeds 8 MiB")

    bytes = File.read!(path)

    if byte_size(bytes) > @max_bytes,
      do: raise(ArgumentError, "execution checkpoint exceeds 8 MiB")

    decoder = %{
      object_start: fn _ -> %{} end,
      object_push: fn k, v, m ->
        if Map.has_key?(m, k), do: raise(ArgumentError, "duplicate execution checkpoint JSON key")
        Map.put(m, k, v)
      end,
      object_finish: fn x, old -> {x, old} end
    }

    case :json.decode(bytes, :root, decoder) do
      {%{} = c, :root, <<>>} -> identity!(c)
      _ -> raise(ArgumentError, "expected one execution checkpoint object")
    end
  end
end
