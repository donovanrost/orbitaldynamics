defmodule OrbitalDynamics.CadenceImport.ProposedContactImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization

  def build(contact, opts, callbacks) do
    contact = JsonNormalization.stringify_keys(contact)
    source_id = Keyword.get(opts, :source_artifact_id, contact["id"])

    Keyword.fetch!(callbacks, :build_manifest).(
      [Keyword.fetch!(callbacks, :row).(contact, 1)],
      %{
        "source" => "OrbitalDynamics.CadenceImport.from_proposed_contact",
        "source_artifact_type" => "proposed_contact.v1",
        "source_artifact_id" => source_id
      },
      %{
        "source_artifact_type" => "proposed_contact.v1",
        "source_artifact_id" => source_id || "proposed_contact",
        "row_source" => "proposed_contact",
        "deterministic_ordering" => "single proposed contact"
      }
    )
  end
end
