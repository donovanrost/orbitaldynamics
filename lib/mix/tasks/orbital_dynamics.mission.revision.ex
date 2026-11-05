defmodule Mix.Tasks.OrbitalDynamics.Mission.Revision do
  use Mix.Task
  @shortdoc "Save a baseline or produce a mission plan revision and review diff"
  @moduledoc """
      mix orbital_dynamics.mission.revision baseline --study PATH --output-dir DIRECTORY
      mix orbital_dynamics.mission.revision revise --baseline PATH --changes PATH --output-dir DIRECTORY
      mix orbital_dynamics.mission.revision advance --baseline PATH --update PATH --output-dir DIRECTORY

  Baselines store inputs and full planning evidence with a content identity.
  A change adds requests and declares whole-horizon service unavailability;
  commitments are selected from baseline activities. Conflicts produce review
  artifacts and no revised snapshot. Advance uses explicit common-epoch state and
  execution declarations. No command execution.
  """
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Snapshot, Files, Report, Advance}
  @impl true
  def run([action | args]) when action in ["baseline", "revise", "advance"] do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          study: [:string, :keep],
          baseline: [:string, :keep],
          changes: [:string, :keep],
          update: [:string, :keep],
          output_dir: [:string, :keep]
        ]
      )

    required =
      case action do
        "baseline" -> [:output_dir, :study]
        "revise" -> [:baseline, :changes, :output_dir]
        "advance" -> [:baseline, :output_dir, :update]
      end

    unless rest == [] and invalid == [] and Enum.sort(Keyword.keys(opts)) == required,
      do:
        Mix.raise(
          "required: baseline --study PATH --output-dir DIRECTORY; or revise --baseline PATH --changes PATH --output-dir DIRECTORY; or advance --baseline PATH --update PATH --output-dir DIRECTORY"
        )

    case action do
      "baseline" ->
        study_path = Path.expand(opts[:study])
        study = ReferenceMission.load!(study_path)
        mission_path = Path.expand(study["mission_manifest"], Path.dirname(study_path))
        mission = ReferenceMission.load!(mission_path)

        dir =
          Files.directory!(opts[:output_dir], ~w(baseline_snapshot.json README.md), [
            study_path,
            mission_path
          ])

        Mix.Task.run("app.start")
        snapshot = Reference.create!(mission, study)
        File.mkdir_p!(dir)

        File.write!(Path.join(dir, "baseline_snapshot.json"), [:json.encode(snapshot), "\n"], [
          :exclusive
        ])

        File.write!(
          Path.join(dir, "README.md"),
          "# Baseline plan\n\nSnapshot: `#{snapshot["snapshot_id"]}`\n\nSupported configured planning evidence; analysis only. Full inputs and report are in baseline_snapshot.json.\n"
        )

        Mix.shell().info("Baseline saved: #{Path.join(dir, "baseline_snapshot.json")}")

      action when action in ["revise", "advance"] ->
        baseline_path = Path.expand(opts[:baseline])

        change_path =
          Path.expand(if(action == "advance", do: opts[:update], else: opts[:changes]))

        snapshot = Snapshot.read!(baseline_path)
        change = ReferenceMission.load!(change_path)

        names =
          ~w(revision.json revised_snapshot.json failed_candidate.json.gz execution_checkpoint.json README.md)

        dir = Files.directory!(opts[:output_dir], names, [baseline_path, change_path])

        # A distinct revision directory avoids retaining a stale successful snapshot after failure.
        if Enum.any?(names, &File.exists?(Path.join(dir, &1))),
          do: Mix.raise("revision outputs already exist; choose a fresh output directory")

        Mix.Task.run("app.start")

        result =
          if(action == "advance",
            do: accept_and_plan(snapshot, change, dir),
            else: Reference.revise!(snapshot, change)
          )

        File.mkdir_p!(dir)

        File.write!(Path.join(dir, "revision.json"), [:json.encode(result.review), "\n"], [
          :exclusive
        ])

        File.write!(Path.join(dir, "README.md"), Report.markdown(result.review), [:exclusive])

        if result.revised_snapshot != :null,
          do:
            File.write!(
              Path.join(dir, "revised_snapshot.json"),
              [
                :json.encode(result.revised_snapshot),
                "\n"
              ],
              [:exclusive]
            )

        if result.revised_snapshot == :null and result.candidate_report != :null,
          do:
            File.write!(
              Path.join(dir, "failed_candidate.json.gz"),
              :zlib.gzip(IO.iodata_to_binary(:json.encode(result.candidate_report))),
              [:exclusive]
            )

        Mix.shell().info("Revision #{result.review["status"]}: #{Path.join(dir, "README.md")}")

        if result.review["status"] != "ready_for_review",
          do:
            Mix.raise(
              "Revision #{result.review["status"]}; no revised snapshot produced; inspect #{Path.join(dir, "README.md")}"
            )
    end
  end

  def run(_), do: Mix.raise("expected baseline, revise or advance subcommand")

  defp accept_and_plan(snapshot, update, dir) do
    accepted = Advance.accept!(snapshot, update)

    if accepted.execution_checkpoint == :null do
      accepted
    else
      File.mkdir_p!(dir)

      File.write!(
        Path.join(dir, "execution_checkpoint.json"),
        [:json.encode(accepted.execution_checkpoint), "\n"],
        [:exclusive]
      )

      Advance.plan!(snapshot, accepted.execution_checkpoint)
    end
  end
end
