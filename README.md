# SalesforceSharingPatterns
Sample application illustrating apex and configuration patterns to implement apex / managed sharing in Salesforce

Note this is WORK IN PROGRESS and might not have anything usable yet

# Pattern 1 : Real time sharing using apex
This illustrates how we can implement sharing management based on a field on the record to be shared.

In the example, the Programme object will be shared to the Major Donor Relationship Manager user specified in the lookup field.

The variation here invovles an asynchronous trigger with sharing logic which fires when a programme is created or updated. It's possible to use similar logic inside a synchronous trigger, or to use future or queueable methods to achieve the same result.

# Pattern 2 : Real time sharing with process builder and flow
This illustrates how we can use information from the object to control sharing with process builder and an auto-launched flow.

In this example, the Donation object will be shared to the Received By User in the lookup field.

A process builder triggered from a donation update which checks for the lookup having changed, and calls an auto-launched flow if so. The flow removes any existing sharing for the sharing reason used, and creates a share record for the new user.

# Pattern 3 : Scheduled sharing with apex
Shows using information from a grandparent object to control sharing by iterating over shared records in a scheduled batch class.

In this example, the Donation object will be shared to the Thematic Area Coordination Public Group specified in the Theme record linked to the Programme record linked to the Donation.

The batch job can be scheduled to run with an appropriate frequency. It's a good pattern to use when the shared object and the information required to set the sharing aren't on the same object, and the number of records in the shared object is quite significant (up to 50 million will be supported by the batch)

# Pattern 4 : Scheduled sharing with flow
Using the scheduled flow option to re-assess sharing for a group of records every day.

In the example, Donations will be shared to the Country Finance Manager on the Country record linked to the Programme which is linked to the Dontation.

This is a good admin-only approach to use when sharing should be based on information in related parent records. As this doesn't only trigger from a specicific object it ensures sharing is right after any record involved is changed. It's best used when there aren't large volumes of records in the object to be shared, as there's a limit on the number of schedule-triggered flows in a 24 hour period (250,000 as of Spring '20)
