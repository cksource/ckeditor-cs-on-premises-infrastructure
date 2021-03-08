const express = require('express');
const jwt = require( 'jsonwebtoken' );
const cors = require( 'cors' );
const bodyParser = require('body-parser')
const crypto = require( 'crypto' );
const url = require( 'url' );
const axios = require( 'axios' );
const fs = require('fs')

let ENVIRONMENT_ID = 'a0ff2ff251386932c19a';
let ACCESS_KEY = '53677cc5d12a90d8a3928fe444634c5631f7';
let ENV_SECRET = 'secret';

const app = express();
app.use(cors())
app.use(bodyParser.json({limit: '10mb'}))

// Serving sample.html from node.js server
app.use(express.static('editor'));
app.get('/', (req, res) => {
  res.redirect('/sample/index.html');
});

// Token endpoint
app.get('/token', generateToken)

// Create environment
app.post('/init', createEnvironment)

app.listen(3000, () => console.log(`Node-server is listening on port 3000`));

////////
function generateToken( req, res ) {

  
  const payload = {
     aud: ENVIRONMENT_ID,
     sub: req.query['user.id'] || 'user-1',
     user: {
         name: req.query['user.name'] || 'John Doe',
         avatar: req.query['user.avatar'] || ''
     },
     auth: {
         'collaboration': {
             '*': {
                 'role': req.query.role || 'writer'
             }
         }
     }
 };

 const result = jwt.sign( payload, ACCESS_KEY, { algorithm: 'HS256' } );

   res.send( result );
} 

async function createEnvironment( req, res ) {
  
  console.log('Init called')
  console.log(req.body)

  ENV_SECRET = req.body.secret;
  
  const newEnvironment = {
    id: _randomString( 20 ), 
    name: 'On-Premises Quick-start',
    organizationId: _randomString( 20 ),
    accessKeys: [ { value: _randomString( 20 ) } ],
    services: [
      {
        id: _randomString( 24 ), 
        type: 'easy-image'
      },
      {
        id: _randomString( 24 ),
        type: 'collaboration'
      }
    ] 
  };
  const timestamp = Date.now();
  const uri = `http://ckeditor-cs:8000/environments`;
  const signature = _generateSignature(
    ENV_SECRET,
    'POST',
    uri,
    timestamp,
    newEnvironment
  );
  const headers = {
    'X-CS-Signature': signature,
    'X-CS-Timestamp': timestamp
  };
  
  try {
    await axios.post( uri, newEnvironment, { headers: headers }) ;
    console.log( 'New Environment created.' );
    console.log( `EnvironmentId: ${ newEnvironment.id } AccessKey: ${ newEnvironment.accessKeys[ 0 ].value }` );
    ENVIRONMENT_ID = newEnvironment.id;
    ACCESS_KEY = newEnvironment.accessKeys[ 0 ].value;

    injectEndpoints( req.body.ip, req.body.csPort, req.body.nodePort )

    res.send('Done')
  } catch ( err ) {
    console.log(err);
    res.status(500).send('Error')
  }
}

function injectEndpoints( ip, csPort, nodePort ) { 
  const tokenEndpoint = `http://${ ip }:${ nodePort }/token`;
  const uploadUrl = `http://${ ip }:${ csPort }/easyimage/upload`;
  const websocketUrl = `ws://${ ip }:${ csPort }/ws`;
  
  let dialogJsFile = fs.readFileSync('./editor/sample/configuration-dialog/configuration-dialog.js').toString();

  dialogJsFile = dialogJsFile.replace(/http:\/\/.*\/token/, tokenEndpoint)
  dialogJsFile = dialogJsFile.replace(/http:\/\/.*\/easyimage\/upload/,uploadUrl)
  dialogJsFile = dialogJsFile.replace(/ws:\/\/.*\/ws/,websocketUrl)

  fs.writeFileSync('./editor/sample/configuration-dialog/configuration-dialog.js', dialogJsFile, 'utf8')
}


function _generateSignature( apiSecret, method, uri, timestamp, body ) {
  const path = url.parse( uri ).path;

  const hmac = crypto.createHmac( 'SHA256', apiSecret );

  hmac.update( `${ method.toUpperCase() }${ path }${ timestamp }` );

  if ( body ) {
      hmac.update( Buffer.from( JSON.stringify( body ) ) );
  }

  return hmac.digest( 'hex' );
}

function _randomString( length ) {
  return crypto.randomBytes( length / 2 ).toString( 'hex' );
}