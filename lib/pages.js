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
    //   if ( Pages.current.is('.comments-page') )
    current: null,

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
      var page, $$;
      for (var i = 0; i < this._pages.length; i++) {
        page = this._pages[i];
        var div = $(page.selector, this._document);
        if ( div.length && page.load ) {
          $$ = function(subselector) {
            return $(subselector, div);
          };
          page.load.call(div, $, $$, div);
          this.current = div;
        }
      }
    },

    // Return true if browser support History pushState.
    //
    //  if ( !Pages.isSupported() ) {
    //    $('.old-browser-notice').show();
    //  }
    isSupported: function() {
      return !!(window.history && history.pushState);
    },

    // Show page by `url` with overrided page `params`.
    open: function(url, params) {
      //TODO
    },

    // Start session history management. It’s called automatically on
    // document ready. You can use it manually after `Pages.disable` calling.
    enable: function() {
      if ( !this.disabled || !this.isSupported() ) {
        return false;
      }
      this.disabled = false;

      $(window).on('popstate.pages', function() {
        Pages.open(location.pathname);
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

    // Link to current `window.document`. It is used for tests.
    _document: document,

    // Arra of added pages options.
    _pages: [],

    // Get page params from data attributes.
    _params: function(el) {
      var all  = el.data();
      var data = { };
      var name;
      for (var key in all) {
        if ( key.match(/^pages/) ) {
          name = key.replace(/^pages/, '');
          name = name[0].toLowerCase() + name.slice(1);
          data[name] = all[key];
        }
      }
      return data;
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

      this.open(href, this._params(link))
      return false;
    }

  }

  $(document).ready(function() {
    Pages.init();
    Pages.enable();
  });
}).call(this, jQuery);
