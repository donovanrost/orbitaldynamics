defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.Files do
  @moduledoc false
  def directory!(directory, names, inputs) do
    directory = canonical(Path.expand(directory))
    inputs = Enum.map(inputs, &canonical(Path.expand(&1)))

    for name <- names do
      path = Path.join(directory, name)
      if path in inputs, do: Mix.raise("revision output must not overwrite an input")

      if File.exists?(path),
        do: Mix.raise("revision outputs already exist; choose a fresh output directory")

      case File.lstat(path) do
        {:ok, %{type: :symlink}} -> Mix.raise("revision output files must not be symlinks")
        _ -> :ok
      end
    end

    directory
  end

  defp canonical(path, n \\ 0)
  defp canonical(_, n) when n > 64, do: Mix.raise("revision path contains a symlink cycle")
  defp canonical("/", _), do: "/"

  defp canonical(path, n) do
    parent = canonical(Path.dirname(path), n)
    result = Path.join(parent, Path.basename(path))

    case File.read_link(result) do
      {:ok, target} -> canonical(Path.expand(target, parent), n + 1)
      _ -> result
    end
  end
end
