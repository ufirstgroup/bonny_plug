# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

### Added

* `BonnyPlug.AdmissionReview`: Internal representation of an admission review
* `BonnyPlug.AdmissionReview.Request`: Helper functions to handle the admission webhook requests
* `BonnyPlug.WebhookPlug`: A plug to handle incoming admission webhook requests
* `BonnyPlug.WebhookHandler`: Handles webhook requests and delegates them to the implementing handlers
