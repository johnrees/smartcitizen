const fetch = require('node-fetch');

function postReadings(url, deviceId, sensorId, token, length) {

  if (url == null) {
    console.log("usage:\n node postReadings_js.js url deviceId, sensorId, token, nrOfLines")
    console.log("example:\n node postReadings_js.js 'http://localhost:3000/v0' 4 12 'd0e50e139b35d646719ce2046e79b8ded8e5c48cd73ff7c9ea9ca6757a837082' 10000")
    return;
  }

  const body = { data:[] };

  for(let j = 1; j < length; j++) {
    body.data.push({"recorded_at":new Date().toISOString(),"sensors":[{"id": sensorId, "value":10 }]});
  }
  var myInit = {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify(body)
  };
  fetch(`${url}/devices/${deviceId}/readings`,myInit).then(
    res => console.log("Res:", res.status, res.statusText, res.timeout)
  );

  console.log('url: ' + url);
  console.log('deviceId: ' + deviceId);
  console.log('sensorId: ' + sensorId);
  console.log('Token: ' + token);
  console.log('length: ' + length);
  console.log('----');
}

postReadings(...process.argv.slice(2));
