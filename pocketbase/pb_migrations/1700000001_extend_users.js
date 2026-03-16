migrate((db) => {
  const dao = new Dao(db);

  // Load the existing users collection
  const collection = dao.findCollectionByNameOrId("users");

  // Add extra fields to the built-in users auth collection
  collection.schema.addField(new SchemaField({
    "name": "username",
    "type": "text",
    "required": true,
    "unique": true,
    "options": {
      "min": 3,
      "max": 50,
      "pattern": ""
    }
  }));

  collection.schema.addField(new SchemaField({
    "name": "total_points",
    "type": "number",
    "required": false,
    "options": {
      "min": 0,
      "max": null,
      "noDecimal": true
    }
  }));

  collection.schema.addField(new SchemaField({
    "name": "sessions_completed",
    "type": "number",
    "required": false,
    "options": {
      "min": 0,
      "max": null,
      "noDecimal": true
    }
  }));

  collection.schema.addField(new SchemaField({
    "name": "average_reaction_time",
    "type": "number",
    "required": false,
    "options": {
      "min": 0,
      "max": null,
      "noDecimal": false
    }
  }));

  collection.schema.addField(new SchemaField({
    "name": "avatar_url",
    "type": "text",
    "required": false,
    "options": {
      "min": null,
      "max": 500,
      "pattern": ""
    }
  }));

  dao.saveCollection(collection);
}, (db) => {
  // Revert — remove the added fields
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("users");

  for (const name of ["username", "total_points", "sessions_completed", "average_reaction_time", "avatar_url"]) {
    const field = collection.schema.getFieldByName(name);
    if (field) {
      collection.schema.removeField(field.id);
    }
  }

  dao.saveCollection(collection);
});
