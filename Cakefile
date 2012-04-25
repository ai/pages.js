fs     = require('fs')
http   = require('http')
coffee = require('coffee-script')

mocha =

  template: """
            <html>
            <head>
              <meta charset="UTF-8">
              <title>Pages.js Tests</title>
              <style>#style#</style>
              <script src="/jquery.js"></script>
              <script>#script#</script>
              <script src="/pages.js"></script>
              <script>#tests#</script>
              <script>
                jQuery(document).ready(function() { mocha.run(); });
              </script>
              <style>
                #integration {
                  position: absolute;
                  margin-left: 80px;
                  font-weight: 200;
                  font-size: 1em;
                }
              </style>
            <body>
              <a href="/integration" id="integration" target="_blank">
                see also integration test →
              </a>
              <div id="mocha"></div>
            </body>
            </html>
            """

  html: ->
    @render @template,
      style:  @cdata(@style())
      script: @cdata(@script())
      tests:  @cdata(@tests())

  render: (template, params) ->
    html = template
    for name, value of params
      html = html.replace("##{name}#", value.replace(/\$/g, '$$$$'))
    html

  cdata: (text) ->
    "//<![CDATA[\n" +
    text + "\n" +
    "//]]>"

  style: ->
    fs.readFileSync('node_modules/mocha/mocha.css')

  script: ->
    @testLibs() +
    "chai.use(sinonChai);\n" +
    "chai.should();\n" +
    "mocha.setup('bdd');\n"

  testLibs: ->
    fs.readFileSync('node_modules/mocha/mocha.js') +
    fs.readFileSync('node_modules/chai/chai.js') +
    fs.readFileSync('node_modules/sinon/lib/sinon.js') +
    fs.readFileSync('node_modules/sinon/lib/sinon/spy.js') +
    fs.readFileSync('node_modules/sinon/lib/sinon/stub.js') +
    fs.readFileSync('node_modules/sinon-chai/lib/sinon-chai.js') +
    fs.readFileSync('node_modules/chai-jquery/chai-jquery.js')

  jquery: ->
    fs.readFileSync('node_modules/jquery-browser/lib/jquery.js')

  lib: ->
    fs.readFileSync('lib/pages.js')

  tests: ->
    files  = fs.readdirSync('test/').
      filter( (i) -> i.match /\.coffee$/ ).map( (i) -> "test/#{i}" )
    src = files.reduce ( (all, i) -> all + fs.readFileSync(i) ), ''
    coffee.compile(src)

task 'test', 'Run specs server', ->
  server = http.createServer (req, res) ->
    if req.url == '/'
      res.writeHead 200, { 'Content-Type': 'text/html' }
      res.write mocha.html()
    else if req.url == '/pages.js'
      res.writeHead 200, {'Content-Type': 'text/javascript'}
      res.write mocha.lib()
    else if req.url == '/jquery.js'
      res.writeHead 200, {'Content-Type': 'text/javascript'}
      res.write mocha.jquery()
    else if req.url == '/integration'
      res.writeHead 200, { 'Content-Type': 'text/html' }
      res.write fs.readFileSync('test/integration.html')
    else
      res.writeHead 404, {'Content-Type': 'text/plain'}
      res.write 'Not Found'
    res.end()
  server.listen 8000
