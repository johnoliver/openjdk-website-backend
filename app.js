const GitHub = require('github-api');
const fs = require('fs')
const mkdirp = require('mkdirp');
const _ = require('underscore');

// basic auth
const gh = new GitHub({
  token: process.env['GITHUB_TOKEN']
});

//var AdoptOpenJDK = gh.getOrganization('AdoptOpenJDK');
const repo = gh.getRepo('AdoptOpenJDK', 'open' + process.env['VERSION'] + '-binaries');

mkdirp(process.env['VERSION'], function (err) {
  if (err) console.error(err)
});

repo.listReleases(function (err, result) {

  const release = process.env['RELEASE'] === "true";
  console.log("Release: " + release + " " + process.env['RELEASE']);

  const filteredResult = _.where(result, {prerelease: !release});

  if (release) {
    var data = JSON.stringify(filteredResult, null, 2)
    console.log("Writing: " + process.env['VERSION'] + '/releases.json');
    console.log(data);
    fs.writeFileSync(process.env['VERSION'] + '/releases.json', data);

    data = JSON.stringify(filteredResult[0], null, 2)
    console.log("Writing: " + process.env['VERSION'] + '/latest_release.json');
    console.log(data);
    fs.writeFileSync(process.env['VERSION'] + '/latest_release.json', JSON.stringify(data, null, 2));
  } else {
    fs.writeFileSync(process.env['VERSION'] + '/nightly.json', JSON.stringify(filteredResult, null, 2))
    fs.writeFileSync(process.env['VERSION'] + '/latest_nightly.json', JSON.stringify(filteredResult[0], null, 2))
  }
});
