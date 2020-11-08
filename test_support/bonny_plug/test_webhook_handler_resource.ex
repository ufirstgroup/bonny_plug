defmodule BonnyPlug.TestWebhookHandlerResource do
  use BonnyPlug.WebhookHandler,
      group: "apps",
      plural: "deployments",
      api_versions: ["v1"]

  @spec validating_webhook(BonnyPlug.AdmissionReview.t()) :: BonnyPlug.AdmissionReview.t()
  @impl true
  def validating_webhook(admission_review)  do
    Map.update!(admission_review, :response, &Map.put(&1, "allowed", false))
  end
end
