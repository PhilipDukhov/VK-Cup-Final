var groupIds = "";
var maxApiCalls = 25;
var count = maxApiCalls - 2;
var groups = API.groups.search({
    "q": Args.q,
    "market": 1,
    "city_id": Args.cityId,
    "count": count,
}).items;
var i = 0;
while (i < groups.length) {
    if (groups[i].is_closed == 1 ||
        API.market.get({
        "owner_id": "-" + groups[i].id,
        "count": 0,
    }).count != 0) {
        groupIds = groupIds + groups[i].id + ",";
    }
    i = i + 1;
}
return API.groups.getById({
    "group_ids": groupIds,
    "fields": "city",
});