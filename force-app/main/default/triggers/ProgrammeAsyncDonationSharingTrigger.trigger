trigger ProgrammeAsyncDonationSharingTrigger on Programme__ChangeEvent (after insert) {
    
    String accessLevel = 'Read';    // Can be "Read" or "Edit". Must be higher privilege than OWD

    Map<Id,Id> ProgrammesNewOwnersMap = new Map<Id,Id>();

    for(Programme__ChangeEvent pe : trigger.new) {

        EventBus.ChangeEventHeader header = pe.ChangeEventHeader;

        // We're only interested in updates and deletions 
        if (header.changetype == 'UPDATE') {

            // Generally id list will only have a single element, but we'll iterate in case multiple
            List<String> idList = header.getRecordIds();
            for(String thisId : idList) {

                // Populate map if owner has changed
                if(pe.OwnerId != null) {
                    ProgrammesNewOwnersMap.put(Id.valueOf(thisId), pe.OwnerId);
                }
            }
        }
    }

    if(ProgrammesNewOwnersMap.isEmpty()) return;

    // Build a map of user ids to the role ids we need
    List<User> users = [SELECT Id, UserRoleId FROM User WHERE Id IN :ProgrammesNewOwnersMap.values()];
    Map<Id,Id> userToRoleIdMap = new Map<Id,Id>();
    for(User u : users) {
        userToRoleIdMap.put(u.Id, u.UserRoleId);
    }

    // Get sharing groups with ids of entities to share with. This table contains role groups for
    // "Role", "RoleAndSubordinates" and "RoleAndSubordinatesInternal"
    List<Group> groups = [SELECT Id, RelatedId FROM Group 
        WHERE RelatedId IN :userToRoleIdMap.values() 
        AND Type = 'RoleAndSubordinates'];
    // Create map to get the right group id from the role id
    Map<Id,Id> roleToGroupMap = new Map<Id,Id>();
    for(Group g : groups) {
        roleToGroupMap.put(g.RelatedId,g.Id);
    }

    // Get donations and their existing related donation shares

    system.debug('keyset: ' + ProgrammesNewOwnersMap.keySet());

    List<Donation__c> donations = [SELECT Id, Programme_to_Support__c, 
        (SELECT Id, UserOrGroupId, ParentId, AccessLevel FROM Shares WHERE RowCause = 'Role_of_Programme_Owner__c')
        FROM Donation__c WHERE Programme_to_Support__c IN :ProgrammesNewOwnersMap.keySet()];

    List<Donation__Share> DontationSharesToDelete = new List<Donation__Share>();

    List<Donation__Share> DontationSharesToInsert = new List<Donation__Share>();

    for(Donation__c d : donations) {
        Boolean newShareRequired = true;

        Id ownerId = ProgrammesNewOwnersMap.get(d.Programme_to_Support__c);
        Id roleId = userToRoleIdMap.get(ownerId);
        Id groupId = roleToGroupMap.get(roleId);

        for(Donation__Share ds : d.Shares) {
            
            // If the new user has no role, remove all sharing and remember that we don't need to create new sharing
            if(roleId == null) {
                DontationSharesToDelete.add(ds);
                newShareRequired = false;
            }

            // If this share record matches setup we require, then keep this record and remember we don't need to create
            else if(roleId != null
                && ds.UserOrGroupId == groupId
                && ds.AccessLevel == accessLevel) {
                newShareRequired = false;
            }

            // Otherwise, remove this sharing
            else {
                DontationSharesToDelete.add(ds);
            }
        }

        if(newShareRequired) {
            Donation__Share ds = new Donation__Share();
            ds.ParentId = d.Id;
            ds.UserOrGroupId = groupId;
            ds.AccessLevel = accessLevel;
            ds.RowCause = 'Role_of_Programme_Owner__c';
            DontationSharesToInsert.add(ds);
        }
    }

    delete DontationSharesToDelete;
    insert DontationSharesToInsert;

}