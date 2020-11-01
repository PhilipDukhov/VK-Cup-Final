var group = API.groups.getById({
    "group_id": Args.groupId,
    "fields": "market"
})[0];
if (group.market.enabled==0||
    API.market.get({
        "owner_id": -group.id,
        "count": 0,
    }).count==0
) {
    return null;
}
return [group];