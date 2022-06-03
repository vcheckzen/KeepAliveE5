const puppeteer = require("puppeteer");
const config = require(process.argv[2]);
const except = require('./except.js');

setTimeout(() => except.fatalError(config.username), except.totalTimeout);

const sleep = (seconds) =>
  new Promise((resolve) => setTimeout(resolve, (seconds || 1) * 1000));

(async () => {
  let success = false;
  let browser = { close: async () => null };
  try {
    browser = await puppeteer.launch({
      // headless: false,
      headless: true,
      args: ["--no-sandbox"],
    });
    const page = await browser.newPage();
    // https://pptr.dev/#?product=Puppeteer&version=v10.4.0&show=api-pagesetdefaulttimeouttimeout
    await page.setDefaultTimeout(except.methodTimeout);

    await page.goto(
      `https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=${config.client_id}&scope=offline_access%20User.Read&response_type=code&redirect_uri=${config.redirect_uri}`
    );

    // email
    await page.waitForSelector("input[type=email]");
    await page.type("input[type=email]", config.username);
    // next
    await page.waitForSelector("[type=submit]");
    await sleep(1);
    await page.click("[type=submit]");

    // password
    await page.waitForSelector("input[type=password]");
    await page.type("input[type=password]", config.password);
    // login
    await sleep(3);
    await page.waitForSelector("[type=submit]");
    await page.click("[type=submit]");
    await page.waitForNavigation();

    // consent
    await page.waitForSelector("[type=checkbox]");
    await sleep(1);
    await page.click("[type=checkbox]");

    // accept
    await page.waitForSelector("[type=submit]");
    await page.click("[type=submit]");
    // request redirect uri
    await sleep(3);
    success = true;
  } catch (error) {
    await browser.close();
    except.fatalError(config.username, error);
  } finally {
    await browser.close();
    process.exit(success ? 0 : 1)
  }
})();
