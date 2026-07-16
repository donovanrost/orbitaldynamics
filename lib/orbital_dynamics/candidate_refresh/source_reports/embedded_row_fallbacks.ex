defmodule OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks do
  @moduledoc false

  def from_rows(_path, _source, [], _artifact, _report_fun), do: nil

  def from_rows(path, source, rows, artifact, report_fun) do
    report_fun.(path, source, rows, artifact)
  end

  def from_embedded_rows(path, source, rows, artifact, report_fun) do
    from_rows(path, source, rows, artifact, report_fun)
  end

  def report_from_embedded_rows(path, source, rows, artifact, report_fun) do
    from_rows(path, source, rows, artifact, report_fun)
  end
end
