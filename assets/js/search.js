(function () {
  if (typeof PagefindUI === 'undefined') {
    document.getElementById('search').textContent =
      'Search index not built yet. Run `npx pagefind --site _site` or wait for the CI build.';
    return;
  }
  new PagefindUI({
    element: '#search',
    showImages: false,
    showSubResults: false,
    resetStyles: false,
    autofocus: true,
    translations: {
      placeholder: 'Search wisdoms…',
      clear_search: 'Clear',
      load_more: 'Load more',
      search_label: 'Search this site',
      filters_label: 'Filters',
      zero_results: 'No matches for [SEARCH_TERM]',
      many_results: '[COUNT] results for [SEARCH_TERM]',
      one_result: '[COUNT] result for [SEARCH_TERM]',
      alt_search: 'No matches for [SEARCH_TERM]. Showing results for [DIFFERENT_TERM] instead',
      search_suggestion: 'No matches for [SEARCH_TERM]. Try one of: [DIFFERENT_TERM]',
      searching: 'Searching for [SEARCH_TERM]…'
    }
  });
})();
