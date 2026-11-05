defmodule Mix.Tasks.OrbitalDynamics.Mission.Checkpoint do
  use Mix.Task
  @shortdoc "Accept declared execution independently, or plan/retry from a frozen checkpoint"
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission, as: M

  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{
    Advance,
    ExecutionCheckpoint,
    Snapshot,
    Files,
    Report
  }

  @impl true
  def run([action | args]) when action in ~w(accept plan) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          baseline: [:string, :keep],
          update: [:string, :keep],
          checkpoint: [:string, :keep],
          attempt: [:string, :keep],
          output_dir: [:string, :keep]
        ]
      )

    required =
      if action == "accept",
        do: [:baseline, :output_dir, :update],
        else: [:attempt, :baseline, :checkpoint, :output_dir]

    unless rest == [] and invalid == [] and Enum.sort(Keyword.keys(opts)) == required,
      do:
        Mix.raise(
          "required: accept --baseline PATH --update PATH --output-dir DIRECTORY; or plan --baseline PATH --checkpoint PATH --attempt PATH --output-dir DIRECTORY"
        )

    names =
      ~w(execution_checkpoint.json acceptance.json revision.json revised_snapshot.json failed_candidate.json.gz README.md)

    inputs =
      Enum.filter(
        [opts[:baseline], opts[:update], opts[:checkpoint], opts[:attempt]],
        &is_binary/1
      )

    dir = Files.directory!(opts[:output_dir], names, inputs)
    parent = Snapshot.read!(opts[:baseline])
    Mix.Task.run("app.start")
    File.mkdir_p!(dir)

    if action == "accept" do
      result = Advance.accept!(parent, M.load!(opts[:update]))
      write(dir, "acceptance.json", result.review)

      if result.execution_checkpoint == :null do
        File.write!(
          Path.join(dir, "README.md"),
          "# Execution state rejected\n\n#{result.review["status"]}; no execution checkpoint or replacement plan accepted.\n",
          [:exclusive]
        )

        Mix.raise("Execution state #{result.review["status"]}; no checkpoint accepted")
      end

      write(dir, "execution_checkpoint.json", result.execution_checkpoint)

      File.write!(
        Path.join(dir, "README.md"),
        "# Execution checkpoint accepted\n\nCheckpoint: `#{result.execution_checkpoint["checkpoint_id"]}`. Epoch: #{result.execution_checkpoint["payload"]["state_update"]["as_of_s"]}.\n\nValidated declared state only; no replacement plan has been produced or accepted.\n",
        [:exclusive]
      )

      Mix.shell().info(
        "Execution checkpoint saved: #{Path.join(dir, "execution_checkpoint.json")}"
      )
    else
      cp = ExecutionCheckpoint.read!(opts[:checkpoint])
      result = Advance.plan!(parent, cp, M.load!(opts[:attempt]))
      write(dir, "revision.json", result.review)
      File.write!(Path.join(dir, "README.md"), Report.markdown(result.review), [:exclusive])

      if result.revised_snapshot != :null,
        do: write(dir, "revised_snapshot.json", result.revised_snapshot)

      if result.revised_snapshot == :null and result.candidate_report != :null,
        do:
          File.write!(
            Path.join(dir, "failed_candidate.json.gz"),
            :zlib.gzip(IO.iodata_to_binary(:json.encode(result.candidate_report))),
            [:exclusive]
          )

      Mix.shell().info(
        "Checkpoint planning #{result.review["status"]}: #{Path.join(dir, "README.md")}"
      )

      if result.revised_snapshot == :null,
        do:
          Mix.raise(
            "Planning #{result.review["status"]}; execution checkpoint retained, no revised snapshot produced"
          )
    end
  end

  def run(_), do: Mix.raise("expected accept or plan subcommand")

  defp write(dir, name, value),
    do: File.write!(Path.join(dir, name), [:json.encode(value), "\n"], [:exclusive])
end
