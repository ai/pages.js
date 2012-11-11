describe 'Pages', ->
  title      = null
  animations = null

  before ->
    title = document.title
    # Disable function, that can broke test page
    history.pushState = ->
    jQuery.ajax = ->

  beforeEach ->
    Pages._doc = $('<div />')[0]
    Pages._current = $('')
    Pages.enable()
    animations = Pages.animations

  afterEach ->
    Pages.animating.end()
    document.title       = title
    Pages._pages         = []
    Pages._liveCallbacks = []
    Pages.animation      = 'immediately'
    Pages.animations     = animations
    Pages.disable()
    history.pushState.restore?()
    Pages[i]?.restore?() for i of Pages

  html = (string) ->
    Pages.disable()
    Pages._doc = document.implementation.createHTMLDocument('')
    $(Pages._doc.body).html(string)
    Pages.init()
    Pages.enable()

  find = (selector) ->
    jQuery(selector, Pages._doc)

  describe '.add()', ->

    it 'should add page description', ->
      Pages.add('.a-page', a: 1)
      Pages._pages.should.eql([{ selector: '.a-page', a: 1 }])

    it 'should add page with only load callback', ->
      load = ->
      Pages.add('.a-page', load)
      Pages._pages.should.eql([{ selector: '.a-page', load: load }])

    it 'should call load callback at all pages', ->
      callback = ($, $$, page) ->
        page.length.should.eql(2)

      Pages.add('.a', callback)
      html '<article class="page a"><a href=""></a></article>' +
           '<article class="page a"><a href=""></a></article>'

    it 'should pass arguments to callbacks', ->
      callback = ($, $$, page) ->
        $.should.eql(jQuery)
        $$('a').length.should.eql(1)
        this.should.eql(page)
        page.should.have.class('a')

      Pages.add('.a', load: ( -> ), open: ( -> ), close: ( -> ))
      sinon.stub(Pages._pages[0], 'load',  callback)
      sinon.stub(Pages._pages[0], 'open',  callback)
      sinon.stub(Pages._pages[0], 'close', callback)
      html '<article class="page a"><a href=""></a></article>' +
           '<article class="page b"><a href=""></a></article>'

      Pages._setCurrent(find('a'))
      Pages._setCurrent(find('b'))

    it 'should add new content listener', ->
      callback = ->
      Pages.add(callback)
      Pages._liveCallbacks.should.eql([callback])

  describe '.init()', ->

    it 'should trigger load events if Pages.js is enable', ->
      sinon.stub(Pages, '_enlive')
      html '<div />'
      Pages._enlive.should.have.been.calledWith($(Pages._doc))

    it 'should set current', ->
      html '<article class="page a"></article>'
      sinon.stub(Pages, '_findCurrent').returns(find('.a'))
      sinon.stub(Pages, '_setCurrent')
      Pages.init()
      Pages._setCurrent.should.been.calledWith(find('.a'))

  describe '.isSupported()', ->

    it 'should return boolean', ->
      Pages.isSupported().should.be.a('boolean')

  describe '.enable()', ->

    beforeEach -> Pages.disable()

    it 'should enable history management', ->
      Pages.enable().should.be.true
      Pages.disabled.should.be.false

    it 'should not enable without support', ->
      sinon.stub(Pages, 'isSupported').returns(false)
      Pages.enable().should.be.false
      Pages.disabled.should.be.true

    it 'should add events', ->
      Pages.enable()
      $(window).data('events').popstate.length.should.eql(1)
      $(Pages._doc).data('events').click.length.should.eql(1)

    it 'should not enabled twice', ->
      Pages.enable().should.be.true
      Pages.enable().should.be.false
      $(window).data('events').popstate.length.should.eql(1)

  describe '.disable()', ->

    it 'should disable history management', ->
      Pages.disable()
      Pages.disabled.should.be.true

    it 'should remove events', ->
      Pages.disable()
      (typeof $(window).data('events') ).should.eql('undefined')
      (typeof $(Pages._doc).data('events') ).should.eql('undefined')

  describe 'history events', ->

    it 'should not open page by popstate event without URL changes', ->
      sinon.spy(Pages, 'open')
      $(window).trigger('popstate.pages')
      Pages.open.should.not.have.been.called

    it 'should open page by popstate event, when URL change', ->
      Pages._lastUrl = null
      sinon.spy(Pages, 'open')
      $(window).trigger('popstate.pages')
      Pages.open.should.have.been.calledWith('/', url: '/', from: 'popstate')

    it 'should open page by link click', ->
      sinon.spy(Pages, '_openLink')
      html '<a></a>'
      find('a').click()
      Pages._openLink.should.have.been.called

  describe '.open()', ->

    beforeEach ->
      sinon.stub(Pages, '_openPage')
      sinon.stub(history, 'pushState')

    it 'should open loaded page', ->
      html '<article class="page a" data-url="/a"></article>'

      a = find('.a')
      sinon.stub(Pages, 'page').withArgs('/a').returns(a)

      Pages.open('/a').should.be.true
      Pages._openPage.should.have.been.calledWith(a, { url: '/a', from: 'js' })
      Pages._lastUrl.should == '/a'

    it 'should load new page', ->
      html '<div><article class="page b" data-url="/b"></article></div>'
      Pages.current = find('.b')
      sinon.stub Pages, '_loadPages', (url, data, callback) ->
        callback($('<article class="page a" data-url="/a"></article>').
          insertAfter(Pages.current))
      Pages.add('.a', sinon.spy())

      Pages.open('/a', { a: 1 }).should.be.false
      find('.a').should.be.exists
      Pages._loadPages.should.have.been.called
      Pages._openPage.should.have.been.called

    it 'should change url if it necessary', ->
      html '<article class="page a" data-url="/a"></article>'
      Pages.open('/a')
      history.pushState.should.have.been.calledWith({ }, '', '/a')

      Pages.open('/a')
      history.pushState.should.have.been.once

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
      Pages.page('/a', find('.b')).length.should.eql(2)

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
      sinon.stub(jQuery, 'get').returns(2)
      callback = ->
      Pages.load('/a', a: 1, callback).should.eql(2)
      jQuery.get.should.have.been.calledWith('/a', callback)

  describe '.stopLoading()', ->

    it 'should call abort in loading object', ->
      loading = { abort: sinon.spy() }
      Pages.stopLoading(loading)
      loading.abort.should.have.been.called

  describe '.title()', ->

    it 'should change title', ->
      Pages.title('New')
      document.title.should.eql('New')

  describe '.animating', ->

    afterEach ->
      Pages.animating[i].restore?() for i of Pages.animating

    it 'should run callbacks now without running animation', ->
      callback = sinon.spy()
      Pages.animating.wait(callback)
      callback.should.have.been.called
      Pages.animating.waiting.should.be.false

    it 'should run callback, when animation will end', ->
      callback = sinon.spy()

      Pages.animating.waiting = true

      Pages.animating.wait(callback)
      callback.should.not.have.been.called

      Pages.animating.end()
      callback.should.have.been.called
      Pages.animating.waiting.should.be.false

    it 'should have shortcut', ->
      done = null
      callback = (arg) -> done = arg
      sinon.spy(Pages.animating, 'wait')
      sinon.spy(Pages.animating, 'end')

      Pages.animating.run(callback)
      Pages.animating.waiting.should.be.true
      Pages.animating.end.should.not.have.been.called
      Pages.animating.wait.should.have.been.called
      done.should.be('function')

      done()
      Pages.animating.end.should.have.been.called

  describe '._enlive()', ->

    it 'should run load event', ->
      h = $('<div class="a"></div>' +
            '<div class="a"></div>' +
            '<div><div class="b"></div></div>')
      a  = sinon.spy()
      b1 = sinon.spy()
      b2 = sinon.spy()
      c  = sinon.spy()
      c  = sinon.spy()
      Pages.add('.a', a)
      Pages.add('.b', b1)
      Pages.add('.b', b2)

      Pages._enlive(h)

      a.should.have.been.calledOnce
      b1.should.have.been.calledOnce
      b2.should.have.been.calledOnce
      c.should.not.have.been.called

      h.filter('.a').data('pages').should.eql([Pages._pages[0]])
      h.find('.b').data('pages').should.eql([Pages._pages[1], Pages._pages[2]])

    it 'should run common content listeners', ->
      h = $('<div />')
      a = sinon.spy()
      Pages.add(a)
      Pages._enlive(h)

      a.should.have.been.calledOnce

  describe '._callbackArgs()', ->

    it 'should return arguments for callback', ->
      html '<div class="a"><a href="#"></a></div>' +
           '<div class="b"><a href="#"></a></div>'
      args = Pages._callbackArgs(find('.a'))

      args[0].should.eql(jQuery)
      args[1]('a').should.be('.a a')
      args[2].should.be('.a')

  describe '._callback()', ->

    it 'should run all callbacks', ->
      a = open: sinon.spy(), close: sinon.spy()
      b = open: sinon.spy()
      div = $('<div />').data(pages: [a, b])
      sinon.stub(Pages, '_callbackArgs', -> [1, 2, 3])

      Pages._callback(div, 'open')

      a.open.should.have.been.calledOnce
      b.open.should.have.been.calledOnce
      a.close.should.not.have.been.called

      Pages._callbackArgs.should.have.been.calledWith(div)
      a.open.should.have.been.calledWith(1, 2, 3)
      a.open.should.have.been.calledOn(div)

  describe '._setCurrent()', ->

    it 'should call open and close events', ->
      html '<article class="page a"></article>' +
           '<article class="page b"></article>'
      Pages.add('.a', open: sinon.spy(), close: sinon.spy())
      Pages.add('.b', open: sinon.spy(), close: sinon.spy())
      Pages._enlive($(Pages._doc))
      Pages.current = $('')

      Pages._setCurrent(find('.a'))
      Pages.current.should.eql(find('.a'))
      Pages._pages[0].open.should.have.been.calledOnce
      Pages._pages[1].open.should.not.have.been.called
      Pages._pages[0].close.should.not.have.been.called
      Pages._pages[1].close.should.not.have.been.called

      Pages._setCurrent(find('.b'))
      Pages.current.should.eql(find('.b'))
      Pages._pages[0].open.should.have.been.calledOnce
      Pages._pages[1].open.should.have.been.calledOnce
      Pages._pages[0].close.should.have.been.calledOnce
      Pages._pages[1].close.should.not.have.been.called

  describe '._openLink()', ->

    beforeEach -> sinon.stub(Pages, 'open')
    afterEach  -> location.hash = ''

    it 'should open url by link', ->
      html '<a href="/a" data-a="1"></a>'
      Pages._openLink(find('a')).should.be.false
      Pages.open.should.have.been.calledWith '/a',
        a:    1
        from: 'link'
        link: find('a')

    it 'should not open external url by link', ->
      html '<a href="http://example.com/"></a>'
      Pages._openLink(find('a')).should.be.true
      Pages.open.should.not.have.been.called

    it 'should not open urb by disabled link', ->
      html '<a href="/a" data-pages-disable></a>'
      Pages._openLink(find('a')).should.be.true
      Pages.open.should.not.have.been.called

    it 'should not call Pages.open without hash', ->
      html '<a href="/a#b"></a>'
      Pages._openLink(find('a')).should.be.false
      Pages.open.should.have.been.calledWith '/a', from: 'link', link: find('a')

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

      Pages.animating.waiting = true
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
      html '<article data-url="/a" data-page-animation="a"></article>'
      Pages.animations.a = { animate: sinon.spy() }
      Pages._openPage(find('article'))
      Pages.animations.a.animate.should.been.called

    it 'should take animation from link first', ->
      html '<article data-url="/a" data-page-animation="a"></article>'
      Pages.animations.a = { animate: sinon.spy() }
      Pages.animations.b = { animate: sinon.spy() }
      Pages._openPage(find('article'), { pageAnimation: 'b' })

      Pages.animations.a.animate.should.not.been.called
      Pages.animations.b.animate.should.been.called

    it 'should choose animation dynamically', ->
      Pages.add '.a', animation: -> 'a'
      html '<article class="page a" data-url="/a"></article>'
      Pages.animations.a = { animate: sinon.spy() }

      Pages._openPage(find('.a'))
      Pages.animations.a.animate.should.been.called

    it 'should not show animation when page will not be changed', ->
      html '<article class="page a" data-url="/a"></article>'
      Pages.current = find('.a')

      Pages.animations.test = { animate: sinon.spy() }
      Pages.animation = 'test'
      sinon.stub(Pages, '_setCurrent')

      Pages._openPage(find('.a'))

      Pages.animations.test.animate.should.not.been.called
      Pages._setCurrent.should.been.called

  describe '._loadPages()', ->

    it 'should load new page', ->
      html '<div><article class="page b" data-url="/b"></article></div>'
      Pages.current = find('.b')
      sinon.stub Pages, 'load', (url, data, callback) ->
        callback('<article class="page a" data-url="/a"></article>')
      callback = sinon.spy()
      Pages.add('.a', sinon.spy())

      Pages._loadPages('/a', { }, callback)

      find('.a').should.be.exists
      callback.should.have.been.called

      Pages.load.should.have.been.called
      Pages._pages[0].load.should.have.been.called
      find('.b').next().should.be('.a')

    it 'should load new page without current one', ->
      html '<div><article class="page b" data-url="/b"></article></div>'
      Pages.current = $('')
      sinon.stub Pages, 'load', (url, data, callback) ->
        callback('<article class="page a" data-url="/a"></article>')
      Pages._loadPages('/a', { }, ->)
      find('.a').prev().should.be('div')

    it 'should tell to body that it load page', ->
      html ''
      body    = find('body')
      loading = sinon.spy()
      loaded  = sinon.spy()
      body.on('page-loading', loading).on('page-loaded', loaded)
      load = ->
      sinon.stub Pages, 'load', (url, data, callback) -> load = callback

      Pages._loadPages('/a', { a: 1 }, -> )

      body.should.have.class('page-loading')
      loading.should.have.been.called
      loaded.should.not.have.been.called

      load()
      body.should.not.have.class('page-loading')
      loaded.should.have.been.called

    it 'should tell to link that it load page', ->
      html '<a href="/a"></a>'
      a       = find('a')
      loading = sinon.spy()
      loaded  = sinon.spy()
      a.on('page-loading', loading).on('page-loaded', loaded)
      load = ->
      sinon.stub Pages, 'load', (url, data, callback) -> load = callback

      Pages._loadPages('/a', { link: a }, -> )

      a.should.have.class('page-loading')
      loading.should.have.been.called
      loaded.should.not.have.been.called

      load()
      a.should.not.have.class('page-loading')
      loaded.should.have.been.called

    it 'should abort previous loading', ->
      aborted = []
      sinon.stub Pages, 'load', (url, data, callback) ->
        { url: url, abort: -> aborted.push(url) }

      Pages._loadPages('/a', { }, -> )
      Pages._loading.url.should.eql('/a')
      aborted.should.eql([])

      Pages._loadPages('/b', { }, -> )
      Pages._loading.url.should.eql('/b')
      aborted.should.eql(['/a'])
