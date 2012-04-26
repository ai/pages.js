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

;(function($) {
  "use strict";

  // Pages.js
  window.Pages = {

    // Is history management disabled.
    disabled: true,

    // jQuery node for current page.
    //
    //   if ( Pages.current.is('.comments-page') ) { … }
    current: null,

    // Selector to find page blocks. Use to find loaded pages and detect
    // current one.
    //
    // Be default it is `article.page` (`article` tag with `page` class).
    //
    //  Pages.pagesSelector = '.page';
    pagesSelector: 'article.page',

    // Current animation name. For some page or link you can set
    // custom animation by `data-pages-animation` attribute.
    //
    //   Pages.animation = 'myOwnAnimation';
    animation: 'immediately',

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
    animations: { },

    // Add description for page with `selector`. Allow options:
    // * `load`: `function ($, $$, page)` which is called,
    //           when page is loaded (contained in document or loaded after
    //           by AJAX).
    //
    //   Pages.add('.comments-page', {
    //     load: function($, $$, page) {
    //       $$('.pagination').ajaxPagination();
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
    add: function(selector, options) {
      if ( typeof(options) == 'function' ) {
        options = { load: options };
      }
      options.selector = selector;
      this._pages.push(options);
    },

    // Run Pages.js. It’s called automatically on document ready.
    // It’s used for tests.
    init: function() {
      this._loadEvent($(this._document));
      this.current = $(this.pagesSelector + ':visible:first', this._document);
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
      if ( !this.disabled || !this.isSupported() ) {
        return false;
      }
      this.disabled = false;

      $(window).on('popstate.pages', function() {
        if ( Pages._lastUrl != location.href ) {
          Pages.open(location.pathname);
        }
      });

      $(this._document).on('click.pages', 'a', function() {
        return Pages._openLink($(this));
      });

      return true;
    },

    // Disable session history management. Pages will load by default browser
    // way without AJAX and animations.
    disable: function() {
      $(this._document).off('click.pages', 'a');
      $(window).off('popstate.pages');
      this.disabled = true;
    },

    // Show page by `url` with overrided page `data`. Return true if page is
    // already loaded and false if Pages request it from server.
    //
    //   setTimeout(function() {
    //     Pages.open('/gameover');
    //   }, 5000);
    open: function(url, data) {
      if ( typeof(data) == 'undefined' ) {
        data = { };
      }
      Pages._lastUrl = url;

      var page = this.page(url);
      if ( page.length ) {
        this._openPage(page, data);
        return true;
      } else {
        this.load(url, data, function(html) {
          var newHtml = $(html);
          if ( Pages.current.length ) {
            newHtml = newHtml.insertAfter(Pages.current);
          } else {
            newHtml = newHtml.appendTo(Pages._document);
          }
          Pages._loadEvent(newHtml);
          page = Pages.page(url, newHtml);
          if ( page.length ) {
            Pages._openPage(page, data);
          }
        });
        return false;
      }
    },

    // Find loaded page by URL in `data-url` attribute.
    // It use `Pages.pagesSelector` to detect pages tags.
    //
    //   if ( Pages.page('/comments').length ) {
    //     // Comment page is loaded to DOM
    //   }
    page: function(url, base) {
      if ( !base ) {
        base = $(this._document);
      }
      var selector = this.pagesSelector + '[data-url="' + url + '"]';
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
    load: function(url, data, callback) {
      $.get(url, callback);
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

    // Internal API to wait previous animation, before start new one.
    //
    //   Pages.animating.wait(function() {
    //     Pages.animating.start();
    //     // Animation code
    //     Pages.animating.end();
    //   });
    animating: {

      // List of callbacks, that wait end of current animation.
      _waiters: [],

      // True if some animation is played now.
      waiting: false,

      // Mark, that we start animation.
      start: function() {
        this.waiting = true;
      },

      // Mark, that current animation is ended.
      end: function() {
        this.waiting = false;
        var waiter;
        while ( waiter = this._waiters.pop() ) {
          waiter();
        }
      },

      // If there isn’t animation now, `callback` will be executed now.
      // Else `callback` will wait, until previous animation will call `end`.
      wait: function(callback) {
        if ( this.waiting ) {
          this._waiters.push(callback);
        } else {
          callback();
        }
      }

    },

    // Link to current `window.document`. It is used for tests.
    _document: document,

    // Arra of added pages options.
    _pages: [],

    // Prevent double load page on double click.
    _lastUrl: null,

    // Find pages in new content and trigger open event on them.
    _loadEvent: function(nodes) {
      var page, $$;
      for (var i = 0; i < this._pages.length; i++) {
        page = this._pages[i];
        if ( page.load ) {
          var div = nodes.filter(page.selector);
          div = div.add( nodes.find(page.selector) );
          if ( div.length ) {
            $$ = function(subselector) {
              return $(subselector, div);
            };
            page.load.call(div, $, $$, div);
          }
        }
      }
    },

    // Open URL from link.
    _openLink: function(link) {
      var href = link.attr('href');
      if ( !href || href[0] != '/' ) {
        return true;
      }
      if ( typeof(link.data('pagesDisable')) != 'undefined' ) {
        return true;
      }

      history.pushState({ }, '', href);
      this.open(href, link.data());
      return false;
    },

    // Open loaded page.
    _openPage: function(page, data) {
      data = $.extend(page.data(), data);
      var anim = data.pagesAnimation || Pages.animation;
      this.animating.wait(function() {
        if ( typeof(data.title) != 'undefined' ) {
          Pages.title(data.title);
        }
        Pages.animating.start();
        Pages.animations[anim].animate(Pages.current, page, function() {
          Pages.current = page;
          Pages.animating.end();
        }, data);
      });
    }

  };

  // The simplest “animation”. Just immediately hide/show pages
  // by CSS display property.
  Pages.animations.immediately = {
    animate: function(prev, next, done, data) {
      prev.hide();
      next.show();
      done();
    }
  }

  $(document).ready(function() {
    Pages._lastUrl = location.href;
    Pages.init();
    Pages.enable();
  });
}).call(this, jQuery);
