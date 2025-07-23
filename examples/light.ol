/*
 * Copyright (C) 2025 Matthias Wallnöfer <mdw@samba.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

// NOTICE: To run it, the Jolie WebSocket library called "main.ol"
// needs to be accessible in the parent directory (..) and the Java
// connector (JAR file) under "lib/".
// Furthermore, Jolie Leonardo needs to reside in the "leonardo/"
// directory with the webcontent under "light/"
from .. import WebSocketUtils, WebSocketHandlerInterface
from console import Console
from string-utils import StringUtils
from runtime import Runtime
from file import File
from json-utils import JsonUtils

constants {
	LEONARDO_ENDPOINT = "socket://localhost:8080/", // web-app
	WEBSOCKET_HOST = "localhost", // host for WebSocket connections
	WEBSOCKET_PORT = 8081, // port for WebSocket connections
}

service Light {
	inputPort Input {
		location: "local"
		interfaces: WebSocketHandlerInterface
	}

	embed WebSocketUtils as wsutils
	embed Console as console
	embed StringUtils as stringUtils
	embed Runtime as runtime
	embed File as file
	embed JsonUtils as jsonUtils

	execution: sequential

	init {
		endpoint =
"
const WEBSOCKET_HOST = '" + WEBSOCKET_HOST + "'
const WEBSOCKET_PORT = " + WEBSOCKET_PORT + "
"
		writeFile@file( {
			filename = "light/endpoint.js",
			content = endpoint
		})()

		print@console( "Binding to " + WEBSOCKET_HOST + ":" + WEBSOCKET_PORT + "..." )()
		bind@wsutils( { host = WEBSOCKET_HOST, port = WEBSOCKET_PORT, tcpNoDelay = true } )()
		println@console( "done!" )()

		web.wwwDir = "light"
		web.location = LEONARDO_ENDPOINT
		web.defaultPage = "index.html"

		loadEmbeddedService@runtime( {
			filepath = "leonardo/main.ol"
			service = "Leonardo"
			params -> web
		})()

		global.light = false // initial light state off
	}

	main {
		[ onStart() ]

		[ onOpen() ] {
			println@console( "Client arrived" )()
		}
		[ onClose() ] {
			println@console( "Client gone" )()
		}

		[ onMessage( m ) ] {
			println@console( "Message received: " + m.message )()
			message << getJsonValue@jsonUtils( m.message )
			if ( message.type == "getLight" ) {
				println@console( "Requesting current light state..." )()
				message << { type = "setLight", payload = global.light } // defaults to off
				send@wsutils( { id = m.id,
								message = getJsonString@jsonUtils( message ) } )()
			} else if ( message.type == "toggleLight" ) {
				println@console( "Toggling light state..." )()
				global.light = !global.light
				message << { type = "setLight", payload = global.light } // toggle to on
				broadcast@wsutils( { message = getJsonString@jsonUtils( message ) } )()
			} else {
				println@console( "Unknown message type: " + message.type )()
			}
		}

		[ onError( m ) ] {
			if ( endsWith@stringUtils( m.id { suffix = WEBSOCKET_PORT } ) ) {
				println@console( "Server error: " + m.error )()
			} else {
				println@console( "Client error: " + m.error )()
			}
		}
	}
}
