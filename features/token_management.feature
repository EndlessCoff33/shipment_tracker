@fake_authentication
Feature: Token management

Background:
  Given I am logged in as "marcus@shipment-tracker.url"

Scenario: Generating a token
  When I generate a token for "circleci"
  Then I should see a token for "circleci" with a value
