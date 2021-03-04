const express = require('express');
const jwt = require( 'jsonwebtoken' );
const cors = require( 'cors' );
const bodyParser = require('body-parser')
const crypto = require( 'crypto' );
const url = require( 'url' );


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