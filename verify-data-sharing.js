const pg      = require('pg');
const request = require('request');

const BUILD_GOCD_URL                    = process.env.BUILD_GOCD_URL;
const BUILD_GOCD_USERNAME               = process.env.BUILD_GOCD_USERNAME;
const BUILD_GOCD_PASSWORD               = process.env.BUILD_GOCD_PASSWORD;
const USAGE_DATA_COLLECTOR_APP_URL      = process.env.USAGE_DATA_COLLECTOR_APP_URL;
const USAGE_DATA_COLLECTOR_APP_DB       = process.env.USAGE_DATA_COLLECTOR_APP_DB;
const USAGE_DATA_COLLECTOR_APP_DB_PORT  = process.env.USAGE_DATA_COLLECTOR_APP_DB_PORT;
const USAGE_DATA_COLLECTOR_APP_USERNAME = process.env.USAGE_DATA_COLLECTOR_APP_USERNAME;
const USAGE_DATA_COLLECTOR_APP_PASSWORD = process.env.USAGE_DATA_COLLECTOR_APP_PASSWORD;

const pgClient = () => {
  const dbHost   = USAGE_DATA_COLLECTOR_APP_URL;
  const username = USAGE_DATA_COLLECTOR_APP_USERNAME;
  const password = USAGE_DATA_COLLECTOR_APP_PASSWORD;
  const dbName   = USAGE_DATA_COLLECTOR_APP_DB;
  const dbPort   = USAGE_DATA_COLLECTOR_APP_DB_PORT;

  const connectionString = "postgres://" + username + ":" + password + "@" + dbHost + ":" + dbPort + "/" + dbName;

  return new pg.Client({connectionString});
};

const getBuildGoCDDataSharingInformation = (data) => {
  const requestConfig = {
    'url':     `${BUILD_GOCD_URL}/api/internal/data_sharing/usagedata`,
    'method':  'GET',
    'auth':    {
      'username': BUILD_GOCD_USERNAME,
      'password': BUILD_GOCD_PASSWORD
    },
    'headers': {'Accept': 'application/vnd.go.cd.v3+json'}
  };

  console.log("Fetching data sharing server id information from build.gocd.org...");
  return new Promise((fulfil, reject) => request(requestConfig, (err, res) => {
    if (err || res.statusCode >= 400) {
      const msg = err ? err : res.body;
      return reject(msg);
    }

    data.gocd_data_sharing_info = JSON.parse(res.body);
    fulfil(data);
  }));
};

const getBuildGoCDVersion = (data) => {
  const requestConfig = {
    'url':     `${BUILD_GOCD_URL}/api/version`,
    'method':  'GET',
    'auth':    {
      'username': BUILD_GOCD_USERNAME,
      'password': BUILD_GOCD_PASSWORD
    },
    'headers': {'Accept': 'application/vnd.go.cd.v1+json'}
  };

  console.log("Fetching currently deployed build.gocd.org version information...");
  return new Promise((fulfil, reject) => request(requestConfig, (err, res) => {
    if (err || res.statusCode >= 400) {
      const msg = err ? err : res.body;
      return reject(msg);
    }

    data.gocd_version = JSON.parse(res.body);
    fulfil(data);
  }));
};

const getUsageDataInformationFromDB = (data) => {
  const gocdDataSharingInformation = data.gocd_data_sharing_info;

  const queryString = `SELECT * FROM usagedata 
                       WHERE serverid='${gocdDataSharingInformation.server_id}'
                       ORDER BY id DESC 
                       limit 10;`;

  console.log("Fetching build.gocd.org's usage data information from usage-data-collector-app db...");
  return new Promise((fulfil, reject) => {
    const client = pgClient();

    client.connect().then(() => {
      client.query(queryString, (error, result) => {
        client.end();
        if (error) {
          return reject(error);
        }
        data.usage_data_info = result.rows;
        fulfil(data);
      });
    });
  });
};

const isToday = function (otherDay) {
  const TODAY = new Date();

  return otherDay.toDateString() === TODAY.toDateString();
};

const assertUsageDataExists = function (data) {
  console.log("Start verifying build.gocd.org usage data reporting..");

  const GoCDVersion            = `${data.gocd_version.version}-${data.gocd_version.build_number}`;
  const lastTenUsageData       = data.usage_data_info;
  const usageDataReportedToday = lastTenUsageData.filter((usageData) => {
    return isToday(new Date(usageData.timestamp))
  });

  if (usageDataReportedToday.length === 0) {
    throw new Error(`build.gocd.org hasn't reported usage data on date: ${new Date().toString()}`);
  }

  const usageDataMatchingVersion = usageDataReportedToday.filter((usageData) => {
    return (usageData.gocdversion === GoCDVersion);
  });

  if (usageDataMatchingVersion.length === 0) {
    console.warn(`build.gocd.org hasn't reported usage data for currently deployed version: ${GoCDVersion}`);
  }

  console.log("Done verifying build.gocd.org usage data reporting..");
};

const printError = (err) => {
  let errMsg = `Failed Verifying Usage Data Reporting for build.gocd.org server.\n Reason: ${err}`;

  console.error(errMsg);
  process.exit(1);
};

getBuildGoCDVersion({})
  .then(getBuildGoCDDataSharingInformation)
  .then(getUsageDataInformationFromDB)
  .then(assertUsageDataExists)
  .catch(printError);
