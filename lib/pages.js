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

    // Link to current `window.document`. It is used for tests.
    _document: document,

    // Arra of added pages options.
    _pages: [],

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

    // Run Pages.js. It is called automatically on document ready.
    // It is used for tests.
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
    }

  }

  $(document).ready(function() {
    Pages.init();
  });
}).call(this, jQuery);
