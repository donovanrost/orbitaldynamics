defmodule Mix.Tasks.OrbitalDynamics.Mission.Validate do
  use Mix.Task
  @shortdoc "Independently check saved plan structure and constant-power accounting offline"
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Reader, Checker, Operations, Report}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Files
  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          snapshot: [:string, :keep],
          operations_dir: [:string, :keep],
          output_dir: [:string, :keep]
        ]
      )

    keys = Enum.sort(Keyword.keys(opts))

    unless rest == [] and invalid == [] and
             keys in [[:output_dir, :snapshot], [:operations_dir, :output_dir]],
           do:
             Mix.raise(
               "required: --snapshot PATH or --operations-dir DIRECTORY, plus --output-dir DIRECTORY"
             )

    source =
      if opts[:snapshot],
        do: Path.expand(opts[:snapshot]),
        else: Path.join(Path.expand(opts[:operations_dir]), "operations.json")

    dir = Files.directory!(opts[:output_dir], ~w(validation.json README.md), [source])

    result =
      case Reader.read(source) do
        {:ok, value} ->
          if opts[:snapshot],
            do: Checker.snapshot(value, source),
            else:
              Operations.validate(value, fn name ->
                Reader.read(Path.join(Path.dirname(source), name))
              end)

        {:error, message} ->
          %{
            "format" => "independent_plan_validation.v1",
            "status" => "failed",
            "issues" => [Checker.issue("invalid_input_file", source, message)]
          }
      end

    result = Map.put(result, "source", source)
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "validation.json"), [:json.encode(result), "\n"], [:exclusive])
    File.write!(Path.join(dir, "README.md"), Report.markdown(result), [:exclusive])
    Mix.shell().info("Independent validation #{result["status"]}: #{Path.join(dir, "README.md")}")

    if result["status"] != "passed",
      do:
        Mix.raise(
          "independent validation #{result["status"]}; inspect #{Path.join(dir, "README.md")}"
        )
  end
end
