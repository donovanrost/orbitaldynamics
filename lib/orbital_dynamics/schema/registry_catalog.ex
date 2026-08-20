defmodule OrbitalDynamics.Schema.RegistryCatalog do
  @moduledoc false

  @contracts OrbitalDynamics.Schema.PlannedActivityRegistryContracts.contracts()
             |> Map.merge(OrbitalDynamics.Schema.ValidationRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.CampaignRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.CandidateRefreshRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.AcceptedStateRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.ValidationAcceptanceRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.ValidationPolicyRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.LintRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.StudyResultRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.OptimizationRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.TimelineTransitionRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.TimelinePreservationRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.TimelineActivityStateRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.TimelineDiffRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.TimelineIntegrityRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.TimelinePublicationRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.OperationalTimelineRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ObjectiveAnalysisRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.StrategyManeuverRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.ExecutionReproducibilityRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.ApprovalPolicyRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.OperatorReviewRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.PlanChangeRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.TimelineFeedbackStateRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.RealizedStateRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ResourceProjectionRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ResourceFilterRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ContactFilterRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ResourceSummaryRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ResourceStateTraceRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ModelCapabilityRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.QualityGateRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.OperationalQualityGateRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.OperationalReadinessRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.CadenceImportRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.ProviderCounterofferRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.StationReservationHoldRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.StationReservationRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.StationCalendarRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ContactContentionRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ActivityTemplateRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ProposedContactRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ContactIntentRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.CommandWindowRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.LinkCapacityRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.RelayDataPathRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationReportRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationSummaryRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationReservationConflictRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationStationPressureRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationCapacityPackRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationProviderReservationRegistryContracts.contracts()
             )

  def contracts, do: @contracts
end
