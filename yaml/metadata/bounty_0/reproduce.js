const yaml = require("../../remote_files");
const string = "[" + "\r".repeat(80);
yaml.parseDocument(string);
