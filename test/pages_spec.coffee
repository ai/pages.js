describe 'Pages', ->

  afterEach ->
    Pages._pages    = []
    Pages._document = document

  html = (string) ->
    Pages._document = jQuery("<div>#{string}</div>")[0]
    Pages.init()

  describe '.add()', ->

    it 'should add page description', ->
      Pages.add('.a-page', a: 1)
      Pages._pages.should.eql([{ selector: '.a-page', a: 1 }])

    it 'should add page with only load callback', ->
      load = ->
      Pages.add('.a-page', load)
      Pages._pages.should.eql([{ selector: '.a-page', load: load }])

  describe 'callbacks', ->

    it 'should call load callbacks', ->
      a = sinon.spy()
      b = sinon.spy()
      c = sinon.spy()
      Pages.add('.a', a)
      Pages.add('.b', b)
      Pages.add('.c', c)
      html '<div class="a"></div><div class="a"></div><div class="b"></div>'

      a.should.have.been.calledOnce
      b.should.have.been.calledOnce
      c.should.not.have.been.called

    it 'should pass arguments to callback', (done) ->
      a = ($, $$, page) ->
        $.should.eql(jQuery)
        $$('.child').length.should.eql(1)
        this.should.eql(page)
        page.length.should.eql(2)
        page.is('.a').should.be.true
        done()

      Pages.add('.a', a)
      html '<div class="a"><div class="child"></div></div><div class="a"></div>'
