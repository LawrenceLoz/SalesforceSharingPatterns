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


// This trigger creates and removes sharing records for programmes
// It shares the record with the person set in the "Major Donor Relationship Manager" lookup
// This illustrates Sharing pattern 1a

trigger ProgrammeAsyncProgrammeSharingTrigger on Programme__ChangeEvent (after insert) {

    String accessLevel = 'Edit';    // Can be "Read" or "Edit". Must be higher privilege than OWD
    String sharingReason = 'Major_Donor_Relationship_Manager__c';  // The API name of a sharing reason set up on programme object

    // Build map of inserted/updated records and users who will need to access
    Map<Id,Id> relMgrsMap = new Map<Id,Id>();
    for(Programme__ChangeEvent p : trigger.new) {

        EventBus.ChangeEventHeader header = p.ChangeEventHeader;
        if (header.changetype == 'UPDATE' || header.changetype == 'INSERT') {
            Id recordId = header.getRecordIds()[0];
            relMgrsMap.put(recordId, p.Major_Donor_Relationship_Manager__c);
        }
    }

    if(!relMgrsMap.isEmpty()) {

        // Query for any existing sharing records
        List<Programme__Share> shares = [SELECT Id, UserOrGroupId, ParentId, AccessLevel
            FROM Programme__Share 
            WHERE RowCause = :sharingReason
            AND ParentId IN : relMgrsMap.keySet()];

        List<Programme__Share> sharesToDelete = new List<Programme__Share>();

        // Check whether sharing required is already in place
        for(Programme__Share ps : shares) {
            Id majorDonorId = relMgrsMap.get(ps.ParentId);

            // Remove element from programme donor map if we have a share record for this already
            // (we'll keep the existing sharing)
            if(ps.UserOrGroupId == majorDonorId
                && ps.AccessLevel == accessLevel) {
                relMgrsMap.remove(ps.ParentId);
            }   

            // Otherwise, add this to the list to be deleted
            else {
                sharesToDelete.add(ps);
            }
        }

        // Get list of users (we want to be sure we can share to them)
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id, IsActive FROM User WHERE Id IN :relMgrsMap.values()]);

        // Create sharing records for all new sharing required
        List<Programme__Share> sharesToInsert = new List<Programme__Share>();
        for(Id recordId : relMgrsMap.keySet()) {
            Id relMgrId = (Id) relMgrsMap.get(recordId);

            // Create a share object only if relationship manager is populated with an active user
            if(relMgrId != null && userMap.get(relMgrId).IsActive) {
                Programme__Share p = new Programme__Share();
                p.ParentId = recordId;
                p.UserOrGroupId = relMgrId;
                p.AccessLevel = accessLevel;
                p.RowCause = sharingReason;
                sharesToInsert.add(p);
            }
        }

        // Make DML changes
        if(!sharesToDelete.isEmpty()) delete sharesToDelete;
        if(!sharesToInsert.isEmpty()) insert sharesToInsert;
    }
}