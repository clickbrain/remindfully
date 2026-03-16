migrate((db) => {
  const collection = new Collection({
    "name": "leaderboard_entries",
    "type": "base",
    "system": false,
    "schema": [
      {
        "name": "user",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "_pb_users_auth_",
          "cascadeDelete": true,
          "minSelect": null,
          "maxSelect": 1,
          "displayFields": ["username"]
        }
      },
      {
        "name": "total_points",
        "type": "number",
        "required": true,
        "options": {
          "min": 0,
          "max": null,
          "noDecimal": true
        }
      },
      {
        "name": "sessions_completed",
        "type": "number",
        "required": true,
        "options": {
          "min": 0,
          "max": null,
          "noDecimal": true
        }
      },
      {
        "name": "period",
        "type": "text",
        "required": true,
        "options": {
          "min": null,
          "max": 20,
          "pattern": ""
        }
      }
    ],
    "listRule": "",
    "viewRule": "",
    "createRule": "@request.auth.id != \"\"",
    "updateRule": "@request.auth.id = user.id",
    "deleteRule": "@request.auth.id = user.id"
  });

  new Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("leaderboard_entries");
  dao.deleteCollection(collection);
});
