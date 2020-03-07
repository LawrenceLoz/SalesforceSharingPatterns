/**
*Copyright 2020 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy 
*of this software and associated documentation files (the "Software"), to deal 
*in the Software without restriction, including without limitation the rights 
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
*of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all 
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

public with sharing class ShareDonationsToThemeGroupsBatch implements Database.Batchable<sObject> {

    String accessLevel = 'Edit';    // Can be "Read" or "Edit". Must be higher privilege than OWD
    String sharingReason = 'Thematic_Area_Coordination_Group__c';  // The API name of a sharing reason set up on programme object


	public Database.QueryLocator start(Database.BatchableContext BC) {

        // Query locator includes all donations, their associated shares, and 
        // information from parent records identifying entities needing access.
        // Checking every donation ensures we assess whether sharing should be added 
        // or revoked following any kind of change
        Database.QueryLocator ql = Database.getQueryLocator([SELECT Id, 
            Programme_to_Support__r.Theme__r.Thematic_Area_Coordination_Public_Group__c,
            (SELECT UserOrGroupId, AccessLevel FROM Shares WHERE RowCause = :sharingReason)
            FROM Donation__c]);

		return ql;
    }
    

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Donation__Share> sharesToInsert = new List<Donation__Share>();
        List<Donation__Share> sharesToDelete = new List<Donation__Share>();

        // Get names of public groups specified in the records
        Set<String> groupNames = new Set<String>();
        for(Donation__c d : (List<Donation__c>) scope) {
            groupNames.add(d.Programme_to_Support__r.Theme__r.Thematic_Area_Coordination_Public_Group__c);
        }

        // Query for the public groups we'll need and establish map of names to ids
        Map<String,Id> groupNamesToIdsMap = new Map<String,Id>();
        List<Group> groups = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNames];
        for(Group g : groups) {
            groupNamesToIdsMap.put(g.DeveloperName, g.Id);
        }

        // Iterate over all donations in this batch
        for(Donation__c d : (List<Donation__c>) scope) {
            Boolean createShare = false;    // variable to track whether or not new sharing is needed

            // Get the group id from the group name specified on the parent record
            Id sharedToId = groupNamesToIdsMap.get(d.Programme_to_Support__r.Theme__r.Thematic_Area_Coordination_Public_Group__c);

            // If a group name was set on the parent and it's a valid public group (i.e. was found in the 
            // query and so in the map), then indicate we'll need to create a new share record (this will 
            // be overridden later if we already have a share for this group)
            if(sharedToId != null) {
                createShare = true;
            }
            
            // Iterate over any apex sharing already applied
            for(Donation__Share share : d.Shares) {

                // If share matches what we need, mark that a new share doesn't need to be inserted
                if(share.UserOrGroupId == sharedToId && share.AccessLevel == accessLevel) {
                    createShare = false;
                }

                // Otherwise add this to a list of shares to delete. These records should correspond with  
                // out of date sharing which shouldn't be kept
                else {
                    sharesToDelete.add(share);
                }
            }

            // Instantiate a new share record if it's needed
            if(createShare) {
                Donation__Share newShare = new Donation__Share();
                newShare.ParentId = d.Id;
                newShare.UserOrGroupId = sharedToId;
                newShare.RowCause = sharingReason;
                newShare.AccessLevel = accessLevel;
                sharesToInsert.add(newShare);
            }
        }

        insert sharesToInsert;
        delete sharesToDelete;
    }


    public void finish(Database.BatchableContext BC) {

    }

}