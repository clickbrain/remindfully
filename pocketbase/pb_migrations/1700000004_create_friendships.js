migrate((db) => {
  const collection = new Collection({
    "name": "friendships",
    "type": "base",
    "system": false,
    "schema": [
      {
        "name": "requester",
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
        "name": "receiver",
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
        "name": "status",
        "type": "text",
        "required": true,
        "options": {
          "min": null,
          "max": 20,
          "pattern": ""
        }
      },
      {
        "name": "created_at",
        "type": "date",
        "required": true,
        "options": {
          "min": "",
          "max": ""
        }
      }
    ],
    "listRule": "@request.auth.id = requester.id || @request.auth.id = receiver.id",
    "viewRule": "@request.auth.id = requester.id || @request.auth.id = receiver.id",
    "createRule": "@request.auth.id != \"\"",
    "updateRule": "@request.auth.id = requester.id || @request.auth.id = receiver.id",
    "deleteRule": "@request.auth.id = requester.id || @request.auth.id = receiver.id"
  });

  new Dao(db).saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("friendships");
  dao.deleteCollection(collection);
});
