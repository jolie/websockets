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
// connector (JAR file) under "lib/"
from .. import WebSocketUtils, WebSocketHandlerInterface
from console import Console
from string-utils import StringUtils

service LocalServer {
	inputPort Input {
		location: "local"
		interfaces: WebSocketHandlerInterface
	}

	embed WebSocketUtils as wsutils
	embed Console as console
	embed StringUtils as stringUtils

	execution: sequential

	init {
		print@console( "Binding to localhost:8080..." )()
		bind@wsutils( { host = "localhost", port = 8080 } )()
		println@console( "done!" )()
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
			println@console( "Message received, sending back message: " + m.message )()
			send@wsutils( { id = m.id, message = m.message } )()
//			broadcast@wsutils( { ids[0] = m.id, message = m.message } )()
			println@console( "done!" )()
		}

		[ onError( m ) ] {
			if ( endsWith@stringUtils( m.id { suffix = "8080" } ) ) {
				println@console( "Server error: " + m.error )()
			} else {
				println@console( "Client error: " + m.error )()
			}
		}
	}
}
