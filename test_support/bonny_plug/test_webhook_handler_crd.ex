defmodule BonnyPlug.TestWebhookHandlerCRD do
  use BonnyPlug.WebhookHandler, crd: "test_support/crds/test_crd.yaml"

  @spec validating_webhook(BonnyPlug.AdmissionReview.t()) :: BonnyPlug.AdmissionReview.t()
  @impl true
  def validating_webhook(admission_review)  do
    Map.update!(admission_review, :response, &Map.put(&1, "allowed", false))
  end
end
