defmodule Mix.Tasks.OrbitalDynamics.Events.Verify do
  use Mix.Task
  @shortdoc "Compare shared event search and solar generation with frozen independent references"
  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args, strict: [output_dir: :string, group: :string])

    unless rest == [] and invalid == [] and Keyword.has_key?(opts, :output_dir) and
             length(Keyword.keys(opts)) == length(Enum.uniq(Keyword.keys(opts))),
           do: Mix.raise("required: --output-dir DIRECTORY [--group all|leo|finite-sun]")

    group =
      case Keyword.get(opts, :group, "all") do
        "all" -> :all
        "leo" -> :leo
        "finite-sun" -> :finite_sun
        _ -> Mix.raise("--group must be all, leo or finite-sun")
      end

    Mix.Task.run("app.start")
    directory = canonical_path(Path.expand(opts[:output_dir]))
    # Inputs are frozen evidence; report destinations cannot overwrite them.
    for bundle <- [
          OrbitalDynamics.Validation.EventSearch.FiniteSunCheck.bundle_path(),
          OrbitalDynamics.Validation.ExternalTruth.OrekitLeoCase.bundle_path()
        ] do
      if directory == canonical_path(Path.expand(bundle)) or
           String.starts_with?(directory, canonical_path(Path.expand(bundle)) <> "/"),
         do: Mix.raise("output directory must not be a reference bundle")
    end

    for name <- ["report.json", "README.md"] do
      case File.lstat(Path.join(directory, name)) do
        {:ok, %{type: :symlink}} -> Mix.raise("output files must not be symlinks")
        _ -> :ok
      end
    end

    {:ok, report} = OrbitalDynamics.Validation.EventSearchCheck.verify(group)
    File.mkdir_p!(directory)
    File.write!(Path.join(directory, "report.json"), [:json.encode(report), "\n"])

    File.write!(
      Path.join(directory, "README.md"),
      OrbitalDynamics.Validation.EventSearchCheck.markdown(report)
    )

    Mix.shell().info(
      "Independent event-reference checks: #{report["status"]}. #{Path.join(directory, "README.md")}"
    )

    if report["status"] != "pass",
      do: Mix.raise("independent event-reference comparison failed; inspect report.json")
  end

  defp canonical_path(path, links \\ 0)

  defp canonical_path(_, links) when links > 64,
    do: Mix.raise("output path contains a symlink cycle")

  defp canonical_path("/", _), do: "/"

  defp canonical_path(path, links) do
    parent = canonical_path(Path.dirname(path), links)
    resolved = Path.join(parent, Path.basename(path))

    case File.read_link(resolved) do
      {:ok, target} -> canonical_path(Path.expand(target, parent), links + 1)
      {:error, _} -> resolved
    end
  end
end
