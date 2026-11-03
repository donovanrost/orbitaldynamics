defmodule OrbitalDynamics.Validation.EventSearch.ReferenceBundle do
  @moduledoc false
  @manifest_sha256 "0b5cee88a631c98f92946f79fdcf2c108f83cf0fb1809ce4f202de5570ea1013"
  @files ~w(EventReference.java cases.csv dependencies.lock generate.sh reference-output.json README.md OrekitTruthGenerator.java leo-fine.properties retain_grid.py leo-reference.json)
  def manifest_identity, do: @manifest_sha256

  def bundle_path,
    do: Application.app_dir(:orbital_dynamics, "priv/validation/event_search_orekit")

  def load!(directory \\ bundle_path()) do
    manifest = bounded_read!(Path.join(directory, "SHA256SUMS"), 8192)

    unless hash(manifest) == @manifest_sha256,
      do: raise(ArgumentError, "finite-Sun manifest digest mismatch")

    entries =
      for line <- String.split(manifest, "\n", trim: true) do
        [digest, file] = String.split(line, "  ", parts: 2)
        {file, digest}
      end

    unless Enum.sort(Enum.map(entries, &elem(&1, 0))) == Enum.sort(@files),
      do: raise(ArgumentError, "finite-Sun file inventory mismatch")

    Map.new(entries, fn {file, digest} ->
      bytes = bounded_read!(Path.join(directory, file), 2_000_000)

      unless hash(bytes) == digest,
        do: raise(ArgumentError, "finite-Sun content mismatch: #{file}")

      {file, bytes}
    end)
  end

  defp bounded_read!(path, limit) do
    File.open!(path, [:read, :binary], fn io ->
      bytes = IO.binread(io, limit + 1)

      unless is_binary(bytes) and byte_size(bytes) <= limit,
        do: raise(ArgumentError, "invalid finite-Sun reference file")

      bytes
    end)
  end

  defp hash(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
