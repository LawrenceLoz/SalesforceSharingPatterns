# SalesforceSharingPatterns
Sample application illustrating apex and configuration patterns to implement apex / managed sharing in Salesforce

Note this is WORK IN PROGRESS and might not have anything usable yet

# Pattern 1 : Real time sharing using apex
This illustrates how we can implement sharing management based on a field on the record to be shared.

In the example, the Programme object will be shared to the Major Donor Relationship Manager user specified in the lookup field.

The variation here invovles an asynchronous trigger with sharing logic which fires when a programme is created or updated. It's possible to use similar logic inside a synchronous trigger, or to use future or queueable methods to achieve the same result.

# Pattern 1 : Real time sharing with process builder and flow
This illustrates how we can use information from the object to control sharing with process builder and an auto-launched flow.

In this example, the Donation object will be shared to the Received By User in the lookup field.

A process builder triggered from a donation update which checks for the lookup having changed, and calls an auto-launched flow if so. The flow removes any existing sharing for the sharing reason used, and creates a share record for the new user
