/*
 * Copyright 2012 Andrey “A.I.” Sitnik <andrey@sitnik.ru>,
 * sponsored by Evil Martians.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

;(function($, undefined) {
  "use strict";

  // Pages.js is a framework for History pushState. It allow you to manage
  // pages JS code and forget about low-level APIs.
  //
  // You need to:
  // 1. Wrap your page content (without layout, header and footer) into
  //    `<article class="page" data-url="/url" data-title="Page">…</article>`
  //    and set page URL to `data-url` and title to `data-title` attributes.
  // 2. Change your server code, to respond AJAX requests with only wrapped
  //    page content without layout. Just check `HTTP_X_REQUESTED_WITH`
  //    HTTP header to equal `"XMLHttpRequest"`.
  // 3. Load jQuery before Pages.js.
  var self = window.Pages = {

    // Is history management disabled.
    disabled: false,

    // jQuery node for current page.
    //
    //   if ( Pages.current.is('.comments-page') ) { … }
    current: $(),

    // Selector to find page blocks. Use to find loaded pages and detect
    // current one.
    //
    // Be default it is `article.page` (`article` tag with `page` class).
    //
    //  Pages.selector = '.page';
    selector: 'article.page',

    // Current animation name. For some page or link you can set
    // custom animation by `data-page-animation` attribute.
    //
    //   Pages.animation = 'myOwnAnimation';
    animation: 'fade',

    // Available animation to set in `Pages.animation`. See definitions below.
    //
    // You can add your own animation. Animation object must contain `animate`
    // function with 4 arguments:
    // * jQuery-node of current page.
    // * jQuery-node of next page.
    // * callback, that you must call, when animation will be end.
    // * data object with merged link and page datas
    //
    //   Pages.animations.slideUpDown = {
    //     animate: function (current, next, done, data) {
    //       var duration = data.duration || 600;
    //       current.slideUp(duration);
    //       next.slideDown(duration, done);
    //     }
    //   };
    //   Pages.animation = 'slideUpDown';
    animations: {
      // The simplest “animation”. Just immediately hide/show pages
      // by CSS display property.
      immediately: {
        animate: function(prev, next, done, data) {
          prev.hide();
          next.show();
          done();
        }
      },

      // Simple fade in/out animation.
      fade: {
        // Animation duration in milliseconds.
        duration: 300,

        animate: function(prev, next, done, data) {
          var half = this.duration / 2;
          prev.fadeOut(half, function() {
            next.fadeIn(half, done);
          });
        }
      },

    },

    // Add description for page with `selector`. Allow options:
    // * `load`: `function ($, $$, page)` which is called, when page is loaded
    //   (contained in document or loaded after by AJAX).
    //   Good place to add events handlers to HTML tags.
    // * `open`: `function ($, $$, page)` which is called, when page become
    //   to be visible (called on document ready and when URL is changed).
    // * `close`: `function ($, $$, page)` which is called, when page become
    //   to be hidden (URL changed and another page become to be open).
    // * `animation`: `function (prev)` to return animation, depend on
    //   previous page. For simple solution use `data-page-animation` attribute
    //   in page or link tags.
    //
    //   Pages.add('.comments-page', {
    //     load:  function($, $$, page) {
    //       $$('.add').click(function() {
    //         postNewComment();
    //       });
    //     },
    //     open:  function($, $$, page) {
    //       page.enableAutoUpdate();
    //     },
    //     close: function($, $$, page) {
    //       page.disableAutoUpdate();
    //     }
    //   });
    //
    // Callbacks get three arguments:
    // * `$`:    jQuery.
    // * `$$`:   jQuery finder only in page (a little bit faster, than $ and
    //           more safely). For example `$$('a')` is equal to
    //           `$('a', page)`.
    // * `page`: jQuery-nodes of pages with this selectors.
    //
    // You can pass `load` as second argument without another options:
    //
    //   Pages.add('.comments-page', function($, $$, page) {
    //     $$('.pagination').ajaxPagination();
    //   });
    //
    // You can set callback to be runned on every content added to DOM
    // (for example, to bind events for controls common for all pages).
    // Just miss `selector`:
    //
    //   Pages.add(function($, $$, content) {
    //     $$('[rel=submit]').click(function() {
    //       $(this).closest('form').submit();
    //     });
    //   });
    add: function(selector, options) {
      if ( options == undefined ) {
        self._liveCallbacks.push(selector);
      } else {
        if ( typeof(options) == 'function' ) {
          options = { load: options };
        }
        options.selector = selector;
        self._pages.push(options);
      }
    },

    // Run Pages.js. It’s called automatically on document ready.
    // It’s used for tests.
    init: function() {
      self._enlive($(self._doc));
      var current = self._findCurrent();
      if ( current.length ) {
        self._setCurrent(current);
      }
    },

    // Return true if browser support History pushState.
    //
    //   if ( !Pages.isSupported() ) {
    //     $('.old-browser-notice').show();
    //   }
    isSupported: function() {
      return !!(window.history && history.pushState);
    },

    // Start session history management. It’s called automatically on
    // document ready. You can use it manually after `Pages.disable` calling.
    enable: function() {
      if ( self._events || !self.isSupported() ) {
        return false;
      }
      self.disabled = false;
      self._events  = true;

      self.watchURL(function() {
        if ( self._lastUrl != self.getURL() ) {
          self.open(self.getURL(), { from: 'popstate' });
        }
      });

      $(self._doc).on('click.pages', 'a', function() {
        return self._openLink($(this));
      });

      return true;
    },

    // Disable session history management. Pages.js will load by default browser
    // way without AJAX and animations.
    disable: function() {
      $(self._doc).off('click.pages', 'a');
      self.unwatchURL();
      self.disabled = true;
      self._events = false;
    },

    // Show page by `url` with overrided page `data`. Return true if page is
    // already loaded and false if Pages.js request it from server.
    //
    //   setTimeout(function() {
    //     Pages.open('/gameover');
    //   }, 5000);
    open: function(url, data) {
      if ( self.getURL() != url ) {
        self.setURL(url);
      }

      if ( data == undefined ) {
        data = { };
      }
      if ( data.from == undefined ) {
        data.from = 'js';
      }
      data.url = url;
      self._lastUrl = url;

      var page = self.page(url);
      if ( page.length ) {
        self._openPage(page, data);
        return true;
      } else {
        self._loadPages(url, data, function(nodes) {
          nodes.hide();
          page = self.page(url, nodes);
          if ( page.length ) {
            self._openPage(page, data);
          }
        });
        return false;
      }
    },

    // Find loaded page by URL in `data-url` attribute.
    // It use `Pages.selector` to detect pages tags.
    //
    //   if ( Pages.page('/comments').length ) {
    //     // Comment page is loaded to DOM
    //   }
    page: function(url, base) {
      if ( !base ) {
        base = $(self._doc);
      }
      var selector = self.selector + '[data-url="' + url + '"]';
      return base.filter(selector).add(base.find(selector));
    },

    // Load page by url. It simple use `jQuery.get`, but allow you
    // to override it.
    //
    // Argument `data` contain page data from link, you can use it
    // in override method.
    //
    //   Page.load = function(url, data, callbacks) {
    //     $.post(url, { password: data.password }, callback);
    //   };
    //
    // Or you can override `load` method, to determine, that page is loaded
    // from AJAX (but `HTTP_X_REQUESTED_WITH` is better way):
    //
    //   Page.load = function(url, data, callbacks) {
    //     return $.get(url + '?no_layout=1', callback);
    //   };
    //
    // It must return some AJAX request object or ID to use it in `stopLoading`.
    // If you use non-jQuery AJAX, you need also override `stopLoading`.
    load: function(url, data, callback) {
      return $.get(url, callback);
    },

    // Stop current AJAX page loading. It just abort jQuery AJAX, but allow you
    // to override it.
    //
    // It will get as argument, what `load` was return.
    //
    // You need to override this method, only if your `load` override, don’t
    // return jQuery jqXHR object (`$.get` and `$.post` return correct jqXHR).
    stopLoading: function(loading) {
      loading.abort();
    },

    // Change document title. It is internal method, used by `Pages.open`,
    // you can override it for some special cases.
    //
    //   Pages.title = function(title) {
    //     document.title = title + ' - ' companyName;
    //   };
    title: function(title) {
      document.title = title;
    },

    // Preload pages from `url`. URL can contain several pages, and can be
    // different from pages URL.
    //
    //   Pages.preload('/posts/all');
    preload: function(url) {
      self._loadPages(url, { }, function(nodes) {
        nodes.hide();
      })
    },

    // Change document URL to `url`. By default it will use
    // `history.pushState`, but you can change it to support
    // your history library or some hacks.
    //
    //   Pages.setURL = function(url) {
    //     sessionStorage.setItem('currentPage', url);
    //   };
    setURL: function(url) {
      history.pushState({ }, '', url);
    },

    // Get current page URL. By default it will use `location.pathname`,
    // but you can change it to support your history library or some hacks.
    //
    //   Pages.getURL = function() {
    //     sessionStorage.getItem('currentPage');
    //   };
    getURL: function() {
      return location.pathname;
    },

    // Set `callback` to watch for current page URL changes.
    // By default it will bind to `popstate` event, but you can change it
    // to support your history library or some hacks.
    //
    //   var urlListener = null;
    //   Pages.watchURL = function() {
    //     var current, last = null;
    //     urlListener = setInterval(function() {
    //       current = sessionStorage.getItem('currentPage');
    //       if ( current != last ) {
    //         last = current;
    //         callback();
    //       }
    //     }, 100);
    //   };
    watchURL: function(callback) {
      $(window).on('popstate.pages', callback);
    },

    // Disable listening, which was set by `watchURL`.
    // By default it will unbind from `popstate` event, but you can change it
    // to support your history library or some hacks.
    //
    //   Pages.unwatchURL = function() {
    //     clearInterval(urlListener);
    //   };
    unwatchURL: function() {
      $(window).off('popstate.pages');
    },

    // Internal API to wait previous animation, before start new one.
    //
    //   Pages.animating.run(function(done) {
    //     // Animation code
    //     done();
    //   });
    animating: {

      // List of callbacks, that wait end of current animation.
      _waiters: [],

      // True if some animation is played now.
      waiting: false,

      // If there isn’t animation now, `callback` will be executed now.
      // Else `callback` will wait, until previous animation will call `end`.
      wait: function(callback) {
        if ( this.waiting ) {
          this._waiters.push(callback);
        } else {
          callback();
        }
      },

      // Mark, that current animation is ended.
      end: function() {
        this.waiting = false;
        var waiter;
        while ( waiter = this._waiters.pop() ) {
          waiter();
        }
      },

      // Wait for previous animation end, execute `callback` and run another
      // animations, only after `callback` will execute it first argument.
      //
      //   Pages.animating.run(function(done) {
      //     // Animation code
      //     done();
      //   });
      run: function(callback) {
        var animating = this;
        animating.wait(function() {
          animating.waiting = true;
          callback(function() {
            animating.end();
          });
        });
      }

    },

    // Link to current `window.document`. It is used for tests.
    _doc: document,

    // Arra of added pages options.
    _pages: [],

    // Prevent double load page on double click.
    _lastUrl: null,

    // Event listeners are already binded.
    _events: false,

    // Callbacks was setted by `Pages.live`.
    _liveCallbacks: [],

    // Find first current page.
    _findCurrent: function() {
      return $(self.selector + ':visible:first', self._doc)
    },

    // AJAX request, if some page is loading now.
    _loading: null,

    // Find pages in new content, set caches and trigger load event on them.
    _enlive: function(nodes) {
      var args = self._callbackArgs(divs)
      for (var i = 0; i < self._liveCallbacks.length; i++) {
        self._liveCallbacks[i].apply(nodes, args);
      }

      var page, pages;
      for (var i = 0; i < self._pages.length; i++) {
        page = self._pages[i];
        var divs = nodes.filter(page.selector);
        divs = divs.add( nodes.find(page.selector) );
        if ( divs.length ) {
          pages = divs.data('pages')
          if ( pages ) {
            pages.push(page);
          } else {
            divs.data('pages', [page]);
          }
          if ( page.load ) {
            page.load.apply(divs, self._callbackArgs(divs));
          }
        }
      }
    },

    // Return callback arguments.
    _callbackArgs: function(nodes) {
      var $$ = function(subselector) {
        return $(subselector, nodes);
      };
      return [$,  $$, nodes];
    },

    // Run _type_ callback on every pages in _div_.
    _callback: function(div, type, args) {
      if ( !div ) {
        return;
      }

      var page, pages = div.data('pages')
      if ( !pages ) {
        return;
      }

      for (var i = 0; i < pages.length; i++) {
        page = pages[i];
        if ( page[type] ) {
          page[type].apply(div, self._callbackArgs(div));
        }
      }
    },

    // Find page descriptions for current and next page and fire `close` and
    // `open` events.
    _setCurrent: function(next) {
      if ( self.current ) {
        self._callback(self.current, 'close');
      }
      self._callback(next, 'open');
      self.current = next;
    },

    // Open URL from link.
    _openLink: function(link) {
      var href = link.attr('href');
      if ( !href || href[0] != '/' ) {
        return true;
      }
      if ( link.data('pagesDisable') != undefined ) {
        return true;
      }

      var data  = link.data();
      data.link = link;
      data.from = 'link';

      href = href.split('#', 2);
      var path = href[0];
      var hash = href[1];

      self.open(path, data);
      if ( hash && location.hash != hash ) {
        location.hash = hash;
      }
      return false;
    },

    // Open loaded page.
    _openPage: function(page, data) {
      if ( page[0] == self.current[0] ) {
        self._setCurrent(page);
        return;
      }

      var anim, pageData = page.data();
      data = $.extend(pageData, data);

      if ( data.pageAnimation ) {
        anim = data.pageAnimation;
      } else {
        var pageAnimation = null;
        if ( pageData.pages ) {
          for (var i = 0; i < pageData.pages.length; i++) {
            pageAnimation = pageData.pages[i].animation;
          }
        }
        if ( pageAnimation ) {
          anim = pageAnimation(self.current);
        }
      }
      anim = anim || self.animation;

      self.animating.run(function(done) {
        if ( data.title != undefined ) {
          self.title(data.title);
        }
        self.animations[anim].animate(self.current, page, function() {
          done();
          self._setCurrent(page);
        }, data);
      });
    },

    // Internal method to load pages. Used in `open` and `preload`.
    _loadPages: function(url, data, callback) {
      var body = $('body', self._doc).addClass('page-loading');
        body.trigger('page-loading', data);
        if ( data.link ) {
          data.link.addClass('page-loading');
          data.link.trigger('page-loading', data);
        }

        if ( self._loading ) {
          self.stopLoading(self._loading);
        }

        self._loading = self.load(url, data, function(html) {
          self._loading = null;

          var nodes = $(html);
          if ( self.current.length ) {
            nodes = nodes.insertAfter(self.current);
          } else {
            nodes = nodes.appendTo(self._doc.body);
          }

          body.removeClass('page-loading');
          body.trigger('page-loaded', data);
          if ( data.link ) {
            data.link.removeClass('page-loading');
            data.link.trigger('page-loaded', data);
          }

          self._enlive(nodes);
          callback(nodes);
        });
    }

  };

  $(document).ready(function() {
    self._lastUrl = self.getURL();
    self.init();
    if ( !self.disabled ) {
      self.enable();
    }
  });

})(jQuery);
