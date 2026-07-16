defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.ClassificationCounts.Classifications do
  @moduledoc false

  alias __MODULE__.ImportClassification

  @readiness_levels %{
    "importable" => "import_eligible",
    "review_only" => "operator_review",
    "analysis_only" => "analysis_only",
    "blocked" => "blocked"
  }

  @statuses %{
    "importable" => "passed",
    "review_only" => "review_required",
    "analysis_only" => "analysis_only",
    "blocked" => "blocked"
  }

  def readiness_level(report) do
    classification = import_classification(report)

    Map.get(@readiness_levels, classification, Map.get(report, "readiness_level"))
  end

  def status(report) do
    classification = import_classification(report)

    Map.get(@statuses, classification, Map.get(report, "status"))
  end

  def import_classification(report) do
    ImportClassification.value(report)
  end
end
