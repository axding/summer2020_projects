var express = require('express');
var bodyParser = require('body-parser');
var MongoClient = require('mongodb').MongoClient;
var app = express();
const connectionString = 'mongodb+srv://axding:P%40nd%40Bing@cluster0-occnb.mongodb.net/test?retryWrites=true&w=majority'



MongoClient.connect(connectionString, {useUnifiedTopology: true})
  .then(client => {
    console.log('Connected to Database');
    // setup database
    const db = client.db('star-wars-quotes');
    const quotesCollection = db.collection('quotes');

    //render html
    app.set('view engine', 'ejs')

    // access middleware
    app.use(bodyParser.urlencoded({extended: true}));
    app.use(express.static('public'));
    app.use(bodyParser.json());

    //request handlers
    app.delete('/quotes', (req, res) => {
      quotesCollection.deleteOne(
        { name: req.body.name }
      )
        .then(result => {
          if(result.deletedCount === 0){
            return res.json('No quote to delete')
          }
          res.json(`Deleted Darth Vadar's quote`)
        })
        .catch(error => console.error(error))
    });

    app.put('/quotes', (req, res) => {
      quotesCollection.findOneAndUpdate(
        {name: 'Yoda'},
        {
          $set: {
            name: req.body.name,
            quote: req.body.quote
          }
        },
        {
          upsert:true
        }
      )
        .then(result => {
          res.json('Success')
        })
        .catch(error => console.error(error))
    });

    app.get('/', function (req, res) {
      db.collection('quotes').find().toArray()
        .then(results => {
          res.render('index.ejs', {quotes: results})
        })
        .catch(error => console.error(error))
    });

    app.post('/quotes', function (req,res) {
      quotesCollection.insertOne(req.body)
        .then(result => {
          res.redirect('/')
        })
        .catch(error => console.error(error))
    });

    app.listen(8080, function () {
      console.log('Example app!');
    });
  })
  .catch(error => console.error(error))
