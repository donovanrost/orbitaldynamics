defmodule Mix.Tasks.OrbitalDynamics.Events.Demo do
  use Mix.Task
  @shortdoc "Run the bounded orbital-event catalog against a synthetic analytic reference orbit"
  def run(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [output_dir: :string])

    unless rest == [] and invalid == [] and Keyword.keys(opts) == [:output_dir],
      do: Mix.raise("required: --output-dir DIRECTORY")

    Mix.Task.run("app.start")
    report = OrbitalDynamics.EventSearch.Reference.run!()
    catalog = OrbitalDynamics.EventSearch.Catalog.describe()
    directory = Path.expand(opts[:output_dir])
    File.mkdir_p!(directory)
    File.write!(Path.join(directory, "report.json"), [:json.encode(report), "\n"])
    File.write!(Path.join(directory, "catalog.json"), [:json.encode(catalog), "\n"])

    rows =
      Enum.map(report["results"], fn r ->
        "| #{r["function"]["id"]} | #{r["status"]} | #{length(r["events"])} | #{length(r["condition_windows"])} | #{length(r["uncovered_intervals"])} |"
      end)

    File.write!(
      Path.join(directory, "README.md"),
      "# Orbital-event reference\n\nStatus: #{report["status"]}.\n\n" <>
        Enum.join(
          [
            "| Function | Search status | Points/candidates | Estimated windows | Unresolved intervals |",
            "| --- | --- | --- | --- | --- |"
          ] ++ rows,
          "\n"
        ) <>
        "\n\nSynthetic geometry only. Precision is relative to the supplied state/function model. Stationary near-zero candidates do not prove a crossing; window edges inherit event brackets. See report.json for all assumptions and residuals.\n"
    )

    Mix.shell().info(
      "#{length(report["results"])} event functions: #{report["status"]}. #{Path.join(directory, "README.md")}"
    )
  end
end
