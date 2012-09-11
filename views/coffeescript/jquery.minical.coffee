# jQuery Minical Plugin
# http://github.com/camerond/jquery-minical
# version 0.5.3
#
# Copyright (c) 2012 Cameron Daigle, http://camerondaigle.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

date_tools =
  getMonthName: (date) ->
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    months[date.getMonth()]
  getDays: ->
    days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    $tr = $("<tr />")
    $("<th />").text(day).appendTo($tr) for day in days
    $tr
  getStartOfCalendarBlock: (date) ->
    firstOfMonth = new Date(date)
    firstOfMonth.setDate(1)
    new Date(firstOfMonth.setDate(1 - firstOfMonth.getDay()))

minical =
  offset:
    x: 0
    y: 5
  trigger: null
  align_to_trigger: true
  read_only: false
  two_months: false
  dropdowns:
    month: null
    day: null
    year: null
  date_format: (date) ->
    [date.getMonth()+1, date.getDate(), date.getFullYear()].join("/")
  from: null
  to: null
  date_changed: $.noop
  month_drawn: $.noop
  getDayClass: (date) ->
    return "minical_day_" + [date.getMonth() + 1, date.getDate(), date.getFullYear()].join("_")
  render: (date) ->
    date ?= @selected_day
    @months_to_render = if @two_months then 2 else 1

    $li = $("<li />", class: "minical_#{date_tools.getMonthName(date).toLowerCase()}")
    $li.html("
      <article>
        <header>
          <h1></h1>
          <a href='#' class='minical_prev'></a>
          <a href='#' class='minical_next'></a>
        </header>
      </article>
    ")
    $article = $li.find('article')
    $h1 = $li.find('header h1')

    renderDate = new Date(date);
    for m in [1..@months_to_render]
      $h1.append("#{date_tools.getMonthName(renderDate)} #{renderDate.getFullYear()}")
      $h1.append(" - ") unless m == @months_to_render
      
      month = @renderMonth(renderDate)
      month.find('table').prepend("<caption>#{date_tools.getMonthName(renderDate)}</caption>") if @months_to_render > 1
      month.addClass('minical_extra_month') if m > 1
      
      $article.append(month)
      
      renderDate.setMonth(renderDate.getMonth() + 1)

    $li.find(".minical_prev").hide() if @from and @from > date_tools.getStartOfCalendarBlock(date)
    $li.find(".#{@getDayClass(new Date())}").addClass("minical_today")
    $li.find(".#{@getDayClass(@selected_day)}").addClass("minical_selected").addClass("minical_highlighted") if @selected_day
    $li.find("td").not(".minical_disabled, .minical_past_month").eq(0).addClass("minical_highlighted") if !$li.find(".minical_highlighted").length
    $li.find(".minical_next").hide() if @to and @to < new Date($li.find("td").last().data("minical_date"))
    
    @month_drawn.apply(@$el)
    
    @$cal.addClass("minical_multiple_months") if @months_to_render > 1
    @$cal.empty().append($li)

  renderMonth: (date) ->
    $section = $('<section />')
    $section.html("
      <table>
        <thead>
          <tr>
          </tr>
        </thead>
        <tbody>
        </tbody>
      </table>
    ")

    days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    $tr = $section.find("tr")

    $("<th />", { text: day }).appendTo($tr) for day in days
    
    $tbody = $section.find("tbody")
    
    current_date = date_tools.getStartOfCalendarBlock(date)
    for w in [1..6]
      $tr = $("<tr />")
      for d in [1..7]
        $tr.append(@renderDay(current_date, date))
        current_date.setDate(current_date.getDate() + 1)
      $tr.appendTo($tbody) if $tr.find(".minical_day").length
    $section
  renderDay: (d, base_date) ->
    $td = $("<td />")
      .data("minical_date", new Date(d))
      .addClass(@getDayClass(d))
      .append($("<a />", {"href": "#"}).text(d.getDate()))
    current_month = d.getMonth()
    month = base_date.getMonth()
    $td.addClass("minical_disabled") if (@from and d < @from) or (@to and d > @to)
    if current_month > month || current_month == 0 and month == 11
      $td.addClass("minical_future_month")
    else if current_month < month
      $td.addClass("minical_past_month")
    else
      $td.addClass("minical_day")
  selectDay: (e) ->
    $td = $(e.target).closest("td")
    return false if $td.hasClass("minical_disabled")
    mc = $td.closest("ul").data("minical")
    mc.selected_day = new Date($td.data("minical_date"))
    if (mc.$el.is(":text"))
      mc.$el.val(mc.date_format(mc.selected_day))
      mc.date_changed.apply(mc.$input)
    else
      mc.dropdowns.$month.val(mc.selected_day.getMonth() + 1)
      mc.dropdowns.$day.val(mc.selected_day.getDate())
      mc.dropdowns.$year.val(mc.selected_day.getFullYear())
      mc.date_changed.apply(mc.dropdowns)
    mc.hideCalendar()
    false
  highlightDay: (e) ->
    $td = $(e.target).closest("td")
    klass = "minical_highlighted"
    $td.closest("tbody").find(".#{klass}").removeClass(klass)
    $td.addClass(klass)
  moveToDay: (x, y) ->
    return true if !@$cal.is(":visible")

    $selected = if @$cal.find(".minical_highlighted").length then @$cal.find(".minical_highlighted").last() else @$cal.find("tbody td").eq(0)
    
    $tr = $selected.closest("tr")
    
    move_from = $selected.data("minical_date")
    
    if $tr.parent().children().eq(0).is($tr)
      if ($selected.parent().children().eq(0).is($selected) and x == -1) or y == -1 then @prevMonth()
    else if $tr.parent().children().eq(-1).is($tr)
      if ($selected.parent().children().eq(-1).is($selected) and x == 1) or y == 1 then @nextMonth()

    move_to = new Date(move_from)
    
    move_to.setDate(move_from.getDate() + x + y * 7)
    
    @$cal.find(".#{@getDayClass(move_to)} a").last().trigger("mouseover")
    false
  nextMonth: (e) ->
    mc = if e then $(e.target).closest(".minical").data("minical") else @
    return false if !mc.$cal.find(".minical_next").is(":visible")
    next = new Date(mc.$cal.find("td").eq(8).data("minical_date"))
    next.setMonth(next.getMonth() + 1)
    mc.render(next)
    false
  prevMonth: (e) ->
    mc = if e then $(e.target).closest(".minical").data("minical") else @
    return false if !mc.$cal.find(".minical_prev").is(":visible")
    prev = new Date(mc.$cal.find("td").eq(8).data("minical_date"))
    prev.setMonth(prev.getMonth() - 1)
    mc.render(prev)
    false
  showCalendar: (e) ->
    mc = if e then $(e.target).data("minical") else @
    $other_cals = $("[id^='minical_calendar']").not(mc.$cal)
    $other_cals.data("minical").hideCalendar() if $other_cals.length
    return true if mc.$cal.is(":visible")
    offset = if mc.align_to_trigger then mc.$trigger.offset() else mc.$el.offset()
    height = if mc.align_to_trigger then mc.$trigger.outerHeight() else mc.$el.outerHeight()
    position =
      left: "#{offset.left + mc.offset.x}px",
      top: "#{offset.top + height + mc.offset.y}px"
    mc.render().css(position).show()
    overlap = mc.$cal.width() + mc.$cal.offset().left - $(window).width()
    if overlap > 0
      mc.$cal.css("left", offset.left - overlap- 10)
    mc.attachCalendarKeyEvents()
  hideCalendar: (e) ->
    mc = @
    if e and (e.type == "focusout" or e.type == "blur")
      mc = $(e.target).data("minical")
      setTimeout(->
        $e = $(document.activeElement)
        if !$e.is("body") and !$e.is(mc.$trigger) and !$e.is(mc.$el)
          mc.$cal.hide()
          mc.detachCalendarKeyEvents()
      , 1)
    else
      mc.$cal.hide()
      mc.detachCalendarKeyEvents()
  attachCalendarKeyEvents: ->
    mc = @
    $(document).off("keydown.minical_#{mc.id}")
    $(document).on("keydown.minical_#{mc.id}", (e) -> mc.keydown.call(mc, e))
  detachCalendarKeyEvents: ->
    $(document).off("keydown.minical_#{@id}")
  keydown: (e) ->
    key = e.which
    mc = @
    keys =
      9:  -> true                  # tab
      13: ->                       # enter
        mc.$cal.find(".minical_highlighted a").click()
        false
      37: -> mc.moveToDay(-1, 0)   # left
      38: -> mc.moveToDay(0, -1)   # up
      39: -> mc.moveToDay(1, 0)    # right
      40: -> mc.moveToDay(0, 1)    # down
    if keys[key]
      keys[key]()
    else if !e.metaKey and !e.ctrlKey
      false
  preventKeystroke: (e) ->
    mc = @
    if mc.$cal.is(":visible") then return true
    key = e.which
    keys =
      9:  -> true                  # tab
      13: ->                    # enter
          mc.showCalendar()
          false
    if keys[key] then return keys[key]() else return !mc.read_only
  dropdownChange: (e) ->
    mc = $(e.target).data("minical")
    dr = mc.dropdowns
    if dr.$year.val() and dr.$month.val() and dr.$day.val()
      mc.selected_day = new Date(dr.$year.val(), dr.$month.val() - 1, dr.$day.val())
    else
      mc.selected_day = new Date()
    mc.render() if mc.$cal.is(":visible")
  outsideClick: (e) ->
    $t = $(e.target)
    return true if $t.is(@$el) or $t.is(@$trigger) or $t.closest(".minical").length
    @hideCalendar()
  init: ->
    @id = $(".minical").length
    mc = @
    @$cal = $("<ul />", { id: "minical_calendar_#{@id}", class: "minical" }).data("minical", @).appendTo($("body"))
    if @trigger
      @$trigger = @$el.find(@trigger)
      @$trigger = @$el.parent().find(@trigger) if !@$trigger.length
      @$trigger
        .data("minical", @)
        .on("blur.minical", @hideCalendar)
        .on("focus.minical", @showCalendar)
        .on("click.minical", () ->
          mc.$trigger.focus()
          false
        )
    else
      @align_to_trigger = false
    if @$el.is("input")
      @$el
        .addClass("minical_input")
        .on("focus.minical click.minical", @showCalendar)
        .on("blur.minical", @hideCalendar)
        .on("keydown.minical", (e) -> mc.preventKeystroke.call(mc, e))
      @selected_day = if @$el.val() then new Date(@$el.val()) else new Date()
    else
      dr = @dropdowns
      dr.$year = @$el.find(dr.year).data("minical", @).change(@dropdownChange) if dr.year
      dr.$month = @$el.find(dr.month).data("minical", @).change(@dropdownChange) if dr.month
      dr.$day = @$el.find(dr.day).data("minical", @).change(@dropdownChange) if dr.day
      if !@from
        min_year = Math.min.apply(Math, dr.$year.children().map(() -> $(@).val() if $(@).val()).get())
        min_month = Math.min.apply(Math, dr.$month.children().map(() -> $(@).val() if $(@).val()).get())
        min_day = Math.min.apply(Math, dr.$day.children().map(() -> $(@).val() if $(@).val()).get())
        @from = new Date(min_year, min_month - 1, min_day)
      if !@to
        max_year = Math.max.apply(Math, dr.$year.children().map(() -> $(@).val()).get())
        @to = new Date(max_year, dr.$month.find("option").eq(-1).val() - 1, dr.$day.find("option").eq(-1).val())
      @align_to_trigger = true
      dr.$year.change()
    @$cal
      .on("click.minical", "td a", @selectDay)
      .on("hover.minical", "td a", @highlightDay)
      .on("click.minical", "a.minical_next", @nextMonth)
      .on("click.minical", "a.minical_prev", @prevMonth)
    $("body").on("click.minical touchend.minical", (e) => @outsideClick.call(@, e))

do (minical) ->
  $.fn.minical = (opts) ->
    @.each ->
      $e = $(@)
      data = $.extend(true, { $el: $e }, minical, opts)
      data.data = data
      $e.data("minical", data)
      data.init()
