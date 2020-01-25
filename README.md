# SalesforceSharingPatterns
Sample application illustrating apex and configuration patterns to implement apex / managed sharing in Salesforce

Note this is WORK IN PROGRESS and might not have anything usable yet

# Pattern 1 : Real time sharing using apex
This illustrates how we can implement sharing management based on a field on the record to be shared.
In the example, the Programme object will be shared to the Major Donor Relationship Manager user specified in the lookup field.
The variation in this example uses an asynchronous trigger with sharing logic which fires when a programme is created or updated. It's possible to use a similar approach inside a synchronous trigger, or to use future or queueable methods to achieve the same result.
