defaultStyle = require './PrettyError/defaultStyle'
ParsedError = require './ParsedError'
RenderKid = require 'RenderKid'
{object} = require 'utila'

q = RenderKid.quote

wrap = (tag, around = '') ->

	"\n<#{tag}>\n#{around}\n</#{tag}>\n"

module.exports = class PrettyError

	self = @

	@_getDefaultStyle: ->

		defaultStyle()

	constructor: ->

		@_renderer = new RenderKid

		@_style = self._getDefaultStyle()

		@_renderer.style @_style

	getStyle: ->

		@_style

	appendStyle: (toAppend) ->

		object.appendOnto @_style, toAppend

		@_renderer.style toAppend

		@

	_getRenderer: ->

		@_renderer

	render: (e, logIt = no, skipModules = no) ->

		obj = @getObject e, skipModules

		rendered = @_renderer.render(obj)

		if logIt is yes

			console.log rendered

		rendered

	getObject: (e, skipModules = no) ->

		unless e instanceof ParsedError

			e = new ParsedError e

		unless typeof skipModules is 'boolean' or Array.isArray skipModules

			throw Error "skipModules only accepts a boolean or an array of module names"

		header =

			kind: e.kind

			colon: ':'

			message: e.message

		traceItems = []

		for item, i in e.trace

			if skipModules isnt no and i > 0

				continue if skipModules is yes and item.modName is '[current]'

				continue if item.modName in skipModules

			traceItems.push item:

				header:

					pointer: do ->

						unless item.file?

							return ''

						{
							file: item.file

							colon: ':'

							line: item.line

						}

					what: item.what

				footer:

					addr: item.shortenedAddr

		obj = 'pretty-error':

			header: header

			trace: traceItems

		obj

	toMarkup: (e, skipModules = no) ->

		unless e instanceof ParsedError

			e = new ParsedError e

		unless typeof skipModules is 'boolean' or Array.isArray skipModules

			throw Error "skipModules only accepts a boolean or an array of module names"

		header = do ->

			kind = wrap 'kind', q e.kind

			colon = wrap 'colon', ':'

			message = wrap 'message', q e.message

			wrap 'header', kind + colon + '&nbsp;' + message

		traceItems = ''

		for item, i in e.trace

			if skipModules isnt no and i > 0

				continue if skipModules is yes and item.modName is '[current]'

				continue if item.modName in skipModules

			itemHeader = do ->

				pointer = do ->

					unless item.file?

						return ''

					file = wrap 'file', q item.file

					colon = wrap 'colon', ':'

					line = wrap 'line', q item.line

					file + colon + line

				what = wrap 'what', q item.what or ''

				wrap 'header', pointer + what

			itemFooter = do ->

				addr = wrap 'addr', q item.shortenedAddr

				wrap 'footer', addr

			traceItems += wrap 'item', itemHeader + itemFooter

		trace = wrap 'trace', traceItems

		markup = wrap 'pretty-error', header + trace

		markup


for prop in ['renderer'] then do ->

	methodName = '_get' + prop[0].toUpperCase() + prop.substr(1, prop.length)

	PrettyError::__defineGetter__ prop, -> do @[methodName]