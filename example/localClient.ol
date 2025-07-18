/*
 * Copyright (C) 2021 Fabrizio Montesi <famontesi@gmail.com>
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
// connector (JAR file) under "lib/"
from .. import WebSocketUtils, WebSocketHandlerInterface
from console import Console

service LocalClient {
	inputPort Input {
		location: "local"
		interfaces: WebSocketHandlerInterface
	}

	embed WebSocketUtils as wsutils
	embed Console as console

	main {
		wid = new
		print@console( "Connecting to the local server... " )()
		connect@wsutils( { id = wid, uri = "ws://localhost:8080" } )()
		println@console( "done!" )()
		[ onOpen() ] {
			println@console( "Sending Hello to the server" )()
			send@wsutils( { id = wid, message = "Hello" } )()

			provide
				[ onMessage( m ) ] {
					println@console( "Echo received: " + m.message )()
					print@console( "Closing websocket... " )()
					close@wsutils( { id = wid } )
					println@console( "done!" )()
				}
			until
				[ onClose() ]
				[ onError() ]
		}

		[ onError() ] {
			println@console( "Could not connect" )()
		}
	}
}
