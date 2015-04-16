HTTPSource = require('./http');
http = require 'http';
AVBuffer = require '../../core/buffer'
rateLimit = require('rateLimit');


class HTTPLimitedSource extends HTTPSource
    constructor: (@url, @limit) ->
    	super @url

    start: ->
        if @response?
            return @response.resume()
        
        @request = (http.get @url)
        @request.on 'response', (@response) =>
            if @response.statusCode isnt 200
                return @errorHandler 'Error loading file. HTTP status code ' + @response.statusCode
            
            rateLimit(@response, @limit);
            @size = parseInt @response.headers['content-length']
            @loaded = 0
            
            @response.on 'data', (chunk) =>
                @loaded += chunk.length
                @emit 'progress', @loaded / @size * 100
                @emit 'data', new AVBuffer(new Uint8Array(chunk))
                
            @response.on 'end', =>
                @emit 'end'
                
            @response.on 'error', @errorHandler
            
        @request.on 'error', @errorHandler
        
module.exports = HTTPLimitedSource


