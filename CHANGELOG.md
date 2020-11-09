# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

## [1.0.1] - 2020-11-09

### Changed

* Add missing dependency to Jason in `mix.exs`

## [1.0.0] - 2020-11-09

### Added

* `BonnyPlug.AdmissionReview`: Internal representation of an admission review
* `BonnyPlug.AdmissionReview.Request`: Helper functions to handle the admission webhook requests
* `BonnyPlug.WebhookPlug`: A plug to handle incoming admission webhook requests
* `BonnyPlug.WebhookHandler`: Handles webhook requests and delegates them to the implementing handlers
