describe 'Pages', ->
  title      = null
  animations = null

  before ->
    title = document.title
    # Disable function, that can broke test page
    history.pushState = ->
    jQuery.ajax = ->

  beforeEach ->
    Pages._document = $('<div />')
    Pages.enable()
    animations = Pages.animations

  afterEach ->
    Pages.animating.end()
    document.title   = title
    Pages._pages     = []
    Pages.animation  = 'immediately'
    Pages.animations = animations
    Pages.disable()
    for method of Pages
      Pages[method]?.restore?()

  html = (string) ->
    Pages.disable()
    Pages._document = jQuery("<div>#{string}</div>")[0]
    Pages.init()
    Pages.enable()

  find = (selector) ->
    jQuery(selector, Pages._document)

  describe '.add()', ->

    it 'should add page description', ->
      Pages.add('.a-page', a: 1)
      Pages._pages.should.eql([{ selector: '.a-page', a: 1 }])

    it 'should add page with only load callback', ->
      load = ->
      Pages.add('.a-page', load)
      Pages._pages.should.eql([{ selector: '.a-page', load: load }])

  describe '.init()', ->

    it 'should trigger load events if Pages is enable', ->
      sinon.stub(Pages, '_loadEvent')
      html '<div />'
      Pages._loadEvent.should.have.been.calledWith($(Pages._document))

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
      $(Pages._document).data('events').click.should.to.have.length(1)

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
      (typeof $(Pages._document).data('events') ).should.eql('undefined')

  describe 'history events', ->

    it 'should not open page by popstate event without URL changes', ->
      sinon.spy(Pages, 'open')
      $(window).trigger('popstate.pages')
      Pages.open.should.not.have.been.calledWith('/')

    it 'should open page by popstate event, when URL change', ->
      Pages._lastUrl = null
      sinon.spy(Pages, 'open')
      $(window).trigger('popstate.pages')
      Pages.open.should.have.been.calledWith('/')

    it 'should open page by link click', ->
      sinon.spy(Pages, '_openLink')
      html '<a></a>'
      find('a').click()
      Pages._openLink.should.have.been.called

  describe '.open()', ->

    it 'should open loaded page', ->
      html '<article class="page a" data-url="/a"></article>'

      a = find('.a')
      sinon.stub(Pages, '_openPage')
      sinon.stub(Pages, 'page').withArgs('/a').returns(a)

      Pages.open('/a').should.be.true
      Pages._openPage.should.have.been.calledWith(a, { })
      Pages._lastUrl.should == '/a'

    it 'should load new page', ->
      html '<div><article class="page b" data-url="/b"></article></div>'
      Pages.current = find('.b')

      sinon.stub(Pages, '_openPage')
      sinon.stub(Pages, 'load').withArgs('/a', { a: 1 }).
        callsArgWith(2, '<article class="page a" data-url="/a"></article>')

      Pages.add('.a', sinon.spy())

      Pages.open('/a', { a: 1 }).should.be.false
      find('.a').should.be.exists

      Pages.load.should.have.been.called
      Pages._pages[0].load.should.have.been.called
      Pages._openPage.should.have.been.called
      find('.b').next().should.be('.a')

    it 'should load new page without current one', ->
      html '<div><article class="page b" data-url="/b"></article></div>'
      sinon.stub(Pages, '_openPage')
      sinon.stub(Pages, 'load').withArgs('/a', { a: 1 }).
        callsArgWith(2, '<article class="page a" data-url="/a"></article>')

      Pages.open('/a', { a: 1 })

      find('.a').prev().should.be('div')

  describe '.page()', ->

    it 'should find loaded page by url', ->
      html '<article class="page a" data-url="/a"></article>' +
           '<div data-url="/a"></div>'
      Pages.page('/a').should.have.class('a')

    it 'should allow set base nodes to find inside', ->
      html '<article class="page" data-url="/a"></article>' +
           '<article class="page b" data-url="/a">' +
             '<article class="page" data-url="/a"></article>' +
           '</article>'
      Pages.page('/a', find('.b')).should.have.length(2)

  describe '.pagesSelector', ->

    selector = null
    beforeEach -> selector = Pages.pagesSelector
    afterEach  -> Pages.pagesSelector = selector

    it 'should use in loaded page finding', ->
      html '<article class="page a" data-url="/a"></article>' +
           '<div data-url="/a"></div>'
      Pages.pagesSelector = 'div'
      Pages.page('/a').should.have.be('div')

  describe '.load()', ->

    after -> jQuery.get.restore?()

    it 'should use jQuery GET AJAX request', ->
      sinon.stub(jQuery, 'get')
      callback = ->
      Pages.load('/a', a: 1, callback)
      jQuery.get.should.have.been.calledWith('/a', callback)

  describe '.title()', ->

    it 'should change title', ->
      Pages.title('New')
      document.title.should.eql('New')

  describe '.animating', ->

    it 'should run callbacks now without running animation', ->
      callback = sinon.spy()
      Pages.animating.wait(callback)
      callback.should.have.been.called
      Pages.animating.waiting.should.be.false

    it 'should run callback, when animation will end', ->
      callback = sinon.spy()

      Pages.animating.start()
      Pages.animating.waiting.should.be.true

      Pages.animating.wait(callback)
      callback.should.not.have.been.called

      Pages.animating.end()
      callback.should.have.been.called
      Pages.animating.waiting.should.be.false

  describe '._loadEvent()', ->

    it 'should run load event', ->
      h = $('<div class="a"></div>' +
            '<div class="a"></div>' +
            '<div><div class="b"></div></div>')
      a = sinon.spy()
      b = sinon.spy()
      c = sinon.spy()
      Pages.add('.a', a)
      Pages.add('.b', b)
      Pages.add('.c', c)

      Pages._loadEvent(h)

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

  describe '._openLink()', ->

    beforeEach ->
      sinon.stub(Pages, 'open')
      sinon.stub(history, 'pushState')

    afterEach ->
      history.pushState.restore?()

    it 'should open url by link', ->
      html '<a href="/a" data-a="1"></a>'
      Pages._openLink(find('a'))
      Pages.open.should.have.been.calledWith('/a', a: 1)

    it 'should change document location', ->
      html '<a href="/a" data-a="1"></a>'
      Pages._openLink(find('a'))
      history.pushState.should.have.been.calledWith({ }, '', '/a')

    it 'should not open external url by link', ->
      html '<a href="http://example.com/"></a>'
      Pages._openLink(find('a'))
      Pages.open.should.not.have.been.called

    it 'should not open urb by disabled link', ->
      html '<a href="/a" data-pages-disable></a>'
      Pages._openLink(find('a'))
      Pages.open.should.not.have.been.called

  describe '._openPage()', ->

    it 'should should animated change pages', ->
      html '<article class="page a" data-url="/a"></article>' +
           '<article class="page b" data-url="/b" data-title="B" ' +
             'data-b="B" data-c="C"></article>'
      a = find('.a')
      b = find('.b')
      b.data(d: 'D')
      Pages.current = a

      sinon.stub(Pages, 'title')

      animationArgs = []
      Pages.animations.test = {
        animate: -> animationArgs = arguments
      }
      sinon.spy(Pages.animations.test, 'animate')
      Pages.animation = 'test'

      Pages.animating.start()
      Pages._openPage(b, { a: 'a', b: 'b' })
      Pages.animations.test.animate.should.not.have.been.called

      Pages.animating.end()
      Pages.title.should.have.been.calledWith('B')
      Pages.animations.test.animate.should.have.been.called
      Pages.current.should.be('.a')
      Pages.animating.waiting.should.be.true

      animationArgs[0].should.be('.a')
      animationArgs[1].should.be('.b')
      animationArgs[3].should.
        eql({ url: '/b', title: 'B', a: 'a', b: 'b', c: 'C', d: 'D' })

      animationArgs[2]()
      Pages.current.should.be('.b')
      Pages.animating.waiting.should.be.false

    it 'should not change title to undefined', ->
      html '<article data-url="/a"></article>'
      Pages.animations.a = { animate: sinon.spy() }
      Pages.animation = 'a'

      sinon.stub(Pages, 'title')
      Pages._openPage(find('article'))

      Pages.title.should.not.have.been.called

    it 'should take animation from page', ->
      html '<article data-url="/a" data-pages-animation="a"></article>'
      Pages.animations.a = { animate: sinon.spy() }
      Pages._openPage(find('article'))
      Pages.animations.a.animate.should.been.called

    it 'should take animation from link first', ->
      html '<article data-url="/a" data-pages-animation="a"></article>'
      Pages.animations.a = { animate: sinon.spy() }
      Pages.animations.b = { animate: sinon.spy() }
      Pages._openPage(find('article'), { pagesAnimation: 'b' })

      Pages.animations.a.animate.should.not.been.called
      Pages.animations.b.animate.should.been.called

  describe '.animations', ->

    describe '.immediately', ->

      it 'should hide old page and show new', ->
        html '<article class="page a"></article>' +
             '<article class="page b" style="display: hide"></article>'
        a    = find('.a')
        b    = find('.b')
        done = sinon.spy()

        Pages.animations.immediately.animate(a, b, done)

        a.css('display').should.eql('none')
        b.css('display').should.eql('block')
        done.should.have.been.called
