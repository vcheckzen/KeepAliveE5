const fs = require("fs");
const qs = require("qs");
const axios = require("axios");
const express = require("express");

const configFile = process.argv[2];
const config = require(configFile);
const app = express();
const except = require('./except.js');

// setTimeout(() => except.fatalError(config.username), except.totalTimeout);

app.get("/", async (req, res) => {
  res.send(req.query.code);

  const resp = await axios.post(
    "https://login.microsoftonline.com/common/oauth2/v2.0/token",
    qs.stringify({
      client_id: config.client_id,
      client_secret: config.client_secret,
      code: req.query.code,
      redirect_uri: config.redirect_uri,
      grant_type: "authorization_code",
    })
  );

  server.close(() => {
    let success = false;

    try {
      config.refresh_token = resp.data.refresh_token;
      fs.writeFileSync(configFile, JSON.stringify(config));

      success = config.refresh_token && config.refresh_token.length > 50;
    } catch (error) {
      except.fatalError(config.username, error);
    } finally {
      if (!success) process.exit(1);
    }

    console.log(`✔ 账号 [${config.username}] 注册成功.`);
  });
});

const server = app.listen(config.redirect_uri.match(/\d+/)[0]);
