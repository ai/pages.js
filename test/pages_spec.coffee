describe 'Pages', ->

  beforeEach ->
    Pages.enable()

  afterEach ->
    Pages._pages    = []
    Pages._document = document
    Pages.disable()
    for method of Pages
      Pages[method]?.restore?()

  html = (string) ->
    Pages.disable()
    Pages._document = jQuery("<div>#{string}</div>")[0]
    Pages.init()
    Pages.enable()

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
        $$('.child').should.to.have.length(1)
        this.should.eql(page)
        page.should.to.have.length(2)
        page.should.have.class('a')
        done()

      Pages.add('.a', a)
      html '<div class="a"><div class="child"></div></div><div class="a"></div>'

  describe '.isSupported()', ->

    it 'should return boolean', ->
      Pages.isSupported().should.be.a('boolean')

  describe '.enable()', ->

    beforeEach ->
      Pages.disable()

    it 'should enable history management', ->
      Pages.enable().should.be.true
      Pages.disabled.should.be.false

    it 'should not enable without support', ->
      sinon.stub(Pages, 'isSupported').returns(false)
      Pages.enable().should.be.false
      Pages.disabled.should.be.true

    it 'should add events', ->
      Pages.enable()
      $(window).data('events').popstate.should.to.have.length(1)
      $(document).data('events').click.should.to.have.length(1)

    it 'should not enabled twice', ->
      Pages.enable().should.be.true
      Pages.enable().should.be.false
      $(window).data('events').popstate.should.to.have.length(1)

  describe '.disable()', ->

    it 'should disable history management', ->
      Pages.disable()
      Pages.disabled.should.be.true

    it 'should remove events', ->
      Pages.disable()
      (typeof $(window).data('events') ).should.eql('undefined')
      (typeof $(document).data('events') ).should.eql('undefined')

  describe '._params()', ->

    it 'should return only pages params', ->
      a = $('<a href="/" data-id="1" data-pages-disable="1" />')
      Pages._params(a).should.eql({ disable: 1 })

  describe 'history events', ->

    it 'should open page by popstate event', ->
      sinon.spy(Pages, 'open')
      $(window).triggerHandler('popstate.pages')
      Pages.open.should.have.been.calledWith('/')

    it 'should open page by link click', ->
      sinon.spy(Pages, '_openLink')
      html '<a></a>'
      $(Pages._document).find('a').click()
      Pages._openLink.should.have.been.called

  describe '._openLink()', ->

    it 'should open url by link', ->
      sinon.spy(Pages, 'open')
      html '<a href="/a" data-pages-a="1"></a>'
      Pages._openLink($(Pages._document).find('a'))
      Pages.open.should.have.been.calledWith('/a', a: 1)

    it 'should not open external url by link', ->
      sinon.spy(Pages, 'open')
      html '<a href="http://example.com/"></a>'
      Pages._openLink($(Pages._document).find('a'))
      Pages.open.should.not.have.been.called

    it 'should not open urb by disabled link', ->
      sinon.spy(Pages, 'open')
      html '<a href="/a" data-pages-disable></a>'
      Pages._openLink($(Pages._document).find('a'))
      Pages.open.should.not.have.been.called

  describe '.animating', ->

    it 'should run callbacks now without running animation', ->
      callback = sinon.spy()
      Pages.animating.wait(callback)
      callback.should.have.been.called
      Pages.animating.waiting.should.be.false

    it 'should run callback, when animation wll end', ->
      callback = sinon.spy()

      Pages.animating.start()
      Pages.animating.waiting.should.be.true

      Pages.animating.wait(callback)
      callback.should.not.have.been.called

      Pages.animating.end()
      callback.should.not.have.been.called
      Pages.animating.waiting.should.be.false

  describe '.page()', ->

    it 'should find loaded page by url', ->
      html '<article class="page a" data-url="/a"></article>' +
           '<div data-url="/a"></div>'
      Pages.page('/a').should.have.class('a')

  describe '.pagesSelector', ->
    selector = null
    beforeEach -> selector = Pages.pagesSelector
    afterEach  -> Pages.pagesSelector = selector

    it 'should use in loaded page finding', ->
      html '<article class="page a" data-url="/a"></article>' +
           '<div data-url="/a"></div>'
      Pages.pagesSelector = 'div'
      Pages.page('/a').should.have.be('div')
