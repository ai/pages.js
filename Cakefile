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
              <script>#script#</script>
              <script src="/page.js"></script>
              <script>#tests#</script>
              <script>
                jQuery(document).ready(function() { mocha.run(); });
              </script>
            <body>
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
    @jquery() +
    "chai.use(sinonChai);\n" +
    "chai.should();\n" +
    "mocha.setup('bdd');\n"

  testLibs: ->
    fs.readFileSync('node_modules/mocha/mocha.js') +
    fs.readFileSync('node_modules/sinon/lib/sinon.js') +
    fs.readFileSync('node_modules/sinon/lib/sinon/spy.js') +
    fs.readFileSync('node_modules/sinon-chai/lib/sinon-chai.js') +
    fs.readFileSync('node_modules/chai/chai.js')

  jquery: ->
    "module = {};\n" +
    fs.readFileSync('node_modules/jquery/node-jquery.js') + "\n"

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
    else if req.url == '/page.js'
      res.writeHead 200, {'Content-Type': 'text/javascript'}
      res.write mocha.lib()
    else
      res.writeHead 404, {'Content-Type': 'text/plain'}
      res.write 'Not Found'
    res.end()
  server.listen 8000
