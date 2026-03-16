migrate((db) => {
  const collection = new Collection({
    "name": "invite_links",
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
        "name": "code",
        "type": "text",
        "required": true,
        "unique": true,
        "options": {
          "min": 8,
          "max": 64,
          "pattern": ""
        }
      },
      {
        "name": "expires_at",
        "type": "date",
        "required": true,
        "options": {
          "min": "",
          "max": ""
        }
      },
      {
        "name": "uses",
        "type": "number",
        "required": false,
        "options": {
          "min": 0,
          "max": null,
          "noDecimal": true
        }
      }
    ],
    "listRule": "@request.auth.id = user.id",
    "viewRule": "",
    "createRule": "@request.auth.id != \"\"",
    "updateRule": "@request.auth.id = user.id",
    "deleteRule": "@request.auth.id = user.id"
  });

  new Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("invite_links");
  dao.deleteCollection(collection);
});
