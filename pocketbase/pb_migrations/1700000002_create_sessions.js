migrate((db) => {
  const collection = new Collection({
    "name": "sessions",
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
        "name": "duration_minutes",
        "type": "number",
        "required": true,
        "options": {
          "min": 1,
          "max": 120,
          "noDecimal": true
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
        "name": "successful_taps",
        "type": "number",
        "required": true,
        "options": {
          "min": 0,
          "max": null,
          "noDecimal": true
        }
      },
      {
        "name": "missed_taps",
        "type": "number",
        "required": true,
        "options": {
          "min": 0,
          "max": null,
          "noDecimal": true
        }
      },
      {
        "name": "avg_reaction_time",
        "type": "number",
        "required": true,
        "options": {
          "min": 0,
          "max": null,
          "noDecimal": false
        }
      },
      {
        "name": "completed_at",
        "type": "date",
        "required": true,
        "options": {
          "min": "",
          "max": ""
        }
      }
    ],
    "listRule": "@request.auth.id != \"\"",
    "viewRule": "@request.auth.id != \"\"",
    "createRule": "@request.auth.id != \"\"",
    "updateRule": "@request.auth.id = user.id",
    "deleteRule": "@request.auth.id = user.id"
  });

  new Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("sessions");
  dao.deleteCollection(collection);
});
