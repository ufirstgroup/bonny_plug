defmodule BonnyPlug.AdmissionReview.Request do
  @moduledoc """
  Helper functions for admission review request handling. This module is imported when using `WebhookHandler`.
  """

  alias BonnyPlug.AdmissionReview

  @doc """
  Responds by allowing the operation

  ## Examples
    iex> admission_review = %BonnyPlug.AdmissionReview{request: %{}, response: %{}}
    ...> BonnyPlug.AdmissionReview.Request.allow(admission_review)
    %BonnyPlug.AdmissionReview{request: %{}, response: %{"allowed" => true}}
  """
  @spec allow(AdmissionReview.t()) :: AdmissionReview.t()
  def allow(admission_review) do
    put_in(admission_review.response["allowed"], true)
  end

  @doc """
  Responds by denying the operation

  ## Examples
    iex> admission_review = %BonnyPlug.AdmissionReview{request: %{}, response: %{}}
    ...> BonnyPlug.AdmissionReview.Request.deny(admission_review)
    %BonnyPlug.AdmissionReview{request: %{}, response: %{"allowed" => false}}
  """
  @spec deny(AdmissionReview.t()) :: AdmissionReview.t()
  def deny(admission_review) do
    put_in(admission_review.response["allowed"], false)
  end

  @doc """
  Responds by denying the operation, returning response code and message

  ## Examples
    iex> admission_review = %BonnyPlug.AdmissionReview{request: %{}, response: %{}}
    ...> BonnyPlug.AdmissionReview.Request.deny(admission_review, 403, "foo")
    %BonnyPlug.AdmissionReview{request: %{}, response: %{"allowed" => false, "status" => %{"code" => 403, "message" => "foo"}}}

    iex> BonnyPlug.AdmissionReview.Request.deny(%BonnyPlug.AdmissionReview{request: %{}, response: %{}}, "foo")
    %BonnyPlug.AdmissionReview{request: %{}, response: %{"allowed" => false, "status" => %{"code" => 400, "message" => "foo"}}}
  """
  @spec deny(AdmissionReview.t(), integer(), binary()) :: AdmissionReview.t()
  @spec deny(AdmissionReview.t(), binary()) :: AdmissionReview.t()
  def deny(admission_review, code \\ 400, message) do
    admission_review
    |> deny()
    |> put_in([Access.key(:response), "status"], %{"code" => code, "message" => message})
  end

  @doc """
  Adds a warning to the admission review's response.

  ## Examples
    iex> admission_review = %BonnyPlug.AdmissionReview{request: %{}, response: %{}}
    ...> BonnyPlug.AdmissionReview.Request.add_warning(admission_review, "warning")
    %BonnyPlug.AdmissionReview{request: %{}, response: %{"warnings" => ["warning"]}}

    iex> admission_review = %BonnyPlug.AdmissionReview{request: %{}, response: %{"warnings" => ["existing_warning"]}}
    ...> BonnyPlug.AdmissionReview.Request.add_warning(admission_review, "new_warning")
    %BonnyPlug.AdmissionReview{request: %{}, response: %{"warnings" => ["new_warning", "existing_warning"]}}
  """
  @spec add_warning(AdmissionReview.t(), binary()) :: AdmissionReview.t()
  def add_warning(admission_review, warning) do
    update_in(admission_review, [Access.key(:response), Access.key("warnings", [])], &([warning | &1]))
  end

  @doc """
  Verifies that a given field has not been mutated.

  ## Examples
    iex> admission_review = %BonnyPlug.AdmissionReview{request: %{"object" => %{"spec" => %{"immutable" => "value"}}, "oldObject" => %{"spec" => %{"immutable" => "value"}}}, response: %{}}
    ...> BonnyPlug.AdmissionReview.Request.check_immutable(admission_review, ["spec", "immutable"])
    %BonnyPlug.AdmissionReview{request: %{"object" => %{"spec" => %{"immutable" => "value"}}, "oldObject" => %{"spec" => %{"immutable" => "value"}}}, response: %{}}

    iex> admission_review = %BonnyPlug.AdmissionReview{request: %{"object" => %{"spec" => %{"immutable" => "new_value"}}, "oldObject" => %{"spec" => %{"immutable" => "value"}}}, response: %{}}
    ...> BonnyPlug.AdmissionReview.Request.check_immutable(admission_review, ["spec", "immutable"])
    %BonnyPlug.AdmissionReview{request: %{"object" => %{"spec" => %{"immutable" => "new_value"}}, "oldObject" => %{"spec" => %{"immutable" => "value"}}}, response: %{"allowed" => false, "status" => %{"code" => 400, "message" => "The field .spec.immutable is immutable."}}}
  """
  @spec check_immutable(AdmissionReview.t(), Enum.t()) :: AdmissionReview.t()
  def check_immutable(admission_review, field) do
    new_value = get_in(admission_review.request, ["object" | field])
    old_value = get_in(admission_review.request, ["oldObject" | field])

    if new_value == old_value, do: admission_review, else: deny(admission_review, "The field .#{Enum.join(field, ".")} is immutable.")
  end
end
