class IDE.ContentSearchResultView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = 'content-search-result'
    options.paneType = 'searchResult'

    super options, data

    {result, stats, searchText, isCaseSensitive} = options

    for fileName, lines of result
      @addSubView new KDCustomHTMLView
        partial  : "#{fileName}"
        cssClass : 'filename'

      for line in lines
        if line.type is 'separator'
          @addSubView new KDCustomHTMLView
            cssClass : 'separator'
            partial  : '...'
        else
          view = @addSubView new KDCustomHTMLView
            tagName  : 'pre'
            cssClass : 'line'

          if line.occurence
            flags    = if isCaseSensitive then 'g' else 'gi'
            regExp   = new RegExp searchText, flags
            replaced = line.line.replace regExp, (match) -> """<p class="match" data-file-path="#{fileName}" data-line-number="#{line.lineNumber}">#{match}</p>"""
          else
            replaced = "<span>#{Encoder.htmlEncode line.line}</span>"

          view.updatePartial "<span class='line-number'>#{line.lineNumber}</span>#{replaced}"

  click: (event) ->
    {target} = event
    return unless  target.classList.contains 'match'

    filePath   = target.getAttribute 'data-file-path'
    lineNumber = target.getAttribute 'data-line-number'
    file       = FSHelper.createFileFromPath filePath

    file.fetchContents (err, contents) ->
      KD.getSingleton('appManager').tell 'IDE', 'openFile', file, contents, (editorPane) ->
        KD.utils.wait 500, -> # setting editor font size is kinda buggy, temp fix for it
          editorPane.goToLine lineNumber
